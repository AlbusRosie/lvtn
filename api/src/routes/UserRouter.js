const express = require('express');
const UserController = require('../controllers/UserController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { avatarUpload, optionalAvatarUpload } = require('../middlewares/AvatarUpload');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');
const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/users', router);

    router.post('/login/admin', UserController.loginAdmin);
    router.post('/login/customer', UserController.loginCustomer);
    router.post('/register', optionalAvatarUpload, UserController.createUser);

    router.use(verifyToken);
    
    router.post('/admin/create', optionalAvatarUpload, requireRole(['admin']), UserController.createUserByAdmin);
    
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
