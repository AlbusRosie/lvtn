const express = require('express');
const OrderController = require('../controllers/OrderController');

function setup(app) {
    const router = express.Router();
    
    router.get('/orders', OrderController.getUserOrders);
    router.get('/orders/:id', OrderController.getOrderById);
    router.get('/orders/:id/details', OrderController.getOrderWithDetails);
    router.put('/orders/:id/cancel', OrderController.cancelOrder);
    router.get('/orders/branch/:branch_id', OrderController.getOrdersByBranch);
    
    app.use('/api', router);
}

module.exports = { setup };
