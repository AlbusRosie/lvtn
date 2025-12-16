const CartService = require('../services/CartService');
const ReservationService = require('./ReservationService');
const knex = require('../database/knex');
class CleanupService {
    constructor() {
        this.isRunning = false;
    }
    async cleanupExpiredCarts() {
        if (this.isRunning) {
            return;
        }
        this.isRunning = true;
        try {
            const expiredTablesCount = await this.cleanupExpiredTableReservations();
            const overdueResult = await ReservationService.checkAndProcessOverdueReservations();
            // Note: Reservations are no longer auto-cancelled just because they don't have orders
            // Customers can book tables without ordering food - reservation stays valid
            // Reservations are only cancelled for no-show (overdue) or manual cancellation
        } catch (error) {
            console.error('Cleanup error:', error);
        } finally {
            this.isRunning = false;
        }
    }
    async cleanupExpiredTableReservations() {
        const now = new Date();
        const currentDate = now.toISOString().split('T')[0];
        const currentTime = now.toTimeString().split(' ')[0];
        const expiredSchedules = await knex('table_schedules')
            .where('schedule_date', '<=', currentDate)
            .where(function() {
                this.whereRaw('(schedule_date < ? OR (schedule_date = ? AND TIME(end_time) < ?))', 
                    [currentDate, currentDate, currentTime]);
            })
            .where('status', '!=', 'cancelled');
        let count = 0;
        for (const schedule of expiredSchedules) {
            await knex('table_schedules')
                .where('id', schedule.id)
                .update({
                    status: 'cancelled'
                });
            count++;
        }
        return count;
    }
    startCleanupJob(intervalMinutes = 30) {
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
