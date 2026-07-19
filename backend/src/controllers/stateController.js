const stateModel = require("../models/stateModel");

const getStates = async (req, res, next) => {
  try {
    const states = await stateModel.getAllStates();

    return res.status(200).json({
      success: true,
      count: states.length,
      data: states,
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getStates,
};