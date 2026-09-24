const express = require('express');
const { listCategories } = require('../controllers/categoryController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.get('/', requireAuth, listCategories);

module.exports = router;
