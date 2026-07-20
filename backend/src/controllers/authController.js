const pool = require('../config/db');

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
      typeof picture === 'string' && picture.trim()
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
      await pool.execute(
        `
          UPDATE users
          SET
            name = ?,
            email = ?,
            profile_image_url = ?
          WHERE firebase_uid = ?
        `,
        [
          name,
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
    const { uid } = request.firebaseUser;

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
      data: userRows[0],
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  getAuthenticatedUser,
  syncFirebaseUser,
};