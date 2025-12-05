const knex = require('../database/knex');
const Paginator = require('./Paginator');

function tableRepository() {
    return knex('tables');
}

function readTable(payload) {
    return {
        branch_id: payload.branch_id,
        floor_id: payload.floor_id,
        capacity: payload.capacity,
        location: payload.location || null,
        position_x: payload.position_x || null,
        position_y: payload.position_y || null
    };
}

async function createTable(payload) {
    if (!payload.branch_id || !payload.floor_id || !payload.capacity) {
        throw new Error('Branch ID, floor ID and capacity are required');
    }

    const branch = await knex('branches').where('id', payload.branch_id).first();
    if (!branch) {
        throw new Error('Branch not found');
    }

    const floor = await knex('floors').where('id', payload.floor_id).first();
    if (!floor) {
        throw new Error('Floor not found');
    }

    if (parseInt(floor.branch_id) !== parseInt(payload.branch_id)) {
        throw new Error('Floor does not belong to the specified branch');
    }

    const table = readTable(payload);
    const [id] = await tableRepository().insert(table);
    return { id, ...table };
}

async function getAllTables(filters = {}) {
    let query = tableRepository()
        .select(
            'tables.*',
            'branches.name as branch_name',
            'floors.name as floor_name',
            'floors.floor_number'
        )
        .join('branches', 'tables.branch_id', 'branches.id')
        .join('floors', 'tables.floor_id', 'floors.id');
    
    if (filters.branch_id) {
        query = query.where('tables.branch_id', parseInt(filters.branch_id));
    }
    
    if (filters.floor_id) {
        query = query.where('tables.floor_id', parseInt(filters.floor_id));
    }
    
    return query
        .orderBy('branches.name', 'asc')
        .orderBy('floors.floor_number', 'asc')
        .orderBy('tables.id', 'asc');
}

async function updateTable(id, payload) {
    const updatedTable = await tableRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!updatedTable) {
        return null;
    }


    if (payload.branch_id || payload.floor_id) {
        const branchId = payload.branch_id || updatedTable.branch_id;
        const floorId = payload.floor_id || updatedTable.floor_id;

        const branch = await knex('branches').where('id', branchId).first();
        if (!branch) {
            throw new Error('Branch not found');
        }

        const floor = await knex('floors').where('id', floorId).first();
        if (!floor) {
            throw new Error('Floor not found');
        }

        if (floor.branch_id !== branchId) {
            throw new Error('Floor does not belong to the specified branch');
        }
    }

    const update = readTable(payload);
    await tableRepository().where('id', id).update(update);
    return { ...updatedTable, ...update };
}

async function updateTableStatus(id, status) {
    throw new Error('updateTableStatus is deprecated. Use table schedule functions to manage table schedules.');
}

async function deleteTable(id) {
    const deletedTable = await tableRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!deletedTable) {
        return null;
    }

    const now = new Date();
    const currentDate = now.toISOString().split('T')[0];
    const currentTime = now.toTimeString().split(' ')[0];
    
    const currentStatus = await getTableCurrentStatus(id, currentDate, currentTime);
    if (currentStatus === 'occupied' || currentStatus === 'reserved') {
        throw new Error('Cannot delete table that is currently occupied or reserved');
    }

    await tableRepository().where('id', id).del();
    return { ...deletedTable, message: 'Table deleted successfully' };
}

function tableScheduleRepository() {
    return knex('table_schedules');
}

/**
 * Check if a table is available at a specific date and time
 * @param {number} tableId - Table ID
 * @param {string} date - Date in YYYY-MM-DD format
 * @param {string} time - Time in HH:MM:SS format
 * @param {number} durationMinutes - Duration in minutes (default: 120)
 * @returns {Promise<boolean>} - True if available, false if conflict
 */
async function isTableAvailable(tableId, date, time, durationMinutes = 120) {
    const startDateTime = new Date(`${date} ${time}`);
    const endDateTime = new Date(startDateTime.getTime() + durationMinutes * 60000);
    const endTime = endDateTime.toTimeString().split(' ')[0].substring(0, 5) + ':00';
    
    const scheduleConflicts = await tableScheduleRepository()
        .where('table_id', tableId)
        .where('schedule_date', date)
        .where(function() {
            this.where(function() {
                this.whereRaw('TIME(start_time) <= TIME(?)', [time])
                    .where(function() {
                        this.whereNull('end_time')
                            .orWhereRaw('TIME(end_time) > TIME(?)', [time]);
                    });
            })
            .orWhere(function() {
                this.whereRaw('TIME(start_time) < TIME(?)', [endTime])
                    .where(function() {
                        this.whereNull('end_time')
                            .orWhereRaw('TIME(end_time) >= TIME(?)', [endTime]);
                    });
            })
            .orWhere(function() {
                this.whereRaw('TIME(start_time) >= TIME(?)', [time])
                    .whereRaw('TIME(start_time) < TIME(?)', [endTime]);
            });
        })
        .where('status', '!=', 'cancelled')
        .first();
    
    if (scheduleConflicts) {
        return false;
    }
    
    const reservationConflicts = await knex('reservations')
        .where('table_id', tableId)
        .where('reservation_date', date)
        .where('status', '!=', 'cancelled')
        .where(function() {
            this.whereRaw('TIME(reservation_time) <= TIME(?)', [time])
                .whereRaw('ADDTIME(TIME(reservation_time), "02:00:00") > TIME(?)', [time])
            .orWhere(function() {
                this.whereRaw('TIME(reservation_time) < TIME(?)', [endTime])
                    .whereRaw('ADDTIME(TIME(reservation_time), "02:00:00") >= TIME(?)', [endTime]);
            })
            .orWhere(function() {
                this.whereRaw('TIME(reservation_time) >= TIME(?)', [time])
                    .whereRaw('TIME(reservation_time) < TIME(?)', [endTime]);
            });
        })
        .first();
    
    return !reservationConflicts;
}

/**
 * Create a table schedule entry
 * @param {Object} payload - Schedule data
 * @returns {Promise<Object>} - Created schedule
 */
async function createTableSchedule(payload) {
    if (!payload.table_id || !payload.schedule_date || !payload.start_time) {
        throw new Error('Table ID, schedule date, and start time are required');
    }

    const table = await knex('tables').where('id', payload.table_id).first();
    if (!table) {
        throw new Error('Table not found');
    }

    const available = await isTableAvailable(
        payload.table_id,
        payload.schedule_date,
        payload.start_time,
        payload.duration_minutes || 120
    );

    if (!available) {
        throw new Error('Table is not available at the requested date and time');
    }

    let endTime = payload.end_time;
    if (!endTime && payload.duration_minutes) {
        const startDateTime = new Date(`${payload.schedule_date} ${payload.start_time}`);
        const endDateTime = new Date(startDateTime.getTime() + payload.duration_minutes * 60000);
        endTime = endDateTime.toTimeString().split(' ')[0].substring(0, 5) + ':00';
    }

    const schedule = {
        table_id: payload.table_id,
        reservation_id: payload.reservation_id || null,
        schedule_date: payload.schedule_date,
        start_time: payload.start_time,
        end_time: endTime || null,
        status: payload.status || 'reserved',
        notes: payload.notes || null,
        created_at: new Date(),
        updated_at: new Date()
    };

    const [id] = await tableScheduleRepository().insert(schedule);
    return { id, ...schedule };
}

/**
 * Get table schedules for a specific table and date range
 * @param {number} tableId - Table ID
 * @param {string} startDate - Start date in YYYY-MM-DD format
 * @param {string} endDate - End date in YYYY-MM-DD format
 * @returns {Promise<Array>} - Array of schedules
 */
async function getTableSchedules(tableId, startDate, endDate) {
    return await tableScheduleRepository()
        .where('table_id', tableId)
        .whereBetween('schedule_date', [startDate, endDate])
        .where('status', '!=', 'cancelled')
        .orderBy('schedule_date', 'asc')
        .orderBy('start_time', 'asc');
}

/**
 * Get table schedule by reservation ID
 * @param {number} reservationId - Reservation ID
 * @returns {Promise<Object|null>} - Schedule or null
 */
async function getTableScheduleByReservation(reservationId) {
    return await tableScheduleRepository()
        .where('reservation_id', reservationId)
        .where('status', '!=', 'cancelled')
        .first();
}

/**
 * Update table schedule status
 * @param {number} scheduleId - Schedule ID
 * @param {string} status - New status
 * @returns {Promise<Object>} - Updated schedule
 */
async function updateTableScheduleStatus(scheduleId, status) {
    const validStatuses = ['reserved', 'occupied', 'maintenance', 'cancelled'];
    if (!validStatuses.includes(status)) {
        throw new Error('Invalid status value');
    }

    const schedule = await tableScheduleRepository()
        .where('id', scheduleId)
        .first();

    if (!schedule) {
        throw new Error('Table schedule not found');
    }

    await tableScheduleRepository()
        .where('id', scheduleId)
        .update({
            status,
            updated_at: new Date()
        });

    return { ...schedule, status };
}

/**
 * Cancel table schedule (usually when reservation is cancelled)
 * @param {number} reservationId - Reservation ID
 * @returns {Promise<Object>} - Updated schedule
 */
async function cancelTableScheduleByReservation(reservationId) {
    const schedule = await getTableScheduleByReservation(reservationId);
    
    if (!schedule) {
        return null;
    }

    return await updateTableScheduleStatus(schedule.id, 'cancelled');
}

/**
 * Check-in: Update schedule status to occupied
 * @param {number} reservationId - Reservation ID
 * @returns {Promise<Object>} - Updated schedule
 */
async function checkInTableSchedule(reservationId) {
    const schedule = await getTableScheduleByReservation(reservationId);
    
    if (!schedule) {
        throw new Error('Table schedule not found for this reservation');
    }

    return await updateTableScheduleStatus(schedule.id, 'occupied');
}

/**
 * Check-out: Remove or mark schedule as completed
 * @param {number} reservationId - Reservation ID
 * @returns {Promise<Object>} - Updated schedule
 */
async function checkOutTableSchedule(reservationId) {
    const schedule = await getTableScheduleByReservation(reservationId);
    
    if (!schedule) {
        return null;
    }

    return await updateTableScheduleStatus(schedule.id, 'cancelled');
}

/**
 * Get current status of a table based on schedules
 * @param {number} tableId - Table ID
 * @param {string} date - Date in YYYY-MM-DD format (default: today)
 * @param {string} time - Time in HH:MM:SS format (default: now)
 * @returns {Promise<string>} - Current status: 'available', 'reserved', 'occupied', or 'maintenance'
 */
async function getTableCurrentStatus(tableId, date = null, time = null) {
    if (!date) {
        const now = new Date();
        date = now.toISOString().split('T')[0];
    }
    if (!time) {
        const now = new Date();
        time = now.toTimeString().split(' ')[0];
    }

    const activeSchedule = await tableScheduleRepository()
        .where('table_id', tableId)
        .where('schedule_date', date)
        .where(function() {
            this.whereRaw('TIME(start_time) <= TIME(?)', [time])
                .where(function() {
                    this.whereNull('end_time')
                        .orWhereRaw('TIME(end_time) > TIME(?)', [time]);
                });
        })
        .where('status', '!=', 'cancelled')
        .orderBy('start_time', 'desc')
        .first();

    if (!activeSchedule) {
        return 'available';
    }

    return activeSchedule.status === 'occupied' ? 'occupied' : 
           activeSchedule.status === 'maintenance' ? 'maintenance' : 
           'reserved';
}

module.exports = {
    createTable,
    getAllTables,
    updateTable,
    updateTableStatus,
    deleteTable,
    isTableAvailable,
    createTableSchedule,
    getTableSchedules,
    getTableScheduleByReservation,
    updateTableScheduleStatus,
    cancelTableScheduleByReservation,
    checkInTableSchedule,
    checkOutTableSchedule,
    getTableCurrentStatus
};