const pool = require('../config/db');

function parseAttractionId(value) {
  const attractionId = Number.parseInt(value, 10);

  if (
    !Number.isInteger(attractionId) ||
    attractionId <= 0
  ) {
    return null;
  }

  return attractionId;
}

async function getDatabaseUserId(firebaseUid) {
  const [userRows] = await pool.execute(
    `
      SELECT id
      FROM users
      WHERE firebase_uid = ?
      LIMIT 1
    `,
    [firebaseUid],
  );

  if (userRows.length === 0) {
    return null;
  }

  return userRows[0].id;
}

async function getBookmarks(
  request,
  response,
  next,
) {
  try {
    const userId = await getDatabaseUserId(
      request.firebaseUser.uid,
    );

    if (!userId) {
      return response.status(404).json({
        success: false,
        message:
          'User has not been synchronised with the database.',
      });
    }

    const [bookmarkRows] = await pool.execute(
      `
        SELECT
          a.id,
          a.state_id,
          s.name AS state_name,
          s.code AS state_code,
          a.category_id,
          c.name AS category_name,
          a.name,
          a.description,
          a.address,
          a.latitude,
          a.longitude,
          a.opening_hours,
          a.entrance_fee,
          a.image_url,
          b.created_at AS bookmarked_at
        FROM bookmarks b
        INNER JOIN attractions a
          ON a.id = b.attraction_id
        INNER JOIN states s
          ON s.id = a.state_id
        INNER JOIN categories c
          ON c.id = a.category_id
        WHERE b.user_id = ?
        ORDER BY b.created_at DESC
      `,
      [userId],
    );

    return response.status(200).json({
      success: true,
      count: bookmarkRows.length,
      data: bookmarkRows,
    });
  } catch (error) {
    return next(error);
  }
}

async function getBookmarkStatus(
  request,
  response,
  next,
) {
  try {
    const attractionId = parseAttractionId(
      request.params.attractionId,
    );

    if (!attractionId) {
      return response.status(400).json({
        success: false,
        message: 'Invalid attraction ID.',
      });
    }

    const userId = await getDatabaseUserId(
      request.firebaseUser.uid,
    );

    if (!userId) {
      return response.status(404).json({
        success: false,
        message:
          'User has not been synchronised with the database.',
      });
    }

    const [bookmarkRows] = await pool.execute(
      `
        SELECT id
        FROM bookmarks
        WHERE user_id = ?
          AND attraction_id = ?
        LIMIT 1
      `,
      [
        userId,
        attractionId,
      ],
    );

    return response.status(200).json({
      success: true,
      data: {
        attraction_id: attractionId,
        is_bookmarked:
          bookmarkRows.length > 0,
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function addBookmark(
  request,
  response,
  next,
) {
  try {
    const attractionId = parseAttractionId(
      request.params.attractionId,
    );

    if (!attractionId) {
      return response.status(400).json({
        success: false,
        message: 'Invalid attraction ID.',
      });
    }

    const userId = await getDatabaseUserId(
      request.firebaseUser.uid,
    );

    if (!userId) {
      return response.status(404).json({
        success: false,
        message:
          'User has not been synchronised with the database.',
      });
    }

    const [attractionRows] = await pool.execute(
      `
        SELECT id
        FROM attractions
        WHERE id = ?
        LIMIT 1
      `,
      [attractionId],
    );

    if (attractionRows.length === 0) {
      return response.status(404).json({
        success: false,
        message: 'Attraction was not found.',
      });
    }

    const [result] = await pool.execute(
      `
        INSERT INTO bookmarks (
          user_id,
          attraction_id
        )
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE
          id = id
      `,
      [
        userId,
        attractionId,
      ],
    );

    const created = result.affectedRows === 1;

    return response
      .status(created ? 201 : 200)
      .json({
        success: true,
        message: created
          ? 'Attraction added to bookmarks.'
          : 'Attraction is already bookmarked.',
        data: {
          attraction_id: attractionId,
          is_bookmarked: true,
        },
      });
  } catch (error) {
    return next(error);
  }
}

async function removeBookmark(
  request,
  response,
  next,
) {
  try {
    const attractionId = parseAttractionId(
      request.params.attractionId,
    );

    if (!attractionId) {
      return response.status(400).json({
        success: false,
        message: 'Invalid attraction ID.',
      });
    }

    const userId = await getDatabaseUserId(
      request.firebaseUser.uid,
    );

    if (!userId) {
      return response.status(404).json({
        success: false,
        message:
          'User has not been synchronised with the database.',
      });
    }

    const [result] = await pool.execute(
      `
        DELETE FROM bookmarks
        WHERE user_id = ?
          AND attraction_id = ?
      `,
      [
        userId,
        attractionId,
      ],
    );

    return response.status(200).json({
      success: true,
      message:
        result.affectedRows > 0
          ? 'Bookmark removed successfully.'
          : 'The attraction was not bookmarked.',
      data: {
        attraction_id: attractionId,
        is_bookmarked: false,
      },
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  addBookmark,
  getBookmarks,
  getBookmarkStatus,
  removeBookmark,
};