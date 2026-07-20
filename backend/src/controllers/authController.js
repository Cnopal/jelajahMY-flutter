const pool = require('../config/db');

const {
  firebaseAdminAuth,
} = require('../config/firebaseAdmin');

const {
  cloudinary,
} = require('../config/cloudinary');

function normaliseName({
  bodyName,
  tokenName,
  email,
}) {
  if (
    typeof bodyName === 'string' &&
    bodyName.trim().length >= 2
  ) {
    return bodyName.trim();
  }

  if (
    typeof tokenName === 'string' &&
    tokenName.trim().length >= 2
  ) {
    return tokenName.trim();
  }

  return email.split('@')[0];
}

function uploadBufferToCloudinary(
  buffer,
  firebaseUid,
) {
  return new Promise((resolve, reject) => {
    const uploadStream =
      cloudinary.uploader.upload_stream(
        {
          resource_type: 'image',
          folder: 'jelajahmy/profile-images',
          public_id: firebaseUid,
          overwrite: true,
          invalidate: true,

          transformation: [
            {
              width: 1000,
              height: 1000,
              crop: 'limit',
              quality: 'auto',
            },
          ],
        },
        (error, result) => {
          if (error) {
            reject(error);
            return;
          }

          if (!result?.secure_url) {
            reject(
              new Error(
                'Cloudinary did not return an image URL.',
              ),
            );
            return;
          }

          resolve(result);
        },
      );

    uploadStream.end(buffer);
  });
}

function normaliseOptionalText(
  value,
  maxLength,
) {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value !== 'string') {
    return null;
  }

  const trimmedValue = value.trim();

  if (!trimmedValue) {
    return null;
  }

  return trimmedValue.substring(0, maxLength);
}

function validateProfileInput(body) {
  const name =
    typeof body?.name === 'string'
      ? body.name.trim()
      : '';

  const phone = normaliseOptionalText(
    body?.phone,
    20,
  );

  const nationality = normaliseOptionalText(
    body?.nationality,
    100,
  );

  if (name.length < 2 || name.length > 100) {
    return {
      valid: false,
      message:
        'Name must contain between 2 and 100 characters.',
    };
  }

  if (
    phone &&
    !/^[0-9+\-()\s]{7,20}$/.test(phone)
  ) {
    return {
      valid: false,
      message:
        'Phone number contains invalid characters.',
    };
  }

  if (
    nationality &&
    nationality.length < 2
  ) {
    return {
      valid: false,
      message:
        'Nationality must contain at least 2 characters.',
    };
  }

  return {
    valid: true,
    data: {
      name,
      phone,
      nationality,
    },
  };
}

async function syncFirebaseUser(
  request,
  response,
  next,
) {
  try {
    const {
      uid,
      email,
      name: tokenName,
      picture,
      email_verified: emailVerified,
    } = request.firebaseUser;

    if (!uid || !email) {
      return response.status(400).json({
        success: false,
        message:
          'Firebase account does not contain a valid UID and email.',
      });
    }

    const name = normaliseName({
      bodyName: request.body?.name,
      tokenName,
      email,
    });

    const profileImageUrl =
      typeof picture === 'string' &&
      picture.trim()
        ? picture.trim()
        : null;

    const [existingUidRows] =
      await pool.execute(
        `
          SELECT id
          FROM users
          WHERE firebase_uid = ?
          LIMIT 1
        `,
        [uid],
      );

    let created = false;

    if (existingUidRows.length > 0) {
      /*
       * Preserve name, phone and nationality for
       * existing users. These fields are controlled
       * through the profile update endpoint.
       */
      await pool.execute(
        `
          UPDATE users
          SET
            email = ?,
            profile_image_url =
              COALESCE(?, profile_image_url)
          WHERE firebase_uid = ?
        `,
        [
          email,
          profileImageUrl,
          uid,
        ],
      );
    } else {
      const [existingEmailRows] =
        await pool.execute(
          `
            SELECT id, firebase_uid
            FROM users
            WHERE email = ?
            LIMIT 1
          `,
          [email],
        );

      if (existingEmailRows.length > 0) {
        return response.status(409).json({
          success: false,
          message:
            'This email is already linked to another database account.',
        });
      }

      await pool.execute(
        `
          INSERT INTO users (
            firebase_uid,
            name,
            email,
            profile_image_url
          )
          VALUES (?, ?, ?, ?)
        `,
        [
          uid,
          name,
          email,
          profileImageUrl,
        ],
      );

      created = true;
    }

    const [userRows] = await pool.execute(
      `
        SELECT
          id,
          firebase_uid,
          name,
          email,
          phone,
          nationality,
          profile_image_url,
          created_at,
          updated_at
        FROM users
        WHERE firebase_uid = ?
        LIMIT 1
      `,
      [uid],
    );

    return response
      .status(created ? 201 : 200)
      .json({
        success: true,
        message: created
          ? 'User created in the database.'
          : 'User synchronised successfully.',
        data: {
          ...userRows[0],
          email_verified:
            emailVerified === true,
        },
      });
  } catch (error) {
    return next(error);
  }
}

async function getAuthenticatedUser(
  request,
  response,
  next,
) {
  try {
    const {
      uid,
      email_verified: emailVerified,
    } = request.firebaseUser;

    const [userRows] = await pool.execute(
      `
        SELECT
          id,
          firebase_uid,
          name,
          email,
          phone,
          nationality,
          profile_image_url,
          created_at,
          updated_at
        FROM users
        WHERE firebase_uid = ?
        LIMIT 1
      `,
      [uid],
    );

    if (userRows.length === 0) {
      return response.status(404).json({
        success: false,
        message:
          'User has not been synchronised with the database.',
      });
    }

    return response.status(200).json({
      success: true,
      data: {
        ...userRows[0],
        email_verified:
          emailVerified === true,
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function updateAuthenticatedUserProfile(
  request,
  response,
  next,
) {
  const validationResult =
    validateProfileInput(request.body);

  if (!validationResult.valid) {
    return response.status(422).json({
      success: false,
      message: validationResult.message,
    });
  }

  const {
    name,
    phone,
    nationality,
  } = validationResult.data;

  const { uid, email_verified: emailVerified } =
    request.firebaseUser;

  let connection;

  try {
    connection = await pool.getConnection();

    await connection.beginTransaction();

    const [existingUsers] =
      await connection.execute(
        `
          SELECT id
          FROM users
          WHERE firebase_uid = ?
          LIMIT 1
          FOR UPDATE
        `,
        [uid],
      );

    if (existingUsers.length === 0) {
      await connection.rollback();

      return response.status(404).json({
        success: false,
        message:
          'User has not been synchronised with the database.',
      });
    }

    await connection.execute(
      `
        UPDATE users
        SET
          name = ?,
          phone = ?,
          nationality = ?
        WHERE firebase_uid = ?
      `,
      [
        name,
        phone,
        nationality,
        uid,
      ],
    );

    /*
     * Keep Firebase Authentication displayName
     * consistent with the MySQL profile.
     */
    await firebaseAdminAuth.updateUser(
      uid,
      {
        displayName: name,
      },
    );

    await connection.commit();

    const [updatedUserRows] =
      await pool.execute(
        `
          SELECT
            id,
            firebase_uid,
            name,
            email,
            phone,
            nationality,
            profile_image_url,
            created_at,
            updated_at
          FROM users
          WHERE firebase_uid = ?
          LIMIT 1
        `,
        [uid],
      );

    return response.status(200).json({
      success: true,
      message:
        'Profile updated successfully.',
      data: {
        ...updatedUserRows[0],
        email_verified:
          emailVerified === true,
      },
    });
  } catch (error) {
    if (connection) {
      await connection.rollback();
    }

    return next(error);
  } finally {
    if (connection) {
      connection.release();
    }
  }
}

async function uploadAuthenticatedUserProfileImage(
  request,
  response,
  next,
) {
    
  try {
    const { uid } = request.firebaseUser;

    if (!request.file?.buffer) {
      return response.status(400).json({
        success: false,
        message:
          'Please select a profile image.',
      });
    }
    

    const [existingUsers] =
      await pool.execute(
        `
          SELECT id
          FROM users
          WHERE firebase_uid = ?
          LIMIT 1
        `,
        [uid],
      );

    if (existingUsers.length === 0) {
      return response.status(404).json({
        success: false,
        message:
          'User has not been synchronised with the database.',
      });
    }

    const uploadResult =
      await uploadBufferToCloudinary(
        request.file.buffer,
        uid,
      );

    await pool.execute(
      `
        UPDATE users
        SET profile_image_url = ?
        WHERE firebase_uid = ?
      `,
      [
        uploadResult.secure_url,
        uid,
      ],
    );

    const [updatedUserRows] =
      await pool.execute(
        `
          SELECT
            id,
            firebase_uid,
            name,
            email,
            phone,
            nationality,
            profile_image_url,
            created_at,
            updated_at
          FROM users
          WHERE firebase_uid = ?
          LIMIT 1
        `,
        [uid],
      );

    return response.status(200).json({
      success: true,
      message:
        'Profile image updated successfully.',
      data: {
        ...updatedUserRows[0],
        email_verified:
          request.firebaseUser
            .email_verified === true,
      },
    });
  } catch (error) {
    console.error(
      'Profile image upload failed:',
      error.message,
    );

    return next(error);
  }
}

module.exports = {
  getAuthenticatedUser,
  syncFirebaseUser,
  updateAuthenticatedUserProfile,
  uploadAuthenticatedUserProfileImage,
};