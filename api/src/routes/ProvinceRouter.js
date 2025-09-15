const express = require('express');
const ProvinceController = require('../controllers/ProvinceController');
const { methodNotAllowed } = require('../controllers/ErrorController');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/provinces', router);

    // Public 
    router.get('/', ProvinceController.getAllProvinces);
    router.get('/search', ProvinceController.searchProvinces);
    router.get('/districts/search', ProvinceController.searchDistricts);
    router.get('/:id', ProvinceController.getProvinceById);
    router.get('/:provinceId/districts', ProvinceController.getDistrictsByProvinceId);
    router.get('/districts/:id', ProvinceController.getDistrictById);
    
    router.all('/', methodNotAllowed);
    router.all('/search', methodNotAllowed);
    router.all('/districts/search', methodNotAllowed);
    router.all('/:id', methodNotAllowed);
    router.all('/:provinceId/districts', methodNotAllowed);
    router.all('/districts/:id', methodNotAllowed);
}
