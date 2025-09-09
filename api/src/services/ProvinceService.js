const knex = require('../database/knex');
const ApiError = require('../api-error');

class ProvinceService {

  async getAllProvinces() {
    try {
      const provinces = await knex('provinces')
        .select('*')
        .orderBy('name', 'asc');

      return provinces;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getProvinceById(id) {
    try {
      const province = await knex('provinces')
        .where('id', id)
        .first();

      if (!province) {
        throw new ApiError(404, 'Province not found');
      }

      return province;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getDistrictsByProvinceId(provinceId) {
    try {
      const districts = await knex('districts')
        .select('*')
        .where('province_id', provinceId)
        .orderBy('name', 'asc');

      return districts;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getDistrictById(id) {
    try {
      const district = await knex('districts')
        .where('id', id)
        .first();

      if (!district) {
        throw new ApiError(404, 'District not found');
      }

      return district;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async searchProvinces(searchTerm) {
    try {
      const provinces = await knex('provinces')
        .select('*')
        .where('name', 'like', `%${searchTerm}%`)
        .orderBy('name', 'asc');

      return provinces;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async searchDistricts(searchTerm, provinceId = null) {
    try {
      let query = knex('districts')
        .select('districts.*', 'provinces.name as province_name')
        .leftJoin('provinces', 'districts.province_id', 'provinces.id')
        .where('districts.name', 'like', `%${searchTerm}%`);

      if (provinceId) {
        query = query.where('districts.province_id', provinceId);
      }

      const districts = await query.orderBy('districts.name', 'asc');
      return districts;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }
}

module.exports = ProvinceService;
