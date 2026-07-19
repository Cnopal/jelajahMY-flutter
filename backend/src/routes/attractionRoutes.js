const express = require("express");

const {
  getAttractions,
  getAttractionById,
} = require("../controllers/attractionController");

const router = express.Router();

router.get("/", getAttractions);
router.get("/:id", getAttractionById);

module.exports = router;