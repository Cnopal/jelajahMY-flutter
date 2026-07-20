const pool = require('../config/db');

function sendValidationError(response, message) {
  return response.status(400).json({
    success: false,
    message,
  });
}

function parsePositiveInteger(value) {
  const parsedValue = Number(value);

  if (!Number.isSafeInteger(parsedValue) || parsedValue <= 0) {
    return null;
  }

  return parsedValue;
}

function normaliseDate(value) {
  if (
    typeof value !== 'string' ||
    !/^\d{4}-\d{2}-\d{2}$/.test(value)
  ) {
    return null;
  }

  const [year, month, day] = value
    .split('-')
    .map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    return null;
  }

  return value;
}

function normaliseOptionalDate(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  return normaliseDate(value);
}

function normaliseOptionalTime(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  if (
    typeof value !== 'string' ||
    !/^([01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/.test(value)
  ) {
    return undefined;
  }

  return value.length === 5 ? `${value}:00` : value;
}

function normaliseTripInput(body) {
  const title =
    typeof body?.title === 'string'
      ? body.title.trim()
      : '';
  const startDate = normaliseDate(body?.startDate);
  const endDate = normaliseDate(body?.endDate);

  let notes = null;

  if (body?.notes !== null && body?.notes !== undefined) {
    if (typeof body.notes !== 'string') {
      return { error: 'Notes must be text.' };
    }

    notes = body.notes.trim() || null;
  }

  if (title.length < 2 || title.length > 150) {
    return {
      error: 'Title must contain between 2 and 150 characters.',
    };
  }

  if (!startDate || !endDate) {
    return {
      error: 'Start date and end date must use YYYY-MM-DD format.',
    };
  }

  if (startDate > endDate) {
    return { error: 'End date cannot be before start date.' };
  }

  return {
    value: {
      title,
      startDate,
      endDate,
      notes,
    },
  };
}

function dateWithinTrip(date, trip) {
  return (
    date === null ||
    (date >= trip.start_date && date <= trip.end_date)
  );
}

async function getDatabaseUser(connection, firebaseUid) {
  const [rows] = await connection.execute(
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

async function getOwnedTrip(
  connection,
  tripId,
  userId,
  { lock = false } = {},
) {
  const [rows] = await connection.execute(
    `
      SELECT
        id,
        user_id,
        title,
        DATE_FORMAT(start_date, '%Y-%m-%d') AS start_date,
        DATE_FORMAT(end_date, '%Y-%m-%d') AS end_date,
        notes,
        created_at,
        updated_at
      FROM trips
      WHERE id = ? AND user_id = ?
      LIMIT 1
      ${lock ? 'FOR UPDATE' : ''}
    `,
    [tripId, userId],
  );

  return rows[0] || null;
}

async function resolveUserOrRespond(connection, request, response) {
  const user = await getDatabaseUser(
    connection,
    request.firebaseUser.uid,
  );

  if (!user) {
    response.status(404).json({
      success: false,
      message: 'User has not been synchronised with the database.',
    });
    return null;
  }

  return user;
}

async function getTrips(request, response, next) {
  try {
    const user = await resolveUserOrRespond(
      pool,
      request,
      response,
    );

    if (!user) return undefined;

    const [rows] = await pool.execute(
      `
        SELECT
          t.id,
          t.title,
          DATE_FORMAT(t.start_date, '%Y-%m-%d') AS start_date,
          DATE_FORMAT(t.end_date, '%Y-%m-%d') AS end_date,
          t.notes,
          t.created_at,
          t.updated_at,
          COUNT(ti.id) AS item_count
        FROM trips t
        LEFT JOIN trip_items ti ON ti.trip_id = t.id
        WHERE t.user_id = ?
        GROUP BY t.id
        ORDER BY t.start_date ASC, t.created_at DESC
      `,
      [user.id],
    );

    return response.status(200).json({
      success: true,
      count: rows.length,
      data: rows,
    });
  } catch (error) {
    return next(error);
  }
}

async function getTrip(request, response, next) {
  try {
    const tripId = parsePositiveInteger(request.params.tripId);

    if (!tripId) {
      return sendValidationError(response, 'Invalid trip ID.');
    }

    const user = await resolveUserOrRespond(
      pool,
      request,
      response,
    );

    if (!user) return undefined;

    const trip = await getOwnedTrip(pool, tripId, user.id);

    if (!trip) {
      return response.status(404).json({
        success: false,
        message: 'Trip was not found.',
      });
    }

    const [items] = await pool.execute(
      `
        SELECT
          ti.id,
          ti.attraction_id,
          a.name AS attraction_name,
          a.address,
          a.latitude,
          a.longitude,
          a.image_url,
          s.name AS state_name,
          c.name AS category_name,
          DATE_FORMAT(ti.visit_date, '%Y-%m-%d') AS visit_date,
          TIME_FORMAT(ti.visit_time, '%H:%i:%s') AS visit_time,
          ti.sequence_number,
          ti.created_at
        FROM trip_items ti
        INNER JOIN attractions a ON a.id = ti.attraction_id
        INNER JOIN states s ON s.id = a.state_id
        INNER JOIN categories c ON c.id = a.category_id
        WHERE ti.trip_id = ?
        ORDER BY
          ti.visit_date IS NULL,
          ti.visit_date ASC,
          ti.sequence_number ASC,
          ti.created_at ASC
      `,
      [trip.id],
    );

    return response.status(200).json({
      success: true,
      data: {
        ...trip,
        items,
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function createTrip(request, response, next) {
  try {
    const input = normaliseTripInput(request.body);

    if (input.error) {
      return sendValidationError(response, input.error);
    }

    const user = await resolveUserOrRespond(
      pool,
      request,
      response,
    );

    if (!user) return undefined;

    const { title, startDate, endDate, notes } = input.value;
    const [result] = await pool.execute(
      `
        INSERT INTO trips (
          user_id,
          title,
          start_date,
          end_date,
          notes
        )
        VALUES (?, ?, ?, ?, ?)
      `,
      [user.id, title, startDate, endDate, notes],
    );

    const trip = await getOwnedTrip(
      pool,
      result.insertId,
      user.id,
    );

    return response.status(201).json({
      success: true,
      message: 'Trip created successfully.',
      data: trip,
    });
  } catch (error) {
    return next(error);
  }
}

async function updateTrip(request, response, next) {
  const tripId = parsePositiveInteger(request.params.tripId);

  if (!tripId) {
    return sendValidationError(response, 'Invalid trip ID.');
  }

  const input = normaliseTripInput(request.body);

  if (input.error) {
    return sendValidationError(response, input.error);
  }

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const user = await resolveUserOrRespond(
      connection,
      request,
      response,
    );

    if (!user) {
      await connection.rollback();
      return undefined;
    }

    const trip = await getOwnedTrip(
      connection,
      tripId,
      user.id,
      { lock: true },
    );

    if (!trip) {
      await connection.rollback();
      return response.status(404).json({
        success: false,
        message: 'Trip was not found.',
      });
    }

    const { title, startDate, endDate, notes } = input.value;
    const [invalidItems] = await connection.execute(
      `
        SELECT id
        FROM trip_items
        WHERE trip_id = ?
          AND visit_date IS NOT NULL
          AND (visit_date < ? OR visit_date > ?)
        LIMIT 1
      `,
      [trip.id, startDate, endDate],
    );

    if (invalidItems.length > 0) {
      await connection.rollback();
      return sendValidationError(
        response,
        'The new date range excludes one or more itinerary items.',
      );
    }

    await connection.execute(
      `
        UPDATE trips
        SET title = ?, start_date = ?, end_date = ?, notes = ?
        WHERE id = ? AND user_id = ?
      `,
      [title, startDate, endDate, notes, trip.id, user.id],
    );

    await connection.commit();
    const updatedTrip = await getOwnedTrip(pool, trip.id, user.id);

    return response.status(200).json({
      success: true,
      message: 'Trip updated successfully.',
      data: updatedTrip,
    });
  } catch (error) {
    await connection.rollback();
    return next(error);
  } finally {
    connection.release();
  }
}

async function deleteTrip(request, response, next) {
  try {
    const tripId = parsePositiveInteger(request.params.tripId);

    if (!tripId) {
      return sendValidationError(response, 'Invalid trip ID.');
    }

    const user = await resolveUserOrRespond(
      pool,
      request,
      response,
    );

    if (!user) return undefined;

    const [result] = await pool.execute(
      'DELETE FROM trips WHERE id = ? AND user_id = ?',
      [tripId, user.id],
    );

    if (result.affectedRows === 0) {
      return response.status(404).json({
        success: false,
        message: 'Trip was not found.',
      });
    }

    return response.status(200).json({
      success: true,
      message: 'Trip deleted successfully.',
    });
  } catch (error) {
    return next(error);
  }
}

async function addTripItem(request, response, next) {
  const tripId = parsePositiveInteger(request.params.tripId);
  const attractionId = parsePositiveInteger(request.body?.attractionId);

  if (!tripId) {
    return sendValidationError(response, 'Invalid trip ID.');
  }

  if (!attractionId) {
    return sendValidationError(response, 'Invalid attraction ID.');
  }

  const visitDate = normaliseOptionalDate(request.body?.visitDate);
  const visitTime = normaliseOptionalTime(request.body?.visitTime);
  const sequenceNumber =
    request.body?.sequenceNumber === undefined
      ? 1
      : parsePositiveInteger(request.body.sequenceNumber);

  if (
    request.body?.visitDate !== null &&
    request.body?.visitDate !== undefined &&
    request.body?.visitDate !== '' &&
    !visitDate
  ) {
    return sendValidationError(
      response,
      'Visit date must use YYYY-MM-DD format.',
    );
  }

  if (visitTime === undefined) {
    return sendValidationError(
      response,
      'Visit time must use HH:mm or HH:mm:ss format.',
    );
  }

  if (visitTime && !visitDate) {
    return sendValidationError(
      response,
      'A visit date is required when a visit time is provided.',
    );
  }

  if (!sequenceNumber || sequenceNumber > 4294967295) {
    return sendValidationError(
      response,
      'Sequence number must be a positive integer.',
    );
  }

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const user = await resolveUserOrRespond(
      connection,
      request,
      response,
    );

    if (!user) {
      await connection.rollback();
      return undefined;
    }

    const trip = await getOwnedTrip(
      connection,
      tripId,
      user.id,
      { lock: true },
    );

    if (!trip) {
      await connection.rollback();
      return response.status(404).json({
        success: false,
        message: 'Trip was not found.',
      });
    }

    if (!dateWithinTrip(visitDate, trip)) {
      await connection.rollback();
      return sendValidationError(
        response,
        'Visit date must be within the trip date range.',
      );
    }

    const [attractions] = await connection.execute(
      'SELECT id FROM attractions WHERE id = ? LIMIT 1',
      [attractionId],
    );

    if (attractions.length === 0) {
      await connection.rollback();
      return response.status(404).json({
        success: false,
        message: 'Attraction was not found.',
      });
    }

    const [duplicates] = await connection.execute(
      `
        SELECT id
        FROM trip_items
        WHERE trip_id = ? AND attraction_id = ?
        LIMIT 1
      `,
      [trip.id, attractionId],
    );

    if (duplicates.length > 0) {
      await connection.rollback();
      return response.status(409).json({
        success: false,
        message: 'Attraction is already included in this trip.',
      });
    }

    if (visitDate) {
      const [occupiedPositions] = await connection.execute(
        `
          SELECT id
          FROM trip_items
          WHERE trip_id = ?
            AND visit_date = ?
            AND sequence_number = ?
          LIMIT 1
        `,
        [trip.id, visitDate, sequenceNumber],
      );

      if (occupiedPositions.length > 0) {
        await connection.rollback();
        return response.status(409).json({
          success: false,
          message:
            'Another itinerary item already uses that day and position.',
        });
      }
    }

    const [result] = await connection.execute(
      `
        INSERT INTO trip_items (
          trip_id,
          attraction_id,
          visit_date,
          visit_time,
          sequence_number
        )
        VALUES (?, ?, ?, ?, ?)
      `,
      [
        trip.id,
        attractionId,
        visitDate,
        visitTime,
        sequenceNumber,
      ],
    );

    await connection.commit();

    return response.status(201).json({
      success: true,
      message: 'Attraction added to trip.',
      data: {
        id: result.insertId,
        trip_id: trip.id,
        attraction_id: attractionId,
        visit_date: visitDate,
        visit_time: visitTime,
        sequence_number: sequenceNumber,
      },
    });
  } catch (error) {
    await connection.rollback();
    return next(error);
  } finally {
    connection.release();
  }
}

async function removeTripItem(request, response, next) {
  try {
    const tripId = parsePositiveInteger(request.params.tripId);
    const itemId = parsePositiveInteger(request.params.itemId);

    if (!tripId || !itemId) {
      return sendValidationError(
        response,
        'Invalid trip or itinerary item ID.',
      );
    }

    const user = await resolveUserOrRespond(
      pool,
      request,
      response,
    );

    if (!user) return undefined;

    const [result] = await pool.execute(
      `
        DELETE ti
        FROM trip_items ti
        INNER JOIN trips t ON t.id = ti.trip_id
        WHERE ti.id = ? AND ti.trip_id = ? AND t.user_id = ?
      `,
      [itemId, tripId, user.id],
    );

    if (result.affectedRows === 0) {
      return response.status(404).json({
        success: false,
        message: 'Itinerary item was not found.',
      });
    }

    return response.status(200).json({
      success: true,
      message: 'Attraction removed from trip.',
    });
  } catch (error) {
    return next(error);
  }
}

function validateItineraryItems(rawItems, trip) {
  if (!Array.isArray(rawItems) || rawItems.length === 0) {
    return { error: 'Items must be a non-empty array.' };
  }

  const itemIds = new Set();
  const positions = new Set();
  const items = [];

  for (const rawItem of rawItems) {
    const itemId = parsePositiveInteger(rawItem?.itemId);
    const visitDate = normaliseOptionalDate(rawItem?.visitDate);
    const visitTime = normaliseOptionalTime(rawItem?.visitTime);
    const sequenceNumber = parsePositiveInteger(
      rawItem?.sequenceNumber,
    );

    if (!itemId || itemIds.has(itemId)) {
      return { error: 'Each itinerary item ID must be valid and unique.' };
    }

    if (
      rawItem?.visitDate !== null &&
      rawItem?.visitDate !== undefined &&
      rawItem?.visitDate !== '' &&
      !visitDate
    ) {
      return { error: 'Visit dates must use YYYY-MM-DD format.' };
    }

    if (!dateWithinTrip(visitDate, trip)) {
      return {
        error: 'Every visit date must be within the trip date range.',
      };
    }

    if (visitTime === undefined) {
      return {
        error: 'Visit times must use HH:mm or HH:mm:ss format.',
      };
    }

    if (visitTime && !visitDate) {
      return {
        error: 'A visit date is required when a visit time is provided.',
      };
    }

    if (!sequenceNumber || sequenceNumber > 4294967295) {
      return {
        error: 'Every sequence number must be a positive integer.',
      };
    }

    if (visitDate) {
      const positionKey = `${visitDate}:${sequenceNumber}`;

      if (positions.has(positionKey)) {
        return {
          error:
            'Sequence numbers must be unique within each itinerary day.',
        };
      }

      positions.add(positionKey);
    }

    itemIds.add(itemId);
    items.push({
      itemId,
      visitDate,
      visitTime,
      sequenceNumber,
    });
  }

  return { value: items };
}

async function updateItinerary(request, response, next) {
  const tripId = parsePositiveInteger(request.params.tripId);

  if (!tripId) {
    return sendValidationError(response, 'Invalid trip ID.');
  }

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const user = await resolveUserOrRespond(
      connection,
      request,
      response,
    );

    if (!user) {
      await connection.rollback();
      return undefined;
    }

    const trip = await getOwnedTrip(
      connection,
      tripId,
      user.id,
      { lock: true },
    );

    if (!trip) {
      await connection.rollback();
      return response.status(404).json({
        success: false,
        message: 'Trip was not found.',
      });
    }

    const validation = validateItineraryItems(
      request.body?.items,
      trip,
    );

    if (validation.error) {
      await connection.rollback();
      return sendValidationError(response, validation.error);
    }

    const itemIds = validation.value.map((item) => item.itemId);
    const placeholders = itemIds.map(() => '?').join(', ');
    const [ownedItems] = await connection.execute(
      `
        SELECT id
        FROM trip_items
        WHERE trip_id = ? AND id IN (${placeholders})
        FOR UPDATE
      `,
      [trip.id, ...itemIds],
    );

    if (ownedItems.length !== itemIds.length) {
      await connection.rollback();
      return response.status(404).json({
        success: false,
        message: 'One or more itinerary items were not found in this trip.',
      });
    }

    const [unchangedItems] = await connection.execute(
      `
        SELECT
          id,
          DATE_FORMAT(visit_date, '%Y-%m-%d') AS visit_date,
          sequence_number
        FROM trip_items
        WHERE trip_id = ?
          AND id NOT IN (${placeholders})
        FOR UPDATE
      `,
      [trip.id, ...itemIds],
    );

    const requestedPositions = new Set(
      validation.value
        .filter((item) => item.visitDate)
        .map(
          (item) => `${item.visitDate}:${item.sequenceNumber}`,
        ),
    );

    const hasPositionConflict = unchangedItems.some(
      (item) =>
        item.visit_date &&
        requestedPositions.has(
          `${item.visit_date}:${item.sequence_number}`,
        ),
    );

    if (hasPositionConflict) {
      await connection.rollback();
      return response.status(409).json({
        success: false,
        message:
          'Another itinerary item already uses a requested day and position.',
      });
    }

    for (const item of validation.value) {
      await connection.execute(
        `
          UPDATE trip_items
          SET visit_date = ?, visit_time = ?, sequence_number = ?
          WHERE id = ? AND trip_id = ?
        `,
        [
          item.visitDate,
          item.visitTime,
          item.sequenceNumber,
          item.itemId,
          trip.id,
        ],
      );
    }

    await connection.commit();

    return response.status(200).json({
      success: true,
      message: 'Itinerary updated successfully.',
      data: validation.value.map((item) => ({
        id: item.itemId,
        visit_date: item.visitDate,
        visit_time: item.visitTime,
        sequence_number: item.sequenceNumber,
      })),
    });
  } catch (error) {
    await connection.rollback();
    return next(error);
  } finally {
    connection.release();
  }
}

module.exports = {
  addTripItem,
  createTrip,
  deleteTrip,
  getTrip,
  getTrips,
  removeTripItem,
  updateItinerary,
  updateTrip,
};
