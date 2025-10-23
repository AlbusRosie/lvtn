const express = require('express');
const CartController = require('../controllers/CartController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken } = require('../middlewares/AuthMiddleware');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/cart', router);

    router.post('/branches/:branch_id/add-item', verifyToken, CartController.addToCart);
    router.get('/branches/:branch_id/user-cart', verifyToken, CartController.getUserCart);
    router.get('/:cart_id', verifyToken, CartController.getCart);
    router.put('/:cart_id/items/:product_id/quantity', verifyToken, CartController.updateCartItemQuantity);
    router.put('/:cart_id/items/:product_id/options', verifyToken, CartController.updateCartItemOptions);
    router.delete('/:cart_id/items/:product_id', verifyToken, CartController.removeFromCart);
    router.post('/:cart_id/reserve-table', verifyToken, CartController.reserveTable);
    router.delete('/:cart_id/cancel-reservation', verifyToken, CartController.cancelTableReservation);
    router.post('/:cart_id/checkout', verifyToken, CartController.checkout);
    router.delete('/:cart_id/clear', verifyToken, CartController.clearCart);

    router.all('/branches/:branch_id/add-item', methodNotAllowed);
    router.all('/branches/:branch_id/user-cart', methodNotAllowed);
    router.all('/:cart_id', methodNotAllowed);
    router.all('/:cart_id/items/:product_id/quantity', methodNotAllowed);
    router.all('/:cart_id/items/:product_id/options', methodNotAllowed);
    router.all('/:cart_id/items/:product_id', methodNotAllowed);
    router.all('/:cart_id/reserve-table', methodNotAllowed);
    router.all('/:cart_id/cancel-reservation', methodNotAllowed);
    router.all('/:cart_id/checkout', methodNotAllowed);
    router.all('/:cart_id/clear', methodNotAllowed);
};
