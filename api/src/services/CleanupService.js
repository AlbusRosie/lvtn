const CartService = require('../services/CartService');
const knex = require('../database/knex');

class CleanupService {
    constructor() {
        this.isRunning = false;
    }

    async cleanupExpiredCarts() {
        if (this.isRunning) {
            console.log('Cleanup job is already running, skipping...');
            return;
        }

        this.isRunning = true;
        console.log('Starting cleanup job...');

        try {
            const expiredCartsCount = await CartService.cleanupExpiredCarts();
            console.log(`Cleaned up ${expiredCartsCount} expired carts`);

            const expiredTablesCount = await this.cleanupExpiredTableReservations();
            console.log(`Released ${expiredTablesCount} expired table reservations`);

            const oldCartsCount = await this.cleanupOldCarts();
            console.log(`Cleaned up ${oldCartsCount} old completed carts`);

            console.log('Cleanup job completed successfully');
        } catch (error) {
            console.error('Cleanup job failed:', error);
        } finally {
            this.isRunning = false;
        }
    }

    async cleanupExpiredTableReservations() {
        const expiredTables = await knex('tables')
            .where('status', 'reserved')
            .where('reserved_until', '<', new Date());

        let count = 0;
        for (const table of expiredTables) {
            await knex('tables')
                .where('id', table.id)
                .update({
                    status: 'available',
                    reserved_until: null,
                    cart_id: null,
                    reservation_id: null
                });
            count++;
        }

        return count;
    }

    async cleanupOldCarts() {
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        
        const oldCarts = await knex('carts')
            .where('status', 'completed')
            .where('updated_at', '<', sevenDaysAgo);

        let count = 0;
        for (const cart of oldCarts) {
            await knex('cart_items').where('cart_id', cart.id).del();
            
            await knex('carts').where('id', cart.id).del();
            count++;
        }

        return count;
    }

    startCleanupJob(intervalMinutes = 30) {
        console.log(`Starting cleanup job every ${intervalMinutes} minutes`);
        
        this.cleanupExpiredCarts();
        
        setInterval(() => {
            this.cleanupExpiredCarts();
        }, intervalMinutes * 60 * 1000);
    }

    async manualCleanup() {
        await this.cleanupExpiredCarts();
    }
}

module.exports = new CleanupService();
