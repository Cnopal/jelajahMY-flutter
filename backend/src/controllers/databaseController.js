const pool = require("../config/db");

const getDatabaseHealth = async (req, res, next) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        DATABASE() AS databaseName,
        VERSION() AS databaseVersion,
        NOW() AS serverTime
    `);

    res.status(200).json({
      success: true,
      message: "MySQL database connection is working",
      database: rows[0].databaseName,
      version: rows[0].databaseVersion,
      serverTime: rows[0].serverTime,
    });
  } catch (error) {
    error.statusCode = 503;
    next(error);
  }
};

module.exports = {
  getDatabaseHealth,
};