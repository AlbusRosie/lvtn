const express = require('express');
const BranchController = require('../controllers/BranchController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();
const branchController = new BranchController();

router.get('/', branchController.getAllBranches.bind(branchController));

router.get('/:id', branchController.getBranchById.bind(branchController));

router.get('/statistics', branchController.getBranchStatistics.bind(branchController));

router.get('/active', branchController.getActiveBranches.bind(branchController));
router.use(verifyToken);
router.use(requireRole(['admin']));

router.post('/', branchController.createBranch.bind(branchController));

router.put('/:id', branchController.updateBranch.bind(branchController));

router.delete('/:id', branchController.deleteBranch.bind(branchController));

module.exports = router;