const express = require('express');
const ChatController = require('../controllers/ChatController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken } = require('../middlewares/AuthMiddleware');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/chat', router);

    router.post('/message', verifyToken, ChatController.sendMessage);
    
    router.get('/history', verifyToken, ChatController.getChatHistory);
    
    router.get('/suggestions', verifyToken, ChatController.getSuggestions);
    
    router.post('/action', verifyToken, ChatController.executeAction);

    router.all('/message', methodNotAllowed);
    router.all('/history', methodNotAllowed);
    router.all('/suggestions', methodNotAllowed);
    router.all('/action', methodNotAllowed);
};

