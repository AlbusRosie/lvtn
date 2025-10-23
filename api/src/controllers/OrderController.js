const OrderService = require('../services/OrderService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

async function getUserOrders(req, res, next) {
    try {
        const { user_id } = req.query;
        
        if (!user_id) {
            throw new ApiError(400, 'User ID is required');
        }

        const orders = await OrderService.getUserOrders(parseInt(user_id));
        res.json(success(orders));
    } catch (error) {
        next(error);
    }
}

async function getUserReservations(req, res, next) {
    try {
        const { user_id } = req.query;
        
        if (!user_id) {
            throw new ApiError(400, 'User ID is required');
        }

        const reservations = await OrderService.getUserReservations(parseInt(user_id));
        res.json(success(reservations));
    } catch (error) {
        next(error);
    }
}

async function getOrderById(req, res, next) {
    try {
        const { id } = req.params;
        const order = await OrderService.getOrderById(parseInt(id));
        
        if (!order) {
            throw new ApiError(404, 'Order not found');
        }
        
        res.json(success(order));
    } catch (error) {
        next(error);
    }
}

async function getOrderWithDetails(req, res, next) {
    try {
        const { id } = req.params;
        const order = await OrderService.getOrderWithDetails(parseInt(id));
        
        if (!order) {
            throw new ApiError(404, 'Order not found');
        }
        
        res.json(success(order));
    } catch (error) {
        next(error);
    }
}

async function getReservationById(req, res, next) {
    try {
        const { id } = req.params;
        const reservation = await OrderService.getReservationById(parseInt(id));
        
        if (!reservation) {
            throw new ApiError(404, 'Reservation not found');
        }
        
        res.json(success(reservation));
    } catch (error) {
        next(error);
    }
}

async function cancelOrder(req, res, next) {
    try {
        const { id } = req.params;
        const result = await OrderService.cancelOrder(parseInt(id));
        
        if (!result) {
            throw new ApiError(400, 'Failed to cancel order');
        }
        
        res.json(success(null, 'Order cancelled successfully'));
    } catch (error) {
        next(error);
    }
}

async function cancelReservation(req, res, next) {
    try {
        const { id } = req.params;
        const result = await OrderService.cancelReservation(parseInt(id));
        
        if (!result) {
            throw new ApiError(400, 'Failed to cancel reservation');
        }
        
        res.json(success(null, 'Reservation cancelled successfully'));
    } catch (error) {
        next(error);
    }
}

async function getOrdersByBranch(req, res, next) {
    try {
        const { branch_id } = req.query;
        
        if (!branch_id) {
            throw new ApiError(400, 'Branch ID is required');
        }

        const orders = await OrderService.getOrdersByBranch(parseInt(branch_id));
        res.json(success(orders));
    } catch (error) {
        next(error);
    }
}

async function getReservationsByBranch(req, res, next) {
    try {
        const { branch_id } = req.query;
        
        if (!branch_id) {
            throw new ApiError(400, 'Branch ID is required');
        }

        const reservations = await OrderService.getReservationsByBranch(parseInt(branch_id));
        res.json(success(reservations));
    } catch (error) {
        next(error);
    }
}

module.exports = {
    getUserOrders,
    getUserReservations,
    getOrderById,
    getOrderWithDetails,
    getReservationById,
    cancelOrder,
    cancelReservation,
    getOrdersByBranch,
    getReservationsByBranch,
};
