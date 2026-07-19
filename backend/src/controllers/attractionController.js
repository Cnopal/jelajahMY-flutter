const attractionModel = require("../models/attractionModel");

const getAttractions = async (req, res, next) => {
  try {
    const filters = {
      search:
        typeof req.query.search === "string"
          ? req.query.search.trim()
          : "",

      state:
        typeof req.query.state === "string"
          ? req.query.state.trim()
          : "",

      category:
        typeof req.query.category === "string"
          ? req.query.category.trim()
          : "",
    };

    const attractions =
      await attractionModel.getAllAttractions(filters);

    return res.status(200).json({
      success: true,
      count: attractions.length,
      filters,
      data: attractions,
    });
  } catch (error) {
    return next(error);
  }
};

const getAttractionById = async (req, res, next) => {
  try {
    const attractionId = Number(req.params.id);

    if (
      !Number.isInteger(attractionId) ||
      attractionId <= 0
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid attraction ID",
      });
    }

    const attraction =
      await attractionModel.getAttractionById(
        attractionId
      );

    if (!attraction) {
      return res.status(404).json({
        success: false,
        message: "Attraction not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: attraction,
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getAttractions,
  getAttractionById,
};