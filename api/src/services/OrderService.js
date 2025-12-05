const knex = require('../database/knex');
class OrderService {
    static async createOrder(orderData) {
        try {
            const {
                user_id = null,
                customer_name = null,
                customer_phone = null,
                branch_id,
                order_type = 'dine_in',
                table_id = null,
                reservation_id = null,
                delivery_address = null,
                total,
                subtotal,
                tax = 0,
                discount = 0,
                payment_method = 'cash',
                payment_status = 'pending',
                status = 'pending',
                items = [],
                reservation_date = null,
                reservation_time = null,
                reservation_duration = null,
                guest_count = null
            } = orderData;
            if (!branch_id) {
                throw new Error('Branch ID is required');
            }
            if ((!items || items.length === 0) && !reservation_id) {
                throw new Error('Order must have at least one item');
            }
            const orderId = await knex.transaction(async (trx) => {
                const [orderId] = await trx('orders').insert({
                    user_id: user_id,
                    branch_id: branch_id,
                    order_type: order_type,
                    table_id: table_id,
                    reservation_id: reservation_id || null,
                    delivery_address: delivery_address,
                    delivery_phone: customer_phone || null,
                    total: total || 0,
                    payment_method: payment_method,
                    payment_status: payment_status,
                    status: status,
                    notes: customer_name ? `Khách hàng: ${customer_name}` : null,
                    created_at: knex.fn.now()
                });
                const orderDetails = items.map(item => ({
                    order_id: orderId,
                    product_id: item.product_id,
                    quantity: item.quantity || 1,
                    price: item.price || 0,
                    special_instructions: item.special_instructions || null
                }));
                if (orderDetails.length > 0) {
                    await trx('order_details').insert(orderDetails);
                }
                if (table_id && reservation_date && reservation_time && reservation_duration) {
                    const TableService = require('./TableService');
                    try {
                        await TableService.createTableSchedule({
                            table_id: table_id,
                            reservation_id: null,
                            schedule_date: reservation_date,
                            start_time: reservation_time,
                            duration_minutes: reservation_duration || 120,
                            status: 'reserved',
                            notes: customer_name ? `Đơn hàng #${orderId} - Khách: ${customer_name}` : `Đơn hàng #${orderId}`
                        });
                    } catch (scheduleError) {
                    }
                }
                return orderId;
            });
            const order = await this.getOrderWithDetails(orderId);
            return order;
        } catch (error) {
            throw new Error(`Failed to create order: ${error.message}`);
        }
    }
    static async getUserOrders(userId) {
        try {
            const orders = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.user_id', userId)
                .groupBy('orders.id', 'branches.name', 'branches.image')
                .orderBy('orders.created_at', 'desc');
            return orders;
        } catch (error) {
            throw new Error(`Failed to get user orders: ${error.message}`);
        }
    }
    static async getOrderById(orderId) {
        try {
            const order = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.id', orderId)
                .groupBy('orders.id', 'branches.name', 'branches.image')
                .first();
            return order;
        } catch (error) {
            throw new Error(`Failed to get order: ${error.message}`);
        }
    }
    static async cancelOrder(orderId, cancelledByUserId = null) {
        try {
            const currentOrder = await knex('orders')
                .where('id', orderId)
                .first();
            if (!currentOrder) {
                return false;
            }
            const oldStatus = currentOrder.status;
            const result = await knex('orders')
                .where('id', orderId)
                .update({
                    status: 'cancelled'
                });
            if (cancelledByUserId && result > 0) {
                try {
                    await knex('order_logs').insert({
                        order_id: orderId,
                        action: 'status_change',
                        old_value: oldStatus || 'pending',
                        new_value: 'cancelled',
                        user_id: cancelledByUserId,
                        created_at: new Date()
                    });
                } catch (logError) {
                    }
            }
            return result > 0;
        } catch (error) {
            throw new Error(`Failed to cancel order: ${error.message}`);
        }
    }
    static async getOrdersByBranch(branchId, filters = {}, page = 1, limit = 100) {
        try {
            const offset = (page - 1) * limit;
            let query = knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'floors.name as floor_name',
                    'users.name as customer_name',
                    'users.phone as customer_phone',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('floors', 'tables.floor_id', 'floors.id')
                .leftJoin('users', 'orders.user_id', 'users.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.branch_id', branchId)
                .groupBy('orders.id', 'branches.name', 'branches.image', 'floors.name', 'users.name', 'users.phone');
            if (filters.status) {
                query = query.where('orders.status', filters.status);
            }
            if (filters.order_type) {
                query = query.where('orders.order_type', filters.order_type);
            }
            if (filters.payment_status) {
                query = query.where('orders.payment_status', filters.payment_status);
            }
            if (filters.date_from) {
                query = query.where('orders.created_at', '>=', filters.date_from);
            }
            if (filters.date_to) {
                query = query.where('orders.created_at', '<=', filters.date_to);
            }
            const countQuery = query.clone().clearSelect().clearOrder().count('* as count').first();
            const total = await countQuery;
            const totalCount = total ? parseInt(total.count) : 0;
            const orders = await query
                .orderBy('orders.created_at', 'desc')
                .limit(limit)
                .offset(offset);
            return {
                orders: orders || [],
                pagination: {
                    page,
                    limit,
                    total: totalCount,
                    pages: Math.ceil(totalCount / limit)
                }
            };
        } catch (error) {
            throw new Error(`Failed to get orders by branch: ${error.message}`);
        }
    }
    static async getOrderWithDetails(orderId) {
        try {
            const order = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'users.name as customer_name',
                    'users.phone as customer_phone'
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('users', 'orders.user_id', 'users.id')
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
    static async getAllOrders(filters = {}, page = 1, limit = 20) {
        try {
            const offset = (page - 1) * limit;
            let query = knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'floors.name as floor_name',
                    'users.name as customer_name',
                    'users.phone as customer_phone',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('floors', 'tables.floor_id', 'floors.id')
                .leftJoin('users', 'orders.user_id', 'users.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .groupBy('orders.id', 'branches.name', 'branches.image', 'floors.name', 'users.name', 'users.phone');
            if (filters.branch_id) {
                const branchId = parseInt(filters.branch_id);
                query = query.where('orders.branch_id', branchId);
            }
            if (filters.status) {
                query = query.where('orders.status', filters.status);
            }
            if (filters.payment_status) {
                query = query.where('orders.payment_status', filters.payment_status);
            }
            if (filters.order_type) {
                query = query.where('orders.order_type', filters.order_type);
            }
            if (filters.payment_method) {
                query = query.where('orders.payment_method', filters.payment_method);
            }
            if (filters.date_from) {
                query = query.where('orders.created_at', '>=', filters.date_from);
            }
            if (filters.date_to) {
                query = query.where('orders.created_at', '<=', filters.date_to);
            }
            const countQuery = query.clone().clearSelect().clearOrder().count('* as count').first();
            const total = await countQuery;
            const totalCount = total ? parseInt(total.count) : 0;
            const orders = await query
                .orderBy('orders.created_at', 'desc')
                .limit(limit)
                .offset(offset);
            return {
                orders: orders || [],
                pagination: {
                    page,
                    limit,
                    total: totalCount,
                    pages: Math.ceil(totalCount / limit)
                }
            };
        } catch (error) {
            throw new Error(`Failed to get all orders: ${error.message}`);
        }
    }
    static async updateOrderStatus(orderId, status, userId = null) {
        try {
            const currentOrder = await knex('orders').where('id', orderId).first();
            if (!currentOrder) {
                return false;
            }
            const oldStatus = currentOrder.status;
            const oldPaymentStatus = currentOrder.payment_status;
            const updateData = {
                status: status
            };
            if (status === 'completed' && oldPaymentStatus !== 'paid') {
                updateData.payment_status = 'paid';
            }
            const result = await knex('orders')
                .where('id', orderId)
                .update(updateData);
            if (result > 0 && oldStatus !== status) {
                await knex('order_logs').insert({
                    order_id: orderId,
                    action: 'status_change',
                    old_value: oldStatus,
                    new_value: status,
                    user_id: userId,
                    created_at: knex.fn.now()
                });
                if (status === 'completed' && oldPaymentStatus !== 'paid') {
                    await knex('order_logs').insert({
                        order_id: orderId,
                        action: 'payment_status_change',
                        old_value: oldPaymentStatus,
                        new_value: 'paid',
                        user_id: userId,
                        metadata: JSON.stringify({
                            auto_updated: true,
                            reason: 'Order completed'
                        }),
                        created_at: knex.fn.now()
                    });
                }
            }
            return result > 0;
        } catch (error) {
            throw new Error(`Failed to update order status: ${error.message}`);
        }
    }
    static async updatePaymentStatus(orderId, paymentStatus, paymentMethod = null, userId = null) {
        try {
            const currentOrder = await knex('orders').where('id', orderId).first();
            if (!currentOrder) {
                return false;
            }
            const oldPaymentStatus = currentOrder.payment_status;
            const oldPaymentMethod = currentOrder.payment_method;
            const updateData = {
                payment_status: paymentStatus
            };
            if (paymentMethod) {
                updateData.payment_method = paymentMethod;
            }
            const result = await knex('orders')
                .where('id', orderId)
                .update(updateData);
            if (result > 0 && (oldPaymentStatus !== paymentStatus || oldPaymentMethod !== paymentMethod)) {
                await knex('order_logs').insert({
                    order_id: orderId,
                    action: 'payment_status_change',
                    old_value: oldPaymentStatus,
                    new_value: paymentStatus,
                    user_id: userId,
                    metadata: JSON.stringify({
                        old_payment_method: oldPaymentMethod,
                        new_payment_method: paymentMethod
                    }),
                    created_at: knex.fn.now()
                });
            }
            return result > 0;
        } catch (error) {
            throw new Error(`Failed to update payment status: ${error.message}`);
        }
    }
    static async updateInternalNotes(orderId, notes) {
        try {
            const result = await knex('orders')
                .where('id', orderId)
                .update({
                    internal_notes: notes
                });
            return result > 0;
        } catch (error) {
            throw new Error(`Failed to update internal notes: ${error.message}`);
        }
    }
    static async getOrderLogs(orderId) {
        try {
            const logs = await knex('order_logs')
                .where('order_id', orderId)
                .orderBy('created_at', 'desc');
            return logs;
        } catch (error) {
            throw new Error(`Failed to get order logs: ${error.message}`);
        }
    }
    static async assignDeliveryStaff(orderId, deliveryStaffId) {
        try {
            const existing = await knex('order_assignments')
                .where('order_id', orderId)
                .first();
            if (existing) {
                await knex('order_assignments')
                    .where('order_id', orderId)
                    .update({
                        delivery_staff_id: deliveryStaffId,
                        assigned_at: knex.fn.now()
                    });
            } else {
                await knex('order_assignments').insert({
                    order_id: orderId,
                    delivery_staff_id: deliveryStaffId,
                    assigned_at: knex.fn.now()
                });
            }
            await knex('orders')
                .where('id', orderId)
                .where('status', 'ready')
                .update({
                    status: 'out_for_delivery'
                });
            return true;
        } catch (error) {
            throw new Error(`Failed to assign delivery staff: ${error.message}`);
        }
    }
    static async getOrderStatistics(filters = {}) {
        try {
            let query = knex('orders');
            if (filters.branch_id) {
                query = query.where('branch_id', filters.branch_id);
            }
            if (filters.date_from) {
                query = query.where('created_at', '>=', filters.date_from);
            }
            if (filters.date_to) {
                query = query.where('created_at', '<=', filters.date_to);
            }
            const stats = await query
                .select(
                    knex.raw('COUNT(*) as total_orders'),
                    knex.raw('SUM(total) as total_revenue'),
                    knex.raw('AVG(total) as average_order_value'),
                    knex.raw('COUNT(DISTINCT user_id) as unique_customers')
                )
                .first();
            return stats;
        } catch (error) {
            throw new Error(`Failed to get order statistics: ${error.message}`);
        }
    }
    static async getTopProducts(filters = {}, limit = 10) {
        try {
            let query = knex('order_details')
                .select(
                    'products.id',
                    'products.name',
                    'products.image',
                    knex.raw('SUM(order_details.quantity) as total_quantity'),
                    knex.raw('SUM(order_details.price * order_details.quantity) as total_revenue')
                )
                .join('products', 'order_details.product_id', 'products.id')
                .join('orders', 'order_details.order_id', 'orders.id')
                .groupBy('products.id', 'products.name', 'products.image');
            if (filters.branch_id) {
                query = query.where('orders.branch_id', filters.branch_id);
            }
            if (filters.date_from) {
                query = query.where('orders.created_at', '>=', filters.date_from);
            }
            if (filters.date_to) {
                query = query.where('orders.created_at', '<=', filters.date_to);
            }
            const products = await query
                .orderBy('total_quantity', 'desc')
                .limit(limit);
            return products;
        } catch (error) {
            throw new Error(`Failed to get top products: ${error.message}`);
        }
    }
    static async getKitchenOrders(branchId) {
        try {
            const orders = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.branch_id', branchId)
                .whereIn('orders.status', ['pending', 'confirmed', 'preparing'])
                .groupBy('orders.id', 'branches.name')
                .orderBy('orders.created_at', 'asc');
            for (const order of orders) {
                const items = await knex('order_details')
                    .select(
                        'order_details.*',
                        'products.name as product_name',
                        'products.image as product_image'
                    )
                    .leftJoin('products', 'order_details.product_id', 'products.id')
                    .where('order_details.order_id', order.id)
                    .orderBy('order_details.id');
                order.items = items;
                const createdAt = new Date(order.created_at);
                const now = new Date();
                order.elapsed_minutes = Math.floor((now - createdAt) / (1000 * 60));
            }
            return orders;
        } catch (error) {
            throw new Error(`Failed to get kitchen orders: ${error.message}`);
        }
    }
    static async markOrderReady(orderId) {
        try {
            await knex('orders')
                .where('id', orderId)
                .update({ status: 'ready' });
            return true;
        } catch (error) {
            throw new Error(`Failed to mark order ready: ${error.message}`);
        }
    }
    static async createEmptyOrder(orderData) {
        try {
            const {
                user_id = null,
                branch_id,
                table_id = null
            } = orderData;
            if (!branch_id) {
                throw new Error('Branch ID is required');
            }
            const orderId = await knex.transaction(async (trx) => {
                const [orderId] = await trx('orders').insert({
                    user_id: user_id,
                    branch_id: branch_id,
                    order_type: 'dine_in',
                    table_id: table_id,
                    reservation_id: null, 
                    total: 0,
                    payment_method: null,
                    payment_status: 'pending',
                    status: 'pending',
                    notes: 'Đơn hàng trống (chờ đặt bàn)',
                    created_at: knex.fn.now()
                });
                return orderId;
            });
            const order = await this.getOrderWithDetails(orderId);
            return order;
        } catch (error) {
            throw new Error(`Failed to create empty order: ${error.message}`);
        }
    }
    static async createEmptyOrderForReservation(orderData) {
        try {
            const {
                user_id = null,
                branch_id,
                table_id = null,
                reservation_id
            } = orderData;
            if (!branch_id || !reservation_id) {
                throw new Error('Branch ID and Reservation ID are required');
            }
            const orderId = await knex.transaction(async (trx) => {
                const [orderId] = await trx('orders').insert({
                    user_id: user_id,
                    branch_id: branch_id,
                    order_type: 'dine_in',
                    table_id: table_id,
                    reservation_id: reservation_id,
                    total: 0,
                    payment_method: null,
                    payment_status: 'pending',
                    status: 'pending',
                    notes: `Đơn hàng trống cho đặt bàn #${reservation_id}`,
                    created_at: knex.fn.now()
                });
                return orderId;
            });
            const order = await this.getOrderWithDetails(orderId);
            return order;
        } catch (error) {
            throw new Error(`Failed to create empty order for reservation: ${error.message}`);
        }
    }
    static async getLatestOrderForReservation(reservationId) {
        try {
            const order = await knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'users.name as customer_name',
                    'users.phone as customer_phone'
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('tables', 'orders.table_id', 'tables.id')
                .leftJoin('users', 'orders.user_id', 'users.id')
                .where('orders.reservation_id', reservationId)
                .orderBy('orders.created_at', 'desc')
                .first();
            if (!order) {
                return null;
            }
            const items = await knex('order_details')
                .select(
                    'order_details.*',
                    'products.name as product_name',
                    'products.image as product_image',
                    'products.description as product_description'
                )
                .leftJoin('products', 'order_details.product_id', 'products.id')
                .where('order_details.order_id', order.id)
                .orderBy('order_details.id');
            order.items = items;
            order.items_count = items.length;
            return order;
        } catch (error) {
            throw new Error(`Failed to get latest order for reservation: ${error.message}`);
        }
    }
    static async deleteOrder(orderId) {
        try {
            const order = await knex('orders')
                .where('id', orderId)
                .first();
            if (!order) {
                throw new Error('Order not found');
            }
            await knex.transaction(async (trx) => {
                await trx('order_logs').where('order_id', orderId).delete();
                await trx('order_details').where('order_id', orderId).delete();
                await trx('orders').where('id', orderId).delete();
            });
            return true;
        } catch (error) {
            throw new Error(`Failed to delete order: ${error.message}`);
        }
    }
}
module.exports = OrderService;
