const express = require('express');
const TableController = require('../controllers/TableController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();
const tableController = new TableController();

router.get('/', tableController.getAllTables.bind(tableController));

router.get('/available', tableController.getAvailableTables.bind(tableController));

router.get('/status/:status', tableController.getTablesByStatus.bind(tableController));

router.get('/branches', tableController.getAllBranches.bind(tableController));

router.get('/branches/:branch_id/floors', tableController.getFloorsByBranch.bind(tableController));

router.get('/branches/:branch_id/floors/:floor_id/tables', tableController.getTablesByBranchAndFloor.bind(tableController));

router.get('/branches/:branch_id/tables/:table_number', tableController.getTableByNumber.bind(tableController));

router.get('/branches/:branch_id/floors/:floor_id/generate-number', tableController.generateNextTableNumber.bind(tableController));

router.get('/statistics', tableController.getTableStatistics.bind(tableController));

router.get('/:id', tableController.getTableById.bind(tableController));
router.use(verifyToken);

router.post('/', requireRole(['admin']), tableController.createTable.bind(tableController));

router.put('/:id', requireRole(['admin']), tableController.updateTable.bind(tableController));

router.patch('/:id/status', requireRole(['admin']), tableController.updateTableStatus.bind(tableController));

router.delete('/:id', requireRole(['admin']), tableController.deleteTable.bind(tableController));

module.exports = router;