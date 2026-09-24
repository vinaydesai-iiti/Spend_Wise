const express = require('express');
const { getFeed, recategorise, exportCsv } = require('../controllers/transactionController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

// Declared before '/:id' so "export" is never swallowed as an :id param.
router.get('/export', exportCsv);
router.get('/', getFeed);
router.patch('/:id', recategorise);

module.exports = router;
