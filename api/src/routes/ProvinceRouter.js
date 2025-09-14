const express = require('express');
const ProvinceController = require('../controllers/ProvinceController');

const router = express.Router();

router.get('/', ProvinceController.getAllProvinces);
router.get('/search', ProvinceController.searchProvinces);
router.get('/:id', ProvinceController.getProvinceById);
router.get('/:provinceId/districts', ProvinceController.getDistrictsByProvinceId);
router.get('/districts/search', ProvinceController.searchDistricts);
router.get('/districts/:id', ProvinceController.getDistrictById);

module.exports = router;
