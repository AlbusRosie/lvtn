const knex = require('../database/knex');
const ReservationService = require('./ReservationService');
let io = null;

// Function to set io instance (called from server.js)
function setSocketIO(socketIO) {
    io = socketIO;
}

class OrderService {
    static async createOrder(orderData) {
        try {
            const {
                user_id = null,
                customer_name = null,
                customer_phone = null,
                branch_id,
                order_type = 'dine_in',
                reservation_id = null,
                delivery_address = null,
                total,
                subtotal,
                tax = 0,
                discount = 0,
                payment_method = 'cash',
                payment_status = 'pending',
                status = 'pending',
                items = []
            } = orderData;
            
            // Force payment method to be cash only
            const finalPaymentMethod = 'cash';
            if (!branch_id) {
                throw new Error('Branch ID is required');
            }
            // Order must have at least one item - no empty orders allowed
            if (!items || items.length === 0) {
                throw new Error('Order must have at least one item');
            }
            // Order total must be greater than 0 - no empty orders allowed
            if (!total || total <= 0) {
                throw new Error('Order total must be greater than 0');
            }
            const orderId = await knex.transaction(async (trx) => {
                const [orderId] = await trx('orders').insert({
                    user_id: user_id,
                    branch_id: branch_id,
                    order_type: order_type,
                    reservation_id: reservation_id || null,
                    delivery_address: delivery_address,
                    delivery_phone: customer_phone || null,
                    total: total, // Already validated to be > 0 above
                    payment_method: finalPaymentMethod,
                    payment_status: payment_status,
                    status: status,
                    notes: customer_name ? `Khách hàng: ${customer_name}` : null,
                    created_at: knex.fn.now()
                });
                // Build order details with branch_product_id
                const orderDetails = await Promise.all(items.map(async (item) => {
                    let branchProductId = item.branch_product_id;
                    // Fallback: if branch_product_id not provided, look it up from product_id
                    if (!branchProductId && item.product_id) {
                        const branchProduct = await trx('branch_products')
                            .where('branch_id', branch_id)
                            .where('product_id', item.product_id)
                            .first();
                        if (branchProduct) {
                            branchProductId = branchProduct.id;
                        }
                    }
                    return {
                    order_id: orderId,
                        branch_product_id: branchProductId || null,
                    quantity: item.quantity || 1,
                    price: item.price || 0,
                    special_instructions: item.special_instructions || null
                    };
                }));
                if (orderDetails.length > 0) {
                    await trx('order_details').insert(orderDetails);
                }
                // Note: table_schedule was already created when reservation was created
                // No need to create it again here
                return orderId;
            });
            const order = await this.getOrderWithDetails(orderId);
            
            // ✅ EMIT REAL-TIME NOTIFICATION
            if (io) {
                const notificationData = {
                    orderId: orderId,
                    branchId: branch_id,
                    orderType: order_type,
                    total: total || 0,
                    customerName: customer_name,
                    timestamp: new Date().toISOString()
                };
                
                // Get room sizes and socket IDs for debugging
                const branchRoom = io.sockets.adapter.rooms.get(`branch:${branch_id}`);
                const adminRoom = io.sockets.adapter.rooms.get('admin');
                const branchRoomSize = branchRoom ? branchRoom.size : 0;
                const adminRoomSize = adminRoom ? adminRoom.size : 0;
                
                // Get socket IDs in branch room
                const branchSocketIds = branchRoom ? Array.from(branchRoom) : [];
                const adminSocketIds = adminRoom ? Array.from(adminRoom) : [];
                
                console.log(`[Socket.IO] Emitting new-order to branch:${branch_id} (${branchRoomSize} listeners)`);
                console.log(`[Socket.IO] Branch room socket IDs:`, branchSocketIds);
                console.log(`[Socket.IO] Emitting new-order to admin room (${adminRoomSize} listeners)`);
                console.log(`[Socket.IO] Admin room socket IDs:`, adminSocketIds);
                console.log(`[Socket.IO] Notification data:`, notificationData);
                
                // Log socket details for each socket in branch room
                if (branchSocketIds.length > 0) {
                    branchSocketIds.forEach(socketId => {
                        const socket = io.sockets.sockets.get(socketId);
                        if (socket) {
                            console.log(`[Socket.IO] Socket ${socketId} - User: ${socket.user?.username}, Role: ${socket.user?.role_id}, Branch: ${socket.user?.branch_id}`);
                        }
                    });
                }
                
                // Notify branch staff
                io.to(`branch:${branch_id}`).emit('new-order', notificationData);
                
                // Notify admin
                io.to('admin').emit('new-order', notificationData);
                
                console.log(`[Socket.IO] ✅ Notification emitted successfully to ${branchRoomSize} branch listeners and ${adminRoomSize} admin listeners`);
            } else {
                console.error('[Socket.IO] ❌ io instance is null, cannot emit new-order notification');
            }
            
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
                    'tables.id as table_id',
                    'floors.name as floor_name',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('reservations', 'orders.reservation_id', 'reservations.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
                .leftJoin('floors', 'tables.floor_id', 'floors.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.user_id', userId)
                .groupBy('orders.id', 'branches.name', 'branches.image', 'tables.id', 'floors.name')
                .orderBy('orders.created_at', 'desc');
            
            // Đảm bảo table_id được set từ reservation nếu có
            return orders.map(order => {
                if (order.table_id) {
                    order.table_name = `Table #${order.table_id}`;
                }
                return order;
            });
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
                    'tables.id as table_id',
                    'floors.name as floor_name',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('reservations', 'orders.reservation_id', 'reservations.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
                .leftJoin('floors', 'tables.floor_id', 'floors.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.id', orderId)
                .groupBy('orders.id', 'branches.name', 'branches.image', 'tables.id', 'floors.name')
                .first();
            
            // Đảm bảo table_id được set từ reservation nếu có
            if (order && order.table_id) {
                order.table_name = `Table #${order.table_id}`;
            }
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
            // ✅ EMIT REAL-TIME NOTIFICATION
            if (result > 0 && io) {
                const order = await this.getOrderById(orderId);
                if (order) {
                    // Notify branch staff
                    io.to(`branch:${order.branch_id}`).emit('order-status-updated', {
                        orderId: orderId,
                        branchId: order.branch_id,
                        orderType: order.order_type, // Add orderType for filtering
                        oldStatus: oldStatus || 'pending',
                        newStatus: 'cancelled',
                        timestamp: new Date().toISOString()
                    });
                    
                    // Notify customer if user_id exists
                    if (order.user_id) {
                        io.to(`user:${order.user_id}`).emit('order-status-updated', {
                            orderId: orderId,
                            orderType: order.order_type, // Add orderType for filtering
                            oldStatus: oldStatus || 'pending',
                            newStatus: 'cancelled',
                            timestamp: new Date().toISOString()
                        });
                    }
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
                    'tables.id as table_id',
                    'floors.name as floor_name',
                    'users.name as customer_name',
                    'users.phone as customer_phone',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('reservations', 'orders.reservation_id', 'reservations.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
                .leftJoin('floors', 'tables.floor_id', 'floors.id')
                .leftJoin('users', 'orders.user_id', 'users.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.branch_id', branchId)
                .groupBy('orders.id', 'branches.name', 'branches.image', 'tables.id', 'floors.name', 'users.name', 'users.phone');
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
                    'users.phone as customer_phone',
                    'tables.id as table_id',
                    'floors.name as floor_name'
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('reservations', 'orders.reservation_id', 'reservations.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
                .leftJoin('floors', 'tables.floor_id', 'floors.id')
                .leftJoin('users', 'orders.user_id', 'users.id')
                .where('orders.id', orderId)
                .first();
            
            // Đảm bảo table_id được set từ reservation nếu có
            if (order && order.table_id) {
                order.table_name = `Table #${order.table_id}`;
            }
            if (!order) {
                throw new Error('Order not found');
            }
            const items = await knex('order_details')
                .select(
                    'order_details.*',
                    'products.name as product_name',
                    'products.image as product_image',
                    'products.description as product_description',
                    'products.id as product_id'
                )
                .leftJoin('branch_products', 'order_details.branch_product_id', 'branch_products.id')
                .leftJoin('products', 'branch_products.product_id', 'products.id')
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
                    'order_assignments.delivery_staff_id',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('reservations', 'orders.reservation_id', 'reservations.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
                .leftJoin('floors', 'tables.floor_id', 'floors.id')
                .leftJoin('users', 'orders.user_id', 'users.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .leftJoin('order_assignments', 'orders.id', 'order_assignments.order_id')
                .groupBy('orders.id', 'branches.name', 'branches.image', 'floors.name', 'users.name', 'users.phone', 'order_assignments.delivery_staff_id');
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
            // Filter for unassigned orders only (for delivery assignment)
            // Simply check if delivery_staff_id is null (order not assigned yet)
            if (filters.unassigned_only) {
                query = query.whereNull('order_assignments.delivery_staff_id');
                console.log(`[OrderService.getAllOrders] Filtering for unassigned orders (delivery_staff_id IS NULL)`);
            }
            
            // Log SQL query for debugging
            if (filters.unassigned_only && filters.order_type === 'delivery' && filters.status === 'ready') {
                const sql = query.clone().toSQL();
                console.log(`[OrderService.getAllOrders] SQL Query:`, sql.sql);
                console.log(`[OrderService.getAllOrders] SQL Bindings:`, sql.bindings);
            }
            
            const countQuery = query.clone().clearSelect().clearOrder().count('* as count').first();
            const total = await countQuery;
            const totalCount = total ? parseInt(total.count) : 0;
            const orders = await query
                .orderBy('orders.created_at', 'desc')
                .limit(limit)
                .offset(offset);
            
            // Log for debugging delivery ready orders
            if (filters.unassigned_only && filters.order_type === 'delivery' && filters.status === 'ready') {
                console.log(`[OrderService.getAllOrders] Found ${orders.length} unassigned delivery ready orders (total count: ${totalCount})`);
                if (orders.length > 0) {
                    console.log(`[OrderService.getAllOrders] Order IDs:`, orders.map(o => ({ id: o.id, status: o.status, order_type: o.order_type, delivery_staff_id: o.delivery_staff_id })));
                } else {
                    console.log(`[OrderService.getAllOrders] No unassigned delivery ready orders found`);
                    // Check if there are any delivery ready orders at all (without unassigned filter)
                    const testQuery = knex('orders')
                        .where('orders.branch_id', filters.branch_id)
                        .where('orders.status', 'ready')
                        .where('orders.order_type', 'delivery');
                    const testOrders = await testQuery.select('orders.id', 'orders.status', 'orders.order_type');
                    console.log(`[OrderService.getAllOrders] Total delivery ready orders (without unassigned filter):`, testOrders.length);
                    if (testOrders.length > 0) {
                        console.log(`[OrderService.getAllOrders] Delivery ready order IDs:`, testOrders.map(o => o.id));
                        // Check which ones have assignments
                        const assignedOrders = await knex('order_assignments')
                            .whereIn('order_id', testOrders.map(o => o.id))
                            .whereNotNull('delivery_staff_id')
                            .select('order_id', 'delivery_staff_id');
                        console.log(`[OrderService.getAllOrders] Assigned orders:`, assignedOrders);
                        const unassignedOrderIds = testOrders
                            .map(o => o.id)
                            .filter(id => !assignedOrders.find(a => a.order_id === id));
                        console.log(`[OrderService.getAllOrders] Unassigned order IDs (should be shown):`, unassignedOrderIds);
                    }
                }
            }
            
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
            
            // ✅ AUTO-UPDATE RESERVATION when order completed
            if (result > 0 && status === 'completed') {
                const order = await knex('orders').where('id', orderId).first();
                if (order && order.reservation_id) {
                    try {
                        // Auto-update reservation status to 'completed'
                        // This will also call TableService.checkOutTableSchedule() 
                        // to set table_schedule status to 'cancelled'
                        await ReservationService.updateReservation(order.reservation_id, {
                            status: 'completed'
                        });
                        console.log(`[OrderService] Auto-updated reservation ${order.reservation_id} to 'completed' when order ${orderId} completed`);
                    } catch (error) {
                        // Log error but don't fail the order update
                        console.error(`[OrderService] Failed to auto-update reservation ${order.reservation_id}:`, error.message);
                    }
                }
            }
            
            // ✅ EMIT REAL-TIME NOTIFICATIONS
            if (result > 0 && io) {
                const order = await this.getOrderById(orderId);
                if (order && oldStatus !== status) {
                    // Notify branch staff
                    io.to(`branch:${order.branch_id}`).emit('order-status-updated', {
                        orderId: orderId,
                        branchId: order.branch_id,
                        orderType: order.order_type, // Add orderType for filtering
                        oldStatus: oldStatus,
                        newStatus: status,
                        timestamp: new Date().toISOString()
                    });
                    
                    // Notify customer if user_id exists
                    if (order.user_id) {
                        io.to(`user:${order.user_id}`).emit('order-status-updated', {
                            orderId: orderId,
                            orderType: order.order_type, // Add orderType for filtering
                            oldStatus: oldStatus,
                            newStatus: status,
                            timestamp: new Date().toISOString()
                        });
                    }
                }
                
                // Auto-update payment status when order completed
                if (status === 'completed' && oldPaymentStatus !== 'paid') {
                    io.to(`branch:${order.branch_id}`).emit('payment-status-updated', {
                        orderId: orderId,
                        branchId: order.branch_id,
                        oldStatus: oldPaymentStatus,
                        newStatus: 'paid',
                        paymentMethod: 'cash',
                        autoUpdated: true,
                        timestamp: new Date().toISOString()
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
                // Only allow cash payment method
                updateData.payment_method = 'cash';
            } else if (paymentStatus === 'paid') {
                // Default to cash if payment status is paid and no method specified
                updateData.payment_method = 'cash';
            }
            const result = await knex('orders')
                .where('id', orderId)
                .update(updateData);
            
            // ✅ EMIT REAL-TIME NOTIFICATION
            if (result > 0 && (oldPaymentStatus !== paymentStatus || oldPaymentMethod !== paymentMethod) && io) {
                const order = await this.getOrderById(orderId);
                if (order) {
                    // Notify branch staff
                    io.to(`branch:${order.branch_id}`).emit('payment-status-updated', {
                        orderId: orderId,
                        branchId: order.branch_id,
                        oldStatus: oldPaymentStatus,
                        newStatus: paymentStatus,
                        paymentMethod: paymentMethod || 'cash',
                        timestamp: new Date().toISOString()
                    });
                    
                    // Notify customer if user_id exists
                    if (order.user_id) {
                        io.to(`user:${order.user_id}`).emit('payment-status-updated', {
                            orderId: orderId,
                            oldStatus: oldPaymentStatus,
                            newStatus: paymentStatus,
                            paymentMethod: paymentMethod || 'cash',
                            timestamp: new Date().toISOString()
                        });
                    }
                }
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
    static async assignDeliveryStaff(orderId, deliveryStaffId) {
        try {
            const order = await knex('orders').where('id', orderId).first();
            if (!order) {
                throw new Error('Order not found');
            }
            
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
            
            const oldStatus = order.status;
            const statusUpdated = await knex('orders')
                .where('id', orderId)
                .where('status', 'ready')
                .update({
                    status: 'out_for_delivery'
                });
            
            // ✅ EMIT REAL-TIME NOTIFICATION
            if (io) {
                // Always notify branch staff about assignment
                io.to(`branch:${order.branch_id}`).emit('order-status-updated', {
                    orderId: orderId,
                    branchId: order.branch_id,
                    orderType: order.order_type, // Add orderType for filtering
                    oldStatus: oldStatus,
                    newStatus: statusUpdated > 0 ? 'out_for_delivery' : oldStatus,
                    deliveryStaffId: deliveryStaffId,
                    timestamp: new Date().toISOString()
                });
                
                // Notify assigned delivery staff (always, even if status didn't change)
                const orderDetails = await this.getOrderById(orderId);
                console.log(`[Socket.IO] Emitting order-assigned to delivery:${deliveryStaffId}`, {
                    orderId: orderId,
                    deliveryStaffId: deliveryStaffId
                });
                io.to(`delivery:${deliveryStaffId}`).emit('order-assigned', {
                    orderId: orderId,
                    branchId: order.branch_id,
                    orderType: order.order_type,
                    deliveryAddress: order.delivery_address,
                    total: order.total || 0,
                    deliveryStaffId: deliveryStaffId,
                    timestamp: new Date().toISOString()
                });
                
                // Notify customer if user_id exists and status changed
                if (order.user_id && statusUpdated > 0) {
                    io.to(`user:${order.user_id}`).emit('order-status-updated', {
                        orderId: orderId,
                        orderType: order.order_type, // Add orderType for filtering
                        oldStatus: oldStatus,
                        newStatus: 'out_for_delivery',
                        timestamp: new Date().toISOString()
                    });
                }
            }
            
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
                .join('branch_products', 'order_details.branch_product_id', 'branch_products.id')
                .join('products', 'branch_products.product_id', 'products.id')
                .join('orders', 'order_details.order_id', 'orders.id')
                .whereNotIn('orders.status', ['cancelled'])
                .groupBy('products.id', 'products.name', 'products.image');
            if (filters.branch_id) {
                query = query.where('orders.branch_id', parseInt(filters.branch_id));
            }
            if (filters.date_from) {
                query = query.where('orders.created_at', '>=', filters.date_from);
            }
            if (filters.date_to) {
                // Add time to end of day for date_to
                const dateTo = new Date(filters.date_to);
                dateTo.setHours(23, 59, 59, 999);
                query = query.where('orders.created_at', '<=', dateTo.toISOString());
            }
            const products = await query
                .orderBy('total_quantity', 'desc')
                .limit(parseInt(limit) || 10);
            return products || [];
        } catch (error) {
            console.error('Error in getTopProducts:', error);
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
                .leftJoin('reservations', 'orders.reservation_id', 'reservations.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
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
                        'products.image as product_image',
                        'products.id as product_id'
                    )
                    .leftJoin('branch_products', 'order_details.branch_product_id', 'branch_products.id')
                    .leftJoin('products', 'branch_products.product_id', 'products.id')
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
            const oldOrder = await knex('orders').where('id', orderId).first();
            if (!oldOrder) {
                throw new Error('Order not found');
            }
            
            await knex('orders')
                .where('id', orderId)
                .update({ status: 'ready' });
            
            // ✅ EMIT REAL-TIME NOTIFICATION
            if (io) {
                // Notify branch staff
                io.to(`branch:${oldOrder.branch_id}`).emit('order-status-updated', {
                    orderId: orderId,
                    branchId: oldOrder.branch_id,
                    orderType: oldOrder.order_type, // Add orderType for filtering
                    oldStatus: oldOrder.status,
                    newStatus: 'ready',
                    timestamp: new Date().toISOString()
                });
                
                // Notify customer if user_id exists
                if (oldOrder.user_id) {
                    io.to(`user:${oldOrder.user_id}`).emit('order-status-updated', {
                        orderId: orderId,
                        orderType: oldOrder.order_type, // Add orderType for filtering
                        oldStatus: oldOrder.status,
                        newStatus: 'ready',
                        timestamp: new Date().toISOString()
                    });
                }
            }
            
            return true;
        } catch (error) {
            throw new Error(`Failed to mark order ready: ${error.message}`);
        }
    }
    /**
     * @deprecated This function is deprecated. Empty orders are no longer allowed.
     * Orders must have at least one item and total > 0.
     * Use createOrder() instead when you have items.
     */
    static async createEmptyOrder(orderData) {
        throw new Error('createEmptyOrder is deprecated. Empty orders are no longer allowed. Orders must have at least one item and total > 0.');
    }
    /**
     * @deprecated This function is deprecated. Empty orders are no longer allowed.
     * Orders must have at least one item and total > 0.
     * Use createOrder() instead when you have items.
     */
    // createEmptyOrderForReservation - REMOVED: deprecated and not used
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
                .leftJoin('reservations', 'orders.reservation_id', 'reservations.id')
                .leftJoin('tables', 'reservations.table_id', 'tables.id')
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
                    'products.description as product_description',
                    'products.id as product_id'
                )
                .leftJoin('branch_products', 'order_details.branch_product_id', 'branch_products.id')
                .leftJoin('products', 'branch_products.product_id', 'products.id')
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
                await trx('order_details').where('order_id', orderId).delete();
                await trx('orders').where('id', orderId).delete();
            });
            return true;
        } catch (error) {
            throw new Error(`Failed to delete order: ${error.message}`);
        }
    }
    static async getDeliveryOrders(filters = {}) {
        try {
            let query = knex('orders')
                .select(
                    'orders.*',
                    'branches.name as branch_name',
                    'branches.image as branch_image',
                    'users.name as customer_name',
                    'users.phone as customer_phone',
                    knex.raw('COUNT(order_details.id) as items_count')
                )
                .leftJoin('branches', 'orders.branch_id', 'branches.id')
                .leftJoin('users', 'orders.user_id', 'users.id')
                .leftJoin('order_details', 'orders.id', 'order_details.order_id')
                .where('orders.order_type', 'delivery');
            
            // Filter by delivery_staff_id if provided - join with order_assignments table
            if (filters.delivery_staff_id) {
                query = query
                    .innerJoin('order_assignments', 'orders.id', 'order_assignments.order_id')
                    .where('order_assignments.delivery_staff_id', filters.delivery_staff_id);
            }
            
            query = query.groupBy('orders.id', 'branches.name', 'branches.image', 'users.name', 'users.phone');
            
            if (filters.status) {
                query = query.where('orders.status', filters.status);
            }
            
            // Only show orders that are ready for delivery or already out for delivery
            if (!filters.status) {
                query = query.whereIn('orders.status', ['ready', 'out_for_delivery', 'completed']);
            }
            
            const orders = await query
                .orderBy('orders.created_at', 'desc');
            
            return orders || [];
        } catch (error) {
            throw new Error(`Failed to get delivery orders: ${error.message}`);
        }
    }
}

// Export setSocketIO function
OrderService.setSocketIO = setSocketIO;

module.exports = OrderService;
