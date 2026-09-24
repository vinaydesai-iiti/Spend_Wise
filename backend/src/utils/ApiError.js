/**
 * A thrown ApiError carries the HTTP status the Flutter app's
 * ErrorMapper already knows how to map:
 *   401 -> BankErrorType.unauthorized ("session has expired")
 *   422 -> BankErrorType.validation   (message shown inline)
 *   anything else >=400 -> BankErrorType.server
 */
class ApiError extends Error {
  constructor(statusCode, message, details) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
  }

  static badRequest(message, details) {
    return new ApiError(400, message, details);
  }

  static unauthorized(message = 'Your session has expired. Please sign in again.') {
    return new ApiError(401, message);
  }

  static forbidden(message = 'You do not have access to this resource.') {
    return new ApiError(403, message);
  }

  static notFound(message = 'Not found.') {
    return new ApiError(404, message);
  }

  static conflict(message = 'That already exists.') {
    return new ApiError(409, message);
  }

  // 422 is the status the Flutter app's ErrorMapper treats specially —
  // it reads response.data.message and shows it as a validation error.
  static unprocessable(message, details) {
    return new ApiError(422, message, details);
  }
}

module.exports = ApiError;
