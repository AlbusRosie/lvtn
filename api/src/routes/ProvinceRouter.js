const express = require('express');
const ProvinceController = require('../controllers/ProvinceController');

const router = express.Router();
const provinceController = new ProvinceController();

// Public routes (không cần authentication)
router.get('/', provinceController.getAllProvinces.bind(provinceController));
router.get('/search', provinceController.searchProvinces.bind(provinceController));
router.get('/:id', provinceController.getProvinceById.bind(provinceController));
router.get('/:provinceId/districts', provinceController.getDistrictsByProvinceId.bind(provinceController));
router.get('/districts/search', provinceController.searchDistricts.bind(provinceController));
router.get('/districts/:id', provinceController.getDistrictById.bind(provinceController));

module.exports = router;
