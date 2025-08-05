const express = require('express');
const BranchController = require('../controllers/BranchController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();
const branchController = new BranchController();

// Get all branches (public)
router.get('/', branchController.getAllBranches.bind(branchController));

// Get branch by ID (public)
router.get('/:id', branchController.getBranchById.bind(branchController));

// Get branch statistics (public)
router.get('/statistics', branchController.getBranchStatistics.bind(branchController));

// Get active branches (public)
router.get('/active', branchController.getActiveBranches.bind(branchController));

// Apply auth middleware to protected routes
router.use(verifyToken);
router.use(requireRole(['admin']));

// Create new branch (admin only)
router.post('/', branchController.createBranch.bind(branchController));

// Update branch (admin only)
router.put('/:id', branchController.updateBranch.bind(branchController));

// Delete branch (admin only)
router.delete('/:id', branchController.deleteBranch.bind(branchController));

module.exports = router; 