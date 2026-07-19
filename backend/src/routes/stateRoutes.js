const express = require("express");

const { getStates } = require("../controllers/stateController");

const router = express.Router();

router.get("/", getStates);

module.exports = router;