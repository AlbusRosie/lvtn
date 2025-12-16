const knex = require('../database/knex');
const crypto = require('crypto');
const OrderService = require('./OrderService');
class CartService {
    async findPendingCart(userId, branchId, sessionId = null) {
        let query = knex('carts')
            .where('user_id', userId)
            .where('branch_id', branchId);
        if (sessionId) {
            query = query.where('session_id', sessionId);
        }
        const cart = await query.first();
        return cart;
    }
    async createCart(userId, branchId, orderType = 'dine_in', sessionId = null) {
        const cartData = {
            user_id: userId,
            branch_id: branchId,
            session_id: sessionId || crypto.randomUUID(),
            order_type: orderType
        };
        const [cartId] = await knex('carts').insert(cartData);
        const cart = await knex('carts').where('id', cartId).first();
        return cart;
    }
    async addToCart(userId, branchId, productId, quantity = 1, orderType = 'delivery', sessionId = null, selectedOptions = [], specialInstructions = null) {
        const product = await knex('products')
            .join('branch_products', 'products.id', 'branch_products.product_id')
            .where('products.id', productId)
            .where('branch_products.branch_id', branchId)
            .where('branch_products.is_available', 1)
            .select('products.*', 'branch_products.price as branch_price', 'branch_products.id as branch_product_id')
            .first();
        if (!product) {
            throw new Error('Product not available in this branch');
        }
        let finalPrice = parseFloat(product.branch_price);
        if (selectedOptions && selectedOptions.length > 0) {
            for (const option of selectedOptions) {
                for (const valueId of option.selected_value_ids) {
                    const optionValue = await knex('product_option_values')
                        .where('id', valueId)
                        .first();
                    if (optionValue) {
                        finalPrice += parseFloat(optionValue.price_modifier || 0);
                    }
                }
            }
        }
        let cart = await this.findPendingCart(userId, branchId, sessionId);
        if (!cart) {
            try {
                cart = await this.createCart(userId, branchId, orderType, sessionId);
            } catch (error) {
                if (error.message.includes('Duplicate entry')) {
                    cart = await this.findPendingCart(userId, branchId, sessionId);
                    if (!cart) {
                        cart = await this.createCart(userId, branchId, orderType, null);
                    }
                } else {
                    throw error;
                }
            }
        } else {
            // Cập nhật orderType của cart nếu khác với orderType được truyền vào
            if (cart.order_type !== orderType) {
                await knex('carts')
                    .where('id', cart.id)
                    .update({ order_type: orderType });
                cart.order_type = orderType;
            }
        }
        const existingItem = await knex('cart_items')
            .where('cart_id', cart.id)
            .where('branch_product_id', product.branch_product_id)
            .first();
        if (existingItem) {
            await knex('cart_items')
                .where('id', existingItem.id)
                .update({
                    quantity: existingItem.quantity + quantity,
                    price: finalPrice,
                    branch_product_id: product.branch_product_id,
                    special_instructions: specialInstructions || (selectedOptions.length > 0 ? JSON.stringify(selectedOptions) : null)
                });
        } else {
            await knex('cart_items').insert({
                cart_id: cart.id,
                branch_product_id: product.branch_product_id,
                quantity: quantity,
                price: finalPrice,
                special_instructions: specialInstructions || (selectedOptions.length > 0 ? JSON.stringify(selectedOptions) : null),
                created_at: new Date()
            });
        }
        return await this.getCartById(cart.id);
    }
    async removeFromCart(cartId, productId) {
        // Get cart to find branch_id
        const cart = await knex('carts').where('id', cartId).first();
        if (!cart) {
            throw new Error('Cart not found');
        }
        // Find branch_product_id from product_id
        const branchProduct = await knex('branch_products')
            .where('branch_id', cart.branch_id)
            .where('product_id', productId)
            .first();
        if (!branchProduct) {
            throw new Error('Product not found in this branch');
        }
        const deleted = await knex('cart_items')
            .where('cart_id', cartId)
            .where('branch_product_id', branchProduct.id)
            .del();
        if (deleted === 0) {
            throw new Error('Item not found in cart');
        }
        return await this.getCartById(cartId);
    }
    async updateCartItemQuantity(cartId, productId, quantity) {
        if (quantity <= 0) {
            return await this.removeFromCart(cartId, productId);
        }
        // Get cart to find branch_id
        const cart = await knex('carts').where('id', cartId).first();
        if (!cart) {
            throw new Error('Cart not found');
        }
        // Find branch_product_id from product_id
        const branchProduct = await knex('branch_products')
            .where('branch_id', cart.branch_id)
            .where('product_id', productId)
            .first();
        if (!branchProduct) {
            throw new Error('Product not found in this branch');
        }
            await knex('cart_items')
            .where('cart_id', cartId)
            .where('branch_product_id', branchProduct.id)
            .update({
                quantity: quantity
            });
        return await this.getCartById(cartId);
    }
    async getCartById(cartId) {
        const cart = await knex('carts')
            .leftJoin('branches', 'carts.branch_id', 'branches.id')
            .where('carts.id', cartId)
            .select(
                'carts.*',
                'branches.name as branch_name'
            )
            .first();
        if (!cart) {
            throw new Error('Cart not found');
        }
        const items = await knex('cart_items')
            .join('branch_products', 'cart_items.branch_product_id', 'branch_products.id')
            .join('products', 'branch_products.product_id', 'products.id')
            .where('cart_items.cart_id', cartId)
            .select(
                'cart_items.*',
                'products.id as product_id',
                'products.name as product_name',
                'products.image as product_image',
                'products.description as product_description'
            );
        items.forEach(item => {
            if (item.special_instructions) {
                try {
                    item.selected_options = JSON.parse(item.special_instructions);
                } catch {
                    item.selected_options = null;
                }
            } else {
                item.selected_options = null;
            }
        });
        cart.items = items;
        cart.total = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
        return cart;
    }
    // DEPRECATED: reserveTable is no longer used - reservation flow is now separate from cart
    // Use ReservationService.createReservation() instead
    async reserveTable(cartId, tableId, reservationDate, reservationTime, guestCount) {
        throw new Error('reserveTable is deprecated. Use ReservationService.createReservation() instead');
        }
    
    // DEPRECATED: cancelTableReservation is no longer used - reservation flow is now separate from cart
    async cancelTableReservation(cartId) {
        throw new Error('cancelTableReservation is deprecated. Use ReservationService to cancel reservations instead');
    }
    async checkout(cartId, reservationId = null, deliveryAddress = null, deliveryPhone = null, customerName = null, customerPhone = null) {
        const cart = await this.getCartById(cartId);
        if (!cart) {
            throw new Error('Cart not found');
        }
        if (cart.items.length === 0) {
            throw new Error('Cart is empty');
        }
        // Lấy địa chỉ và số điện thoại của user nếu orderType là delivery và chưa có
        let finalDeliveryAddress = deliveryAddress;
        let userPhone = null;
        if (cart.order_type === 'delivery' && cart.user_id) {
            const user = await knex('users')
                .where('id', cart.user_id)
                .select('address', 'phone')
                .first();
            if (user) {
                if (!finalDeliveryAddress && user.address) {
                    finalDeliveryAddress = user.address;
                }
                if (user.phone) {
                    userPhone = user.phone;
                }
            }
        }
        // Validate delivery address for delivery orders
        if (cart.order_type === 'delivery' && !finalDeliveryAddress) {
            throw new Error('Delivery address is required for delivery orders');
        }
        // Format notes with customer name if provided
        let notes = cart.special_requests || null;
        if (customerName) {
            notes = notes ? `${notes}\nKhách hàng: ${customerName}` : `Khách hàng: ${customerName}`;
        }
        
        // Use customer_phone for delivery_phone if provided, otherwise use deliveryPhone, otherwise use user phone
        const finalDeliveryPhone = customerPhone || deliveryPhone || (cart.order_type === 'delivery' ? userPhone : null);
        
        const orderData = {
            user_id: cart.user_id,
            branch_id: cart.branch_id,
            order_type: cart.order_type,
            delivery_address: cart.order_type === 'delivery' ? finalDeliveryAddress : null,
            delivery_phone: finalDeliveryPhone,
            total: cart.total,
            status: 'pending',
            payment_status: 'pending',
            notes: notes
        };
        // Note: Empty orders are no longer created automatically when creating reservation
        // Order will be created only when checkout with items
        if (reservationId) {
            // Check if there's an existing order for this reservation (for backward compatibility with old empty orders)
            const existingOrder = await knex('orders')
                .where('reservation_id', reservationId)
                .where('total', 0)
                .orderBy('created_at', 'desc')
                .first();
            if (existingOrder) {
                // Update existing empty order (backward compatibility only)
                // Format notes with customer name if provided
                let notes = cart.special_requests || null;
                if (customerName) {
                    notes = notes ? `${notes}\nKhách hàng: ${customerName}` : `Khách hàng: ${customerName}`;
                }
                const finalDeliveryPhone = customerPhone || (cart.order_type === 'delivery' ? deliveryPhone : null);
                
                await knex('orders')
                    .where('id', existingOrder.id)
                    .update({
                        total: cart.total,
                        delivery_address: cart.order_type === 'delivery' ? finalDeliveryAddress : null,
                        delivery_phone: finalDeliveryPhone,
                        notes: notes,
                        payment_method: 'cash',
                        payment_status: 'pending',
                        status: 'pending'
                    });
                await knex('order_details').where('order_id', existingOrder.id).del();
                const orderDetails = cart.items.map(item => ({
                    order_id: existingOrder.id,
                    branch_product_id: item.branch_product_id || null,
                    quantity: item.quantity,
                    price: item.price,
                    special_instructions: item.special_instructions
                }));
                await knex('order_details').insert(orderDetails);
                
                // ✅ EMIT REAL-TIME NOTIFICATION for updated order
                // Get io instance from server
                let io = null;
                try {
                    // Try to get io from module exports (set in server.js)
                    const serverModule = require('../../server');
                    io = serverModule.io;
                } catch (error) {
                    console.warn('[CartService] Could not get io instance:', error.message);
                }
                
                if (io) {
                    const notificationData = {
                        orderId: existingOrder.id,
                        branchId: cart.branch_id,
                        orderType: cart.order_type,
                        total: cart.total || 0,
                        customerName: customerName,
                        timestamp: new Date().toISOString(),
                        isUpdate: true // Flag to indicate this is an update, not new order
                    };
                    
                    // Get room sizes for debugging
                    const branchRoom = io.sockets.adapter.rooms.get(`branch:${cart.branch_id}`);
                    const adminRoom = io.sockets.adapter.rooms.get('admin');
                    const branchRoomSize = branchRoom ? branchRoom.size : 0;
                    const adminRoomSize = adminRoom ? adminRoom.size : 0;
                    
                    console.log(`[Socket.IO] Emitting new-order (update) to branch:${cart.branch_id} (${branchRoomSize} listeners)`, notificationData);
                    console.log(`[Socket.IO] Emitting new-order (update) to admin room (${adminRoomSize} listeners)`);
                    
                    // Notify branch staff
                    io.to(`branch:${cart.branch_id}`).emit('new-order', notificationData);
                    
                    // Notify admin
                    io.to('admin').emit('new-order', notificationData);
                    
                    console.log(`[Socket.IO] ✅ Notification emitted successfully for updated order`);
                }
                
                // Note: table_schedule was already created when reservation was created
                // No need to create it again here
                await knex('cart_items').where('cart_id', cartId).del();
                await knex('carts').where('id', cartId).del();
                return {
                    order_id: existingOrder.id,
                    reservation_id: reservationId,
                    total: cart.total
                };
            } else {
                // Use OrderService.createOrder() to ensure socket notifications are sent
                const items = cart.items.map(item => ({
                    product_id: item.product_id,
                    branch_product_id: item.branch_product_id || null,
                    quantity: item.quantity,
                    price: item.price,
                    special_instructions: item.special_instructions
                }));
                
                const finalOrderData = {
                    ...orderData,
                    reservation_id: reservationId,
                    items: items,
                    customer_name: customerName,
                    customer_phone: customerPhone
                };
                
                const order = await OrderService.createOrder(finalOrderData);
                
                // Clean up cart after successful order creation
                await knex('cart_items').where('cart_id', cartId).del();
                await knex('carts').where('id', cartId).del();
                
                return {
                    order_id: order.id,
                    reservation_id: reservationId,
                    total: cart.total
                };
            }
        }
        
        // Use OrderService.createOrder() to ensure socket notifications are sent
        const items = cart.items.map(item => ({
            product_id: item.product_id,
            branch_product_id: item.branch_product_id || null,
            quantity: item.quantity,
            price: item.price,
            special_instructions: item.special_instructions
        }));
        
        const finalOrderData = {
            ...orderData,
            reservation_id: reservationId,
            items: items,
            customer_name: customerName,
            customer_phone: customerPhone
        };
        
        const order = await OrderService.createOrder(finalOrderData);
        
        // Clean up cart after successful order creation
        await knex('cart_items').where('cart_id', cartId).del();
        await knex('carts').where('id', cartId).del();
        
        return {
            order_id: order.id,
            reservation_id: reservationId,
            total: cart.total
        };
    }
    async updateCartItemOptions(cartId, productId, selectedOptions) {
        const cart = await knex('carts')
            .where('id', cartId)
            .first();
        if (!cart) {
            throw new Error('Cart not found');
        }
        const branchProduct = await knex('branch_products')
            .where('branch_id', cart.branch_id)
            .where('product_id', productId)
            .first();
        if (!branchProduct) {
            throw new Error('Product not available in this branch');
        }
        const cartItem = await knex('cart_items')
            .where('cart_id', cartId)
            .where('branch_product_id', branchProduct.id)
            .first();
        if (!cartItem) {
            throw new Error('Cart item not found');
        }
        let totalPriceModifier = 0;
        for (const option of selectedOptions) {
            for (const valueId of option.selected_value_ids) {
                const optionValue = await knex('product_option_values')
                    .where('id', valueId)
                    .first();
                if (optionValue) {
                    totalPriceModifier += parseFloat(optionValue.price_modifier || 0);
                }
            }
        }
        const newPrice = parseFloat(branchProduct.price) + totalPriceModifier;
        await knex('cart_items')
            .where('cart_id', cartId)
            .where('branch_product_id', branchProduct.id)
            .update({
                price: newPrice,
                special_instructions: JSON.stringify(selectedOptions)
            });
        return await this.getCartById(cartId);
    }
    async getUserCart(userId, branchId, sessionId = null) {
        const cart = await this.findPendingCart(userId, branchId, sessionId);
        if (!cart) {
            return null;
        }
        return await this.getCartById(cart.id);
    }
}
module.exports = new CartService();
