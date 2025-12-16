const express = require('express');
const UserController = require('../controllers/UserController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { avatarUpload, optionalAvatarUpload } = require('../middlewares/AvatarUpload');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');
const BranchMiddleware = require('../middlewares/BranchMiddleware');
const router = express.Router();
module.exports.setup = (app) => {
    app.use('/api/users', router);
    router.post('/login/admin', UserController.loginAdmin);
    router.post('/login/customer', UserController.loginCustomer);
    router.post('/register', optionalAvatarUpload, UserController.createUser);
    router.use(verifyToken);
    router.post('/admin/create', optionalAvatarUpload, requireRole(['admin', 'manager']), BranchMiddleware.enforceBranchAccess, UserController.createUserByAdmin);

    router.get('/', BranchMiddleware.enforceBranchAccess, UserController.getUsersByFilter);
    router.get('/:id', BranchMiddleware.validateResourceBranch('user'), UserController.getUser);
    router.put('/:id', avatarUpload, BranchMiddleware.validateResourceBranch('user'), UserController.updateUser);
    router.delete('/:id', requireRole(['admin']), UserController.deleteUser);
    router.all('/:id', methodNotAllowed);
    router.all('/', methodNotAllowed);
    router.all('/login/admin', methodNotAllowed);
    router.all('/login/customer', methodNotAllowed);
    router.all('/register', methodNotAllowed);
    router.all('/admin/create', methodNotAllowed);
}
