const knex = require('../database/knex');

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

    const reservation = readReservation(payload);
    const [id] = await reservationRepository().insert(reservation);
    return { id, ...reservation };
}

async function getReservationsByDateRange(startDate, endDate) {
    return await reservationRepository()
        .select(
            'reservations.*',
            'users.name as user_name',
            'users.email as user_email',
            'branches.name as branch_name',
            'tables.table_number',
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
    return await reservationRepository()
        .select(
            'reservations.*',
            'users.name as user_name',
            'users.email as user_email',
            'branches.name as branch_name',
            'tables.table_number',
            'tables.capacity'
        )
        .leftJoin('users', 'reservations.user_id', 'users.id')
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id')
        .where('reservations.table_id', tableId)
        .whereBetween('reservation_date', [startDate, endDate])
        .where('status', '!=', 'cancelled')
        .orderBy('reservation_date', 'asc')
        .orderBy('reservation_time', 'asc');
}

async function getAllReservations(filters = {}) {
    let query = reservationRepository()
        .select(
            'reservations.*',
            'users.name as user_name',
            'users.email as user_email',
            'branches.name as branch_name',
            'tables.table_number',
            'tables.capacity'
        )
        .leftJoin('users', 'reservations.user_id', 'users.id')
        .leftJoin('branches', 'reservations.branch_id', 'branches.id')
        .leftJoin('tables', 'reservations.table_id', 'tables.id');

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
            'tables.table_number',
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
    return await getReservationById(id);
}

async function deleteReservation(id) {
    const reservation = await reservationRepository().where('id', id).first();
    if (!reservation) {
        throw new Error('Reservation not found');
    }

    await reservationRepository().where('id', id).del();
    return { message: 'Reservation deleted successfully' };
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

    const availableTables = await knex('tables')
        .where('branch_id', payload.branch_id)
        .where('status', 'available')
        .where('capacity', '>=', payload.guest_count)
        .orderBy('capacity', 'asc')
        .select('*');

    if (availableTables.length === 0) {
        throw new Error('No available table found for the requested capacity at this branch');
    }

    let selectedTable = null;
    for (const table of availableTables) {
        const conflictingReservation = await reservationRepository()
            .where('table_id', table.id)
            .where('reservation_date', payload.reservation_date)
            .where('status', '!=', 'cancelled')
            .whereRaw(`
                ABS(TIMESTAMPDIFF(MINUTE, 
                    CONCAT(reservation_date, ' ', reservation_time), 
                    CONCAT(?, ' ', ?)
                )) < 120
            `, [payload.reservation_date, payload.reservation_time])
            .first();

        if (!conflictingReservation) {
            selectedTable = table;
            break;
        }
    }

    if (!selectedTable) {
        throw new Error('No available table found for the requested date and time. Please try a different time slot.');
    }

    const reservation = readReservation({
        ...payload,
        table_id: selectedTable.id
    });

    const [id] = await reservationRepository().insert(reservation);
    
    await knex('tables')
        .where('id', selectedTable.id)
        .update({
            status: 'reserved',
            reservation_id: id
        });

    return {
        id,
        ...reservation,
        table_number: selectedTable.table_number,
        table_capacity: selectedTable.capacity,
        floor_id: selectedTable.floor_id
    };
}

module.exports = {
    createReservation,
    createQuickReservation,
    getReservationsByDateRange,
    getTableSchedule,
    getAllReservations,
    getReservationById,
    updateReservation,
    deleteReservation
};
