const pool = require('../config/db');

const maximumCommentLength = 2000;

function parsePositiveInteger(value) {
  const parsedValue = Number(value);

  if (!Number.isSafeInteger(parsedValue) || parsedValue <= 0) {
    return null;
  }

  return parsedValue;
}

function validateReviewInput(body) {
  const rating = body?.rating;

  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    return { error: 'Rating must be an integer between 1 and 5.' };
  }

  let comment = null;

  if (body?.comment !== null && body?.comment !== undefined) {
    if (typeof body.comment !== 'string') {
      return { error: 'Comment must be text.' };
    }

    const trimmedComment = body.comment.trim();

    if (trimmedComment.length > maximumCommentLength) {
      return {
        error: `Comment cannot exceed ${maximumCommentLength} characters.`,
      };
    }

    comment = trimmedComment || null;
  }

  return { value: { rating, comment } };
}

function sendInvalidId(response, resource) {
  return response.status(400).json({
    success: false,
    message: `Invalid ${resource} ID.`,
  });
}

async function attractionExists(attractionId) {
  const [rows] = await pool.execute(
    'SELECT id FROM attractions WHERE id = ? LIMIT 1',
    [attractionId],
  );

  return rows.length > 0;
}

async function getDatabaseUser(firebaseUid) {
  const [rows] = await pool.execute(
    `
      SELECT id
      FROM users
      WHERE firebase_uid = ?
      LIMIT 1
    `,
    [firebaseUid],
  );

  return rows[0] || null;
}

async function resolveUserOrRespond(request, response) {
  const user = await getDatabaseUser(request.firebaseUser.uid);

  if (!user) {
    response.status(404).json({
      success: false,
      message: 'User has not been synchronised with the database.',
    });
    return null;
  }

  return user;
}

async function validateAttractionOrRespond(request, response) {
  const attractionId = parsePositiveInteger(request.params.attractionId);

  if (!attractionId) {
    sendInvalidId(response, 'attraction');
    return null;
  }

  if (!(await attractionExists(attractionId))) {
    response.status(404).json({
      success: false,
      message: 'Attraction was not found.',
    });
    return null;
  }

  return attractionId;
}

const reviewSelect = `
  SELECT
    r.id,
    r.rating,
    r.comment,
    r.image_url,
    r.created_at,
    r.updated_at,
    u.name AS reviewer_name,
    u.profile_image_url AS reviewer_profile_image_url
  FROM reviews r
  INNER JOIN users u ON u.id = r.user_id
`;

async function getReviews(request, response, next) {
  try {
    const attractionId = await validateAttractionOrRespond(
      request,
      response,
    );

    if (!attractionId) return undefined;

    const [reviews] = await pool.execute(
      `
        ${reviewSelect}
        WHERE r.attraction_id = ?
        ORDER BY r.created_at DESC, r.id DESC
      `,
      [attractionId],
    );

    return response.status(200).json({
      success: true,
      count: reviews.length,
      data: reviews,
    });
  } catch (error) {
    return next(error);
  }
}

async function getRatingSummary(request, response, next) {
  try {
    const attractionId = await validateAttractionOrRespond(
      request,
      response,
    );

    if (!attractionId) return undefined;

    const [rows] = await pool.execute(
      `
        SELECT
          ROUND(AVG(rating), 2) AS average_rating,
          COUNT(*) AS total_reviews
        FROM reviews
        WHERE attraction_id = ?
      `,
      [attractionId],
    );

    return response.status(200).json({
      success: true,
      data: {
        attraction_id: attractionId,
        average_rating:
          rows[0].average_rating === null
            ? 0
            : Number(rows[0].average_rating),
        total_reviews: Number(rows[0].total_reviews),
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function getCurrentUserReview(request, response, next) {
  try {
    const attractionId = await validateAttractionOrRespond(
      request,
      response,
    );

    if (!attractionId) return undefined;

    const user = await resolveUserOrRespond(request, response);

    if (!user) return undefined;

    const [reviews] = await pool.execute(
      `
        ${reviewSelect}
        WHERE r.attraction_id = ? AND r.user_id = ?
        LIMIT 1
      `,
      [attractionId, user.id],
    );

    return response.status(200).json({
      success: true,
      data: reviews[0] || null,
    });
  } catch (error) {
    return next(error);
  }
}

async function createReview(request, response, next) {
  try {
    const attractionId = await validateAttractionOrRespond(
      request,
      response,
    );

    if (!attractionId) return undefined;

    const input = validateReviewInput(request.body);

    if (input.error) {
      return response.status(400).json({
        success: false,
        message: input.error,
      });
    }

    const user = await resolveUserOrRespond(request, response);

    if (!user) return undefined;

    const [existingReviews] = await pool.execute(
      `
        SELECT id
        FROM reviews
        WHERE user_id = ? AND attraction_id = ?
        LIMIT 1
      `,
      [user.id, attractionId],
    );

    if (existingReviews.length > 0) {
      return response.status(409).json({
        success: false,
        message: 'You have already reviewed this attraction.',
      });
    }

    const { rating, comment } = input.value;
    let result;

    try {
      [result] = await pool.execute(
        `
          INSERT INTO reviews (
            user_id,
            attraction_id,
            rating,
            comment,
            image_url
          )
          VALUES (?, ?, ?, ?, NULL)
        `,
        [user.id, attractionId, rating, comment],
      );
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') {
        return response.status(409).json({
          success: false,
          message: 'You have already reviewed this attraction.',
        });
      }

      throw error;
    }

    const [reviews] = await pool.execute(
      `
        ${reviewSelect}
        WHERE r.id = ? AND r.user_id = ?
        LIMIT 1
      `,
      [result.insertId, user.id],
    );

    return response.status(201).json({
      success: true,
      message: 'Review created successfully.',
      data: reviews[0],
    });
  } catch (error) {
    return next(error);
  }
}

async function updateReview(request, response, next) {
  try {
    const attractionId = await validateAttractionOrRespond(
      request,
      response,
    );

    if (!attractionId) return undefined;

    const reviewId = parsePositiveInteger(request.params.reviewId);

    if (!reviewId) {
      return sendInvalidId(response, 'review');
    }

    const input = validateReviewInput(request.body);

    if (input.error) {
      return response.status(400).json({
        success: false,
        message: input.error,
      });
    }

    const user = await resolveUserOrRespond(request, response);

    if (!user) return undefined;

    const [ownedReviews] = await pool.execute(
      `
        SELECT id
        FROM reviews
        WHERE id = ? AND attraction_id = ? AND user_id = ?
        LIMIT 1
      `,
      [reviewId, attractionId, user.id],
    );

    if (ownedReviews.length === 0) {
      return response.status(404).json({
        success: false,
        message: 'Review was not found.',
      });
    }

    const { rating, comment } = input.value;
    await pool.execute(
      `
        UPDATE reviews
        SET rating = ?, comment = ?
        WHERE id = ? AND attraction_id = ? AND user_id = ?
      `,
      [rating, comment, reviewId, attractionId, user.id],
    );

    const [reviews] = await pool.execute(
      `
        ${reviewSelect}
        WHERE r.id = ? AND r.user_id = ?
        LIMIT 1
      `,
      [reviewId, user.id],
    );

    return response.status(200).json({
      success: true,
      message: 'Review updated successfully.',
      data: reviews[0],
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteReview(request, response, next) {
  try {
    const attractionId = await validateAttractionOrRespond(
      request,
      response,
    );

    if (!attractionId) return undefined;

    const reviewId = parsePositiveInteger(request.params.reviewId);

    if (!reviewId) {
      return sendInvalidId(response, 'review');
    }

    const user = await resolveUserOrRespond(request, response);

    if (!user) return undefined;

    const [result] = await pool.execute(
      `
        DELETE FROM reviews
        WHERE id = ? AND attraction_id = ? AND user_id = ?
      `,
      [reviewId, attractionId, user.id],
    );

    if (result.affectedRows === 0) {
      return response.status(404).json({
        success: false,
        message: 'Review was not found.',
      });
    }

    return response.status(200).json({
      success: true,
      message: 'Review deleted successfully.',
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createReview,
  deleteReview,
  getCurrentUserReview,
  getRatingSummary,
  getReviews,
  updateReview,
};
