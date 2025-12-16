const knex = require('../database/knex');
const TableService = require('./TableService');
let io = null;

// Function to set io instance (called from server.js)
function setSocketIO(socketIO) {
    io = socketIO;
}
function reservationRepository() {
    return knex('reservations');
}
function readReservation(payload) {
    return {
        user_id: payload.user_id,
        branch_id: payload.branch_id,
        table_id: payload.table_id,
        reservation_date: payload.reservation_date,
        reservation_time: payload.reservation_time,
        guest_count: payload.guest_count,
        status: payload.status || 'pending',
        special_requests: payload.special_requests || null,
        created_at: new Date()
    };
}
async function createReservation(payload) {
    if (!payload.user_id || !payload.branch_id || !payload.table_id || 
        !payload.reservation_date || !payload.reservation_time || !payload.guest_count) {
        throw new Error('Missing required fields');
    }
    const user = await knex('users').where('id', payload.user_id).first();
    if (!user) {
        throw new Error('User not found');
    }
    const branch = await knex('branches').where('id', payload.branch_id).first();
    if (!branch) {
        throw new Error('Branch not found');
    }
    const table = await knex('tables')
        .leftJoin('floors', 'tables.floor_id', 'floors.id')
        .where('tables.id', payload.table_id)
        .select('tables.*', 'floors.branch_id')
        .first();
    if (!table) {
        throw new Error('Table not found');
    }
    if (table.branch_id !== payload.branch_id) {
        throw new Error('Table does not belong to the specified branch');
    }
    const available = await TableService.isTableAvailable(
        payload.table_id,
        payload.reservation_date,
        payload.reservation_time,
        120
    );
    if (!available) {
        throw new Error('Table is not available at the requested date and time');
    }
    return await knex.transaction(async (trx) => {
        // Lock table row to prevent race condition
        // SELECT FOR UPDATE ensures only one transaction can proceed at a time
        const tableLock = await trx('tables')
            .where('id', payload.table_id)
            .forUpdate()
            .first();
        
        if (!tableLock) {
            throw new Error('Table not found');
        }
        
        // Recheck availability within transaction (with lock)
        const recheckAvailable = await TableService.isTableAvailable(
            payload.table_id,
            payload.reservation_date,
            payload.reservation_time,
            120,
            trx // Pass transaction to check within locked transaction
        );
        if (!recheckAvailable) {
            throw new Error('Table is not available at the requested date and time. It may have been reserved by another customer.');
        }
        const reservation = readReservation(payload);
        const [id] = await trx('reservations').insert(reservation);
        // Create table_schedule immediately to block the table slot
        // This prevents other users from booking the same table
        // Note: Reservation stays valid even without order - customers can book tables without ordering food
        await TableService.createTableSchedule({
            table_id: payload.table_id,
            reservation_id: id,
            schedule_date: payload.reservation_date,
            start_time: payload.reservation_time,
            duration_minutes: 120,
            status: 'reserved'
        }, trx);
        
        const newReservation = { 
            id, 
            ...reservation
        };
        
        // ✅ EMIT REAL-TIME NOTIFICATION
        if (io) {
            // Notify branch staff
            io.to(`branch:${payload.branch_id}`).emit('reservation-created', {
                reservationId: id,
                reservation: newReservation,
                branchId: payload.branch_id,
                tableId: payload.table_id,
                timestamp: new Date().toISOString()
            });
            
            // Notify admin
            io.to('admin').emit('reservation-created', {
                reservationId: id,
                reservation: newReservation,
                branchId: payload.branch_id,
                tableId: payload.table_id,
                timestamp: new Date().toISOString()
            });
            
            // Notify customer
            if (payload.user_id) {
                io.to(`user:${payload.user_id}`).emit('reservation-created', {
                    reservationId: id,
                    reservation: newReservation,
                    branchId: payload.branch_id,
                    tableId: payload.table_id,
                    timestamp: new Date().toISOString()
                });
            }
        }
        
        return newReservation;
    });
}

async function getReservationsByDateRange(startDate, endDate) {
    return await reservationRepository()
        .select(
            'reservations.*',
            'users.name as user_name',
            'users.email as user_email',
            'branches.name as branch_name',
            'tables.capacity'
        )
        .leftJoin('users', 'reservations.user_id', 'users.id')
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .whereBetween('reservation_date', [startDate, endDate])
        .orderBy('reservation_date', 'asc')
        .orderBy('reservation_time', 'asc');
}
async function getTableSchedule(tableId, startDate, endDate) {
    const reservations = await reservationRepository()
        .select(
            'reservations.*',
            'users.name as user_name',
            'users.email as user_email',
            'branches.name as branch_name',
            'tables.capacity'
        )
        .leftJoin('users', 'reservations.user_id', 'users.id')
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .where('reservations.table_id', tableId)
        .whereBetween('reservations.reservation_date', [startDate, endDate])
        .where('reservations.status', '!=', 'cancelled')
        .orderBy('reservations.reservation_date', 'asc')
        .orderBy('reservations.reservation_time', 'asc');
    const tableSchedules = await TableService.getTableSchedules(tableId, startDate, endDate);
    const activeOrders = await knex('orders')
        .select(
            'orders.id as order_id',
            'reservations.table_id',
            'orders.created_at',
            'orders.status as order_status',
            'orders.order_type',
            'users.name as user_name',
            'users.email as user_email',
            'tables.capacity'
        )
        .leftJoin('users', 'orders.user_id', 'users.id')
        .leftJoin('reservations', 'orders.reservation_id', 'reservations.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .where('reservations.table_id', tableId)
        .where('orders.order_type', 'dine_in')
        .whereIn('orders.status', ['pending', 'preparing', 'ready'])
        .whereBetween(knex.raw('DATE(orders.created_at)'), [startDate, endDate])
        .whereNotExists(function() {
            this.select('*')
                .from('table_schedules')
                .whereRaw('table_schedules.table_id = reservations.table_id')
                .whereRaw('DATE(table_schedules.schedule_date) = DATE(orders.created_at)')
                .whereRaw('TIME(table_schedules.start_time) <= TIME(orders.created_at)')
                .where(function() {
                    this.whereNull('table_schedules.end_time')
                        .orWhereRaw('TIME(table_schedules.end_time) >= TIME(orders.created_at)');
                })
                .where('table_schedules.status', '!=', 'cancelled');
        });
    const scheduleItems = tableSchedules.map(schedule => ({
        id: schedule.id,
        reservation_id: schedule.reservation_id,
        order_id: schedule.order_id || null,
        table_id: schedule.table_id,
        reservation_date: schedule.schedule_date,
        reservation_time: schedule.start_time,
        end_time: schedule.end_time,
        duration_minutes: schedule.duration_minutes || (() => {
            if (schedule.start_time && schedule.end_time) {
                const start = new Date(`${schedule.schedule_date} ${schedule.start_time}`);
                const end = new Date(`${schedule.schedule_date} ${schedule.end_time}`);
                return Math.round((end - start) / 60000);
            }
            return 120;
        })(),
        status: schedule.status,
        guest_count: null,
        user_name: null,
        customer_name: null,
        special_requests: schedule.notes || null,
        created_at: schedule.created_at
    }));
    const orderScheduleItems = activeOrders.map(order => {
        const orderDate = new Date(order.created_at);
        const orderDateStr = orderDate.toISOString().split('T')[0];
        const orderTimeStr = orderDate.toTimeString().split(' ')[0].substring(0, 8);
        const endDateTime = new Date(orderDate.getTime() + 120 * 60000);
        const endTimeStr = endDateTime.toTimeString().split(' ')[0].substring(0, 8);
        return {
            id: `order_${order.order_id}`,
            reservation_id: null,
            order_id: order.order_id,
            table_id: order.table_id,
            reservation_date: orderDateStr,
            reservation_time: orderTimeStr,
            end_time: endTimeStr,
            duration_minutes: 120,
            status: 'occupied',
            guest_count: null,
            user_name: order.user_name,
            customer_name: order.user_name,
            special_requests: `Đơn hàng #${order.order_id} - ${order.order_status}`,
            created_at: order.created_at
        };
    });
    return [...reservations, ...scheduleItems, ...orderScheduleItems];
}
async function getAllReservations(filters = {}) {
    let query = reservationRepository()
        .select(
            'reservations.*',
            'users.name as user_name',
            'users.name as customer_name',
            'users.email as user_email',
            'branches.name as branch_name',
            'tables.capacity',
            'floors.name as floor_name',
            knex.raw('(SELECT id FROM orders WHERE orders.reservation_id = reservations.id AND orders.user_id = reservations.user_id AND orders.status != "cancelled" AND orders.created_at >= reservations.created_at ORDER BY orders.created_at ASC LIMIT 1) as order_id')
        )
        .leftJoin('users', 'reservations.user_id', 'users.id')
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .leftJoin('floors', 'tables.floor_id', 'floors.id');
    if (filters.status) {
        query = query.where('reservations.status', filters.status);
    }
    if (filters.branch_id) {
        query = query.where('reservations.branch_id', filters.branch_id);
    }
    if (filters.user_id) {
        query = query.where('reservations.user_id', filters.user_id);
    }
    if (filters.start_date && filters.end_date) {
        query = query.whereBetween('reservation_date', [filters.start_date, filters.end_date]);
    }
    return await query
        .orderBy('reservation_date', 'asc')
        .orderBy('reservation_time', 'asc');
}
async function getReservationById(id) {
    const reservation = await reservationRepository()
        .select(
            'reservations.*',
            'users.name as user_name',
            'users.email as user_email',
            'branches.name as branch_name',
            'tables.capacity'
        )
        .leftJoin('users', 'reservations.user_id', 'users.id')
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .where('reservations.id', id)
        .first();
    if (!reservation) {
        throw new Error('Reservation not found');
    }
    return reservation;
}
async function updateReservation(id, payload) {
    const existingReservation = await reservationRepository().where('id', id).first();
    if (!existingReservation) {
        throw new Error('Reservation not found');
    }
    const oldStatus = existingReservation.status;
    await reservationRepository().where('id', id).update(payload);
    if (payload.status) {
        if (payload.status === 'checked_in' || payload.status === 'confirmed') {
            await TableService.checkInTableSchedule(id);
        } else if (payload.status === 'cancelled') {
            await TableService.cancelTableScheduleByReservation(id);
        } else if (payload.status === 'completed') {
            await TableService.checkOutTableSchedule(id);
        }
    }
    const updated = await getReservationById(id);
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io && updated) {
        const newStatus = payload.status || oldStatus;
        // Notify branch staff
        io.to(`branch:${updated.branch_id}`).emit('reservation-updated', {
            reservationId: id,
            reservation: updated,
            branchId: updated.branch_id,
            oldStatus: oldStatus,
            newStatus: newStatus,
            timestamp: new Date().toISOString()
        });
        
        // Notify admin
        io.to('admin').emit('reservation-updated', {
            reservationId: id,
            reservation: updated,
            branchId: updated.branch_id,
            oldStatus: oldStatus,
            newStatus: newStatus,
            timestamp: new Date().toISOString()
        });
        
        // Notify customer
        if (updated.user_id) {
            io.to(`user:${updated.user_id}`).emit('reservation-updated', {
                reservationId: id,
                reservation: updated,
                oldStatus: oldStatus,
                newStatus: newStatus,
                timestamp: new Date().toISOString()
            });
        }
    }
    
    return updated;
}
async function deleteReservation(id) {
    const reservation = await reservationRepository().where('id', id).first();
    if (!reservation) {
        throw new Error('Reservation not found');
    }
    await TableService.cancelTableScheduleByReservation(id);
    await reservationRepository().where('id', id).del();
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io) {
        // Notify branch staff
        io.to(`branch:${reservation.branch_id}`).emit('reservation-deleted', {
            reservationId: id,
            reservation: reservation,
            branchId: reservation.branch_id,
            timestamp: new Date().toISOString()
        });
        
        // Notify admin
        io.to('admin').emit('reservation-deleted', {
            reservationId: id,
            reservation: reservation,
            branchId: reservation.branch_id,
            timestamp: new Date().toISOString()
        });
        
        // Notify customer
        if (reservation.user_id) {
            io.to(`user:${reservation.user_id}`).emit('reservation-deleted', {
                reservationId: id,
                timestamp: new Date().toISOString()
            });
        }
    }
    
    return { message: 'Reservation deleted successfully' };
}
async function checkTableAvailability(branchId, date, time, guestCount) {
    try {
        if (!branchId || !date || !time || !guestCount) {
            return { available: false, reason: 'invalid_input' };
        }
        const allTables = await knex('tables')
            .leftJoin('floors', 'tables.floor_id', 'floors.id')
            .where('floors.branch_id', branchId)
            .where('tables.capacity', '>=', guestCount)
            .orderBy('tables.capacity', 'asc')
            .select('tables.*');
        if (allTables.length === 0) {
            return { available: false, reason: 'capacity' };
        }
        for (const table of allTables) {
            try {
                const available = await TableService.isTableAvailable(
                    table.id,
                    date,
                    time,
                    120
                );
                if (available) {
                    return { available: true, table: table };
                }
            } catch (error) {
                continue;
            }
        }
        return { available: false, reason: 'time' };
    } catch (error) {
        return { available: false, reason: 'error' };
    }
}
async function findAvailableTimeSlots(branchId, date, guestCount, branch, maxSlots = 6) {
    try {
        if (!branch || !branch.opening_hours || !branch.close_hours) {
            return [];
        }
        const availableSlots = [];
        const startHour = branch.opening_hours;
        const endHour = branch.close_hours;
        const timeSlots = [];
        for (let hour = startHour; hour < endHour; hour++) {
            timeSlots.push(`${hour.toString().padStart(2, '0')}:00`);
            if (hour < endHour - 1) {
                timeSlots.push(`${hour.toString().padStart(2, '0')}:30`);
            }
        }
        for (const timeSlot of timeSlots) {
            try {
                const checkResult = await checkTableAvailability(branchId, date, timeSlot, guestCount);
                if (checkResult.available) {
                    availableSlots.push(timeSlot);
                    if (availableSlots.length >= maxSlots) {
                        break;
                    }
                }
            } catch (error) {
                continue;
            }
        }
        return availableSlots;
    } catch (error) {
        return [];
    }
}
async function createQuickReservation(payload) {
    if (!payload.user_id || !payload.branch_id || 
        !payload.reservation_date || !payload.reservation_time || !payload.guest_count) {
        throw new Error('Missing required fields');
    }
    const user = await knex('users').where('id', payload.user_id).first();
    if (!user) {
        throw new Error('User not found');
    }
    const branch = await knex('branches').where('id', payload.branch_id).first();
    if (!branch) {
        throw new Error('Branch not found');
    }
    const availabilityCheck = await checkTableAvailability(
        payload.branch_id,
        payload.reservation_date,
        payload.reservation_time,
        payload.guest_count
    );
    if (!availabilityCheck.available) {
        let availableSlots = [];
        try {
            availableSlots = await findAvailableTimeSlots(
                payload.branch_id,
                payload.reservation_date,
                payload.guest_count,
                branch,
                6
            );
        } catch (error) {
            }
        let errorMessage = '';
        if (availabilityCheck.reason === 'capacity') {
            errorMessage = `Rất tiếc! Chi nhánh ${branch.name} không có bàn đủ lớn cho ${payload.guest_count} người.\n\n`;
            errorMessage += `Gợi ý:\n`;
            errorMessage += `• Đặt nhiều bàn nhỏ hơn\n`;
            errorMessage += `• Chọn chi nhánh khác có bàn lớn hơn\n`;
            errorMessage += `• Liên hệ trực tiếp với nhà hàng: ${branch.phone || 'hotline'}`;
        } else if (availabilityCheck.reason === 'time') {
            errorMessage = `Rất tiếc! Không còn bàn trống tại ${branch.name} vào lúc ${payload.reservation_time} ngày ${payload.reservation_date} cho ${payload.guest_count} người.\n\n`;
            errorMessage += `Có thể bàn đã được đặt bởi khách hàng khác.\n\n`;
            if (availableSlots.length > 0) {
                errorMessage += `Các giờ khác còn bàn trống trong ngày:\n\n`;
                availableSlots.forEach((slot, idx) => {
                    errorMessage += `${idx + 1}. ${slot}\n`;
                });
                errorMessage += `\nBạn có muốn chọn một trong các giờ này không?`;
            } else {
                errorMessage += `Không còn giờ nào trống trong ngày này.\n\n`;
                errorMessage += `Gợi ý:\n`;
                errorMessage += `• Chọn ngày khác\n`;
                errorMessage += `• Chọn chi nhánh khác\n`;
                errorMessage += `• Liên hệ trực tiếp: ${branch.phone || 'hotline'}`;
            }
        } else {
            errorMessage = `Rất tiếc! Không thể đặt bàn tại ${branch.name} vào lúc ${payload.reservation_time} ngày ${payload.reservation_date}.\n\n`;
            errorMessage += `Có thể bàn đã được đặt bởi khách hàng khác hoặc đã hết bàn.\n\n`;
            errorMessage += `Vui lòng thử thời gian khác hoặc liên hệ trực tiếp với nhà hàng: ${branch.phone || 'hotline'}`;
        }
        throw new Error(errorMessage);
    }
    let selectedTable = availabilityCheck.table;
    return await knex.transaction(async (trx) => {
        // Lock table row to prevent race condition
        // SELECT FOR UPDATE ensures only one transaction can proceed at a time
        const tableLock = await trx('tables')
            .where('id', selectedTable.id)
            .forUpdate()
            .first();
        
        if (!tableLock) {
            throw new Error('Table not found');
        }
        
        // Recheck availability within transaction (with lock)
        const recheckAvailable = await TableService.isTableAvailable(
            selectedTable.id,
            payload.reservation_date,
            payload.reservation_time,
            120,
            trx // Pass transaction to check within locked transaction
        );
        if (!recheckAvailable) {
            // Release lock before searching for alternative tables
            const allTables = await trx('tables')
                .leftJoin('floors', 'tables.floor_id', 'floors.id')
                .where('floors.branch_id', payload.branch_id)
                .where('tables.capacity', '>=', payload.guest_count)
                .where('tables.id', '!=', selectedTable.id) 
                .orderBy('tables.capacity', 'asc')
                .select('tables.*');
            let alternativeTable = null;
            for (const table of allTables) {
                // Lock each table row when checking
                const tableLock = await trx('tables')
                    .where('id', table.id)
                    .forUpdate()
                    .first();
                
                if (!tableLock) continue;
                
                const isAvailable = await TableService.isTableAvailable(
                    table.id,
                    payload.reservation_date,
                    payload.reservation_time,
                    120,
                    trx // Pass transaction to check within locked transaction
                );
                if (isAvailable) {
                    alternativeTable = table;
                    break;
                }
            }
            if (!alternativeTable) {
                let availableSlots = [];
                try {
                    availableSlots = await findAvailableTimeSlots(
                        payload.branch_id,
                        payload.reservation_date,
                        payload.guest_count,
                        branch,
                        6
                    );
                } catch (error) {
                    }
                let errorMessage = `Rất tiếc! Bàn vừa được đặt bởi khách hàng khác. Không còn bàn trống tại ${branch.name} vào lúc ${payload.reservation_time} ngày ${payload.reservation_date} cho ${payload.guest_count} người.\n\n`;
                if (availableSlots.length > 0) {
                    errorMessage += `Các giờ khác còn bàn trống trong ngày:\n\n`;
                    availableSlots.forEach((slot, idx) => {
                        errorMessage += `${idx + 1}. ${slot}\n`;
                    });
                    errorMessage += `\nBạn có muốn chọn một trong các giờ này không?`;
                } else {
                    errorMessage += `Không còn giờ nào trống trong ngày này.\n\n`;
                    errorMessage += `Gợi ý:\n`;
                    errorMessage += `• Chọn ngày khác\n`;
                    errorMessage += `• Chọn chi nhánh khác\n`;
                    errorMessage += `• Liên hệ trực tiếp: ${branch.phone || 'hotline'}`;
                }
                throw new Error(errorMessage);
            }
            selectedTable = alternativeTable;
            }
        const reservation = readReservation({
            ...payload,
            table_id: selectedTable.id
        });
        const [id] = await trx('reservations').insert(reservation);
        // Create table_schedule immediately to block the table slot
        // This prevents other users from booking the same table
        // Note: Reservation stays valid even without order - customers can book tables without ordering food
        await TableService.createTableSchedule({
            table_id: selectedTable.id,
            reservation_id: id,
            schedule_date: payload.reservation_date,
            start_time: payload.reservation_time,
            duration_minutes: 120,
            status: 'reserved'
        }, trx);
        return {
            id,
            ...reservation,
            table_id: selectedTable.id,
            table_capacity: selectedTable.capacity,
            floor_id: selectedTable.floor_id,
            order_id: null
        };
    });
}
async function getOverdueReservations(minutesOverdue = 30) {
    const now = new Date();
    const currentDate = now.toISOString().split('T')[0];
    const thresholdTime = new Date(now.getTime() - minutesOverdue * 60000);
    const thresholdTimeStr = thresholdTime.toTimeString().split(' ')[0];
    const overdueReservations = await knex('reservations')
        .select(
            'reservations.*',
            'users.name as user_name',
            'users.email as user_email',
            'users.phone as user_phone',
            'branches.name as branch_name',
            'floors.name as floor_name',
            knex.raw('TIMESTAMPDIFF(MINUTE, CONCAT(reservation_date, " ", reservation_time), NOW()) as minutes_overdue')
        )
        .leftJoin('users', 'reservations.user_id', 'users.id')
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .leftJoin('floors', 'tables.floor_id', 'floors.id')
        .where(function() {
            this.where('reservation_date', '<', currentDate)
                .orWhere(function() {
                    this.where('reservation_date', '=', currentDate)
                        .whereRaw('TIME(reservation_time) <= TIME(?)', [thresholdTimeStr]);
                });
        })
        .whereIn('reservations.status', ['pending', 'confirmed'])
        .whereNull('reservations.check_in_time')
        .orderBy('reservation_date', 'asc')
        .orderBy('reservation_time', 'asc');
    return overdueReservations;
}
async function getReservationsNeedingWarning() {
    return await getOverdueReservations(30);
}
async function getReservationsToCancel() {
    return await getOverdueReservations(60);
}
/**
 * @deprecated This function is deprecated. Reservations are no longer auto-cancelled 
 * just because they don't have orders. Customers can book tables without ordering food.
 * Reservations are only cancelled for no-show (overdue) or manual cancellation.
 */
async function getReservationsWithoutOrder(timeoutMinutes = 30) {
    // Deprecated - no longer used
    return [];
}
/**
 * @deprecated This function is deprecated. Reservations are no longer auto-cancelled 
 * just because they don't have orders. Customers can book tables without ordering food.
 * Reservations are only cancelled for no-show (overdue) or manual cancellation.
 */
async function cancelReservationsWithoutOrder(timeoutMinutes = 30) {
    // Deprecated - no longer used
    return 0;
}
async function cancelOverdueReservations() {
    const reservationsToCancel = await getReservationsToCancel();
    let cancelledCount = 0;
    for (const reservation of reservationsToCancel) {
        try {
            await updateReservation(reservation.id, {
                status: 'cancelled',
                cancelled_at: new Date(),
                notes: reservation.notes 
                    ? `${reservation.notes}\n[Auto-cancelled] Reservation was automatically cancelled due to no-show (60+ minutes overdue).`
                    : '[Auto-cancelled] Reservation was automatically cancelled due to no-show (60+ minutes overdue).'
            });
            cancelledCount++;
        } catch (error) {
            }
    }
    return cancelledCount;
}
async function createOverdueNotifications(overdueReservations) {
    let notificationCount = 0;
    for (const reservation of overdueReservations) {
        const minutesOverdue = reservation.minutes_overdue || 0;
        const isCancelled = minutesOverdue >= 60;
        
        // ✅ EMIT REAL-TIME NOTIFICATIONS VIA SOCKET.IO
        if (io) {
            // Notify customer if user_id exists
            if (reservation.user_id) {
                io.to(`user:${reservation.user_id}`).emit('reservation-overdue', {
                    reservationId: reservation.id,
                    branchId: reservation.branch_id,
                    branchName: reservation.branch_name,
                    tableId: reservation.table_id,
                    floorName: reservation.floor_name,
                    reservationTime: reservation.reservation_time,
                    minutesOverdue: Math.floor(minutesOverdue),
                    isCancelled: isCancelled,
                    title: isCancelled 
                        ? 'Đặt bàn đã bị hủy do không đến'
                        : 'Cảnh báo: Đặt bàn của bạn đã quá giờ',
                    message: isCancelled
                        ? `Đặt bàn của bạn tại ${reservation.branch_name}, bàn #${reservation.table_id || 'N/A'} (${reservation.floor_name}) lúc ${reservation.reservation_time} đã bị hủy tự động do bạn không đến sau 60 phút.`
                        : `Đặt bàn của bạn tại ${reservation.branch_name}, bàn #${reservation.table_id || 'N/A'} (${reservation.floor_name}) lúc ${reservation.reservation_time} đã quá ${Math.floor(minutesOverdue)} phút. Vui lòng đến sớm hoặc liên hệ nhà hàng.`,
                    type: isCancelled ? 'urgent' : 'general',
                    timestamp: new Date().toISOString()
                });
                notificationCount++;
            }
            
            // Notify branch staff (manager and cashier)
            if (reservation.branch_id) {
                io.to(`branch:${reservation.branch_id}`).emit('reservation-overdue', {
                    reservationId: reservation.id,
                    branchId: reservation.branch_id,
                    branchName: reservation.branch_name,
                    tableId: reservation.table_id,
                    floorName: reservation.floor_name,
                    reservationTime: reservation.reservation_time,
                    minutesOverdue: Math.floor(minutesOverdue),
                    isCancelled: isCancelled,
                    title: isCancelled
                        ? 'Đặt bàn đã bị hủy tự động'
                        : 'Cảnh báo: Khách hàng chưa đến đặt bàn',
                    message: isCancelled
                        ? `Đặt bàn #${reservation.id} tại bàn #${reservation.table_id || 'N/A'} (${reservation.floor_name}) lúc ${reservation.reservation_time} đã bị hủy tự động do khách hàng không đến sau 60 phút.`
                        : `Đặt bàn #${reservation.id} tại ${reservation.branch_name}, bàn #${reservation.table_id || 'N/A'} (${reservation.floor_name}) lúc ${reservation.reservation_time} đã quá ${Math.floor(minutesOverdue)} phút mà khách hàng chưa đến.`,
                    type: 'urgent',
                    timestamp: new Date().toISOString()
                });
                notificationCount++;
            }
        }
    }
    return notificationCount;
}
async function checkAndProcessOverdueReservations() {
    const warningReservations = await getReservationsNeedingWarning();
    const cancelReservations = await getReservationsToCancel();
    const allOverdue = await getOverdueReservations(30);
    const notificationCount = await createOverdueNotifications(allOverdue);
    const cancelledCount = await cancelOverdueReservations();
    return {
        warningCount: warningReservations.length,
        cancelCount: cancelReservations.length,
        notificationCount,
        cancelledCount
    };
}
async function getUserReservations(userId) {
    const reservations = await reservationRepository()
        .select(
            'reservations.*',
            'branches.name as branch_name',
        )
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .where('reservations.user_id', userId)
        .orderBy('reservations.created_at', 'desc');
    return reservations;
}
async function getReservationsByBranch(branchId) {
    const reservations = await reservationRepository()
        .select(
            'reservations.*',
            'branches.name as branch_name',
        )
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .where('reservations.branch_id', branchId)
        .orderBy('reservations.created_at', 'desc');
    return reservations;
}
async function cancelReservationSimple(reservationId) {
    const result = await reservationRepository()
        .where('id', reservationId)
        .update({
            status: 'cancelled'
        });
    return result > 0;
}
module.exports = {
    createReservation,
    createQuickReservation,
    checkTableAvailability,
    findAvailableTimeSlots,
    getReservationsByDateRange,
    getTableSchedule,
    getAllReservations,
    getReservationById,
    updateReservation,
    deleteReservation,
    getOverdueReservations,
    getReservationsNeedingWarning,
    getReservationsToCancel,
    cancelOverdueReservations,
    createOverdueNotifications,
    checkAndProcessOverdueReservations,
    getUserReservations,
    getReservationsByBranch,
    cancelReservationSimple,
    // Deprecated functions removed:
    // - getReservationsWithoutOrder (deprecated, not used)
    // - cancelReservationsWithoutOrder (deprecated, not used)
    setSocketIO
};
