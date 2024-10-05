const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const compression = require("compression");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");
const mongoSanitize = require("express-mongo-sanitize");
const xss = require("xss-clean");
const hpp = require("hpp");
const swaggerUi = require("swagger-ui-express");
const YAML = require("yamljs");
const swaggerDocument = require("../docs/api/swagger.json");
const routes = require("./routes");

//const routes = require("./routes");
const { errorMiddleware } = require("./middlewares/error.middleware");
const logger = require("./utils/logger");
const db = require("./config/database");

const app = express();

// Connect to MongoDB
db.connect();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "10kb" }));
app.use(express.urlencoded({ extended: true, limit: "10kb" }));
app.use(compression());
app.use(morgan("combined", { stream: logger.stream }));

// Security middleware
app.use(mongoSanitize());
app.use(xss());
app.use(
  hpp({
    whitelist: ["price", "createdAt", "updatedAt"],
  })
);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: "Too many requests from this IP, please try again later.",
});
app.use("/api", limiter);

//API documentation
console.log(swaggerDocument);
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Routes
app.use("/", routes);

// 404 handler
app.use((req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  error.status = 404;
  next(error);
});

// Error handling middleware
app.use(errorMiddleware);

module.exports = app;
