// Wraps an async Express handler so a rejected promise is forwarded to
// next(err) instead of crashing the process. Every controller uses this
// instead of a try/catch block.
function asyncHandler(fn) {
  return function wrapped(req, res, next) {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = asyncHandler;
