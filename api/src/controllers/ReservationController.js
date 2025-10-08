const ReservationService = require('../services/ReservationService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

async function createReservation(req, res, next) {
    try {
        const { user_id, branch_id, table_id, reservation_date, reservation_time, guest_count, special_requests } = req.body;

        if (!user_id || !branch_id || !table_id || !reservation_date || !reservation_time || !guest_count) {
            throw new ApiError(400, 'Missing required fields: user_id, branch_id, table_id, reservation_date, reservation_time, guest_count');
        }

        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (!dateRegex.test(reservation_date)) {
            throw new ApiError(400, 'Invalid reservation_date format. Use YYYY-MM-DD');
        }

        const timeRegex = /^\d{2}:\d{2}$/;
        if (!timeRegex.test(reservation_time)) {
            throw new ApiError(400, 'Invalid reservation_time format. Use HH:MM');
        }

        if (guest_count < 1) {
            throw new ApiError(400, 'Guest count must be at least 1');
        }

        const reservationData = {
            user_id: parseInt(user_id),
            branch_id: parseInt(branch_id),
            table_id: parseInt(table_id),
            reservation_date: reservation_date,
            reservation_time: reservation_time + ':00', // Add seconds
            guest_count: parseInt(guest_count),
            special_requests: special_requests || null,
            status: 'pending'
        };

        const reservation = await ReservationService.createReservation(reservationData);
        res.status(201).json(success(reservation, 'Reservation created successfully'));
    } catch (error) {
        if (error.message === 'User not found' || 
            error.message === 'Branch not found' || 
            error.message === 'Table not found' ||
            error.message === 'Table does not belong to the specified branch') {
            return next(new ApiError(400, error.message));
        }
        next(error);
    }
}

async function getReservations(req, res, next) {
    try {
        const { start_date, end_date, status, branch_id, user_id } = req.query;
        
        const filters = {};
        if (start_date) filters.start_date = start_date;
        if (end_date) filters.end_date = end_date;
        if (status) filters.status = status;
        if (branch_id) filters.branch_id = parseInt(branch_id);
        if (user_id) filters.user_id = parseInt(user_id);

        const reservations = await ReservationService.getAllReservations(filters);
        res.json(success({ reservations }, 'Reservations retrieved successfully'));
    } catch (error) {
        next(error);
    }
}

async function getReservationsByDateRange(req, res, next) {
    try {
        const { start_date, end_date } = req.query;

        if (!start_date || !end_date) {
            throw new ApiError(400, 'start_date and end_date are required');
        }

        const reservations = await ReservationService.getReservationsByDateRange(start_date, end_date);
        res.json(success({ reservations }, 'Reservations retrieved successfully'));
    } catch (error) {
        next(error);
    }
}

async function getTableSchedule(req, res, next) {
    try {
        const { tableId } = req.params;
        const { start_date, end_date } = req.query;

        if (!tableId) {
            throw new ApiError(400, 'Table ID is required');
        }

        if (!start_date || !end_date) {
            throw new ApiError(400, 'start_date and end_date are required');
        }

        const reservations = await ReservationService.getTableSchedule(parseInt(tableId), start_date, end_date);
        res.json(success({ reservations }, 'Table schedule retrieved successfully'));
    } catch (error) {
        next(error);
    }
}

async function getReservationById(req, res, next) {
    try {
        const { id } = req.params;
        const reservation = await ReservationService.getReservationById(parseInt(id));
        res.json(success({ reservation }, 'Reservation retrieved successfully'));
    } catch (error) {
        if (error.message === 'Reservation not found') {
            return next(new ApiError(404, error.message));
        }
        next(error);
    }
}

async function updateReservation(req, res, next) {
    try {
        const { id } = req.params;
        const updateData = req.body;

        const reservation = await ReservationService.updateReservation(parseInt(id), updateData);
        res.json(success({ reservation }, 'Reservation updated successfully'));
    } catch (error) {
        if (error.message === 'Reservation not found') {
            return next(new ApiError(404, error.message));
        }
        next(error);
    }
}

async function deleteReservation(req, res, next) {
    try {
        const { id } = req.params;
        const result = await ReservationService.deleteReservation(parseInt(id));
        res.json(success(result, 'Reservation deleted successfully'));
    } catch (error) {
        if (error.message === 'Reservation not found') {
            return next(new ApiError(404, error.message));
        }
        next(error);
    }
}

module.exports = {
    createReservation,
    getReservations,
    getReservationsByDateRange,
    getTableSchedule,
    getReservationById,
    updateReservation,
    deleteReservation
};
