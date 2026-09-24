const ApiError = require('../utils/ApiError');

function notFoundHandler(req, res, next) {
  next(ApiError.notFound(`No route: ${req.method} ${req.originalUrl}`));
}

// Central error handler — every response body follows the same shape
// the Flutter app's ErrorMapper expects: { message, ...details }.
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  let status = err.statusCode || 500;
  let message = err.message || 'Something went wrong on our end.';
  let details = err.details;

  // Mongoose validation error -> 422, matching the app's "validation" BankErrorType.
  if (err.name === 'ValidationError') {
    status = 422;
    message = Object.values(err.errors)
      .map((e) => e.message)
      .join(' ');
  }

  // Duplicate key (e.g. email already registered) -> 409.
  if (err.code === 11000) {
    status = 409;
    const field = Object.keys(err.keyPattern || { field: 1 })[0];
    message = `That ${field} is already in use.`;
  }

  // Malformed ObjectId in a route param -> 404, not a 500.
  if (err.name === 'CastError') {
    status = 404;
    message = 'Not found.';
  }

  if (status >= 500) {
    console.error('[error]', err);
  }

  res.status(status).json({
    message,
    ...(details ? { details } : {}),
  });
}

module.exports = { notFoundHandler, errorHandler };
