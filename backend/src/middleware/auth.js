const { verifyAccessToken } = require('../utils/jwt');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const User = require('../models/User');

/**
 * Requires `Authorization: Bearer <jwt>` — exactly what the Flutter app's
 * `_AuthInterceptor` in core/network/api_client.dart attaches to every
 * request once signed in. On success sets req.userId / req.user.
 * On failure throws a 401, which the app's ErrorMapper turns into
 * "Your session has expired. Please sign in again." and the router's
 * auth guard bounces the user back to /login.
 */
const requireAuth = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    throw ApiError.unauthorized('Missing or malformed Authorization header.');
  }

  let payload;
  try {
    payload = verifyAccessToken(token);
  } catch (err) {
    throw ApiError.unauthorized('Your session has expired. Please sign in again.');
  }

  const user = await User.findById(payload.sub);
  if (!user) {
    throw ApiError.unauthorized('Account no longer exists.');
  }

  req.userId = user._id;
  req.user = user;
  next();
});

module.exports = { requireAuth };
