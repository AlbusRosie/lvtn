const express = require('express');
const FloorController = require('../controllers/FloorController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();
const floorController = new FloorController();

router.get('/', floorController.getAllFloors.bind(floorController));

router.get('/:id', floorController.getFloorById.bind(floorController));

router.get('/branch/:branch_id', floorController.getFloorsByBranch.bind(floorController));

router.get('/statistics', floorController.getFloorStatistics.bind(floorController));

router.get('/active', floorController.getActiveFloors.bind(floorController));

router.get('/generate-number/:branch_id', floorController.generateNextFloorNumber.bind(floorController));

router.use(verifyToken);
router.use(requireRole(['admin']));

router.post('/', floorController.createFloor.bind(floorController));

router.put('/:id', floorController.updateFloor.bind(floorController));

router.delete('/:id', floorController.deleteFloor.bind(floorController));

module.exports = router;