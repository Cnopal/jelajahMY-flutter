const pool = require("../config/db");

const getAllCategories = async () => {
  const [rows] = await pool.execute(`
    SELECT
      id,
      name,
      description
    FROM categories
    ORDER BY name ASC
  `);

  return rows;
};

module.exports = {
  getAllCategories,
};