const express = require('express');
const ReservationController = require('../controllers/ReservationController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken } = require('../middlewares/AuthMiddleware');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/reservations', router);

    router.get('/', ReservationController.getReservations);
    router.get('/date-range', ReservationController.getReservationsByDateRange);
    router.get('/table/:tableId/schedule', ReservationController.getTableSchedule);
    router.get('/:id', ReservationController.getReservationById);
    
    router.post('/', verifyToken, ReservationController.createReservation);
    router.post('/quick', verifyToken, ReservationController.createQuickReservation);
    router.put('/:id', verifyToken, ReservationController.updateReservation);
    router.delete('/:id', verifyToken, ReservationController.deleteReservation);

    router.all('/', methodNotAllowed);
    router.all('/quick', methodNotAllowed);
    router.all('/date-range', methodNotAllowed);
    router.all('/table/:tableId/schedule', methodNotAllowed);
    router.all('/:id', methodNotAllowed);
};
