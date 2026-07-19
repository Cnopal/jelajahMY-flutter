require("dotenv").config();

const app = require("./src/app");

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`JelajahMY API running at http://localhost:${PORT}`);
});

// Handle unexpected promise errors
process.on("unhandledRejection", (error) => {
  console.error("Unhandled rejection:", error);

  server.close(() => {
    process.exit(1);
  });
});

// Handle unexpected synchronous errors
process.on("uncaughtException", (error) => {
  console.error("Uncaught exception:", error);
  process.exit(1);
});