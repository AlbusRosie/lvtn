const express = require('express');
const UserController = require('../controllers/UserController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { avatarUpload } = require('../middlewares/AvatarUpload');
const router = express.Router();
const { verifyToken } = require('../middlewares/AuthMiddleware');

module.exports.setup = (app) => {
    app.use('/api/users', router);

    router.post('/login', UserController.login);
    router.post('/register', avatarUpload, UserController.createUser);

    router.delete('/', verifyToken, UserController.deleteAllUsers);
    router.get('/', verifyToken, UserController.getUsersByFilter);

    router.get('/:id', verifyToken, UserController.getUser);
    router.put('/:id',verifyToken,avatarUpload, UserController.updateUser);
    router.delete('/:id', verifyToken, UserController.deleteUser);
    router.all('/:id', methodNotAllowed);
    
    router.all('/', methodNotAllowed);
    router.all('/login', methodNotAllowed);
    router.all('/register', methodNotAllowed);
}
