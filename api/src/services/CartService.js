const knex = require('../database/knex');
const crypto = require('crypto');

class CartService {
    constructor() {
        this.CART_TIMEOUT_MINUTES = 30;
    }

    async findPendingCart(userId, branchId, sessionId = null) {
        let query = knex('carts')
            .where('user_id', userId)
            .where('branch_id', branchId)
            .where('status', 'pending')
            .where('expires_at', '>', new Date());

        if (sessionId) {
            query = query.where('session_id', sessionId);
        }

        const cart = await query.first();
        
        
        return cart;
    }

    async createCart(userId, branchId, orderType = 'dine_in', sessionId = null) {
        const expiresAt = new Date(Date.now() + this.CART_TIMEOUT_MINUTES * 60 * 1000);
        
        const cartData = {
            user_id: userId,
            branch_id: branchId,
            session_id: sessionId || crypto.randomUUID(),
            order_type: orderType,
            status: 'pending',
            expires_at: expiresAt
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
            .select('products.*', 'branch_products.price as branch_price')
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
        }

        const existingItem = await knex('cart_items')
            .where('cart_id', cart.id)
            .where('product_id', productId)
            .first();

        if (existingItem) {
            await knex('cart_items')
                .where('id', existingItem.id)
                .update({
                    quantity: existingItem.quantity + quantity,
                    price: finalPrice,
                    special_instructions: specialInstructions || (selectedOptions.length > 0 ? JSON.stringify(selectedOptions) : null),
                    updated_at: new Date()
                });
        } else {
            await knex('cart_items').insert({
                cart_id: cart.id,
                product_id: productId,
                quantity: quantity,
                price: finalPrice,
                special_instructions: specialInstructions || (selectedOptions.length > 0 ? JSON.stringify(selectedOptions) : null),
                created_at: new Date(),
                updated_at: new Date()
            });
        }

        return await this.getCartById(cart.id);
    }

    async removeFromCart(cartId, productId) {
        const deleted = await knex('cart_items')
            .where('cart_id', cartId)
            .where('product_id', productId)
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

        await knex('cart_items')
            .where('cart_id', cartId)
            .where('product_id', productId)
            .update({
                quantity: quantity,
                updated_at: new Date()
            });

        return await this.getCartById(cartId);
    }

    async getCartById(cartId) {
        const cart = await knex('carts')
            .leftJoin('tables', 'carts.table_id', 'tables.id')
            .leftJoin('branches', 'carts.branch_id', 'branches.id')
            .where('carts.id', cartId)
            .select(
                'carts.*',
                'tables.table_number',
                'tables.capacity',
                'branches.name as branch_name'
            )
            .first();

        if (!cart) {
            throw new Error('Cart not found');
        }

        const items = await knex('cart_items')
            .join('products', 'cart_items.product_id', 'products.id')
            .where('cart_items.cart_id', cartId)
            .select(
                'cart_items.*',
                'products.name as product_name',
                'products.image as product_image',
                'products.description as product_description'
            );

        items.forEach(item => {
            if (item.special_instructions) {
                try {
                    item.selected_options = JSON.parse(item.special_instructions);
                } catch (e) {
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

    async reserveTable(cartId, tableId, reservationDate, reservationTime, guestCount) {
        const cart = await knex('carts').where('id', cartId).first();
        if (!cart) {
            throw new Error('Cart not found');
        }

        if (cart.status !== 'pending') {
            throw new Error('Cart is not in pending status');
        }

        const table = await knex('tables')
            .where('id', tableId)
            .where('branch_id', cart.branch_id)
            .where('status', 'available')
            .first();

        if (!table) {
            throw new Error('Table is not available');
        }

        if (guestCount > table.capacity) {
            throw new Error(`Table capacity is ${table.capacity}, but ${guestCount} guests requested`);
        }

        const reserved = await knex('tables')
            .where('id', tableId)
            .where('status', 'available')
            .update({
                status: 'reserved',
                reserved_until: cart.expires_at,
                cart_id: cartId
            });

        if (reserved === 0) {
            throw new Error('Table reservation failed - table may have been taken');
        }

        await knex('carts')
            .where('id', cartId)
            .update({
                table_id: tableId,
                reservation_date: reservationDate,
                reservation_time: reservationTime,
                guest_count: guestCount
            });

        return await this.getCartById(cartId);
    }

    async cancelTableReservation(cartId) {
        const cart = await knex('carts').where('id', cartId).first();
        if (!cart || !cart.table_id) {
            return cart;
        }


        await knex('carts')
            .where('id', cartId)
            .update({
                table_id: null,
                reservation_date: null,
                reservation_time: null,
                guest_count: null
            });

        return await this.getCartById(cartId);
    }

    async checkout(cartId) {
        const cart = await this.getCartById(cartId);
        
        if (!cart || cart.status !== 'pending') {
            throw new Error('Cart not found or not in pending status');
        }

        if (cart.items.length === 0) {
            throw new Error('Cart is empty');
        }

        const orderData = {
            user_id: cart.user_id,
            branch_id: cart.branch_id,
            table_id: cart.table_id,
            order_type: cart.order_type,
            total: cart.total,
            status: 'pending',
            payment_status: 'pending',
            notes: cart.special_requests
        };

        const [orderId] = await knex('orders').insert(orderData);

        const orderDetails = cart.items.map(item => ({
            order_id: orderId,
            product_id: item.product_id,
            quantity: item.quantity,
            price: item.price,
            special_instructions: item.special_instructions
        }));

        await knex('order_details').insert(orderDetails);

        let reservationId = null;
        if (cart.order_type === 'dine_in' && cart.table_id) {
            const reservationData = {
                user_id: cart.user_id,
                branch_id: cart.branch_id,
                table_id: cart.table_id,
                reservation_date: cart.reservation_date,
                reservation_time: cart.reservation_time,
                guest_count: cart.guest_count,
                status: 'confirmed',
                special_requests: cart.special_requests
            };

            const [resId] = await knex('reservations').insert(reservationData);
            reservationId = resId;

            await knex('tables')
                .where('id', cart.table_id)
                .update({
                    status: 'reserved',
                    reservation_id: reservationId
                });
        }

        await knex('carts')
            .where('id', cartId)
            .update({ status: 'completed' });

        return {
            order_id: orderId,
            reservation_id: reservationId,
            total: cart.total
        };
    }

    async cleanupExpiredCarts() {
        const expiredCarts = await knex('carts')
            .where('expires_at', '<', new Date())
            .where('status', 'pending');

        for (const cart of expiredCarts) {
            if (cart.table_id) {
                await knex('tables')
                    .where('id', cart.table_id)
                    .update({
                        status: 'available',
                        reserved_until: null,
                        cart_id: null
                    });
            }

            await knex('carts')
                .where('id', cart.id)
                .update({ status: 'expired' });
        }

        return expiredCarts.length;
    }

    async updateCartItemOptions(cartId, productId, selectedOptions) {
        const cart = await knex('carts').where('id', cartId).first();
        if (!cart || cart.status !== 'pending') {
            throw new Error('Cart not found');
        }

        const cartItem = await knex('cart_items')
            .where('cart_id', cartId)
            .where('product_id', productId)
            .first();
        
        if (!cartItem) {
            throw new Error('Cart item not found');
        }

        const branchProduct = await knex('branch_products')
            .where('branch_id', cart.branch_id)
            .where('product_id', productId)
            .first();

        if (!branchProduct) {
            throw new Error('Product not available in this branch');
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
            .where('product_id', productId)
            .update({
                price: newPrice,
                special_instructions: JSON.stringify(selectedOptions),
                updated_at: new Date()
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
