const express = require('express');
const MapController = require('../controllers/MapController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const router = express.Router();
module.exports.setup = (app) => {
    app.use('/api/config', router);
    router.get('/mapbox-key', MapController.getMapboxApiKey);
    router.all('/mapbox-key', methodNotAllowed);
    router.get('/googlemaps-key', MapController.getGoogleMapsApiKey);
    router.all('/googlemaps-key', methodNotAllowed);
    router.get('/vietmap-key', MapController.getVietmapApiKey);
    router.all('/vietmap-key', methodNotAllowed);
    app.get('/api/map/vietmap/autocomplete', MapController.vietmapAutocomplete);
    app.get('/api/map/vietmap/search', MapController.vietmapSearch);
    app.get('/api/map/vietmap/place', MapController.vietmapPlaceDetails);
    app.get('/api/map/mapbox/search', MapController.mapboxGeocode);
    app.get('/api/map/mapbox/place', MapController.mapboxPlaceDetails);
};
