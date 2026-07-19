const errorHandler = (error, req, res, next) => {
  const statusCode = error.statusCode || error.status || 500;

  if (process.env.NODE_ENV !== "production") {
    console.error(error);
  }

  const response = {
    success: false,
    message: error.message || "Internal server error",
  };

  if (process.env.NODE_ENV !== "production") {
    response.stack = error.stack;
  }

  res.status(statusCode).json(response);
};

module.exports = errorHandler;