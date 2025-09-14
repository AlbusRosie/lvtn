const express = require('express');
const TableController = require('../controllers/TableController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();

router.get('/', TableController.getAllTables);

router.get('/available', TableController.getAvailableTables);

router.get('/status/:status', TableController.getTablesByStatus);

router.get('/branches', TableController.getAllBranches);

router.get('/branches/:branch_id/floors', TableController.getFloorsByBranch);

router.get('/branches/:branch_id/floors/:floor_id/tables', TableController.getTablesByBranchAndFloor);

router.get('/branches/:branch_id/tables/:table_number', TableController.getTableByNumber);

router.get('/branches/:branch_id/floors/:floor_id/generate-number', TableController.generateNextTableNumber);

router.get('/statistics', TableController.getTableStatistics);

router.get('/:id', TableController.getTableById);

router.use(verifyToken);

router.post('/', requireRole(['admin']), TableController.createTable);

router.put('/:id', requireRole(['admin']), TableController.updateTable);

router.patch('/:id/status', requireRole(['admin']), TableController.updateTableStatus);

router.delete('/:id', requireRole(['admin']), TableController.deleteTable);

module.exports = router;