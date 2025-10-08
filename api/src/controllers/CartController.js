const CartService = require('../services/CartService');
const ApiError = require('../api-error');
const { success } = require('../jsend');
const knex = require('../database/knex');

async function addToCart(req, res, next) {
    try {
        const { product_id, quantity = 1, order_type = 'dine_in', session_id } = req.body;
        const { branch_id } = req.params;
        const user_id = req.user.id;

        if (!product_id) {
            throw new ApiError(400, 'Product ID is required');
        }

        if (quantity <= 0) {
            throw new ApiError(400, 'Quantity must be greater than 0');
        }

        const cart = await CartService.addToCart(
            user_id, 
            parseInt(branch_id), 
            parseInt(product_id), 
            parseInt(quantity),
            order_type,
            session_id
        );

        res.status(201).json(success(cart, 'Item added to cart successfully'));
    } catch (error) {
        if (error.message === 'Product not available in this branch') {
            return next(new ApiError(400, error.message));
        }
        next(new ApiError(500, error.message));
    }
}

async function removeFromCart(req, res, next) {
    try {
        const { cart_id, product_id } = req.params;

        const cart = await CartService.removeFromCart(parseInt(cart_id), parseInt(product_id));
        res.json(success(cart, 'Item removed from cart successfully'));
    } catch (error) {
        if (error.message === 'Item not found in cart') {
            return next(new ApiError(404, error.message));
        }
        next(new ApiError(500, error.message));
    }
}

async function updateCartItemQuantity(req, res, next) {
    try {
        const { cart_id, product_id } = req.params;
        const { quantity } = req.body;

        if (!quantity || quantity < 0) {
            throw new ApiError(400, 'Valid quantity is required');
        }

        const cart = await CartService.updateCartItemQuantity(
            parseInt(cart_id), 
            parseInt(product_id), 
            parseInt(quantity)
        );

        res.json(success(cart, 'Cart item quantity updated successfully'));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function getCart(req, res, next) {
    try {
        const { cart_id } = req.params;

        const cart = await CartService.getCartById(parseInt(cart_id));
        res.json(success(cart, 'Cart retrieved successfully'));
    } catch (error) {
        if (error.message === 'Cart not found') {
            return next(new ApiError(404, error.message));
        }
        next(new ApiError(500, error.message));
    }
}

async function getUserCart(req, res, next) {
    try {
        const { branch_id } = req.params;
        const { session_id } = req.query;
        const user_id = req.user.id;

        const cart = await CartService.getUserCart(user_id, parseInt(branch_id), session_id);
        
        if (!cart) {
            return res.json(success(null, 'No active cart found'));
        }

        res.json(success(cart, 'User cart retrieved successfully'));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function reserveTable(req, res, next) {
    try {
        const { cart_id } = req.params;
        const { table_id, reservation_date, reservation_time, guest_count } = req.body;

        if (!table_id || !reservation_date || !reservation_time || !guest_count) {
            throw new ApiError(400, 'Table ID, reservation date, time, and guest count are required');
        }

        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (!dateRegex.test(reservation_date)) {
            throw new ApiError(400, 'Invalid reservation_date format. Use YYYY-MM-DD');
        }

        const timeRegex = /^\d{2}:\d{2}$/;
        if (!timeRegex.test(reservation_time)) {
            throw new ApiError(400, 'Invalid reservation_time format. Use HH:MM');
        }

        if (guest_count < 1) {
            throw new ApiError(400, 'Guest count must be at least 1');
        }

        const cart = await CartService.reserveTable(
            parseInt(cart_id),
            parseInt(table_id),
            reservation_date,
            reservation_time,
            parseInt(guest_count)
        );

        res.json(success(cart, 'Table reserved successfully'));
    } catch (error) {
        if (error.message.includes('not available') || 
            error.message.includes('capacity') ||
            error.message.includes('reservation failed')) {
            return next(new ApiError(400, error.message));
        }
        next(new ApiError(500, error.message));
    }
}

async function cancelTableReservation(req, res, next) {
    try {
        const { cart_id } = req.params;

        const cart = await CartService.cancelTableReservation(parseInt(cart_id));
        res.json(success(cart, 'Table reservation cancelled successfully'));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function checkout(req, res, next) {
    try {
        const { cart_id } = req.params;

        const result = await CartService.checkout(parseInt(cart_id));
        res.json(success(result, 'Order created successfully'));
    } catch (error) {
        if (error.message === 'Cart not found or not in pending status' ||
            error.message === 'Cart is empty') {
            return next(new ApiError(400, error.message));
        }
        next(new ApiError(500, error.message));
    }
}

async function clearCart(req, res, next) {
    try {
        const { cart_id } = req.params;

        await CartService.cancelTableReservation(parseInt(cart_id));

        await knex('cart_items').where('cart_id', parseInt(cart_id)).del();

        await knex('carts').where('id', parseInt(cart_id)).del();

        res.json(success(null, 'Cart cleared successfully'));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

module.exports = {
    addToCart,
    removeFromCart,
    updateCartItemQuantity,
    getCart,
    getUserCart,
    reserveTable,
    cancelTableReservation,
    checkout,
    clearCart
};
