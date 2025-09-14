const express = require('express');
const FloorController = require('../controllers/FloorController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();

router.get('/', FloorController.getAllFloors);

router.get('/:id', FloorController.getFloorById);

router.get('/branch/:branch_id', FloorController.getFloorsByBranch);

router.get('/statistics', FloorController.getFloorStatistics);

router.get('/active', FloorController.getActiveFloors);

router.get('/generate-number/:branch_id', FloorController.generateNextFloorNumber);


router.use(verifyToken);
router.use(requireRole(['admin']));

router.post('/', FloorController.createFloor);

router.put('/:id', FloorController.updateFloor);

router.delete('/:id', FloorController.deleteFloor);

module.exports = router;