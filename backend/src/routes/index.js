const express = require('express');

const authRoutes = require('./authRoutes');
const transactionRoutes = require('./transactionRoutes');
const summaryRoutes = require('./summaryRoutes'); // mounts /summary and /insights
const budgetRoutes = require('./budgetRoutes');
const merchantRoutes = require('./merchantRoutes');
const categoryRoutes = require('./categoryRoutes');

const router = express.Router();

router.get('/health', (req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

router.use('/auth', authRoutes);
router.use('/transactions', transactionRoutes);
router.use('/', summaryRoutes); // -> /summary, /insights (matches P05 §7 exactly)
router.use('/budgets', budgetRoutes);
router.use('/merchants', merchantRoutes);
router.use('/categories', categoryRoutes);

module.exports = router;
