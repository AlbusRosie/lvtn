const express = require('express');
const OrderController = require('../controllers/OrderController');
const AuthMiddleware = require('../middlewares/AuthMiddleware');
const BranchMiddleware = require('../middlewares/BranchMiddleware');
function setup(app) {
    const router = express.Router();
    router.post('/orders', AuthMiddleware.verifyToken, OrderController.createOrder);
    router.get('/orders', OrderController.getUserOrders);
    router.get('/orders/branch/:branch_id', OrderController.getOrdersByBranch);
    router.get('/orders/:id/details', OrderController.getOrderWithDetails);
    router.put('/orders/:id/cancel', AuthMiddleware.verifyToken, OrderController.cancelOrder);
    router.get('/orders/:id', OrderController.getOrderById);
    const adminAccess = [
        AuthMiddleware.verifyToken, 
        AuthMiddleware.requireRole(['admin', 'manager']),
        BranchMiddleware.enforceBranchAccess
    ];
    router.get('/admin/orders', ...adminAccess, OrderController.getAllOrders);
    router.get('/admin/orders/:id/details', ...adminAccess, BranchMiddleware.validateResourceBranch('order'), OrderController.getOrderWithDetails);
    router.put('/admin/orders/:id/status', ...adminAccess, BranchMiddleware.validateResourceBranch('order'), OrderController.updateOrderStatus);
    router.put('/admin/orders/:id/payment-status', ...adminAccess, BranchMiddleware.validateResourceBranch('order'), OrderController.updatePaymentStatus);
    router.put('/admin/orders/:id/internal-notes', ...adminAccess, BranchMiddleware.validateResourceBranch('order'), OrderController.updateInternalNotes);

    router.put('/admin/orders/:id/assign-delivery', ...adminAccess, BranchMiddleware.validateResourceBranch('order'), OrderController.assignDeliveryStaff);
    router.delete('/admin/orders/:id', ...adminAccess, BranchMiddleware.validateResourceBranch('order'), OrderController.deleteOrder);
    router.get('/admin/orders/statistics', ...adminAccess, OrderController.getOrderStatistics);
    router.get('/admin/orders/top-products', ...adminAccess, OrderController.getTopProducts);
    router.get('/kitchen/orders', AuthMiddleware.verifyToken, OrderController.getKitchenOrders);
    router.put('/kitchen/orders/:order_id/ready', AuthMiddleware.verifyToken, OrderController.markOrderReady);
    router.put('/employee/orders/:id/status', AuthMiddleware.verifyToken, OrderController.updateOrderStatus);
    router.put('/employee/orders/:id/payment-status', AuthMiddleware.verifyToken, OrderController.updatePaymentStatus);
    router.get('/delivery/orders', AuthMiddleware.verifyToken, OrderController.getDeliveryOrders);
    router.put('/delivery/orders/:id/status', AuthMiddleware.verifyToken, OrderController.updateOrderStatus);
    app.use('/api', router);
}
module.exports = { setup };
