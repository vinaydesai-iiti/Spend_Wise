const express = require('express');
const { getMerchants, getMerchantHistory } = require('../controllers/merchantController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

router.get('/', getMerchants);
router.get('/:merchantName/history', getMerchantHistory);

module.exports = router;
