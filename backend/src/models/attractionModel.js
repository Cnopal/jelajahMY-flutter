const pool = require("../config/db");

const attractionSelectQuery = `
  SELECT
    attractions.id,
    attractions.name,
    attractions.description,
    attractions.address,
    attractions.latitude,
    attractions.longitude,
    attractions.opening_hours AS openingHours,
    attractions.entrance_fee AS entranceFee,
    attractions.image_url AS imageUrl,

    states.id AS stateId,
    states.name AS stateName,
    states.code AS stateCode,

    categories.id AS categoryId,
    categories.name AS categoryName

  FROM attractions

  INNER JOIN states
    ON states.id = attractions.state_id

  INNER JOIN categories
    ON categories.id = attractions.category_id
`;

const getAllAttractions = async ({
  search,
  state,
  category,
}) => {
  let query = `
    ${attractionSelectQuery}
    WHERE 1 = 1
  `;

  const parameters = [];

  if (search) {
    const searchTerm = `%${search}%`;

    query += `
      AND (
        attractions.name LIKE ?
        OR attractions.description LIKE ?
        OR attractions.address LIKE ?
      )
    `;

    parameters.push(
      searchTerm,
      searchTerm,
      searchTerm
    );
  }

  if (state) {
    query += `
      AND (
        states.name = ?
        OR states.code = ?
      )
    `;

    parameters.push(state, state);
  }

  if (category) {
    query += `
      AND categories.name = ?
    `;

    parameters.push(category);
  }

  query += `
    ORDER BY attractions.name ASC
  `;

  const [rows] = await pool.execute(query, parameters);

  return rows;
};

const getAttractionById = async (id) => {
  const [rows] = await pool.execute(
    `
      ${attractionSelectQuery}
      WHERE attractions.id = ?
      LIMIT 1
    `,
    [id]
  );

  return rows[0] || null;
};

module.exports = {
  getAllAttractions,
  getAttractionById,
};