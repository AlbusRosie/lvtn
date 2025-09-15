const express = require('express');
const TableController = require('../controllers/TableController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/tables', router);

    // Public 
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
    
    router.all('/', methodNotAllowed);
    router.all('/available', methodNotAllowed);
    router.all('/status/:status', methodNotAllowed);
    router.all('/branches', methodNotAllowed);
    router.all('/branches/:branch_id/floors', methodNotAllowed);
    router.all('/branches/:branch_id/floors/:floor_id/tables', methodNotAllowed);
    router.all('/branches/:branch_id/tables/:table_number', methodNotAllowed);
    router.all('/branches/:branch_id/floors/:floor_id/generate-number', methodNotAllowed);
    router.all('/statistics', methodNotAllowed);
    
    // Admin
    router.use(verifyToken);
    router.use(requireRole(['admin']));
    router.post('/', TableController.createTable);
    router.put('/:id', TableController.updateTable);
    router.patch('/:id/status', TableController.updateTableStatus);
    router.delete('/:id', TableController.deleteTable);
    
    router.all('/:id', methodNotAllowed);
}