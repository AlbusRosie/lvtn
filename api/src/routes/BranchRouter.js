const express = require('express');
const BranchController = require('../controllers/BranchController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();


router.get('/', BranchController.getAllBranches);
router.get('/active', BranchController.getActiveBranches);
router.get('/statistics', BranchController.getBranchStatistics);
router.get('/:id', BranchController.getBranchById);


router.get('/managers', verifyToken, BranchController.getManagers);


router.use(verifyToken);
router.use(requireRole(['admin']));

router.post('/', BranchController.createBranch);
router.put('/:id', BranchController.updateBranch);
router.delete('/:id', BranchController.deleteBranch);

module.exports = router;