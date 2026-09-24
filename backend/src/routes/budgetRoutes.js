const express = require('express');
const { getBudgets, setBudget } = require('../controllers/budgetController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

router.get('/', getBudgets);
router.put('/', setBudget);

module.exports = router;
