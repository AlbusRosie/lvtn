const knex = require('../database/knex');

class OrderService {
    static async getUserOrders(userId) {
        try {
            const orders = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'tables.table_number',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.user_id', userId)
                .groupBy('orders.id', 'branches.name', 'branches.image', 'tables.table_number')
                .orderBy('orders.created_at', 'desc');

            return orders;
        } catch (error) {
            throw new Error(`Failed to get user orders: ${error.message}`);
        }
    }

    static async getUserReservations(userId) {
        try {
            const reservations = await knex('reservations')
                .select(
                    'reservations.*',
                    'branches.name as branch_name',
                    'tables.table_number'
                )
                .leftJoin('branches', 'reservations.branch_id', 'branches.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
                .where('reservations.user_id', userId)
                .orderBy('reservations.created_at', 'desc');

            return reservations;
        } catch (error) {
            throw new Error(`Failed to get user reservations: ${error.message}`);
        }
    }

    static async getOrderById(orderId) {
        try {
            const order = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'tables.table_number',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.id', orderId)
                .groupBy('orders.id', 'branches.name', 'branches.image', 'tables.table_number')
                .first();

            return order;
        } catch (error) {
            throw new Error(`Failed to get order: ${error.message}`);
        }
    }

    static async getReservationById(reservationId) {
        try {
            const reservation = await knex('reservations')
                .select(
                    'reservations.*',
                    'branches.name as branch_name',
                    'tables.table_number'
                )
                .leftJoin('branches', 'reservations.branch_id', 'branches.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
                .where('reservations.id', reservationId)
                .first();

            return reservation;
        } catch (error) {
            throw new Error(`Failed to get reservation: ${error.message}`);
        }
    }

    static async cancelOrder(orderId) {
        try {
            const result = await knex('orders')
                .where('id', orderId)
                .update({
                    status: 'cancelled',
                    updated_at: knex.fn.now()
                });

            return result > 0;
        } catch (error) {
            throw new Error(`Failed to cancel order: ${error.message}`);
        }
    }

    static async cancelReservation(reservationId) {
        try {
            const result = await knex('reservations')
                .where('id', reservationId)
                .update({
                    status: 'cancelled',
                    updated_at: knex.fn.now()
                });

            return result > 0;
        } catch (error) {
            throw new Error(`Failed to cancel reservation: ${error.message}`);
        }
    }

    static async getOrdersByBranch(branchId) {
        try {
            const orders = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'tables.table_number',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.branch_id', branchId)
                .groupBy('orders.id', 'branches.name', 'branches.image', 'tables.table_number')
                .orderBy('orders.created_at', 'desc');

            return orders;
        } catch (error) {
            throw new Error(`Failed to get orders by branch: ${error.message}`);
        }
    }

    static async getReservationsByBranch(branchId) {
        try {
            const reservations = await knex('reservations')
                .select(
                    'reservations.*',
                    'branches.name as branch_name',
                    'tables.table_number'
                )
                .leftJoin('branches', 'reservations.branch_id', 'branches.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
                .where('reservations.branch_id', branchId)
                .orderBy('reservations.created_at', 'desc');

            return reservations;
        } catch (error) {
            throw new Error(`Failed to get reservations by branch: ${error.message}`);
        }
    }

    static async getOrderWithDetails(orderId) {
        try {
            const order = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'tables.table_number'
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .where('orders.id', orderId)
                .first();

            if (!order) {
                throw new Error('Order not found');
            }

            const items = await knex('order_details')
                .select(
                    'order_details.*',
                    'products.name as product_name',
                    'products.image as product_image',
                    'products.description as product_description'
                )
                .leftJoin('products', 'order_details.product_id', 'products.id')
                .where('order_details.order_id', orderId)
                .orderBy('order_details.id');

            order.items = items;
            order.items_count = items.length;

            return order;
        } catch (error) {
            throw new Error(`Failed to get order with details: ${error.message}`);
        }
    }
}

module.exports = OrderService;
