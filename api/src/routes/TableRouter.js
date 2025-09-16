const express = require('express');
const TableController = require('../controllers/TableController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/tables', router);

    // Public 
    router.get('/', TableController.getAllTables);
    router.get('/branches/:branch_id/floors/:floor_id/tables', TableController.getTablesByBranchAndFloor);
    
    router.all('/', methodNotAllowed);
    router.all('/branches', methodNotAllowed);
    router.all('/branches/:branch_id/floors', methodNotAllowed);
    router.all('/branches/:branch_id/floors/:floor_id/tables', methodNotAllowed);
    
    // Admin
    router.use(verifyToken);
    router.use(requireRole(['admin']));
    router.post('/', TableController.createTable);
    router.put('/:id', TableController.updateTable);
    router.patch('/:id/status', TableController.updateTableStatus);
    router.delete('/:id', TableController.deleteTable);
    
}