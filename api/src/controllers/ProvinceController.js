const ProvinceService = require('../services/ProvinceService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

class ProvinceController {
  constructor() {
    this.provinceService = new ProvinceService();
  }

  async getAllProvinces(req, res, next) {
    try {
      const provinces = await this.provinceService.getAllProvinces();
      res.json(success(provinces));
    } catch (error) {
      next(error);
    }
  }

  async getProvinceById(req, res, next) {
    try {
      const { id } = req.params;
      const province = await this.provinceService.getProvinceById(id);
      res.json(success(province));
    } catch (error) {
      next(error);
    }
  }

  async getDistrictsByProvinceId(req, res, next) {
    try {
      const { provinceId } = req.params;
      const districts = await this.provinceService.getDistrictsByProvinceId(provinceId);
      res.json(success(districts));
    } catch (error) {
      next(error);
    }
  }

  async getDistrictById(req, res, next) {
    try {
      const { id } = req.params;
      const district = await this.provinceService.getDistrictById(id);
      res.json(success(district));
    } catch (error) {
      next(error);
    }
  }

  async searchProvinces(req, res, next) {
    try {
      const { q } = req.query;
      if (!q) {
        throw new ApiError(400, 'Search term is required');
      }
      const provinces = await this.provinceService.searchProvinces(q);
      res.json(success(provinces));
    } catch (error) {
      next(error);
    }
  }

  async searchDistricts(req, res, next) {
    try {
      const { q, province_id } = req.query;
      if (!q) {
        throw new ApiError(400, 'Search term is required');
      }
      const districts = await this.provinceService.searchDistricts(q, province_id);
      res.json(success(districts));
    } catch (error) {
      next(error);
    }
  }
}

module.exports = ProvinceController;
