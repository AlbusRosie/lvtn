const express = require('express');
const UserController = require('../controllers/UserController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { avatarUpload, optionalAvatarUpload } = require('../middlewares/AvatarUpload');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');
const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/users', router);

    // Public routes - no authentication required
    router.post('/login/admin', UserController.loginAdmin);
    router.post('/login/customer', UserController.loginCustomer);
    router.post('/register', optionalAvatarUpload, UserController.createUser);

    // Protected routes - authentication required
    router.use(verifyToken);
    
    // Admin-only routes
    router.post('/admin/create', optionalAvatarUpload, requireRole(['admin']), UserController.createUserByAdmin);
    
    // General protected routes
    router.delete('/', UserController.deleteAllUsers);
    router.get('/', UserController.getUsersByFilter);
    router.get('/:id', UserController.getUser);
    router.put('/:id', avatarUpload, UserController.updateUser);
    router.delete('/:id', UserController.deleteUser);
    
    router.all('/:id', methodNotAllowed);
    router.all('/', methodNotAllowed);
    router.all('/login/admin', methodNotAllowed);
    router.all('/login/customer', methodNotAllowed);
    router.all('/register', methodNotAllowed);
    router.all('/admin/create', methodNotAllowed);
}
