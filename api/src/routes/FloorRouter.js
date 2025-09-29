const express = require('express');
const FloorController = require('../controllers/FloorController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/floors', router);

    // Public
    router.get('/', FloorController.getAllFloors);
    router.get('/active', FloorController.getActiveFloors);
    router.get('/statistics', FloorController.getFloorStatistics);
    router.get('/branch/:branch_id', FloorController.getFloorsByBranch);
    router.get('/generate-number/:branch_id', FloorController.generateNextFloorNumber);
    router.get('/:id', FloorController.getFloorById);

    // Admin nhé
    router.use(verifyToken);
    router.use(requireRole(['admin']));

    router.post('/', FloorController.createFloor);
    router.put('/:id', FloorController.updateFloor);
    router.delete('/:id', FloorController.deleteFloor);
    
    router.all('/', methodNotAllowed);
    router.all('/active', methodNotAllowed);
    router.all('/statistics', methodNotAllowed);
    router.all('/branch/:branch_id', methodNotAllowed);
    router.all('/generate-number/:branch_id', methodNotAllowed);
    router.all('/:id', methodNotAllowed);
}