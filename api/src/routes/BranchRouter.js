const express = require('express');
const BranchController = require('../controllers/BranchController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/branches', router);

    // Public nè
    router.get('/', BranchController.getAllBranches);
    router.get('/active', BranchController.getActiveBranches);
    router.get('/statistics', BranchController.getBranchStatistics);
    router.get('/:id', BranchController.getBranchById);

    // Admin
    router.use(verifyToken);
    router.use(requireRole(['admin']));
    router.get('/managers', BranchController.getManagers);
    router.post('/', BranchController.createBranch);
    router.put('/:id', BranchController.updateBranch);
    router.delete('/:id', BranchController.deleteBranch);
    
    // Những route không được phép (đặt ở cuối)
    router.all('/', methodNotAllowed);
    router.all('/active', methodNotAllowed);
    router.all('/statistics', methodNotAllowed);
    router.all('/managers', methodNotAllowed);
    router.all('/:id', methodNotAllowed);
}