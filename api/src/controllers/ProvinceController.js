const ProvinceService = require('../services/ProvinceService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

async function getAllProvinces(req, res, next) {
  try {
    const provinces = await ProvinceService.getAllProvinces();
    res.json(success(provinces));
  } catch (error) {
    next(error);
  }
}

async function getProvinceById(req, res, next) {
  try {
    const { id } = req.params;
    const province = await ProvinceService.getProvinceById(id);
    res.json(success(province));
  } catch (error) {
    next(error);
  }
}

async function getDistrictsByProvinceId(req, res, next) {
  try {
    const { provinceId } = req.params;
    const districts = await ProvinceService.getDistrictsByProvinceId(provinceId);
    res.json(success(districts));
  } catch (error) {
    next(error);
  }
}

async function getDistrictById(req, res, next) {
  try {
    const { id } = req.params;
    const district = await ProvinceService.getDistrictById(id);
    res.json(success(district));
  } catch (error) {
    next(error);
  }
}

async function searchProvinces(req, res, next) {
  try {
    const { q } = req.query;
    if (!q) {
      throw new ApiError(400, 'Search term is required');
    }
    const provinces = await ProvinceService.searchProvinces(q);
    res.json(success(provinces));
  } catch (error) {
    next(error);
  }
}

async function searchDistricts(req, res, next) {
  try {
    const { q, province_id } = req.query;
    if (!q) {
      throw new ApiError(400, 'Search term is required');
    }
    const districts = await ProvinceService.searchDistricts(q, province_id);
    res.json(success(districts));
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllProvinces,
  getProvinceById,
  getDistrictsByProvinceId,
  getDistrictById,
  searchProvinces,
  searchDistricts
};
