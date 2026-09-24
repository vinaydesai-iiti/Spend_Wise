const Category = require('../models/Category');
const asyncHandler = require('../utils/asyncHandler');

// GET /categories -> { items: Category[] }
// Not currently called by the app (it ships the same 8 categories
// statically in mock/mock_data.dart for their icon/color mapping), but
// exposed so the category list has a single authoritative source of
// truth on the server and the app can switch to it later.
const listCategories = asyncHandler(async (req, res) => {
  const categories = await Category.find().sort({ name: 1 });
  res.json({ items: categories.map((c) => c.toPublicJSON()) });
});

module.exports = { listCategories };
