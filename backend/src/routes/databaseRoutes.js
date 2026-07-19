const express = require("express");

const {
  getDatabaseHealth,
} = require("../controllers/databaseController");

const router = express.Router();

router.get("/", getDatabaseHealth);

module.exports = router;