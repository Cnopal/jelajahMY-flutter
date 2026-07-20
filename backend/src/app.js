const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const notFound = require("./middleware/notFound");
const errorHandler = require("./middleware/errorHandler");

const healthRoutes = require("./routes/healthRoutes");
const databaseRoutes = require("./routes/databaseRoutes");
const stateRoutes = require("./routes/stateRoutes");
const categoryRoutes = require("./routes/categoryRoutes");
const attractionRoutes = require("./routes/attractionRoutes");
const authRoutes = require('./routes/authRoutes');
const bookmarkRoutes = require(
  './routes/bookmarkRoutes',
);
const tripRoutes = require('./routes/tripRoutes');
const reviewRoutes = require('./routes/reviewRoutes');

const app = express();

// Add basic security headers
app.use(helmet());

// Allow requests from clients such as Flutter
app.use(cors());

// Read JSON request bodies
app.use(express.json({ limit: "10mb" }));

// Read URL-encoded request bodies
app.use(express.urlencoded({ extended: true }));

// Root endpoint
app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Welcome to JelajahMY API",
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use("/api/health", healthRoutes);
app.use("/api/database-health", databaseRoutes);
app.use("/api/states", stateRoutes);
app.use("/api/categories", categoryRoutes);
app.use("/api/attractions", attractionRoutes);
app.use(
  '/api/attractions/:attractionId/reviews',
  reviewRoutes,
);
app.use('/api/bookmarks', bookmarkRoutes);
app.use('/api/trips', tripRoutes);

// Handle unknown endpoints
app.use(notFound);

// Handle server errors
app.use(errorHandler);

module.exports = app;
