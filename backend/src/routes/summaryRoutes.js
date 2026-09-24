const express = require('express');
const { getSummary, getInsights } = require('../controllers/summaryController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

router.get('/summary', getSummary);
router.get('/insights', getInsights);

module.exports = router;
