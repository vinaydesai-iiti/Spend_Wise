const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../utils/jwt');
const bcrypt = require('bcryptjs');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Matches the AuthResult shape the Flutter app parses in
// features/auth/domain/auth_models.dart:
//   { accessToken, refreshToken?, user: { id, name, email } }
function authPayload(user, accessToken, refreshToken) {
  return { accessToken, refreshToken, user: user.toPublicJSON() };
}

// POST /auth/register — { name, email, password } -> AuthResult
// Not called by the shipped login screen (which only signs in), but every
// real backend needs a way to create the account the app then logs into.
const register = asyncHandler(async (req, res) => {
  const { name, email, password } = req.body || {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    throw ApiError.unprocessable('Name is required.');
  }
  if (!email || typeof email !== 'string' || !EMAIL_RE.test(email.trim())) {
    throw ApiError.unprocessable('Enter a valid email address.');
  }
  if (!password || typeof password !== 'string' || password.length < 6) {
    throw ApiError.unprocessable('Password must be at least 6 characters.');
  }

  const normalisedEmail = email.trim().toLowerCase();
  const existing = await User.findOne({ email: normalisedEmail });
  if (existing) {
    throw ApiError.conflict('An account with that email already exists.');
  }

  const user = new User({ name: name.trim(), email: normalisedEmail });
  await user.setPassword(password);

  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  user.refreshTokenHash = await bcrypt.hash(refreshToken, 10);
  await user.save();

  res.status(201).json(authPayload(user, accessToken, refreshToken));
});

// POST /auth/login — { email, password } -> AuthResult
// Mirrors AuthRepository.login exactly, including returning a 422 for
// bad credentials, which is what the Flutter app's mock already assumes.
const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body || {};

  if (!email || typeof email !== 'string' || !EMAIL_RE.test(email.trim())) {
    throw ApiError.unprocessable('Incorrect email or password.');
  }
  if (!password || typeof password !== 'string' || password.length < 6) {
    throw ApiError.unprocessable('Incorrect email or password.');
  }

  const normalisedEmail = email.trim().toLowerCase();
  const user = await User.findOne({ email: normalisedEmail }).select('+passwordHash');
  if (!user) {
    throw ApiError.unprocessable('Incorrect email or password.');
  }

  const ok = await user.comparePassword(password);
  if (!ok) {
    throw ApiError.unprocessable('Incorrect email or password.');
  }

  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  user.refreshTokenHash = await bcrypt.hash(refreshToken, 10);
  await user.save();

  res.status(200).json(authPayload(user, accessToken, refreshToken));
});

// POST /auth/refresh — { refreshToken } -> { accessToken, refreshToken }
// Not currently called by the app (it just bounces to /login on a 401),
// but the app already persists a refreshToken via SecureSessionStore, so
// this is here ready for the app to adopt silent refresh later.
const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body || {};
  if (!refreshToken) {
    throw ApiError.unprocessable('refreshToken is required.');
  }

  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch (err) {
    throw ApiError.unauthorized('Refresh token is invalid or expired.');
  }

  const user = await User.findById(payload.sub).select('+refreshTokenHash');
  if (!user || !user.refreshTokenHash) {
    throw ApiError.unauthorized('Refresh token is invalid or expired.');
  }
  const matches = await bcrypt.compare(refreshToken, user.refreshTokenHash);
  if (!matches) {
    throw ApiError.unauthorized('Refresh token is invalid or expired.');
  }

  const accessToken = signAccessToken(user);
  const newRefreshToken = signRefreshToken(user);
  user.refreshTokenHash = await bcrypt.hash(newRefreshToken, 10);
  await user.save();

  res.status(200).json({ accessToken, refreshToken: newRefreshToken });
});

// POST /auth/logout — best-effort, matches AuthRepository.logout: the app
// clears its local session regardless of this response. We invalidate the
// stored refresh token so it can't be replayed.
const logout = asyncHandler(async (req, res) => {
  if (req.userId) {
    await User.findByIdAndUpdate(req.userId, { refreshTokenHash: null });
  }
  res.status(204).send();
});

// GET /auth/me -> AppUser — handy for verifying a restored session.
const me = asyncHandler(async (req, res) => {
  res.status(200).json(req.user.toPublicJSON());
});

module.exports = { register, login, refresh, logout, me };
