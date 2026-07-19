const categoryModel = require("../models/categoryModel");

const getCategories = async (req, res, next) => {
  try {
    const categories = await categoryModel.getAllCategories();

    return res.status(200).json({
      success: true,
      count: categories.length,
      data: categories,
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getCategories,
};