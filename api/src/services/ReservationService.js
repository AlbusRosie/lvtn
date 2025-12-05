const knex = require('../database/knex');
const TableService = require('./TableService');
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
    const table = await knex('tables').where('id', payload.table_id).first();
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
        const recheckAvailable = await TableService.isTableAvailable(
            payload.table_id,
            payload.reservation_date,
            payload.reservation_time,
            120
        );
        if (!recheckAvailable) {
            throw new Error('Table is not available at the requested date and time. It may have been reserved by another customer.');
        }
        const reservation = readReservation(payload);
        const [id] = await trx('reservations').insert(reservation);
        await TableService.createTableSchedule({
            table_id: payload.table_id,
            reservation_id: id,
            schedule_date: payload.reservation_date,
            start_time: payload.reservation_time,
            duration_minutes: 120,
            status: 'reserved'
        });
        try {
            const OrderService = require('./OrderService');
            await OrderService.createEmptyOrderForReservation({
                user_id: payload.user_id,
                branch_id: payload.branch_id,
                table_id: payload.table_id,
                reservation_id: id
            });
        } catch (orderError) {
            }
        return { 
            id, 
            ...reservation
        };
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
            'orders.table_id',
            'orders.created_at',
            'orders.status as order_status',
            'orders.order_type',
            'users.name as user_name',
            'users.email as user_email',
            'tables.capacity'
        )
        .leftJoin('users', 'orders.user_id', 'users.id')
        .leftJoin('tables', 'orders.table_id', 'tables.id')
        .where('orders.table_id', tableId)
        .where('orders.order_type', 'dine_in')
        .whereIn('orders.status', ['pending', 'preparing', 'ready'])
        .whereBetween(knex.raw('DATE(orders.created_at)'), [startDate, endDate])
        .whereNotExists(function() {
            this.select('*')
                .from('table_schedules')
                .whereRaw('table_schedules.table_id = orders.table_id')
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
            knex.raw('(SELECT id FROM orders WHERE orders.table_id = reservations.table_id AND orders.user_id = reservations.user_id AND orders.status != "cancelled" AND orders.created_at >= reservations.created_at ORDER BY orders.created_at ASC LIMIT 1) as order_id')
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
    return await getReservationById(id);
}
async function deleteReservation(id) {
    const reservation = await reservationRepository().where('id', id).first();
    if (!reservation) {
        throw new Error('Reservation not found');
    }
    await TableService.cancelTableScheduleByReservation(id);
    await reservationRepository().where('id', id).del();
    return { message: 'Reservation deleted successfully' };
}
async function checkTableAvailability(branchId, date, time, guestCount) {
    try {
        if (!branchId || !date || !time || !guestCount) {
            return { available: false, reason: 'invalid_input' };
        }
        const allTables = await knex('tables')
            .where('branch_id', branchId)
            .where('capacity', '>=', guestCount)
            .orderBy('capacity', 'asc')
            .select('*');
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
            errorMessage = `❌ Rất tiếc! Chi nhánh ${branch.name} không có bàn đủ lớn cho ${payload.guest_count} người.\n\n`;
            errorMessage += `💡 Gợi ý:\n`;
            errorMessage += `• Đặt nhiều bàn nhỏ hơn\n`;
            errorMessage += `• Chọn chi nhánh khác có bàn lớn hơn\n`;
            errorMessage += `• Liên hệ trực tiếp với nhà hàng: ${branch.phone || 'hotline'}`;
        } else if (availabilityCheck.reason === 'time') {
            errorMessage = `❌ Rất tiếc! Không còn bàn trống tại ${branch.name} vào lúc ${payload.reservation_time} ngày ${payload.reservation_date} cho ${payload.guest_count} người.\n\n`;
            errorMessage += `⚠️ Có thể bàn đã được đặt bởi khách hàng khác.\n\n`;
            if (availableSlots.length > 0) {
                errorMessage += `💡 Các giờ khác còn bàn trống trong ngày:\n\n`;
                availableSlots.forEach((slot, idx) => {
                    errorMessage += `${idx + 1}. 🕐 ${slot}\n`;
                });
                errorMessage += `\nBạn có muốn chọn một trong các giờ này không?`;
            } else {
                errorMessage += `❌ Không còn giờ nào trống trong ngày này.\n\n`;
                errorMessage += `💡 Gợi ý:\n`;
                errorMessage += `• Chọn ngày khác\n`;
                errorMessage += `• Chọn chi nhánh khác\n`;
                errorMessage += `• Liên hệ trực tiếp: ${branch.phone || 'hotline'}`;
            }
        } else {
            errorMessage = `❌ Rất tiếc! Không thể đặt bàn tại ${branch.name} vào lúc ${payload.reservation_time} ngày ${payload.reservation_date}.\n\n`;
            errorMessage += `⚠️ Có thể bàn đã được đặt bởi khách hàng khác hoặc đã hết bàn.\n\n`;
            errorMessage += `Vui lòng thử thời gian khác hoặc liên hệ trực tiếp với nhà hàng: ${branch.phone || 'hotline'}`;
        }
        throw new Error(errorMessage);
    }
    let selectedTable = availabilityCheck.table;
    return await knex.transaction(async (trx) => {
        const recheckAvailable = await TableService.isTableAvailable(
            selectedTable.id,
            payload.reservation_date,
            payload.reservation_time,
            120
        );
        if (!recheckAvailable) {
            const allTables = await trx('tables')
                .where('branch_id', payload.branch_id)
                .where('capacity', '>=', payload.guest_count)
                .where('id', '!=', selectedTable.id) 
                .where(function() {
                    this.where('status', '!=', 'disabled')
                        .where('status', '!=', 'inactive')
                        .orWhereNull('status');
                })
                .orderBy('capacity', 'asc')
                .select('*');
            let alternativeTable = null;
            for (const table of allTables) {
                const isAvailable = await TableService.isTableAvailable(
                    table.id,
                    payload.reservation_date,
                    payload.reservation_time,
                    120
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
                let errorMessage = `❌ Rất tiếc! Bàn vừa được đặt bởi khách hàng khác. Không còn bàn trống tại ${branch.name} vào lúc ${payload.reservation_time} ngày ${payload.reservation_date} cho ${payload.guest_count} người.\n\n`;
                if (availableSlots.length > 0) {
                    errorMessage += `💡 Các giờ khác còn bàn trống trong ngày:\n\n`;
                    availableSlots.forEach((slot, idx) => {
                        errorMessage += `${idx + 1}. 🕐 ${slot}\n`;
                    });
                    errorMessage += `\nBạn có muốn chọn một trong các giờ này không?`;
                } else {
                    errorMessage += `❌ Không còn giờ nào trống trong ngày này.\n\n`;
                    errorMessage += `💡 Gợi ý:\n`;
                    errorMessage += `• Chọn ngày khác\n`;
                    errorMessage += `• Chọn chi nhánh khác\n`;
                    errorMessage += `• Liên hệ trực tiếp: ${branch.phone || 'hotline'}`;
                }
                throw new Error(errorMessage);
            }
            selectedTable = alternativeTable;
        }
        const OrderService = require('./OrderService');
        let emptyOrder = null;
        try {
            emptyOrder = await OrderService.createEmptyOrder({
                user_id: payload.user_id,
                branch_id: payload.branch_id,
                table_id: selectedTable.id
            });
        } catch (orderError) {
            }
        const reservation = readReservation({
            ...payload,
            table_id: selectedTable.id
        });
        const [id] = await trx('reservations').insert(reservation);
        await TableService.createTableSchedule({
            table_id: selectedTable.id,
            reservation_id: id,
            schedule_date: payload.reservation_date,
            start_time: payload.reservation_time,
            duration_minutes: 120,
            status: 'reserved'
        });
        if (emptyOrder) {
            try {
                await trx('orders')
                    .where('id', emptyOrder.id)
                    .update({ reservation_id: id });
            } catch (updateError) {
                }
        }
        return {
            id,
            ...reservation,
            table_id: selectedTable.id,
            table_capacity: selectedTable.capacity,
            floor_id: selectedTable.floor_id,
            order_id: emptyOrder?.id || null
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
        if (reservation.user_id) {
            try {
                await knex('notifications').insert({
                    user_id: reservation.user_id,
                    title: minutesOverdue >= 60 
                        ? 'Đặt bàn đã bị hủy do không đến'
                        : 'Cảnh báo: Đặt bàn của bạn đã quá giờ',
                    message: minutesOverdue >= 60
                        ? `Đặt bàn của bạn tại ${reservation.branch_name}, bàn #${reservation.table_id || 'N/A'} (${reservation.floor_name}) lúc ${reservation.reservation_time} đã bị hủy tự động do bạn không đến sau 60 phút.`
                        : `Đặt bàn của bạn tại ${reservation.branch_name}, bàn #${reservation.table_id || 'N/A'} (${reservation.floor_name}) lúc ${reservation.reservation_time} đã quá ${Math.floor(minutesOverdue)} phút. Vui lòng đến sớm hoặc liên hệ nhà hàng.`,
                    type: minutesOverdue >= 60 ? 'urgent' : 'general',
                    is_read: 0,
                    created_at: new Date()
                });
                notificationCount++;
            } catch (error) {
                }
        }
        if (reservation.branch_id) {
            try {
                const branchStaff = await knex('users')
                    .where('branch_id', reservation.branch_id)
                    .whereIn('role_id', [2, 6])
                    .select('id');
                for (const staff of branchStaff) {
                    await knex('notifications').insert({
                        user_id: staff.id,
                        title: minutesOverdue >= 60
                            ? 'Đặt bàn đã bị hủy tự động'
                            : 'Cảnh báo: Khách hàng chưa đến đặt bàn',
                        message: minutesOverdue >= 60
                            ? `Đặt bàn #${reservation.id} tại bàn #${reservation.table_id || 'N/A'} (${reservation.floor_name}) lúc ${reservation.reservation_time} đã bị hủy tự động do khách hàng không đến sau 60 phút.`
                            : `Đặt bàn #${reservation.id} tại ${reservation.branch_name}, bàn #${reservation.table_id || 'N/A'} (${reservation.floor_name}) lúc ${reservation.reservation_time} đã quá ${Math.floor(minutesOverdue)} phút mà khách hàng chưa đến.`,
                        type: minutesOverdue >= 60 ? 'urgent' : 'urgent',
                        is_read: 0,
                        created_at: new Date()
                    });
                    notificationCount++;
                }
            } catch (error) {
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
            status: 'cancelled',
            updated_at: new Date()
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
    cancelReservationSimple
};
