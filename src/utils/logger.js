const winston = require("winston");
const DailyRotateFile = require("winston-daily-rotate-file");
const { format } = winston;
const { combine, timestamp, printf, colorize, errors } = format;

const { NODE_ENV, LOG_LEVEL } = process.env;

// Define log format
const logFormat = printf(({ level, message, timestamp, stack }) => {
  return `${timestamp} ${level}: ${stack || message}`;
});

// Create rotate file transport for error logs
const errorLogRotateTransport = new DailyRotateFile({
  filename: "logs/error-%DATE%.log",
  datePattern: "YYYY-MM-DD",
  level: "error",
  maxSize: "20m",
  maxFiles: "14d",
  format: combine(timestamp(), errors({ stack: true }), logFormat),
});

// Create rotate file transport for combined logs
const combinedLogRotateTransport = new DailyRotateFile({
  filename: "logs/combined-%DATE%.log",
  datePattern: "YYYY-MM-DD",
  maxSize: "20m",
  maxFiles: "14d",
  format: combine(timestamp(), logFormat),
});

// Define transports
const transports = [errorLogRotateTransport, combinedLogRotateTransport];

// Add console transport in development environment
if (NODE_ENV !== "production") {
  transports.push(
    new winston.transports.Console({
      format: combine(
        colorize(),
        timestamp(),
        printf(({ level, message, timestamp, stack }) => {
          return `${timestamp} ${level}: ${stack || message}`;
        })
      ),
    })
  );
}

// Create the logger
const logger = winston.createLogger({
  level: LOG_LEVEL || "info",
  format: combine(timestamp(), errors({ stack: true }), logFormat),
  transports: transports,
  // Handling uncaught exceptions and unhandled promise rejections
  exceptionHandlers: [
    new winston.transports.File({ filename: "logs/exceptions.log" }),
  ],
  rejectionHandlers: [
    new winston.transports.File({ filename: "logs/rejections.log" }),
  ],
  exitOnError: false,
});

// Create a stream object with a 'write' function that will be used by morgan
logger.stream = {
  write: function (message, encoding) {
    logger.info(message);
  },
};

module.exports = logger;
