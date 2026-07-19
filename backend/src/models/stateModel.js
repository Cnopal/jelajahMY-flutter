const pool = require("../config/db");

const getAllStates = async () => {
  const [rows] = await pool.execute(`
    SELECT
      id,
      name,
      code,
      description,
      image_url AS imageUrl
    FROM states
    ORDER BY name ASC
  `);

  return rows;
};

module.exports = {
  getAllStates,
};