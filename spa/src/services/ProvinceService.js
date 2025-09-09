import axios from 'axios';
import { API_BASE_URL } from '@/constants';

const API_URL = `${API_BASE_URL}/provinces`;

class ProvinceService {

  async getAllProvinces() {
    try {
      const response = await axios.get(API_URL);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  async getProvinceById(id) {
    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  async getDistrictsByProvinceId(provinceId) {
    try {
      const response = await axios.get(`${API_URL}/${provinceId}/districts`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  async getDistrictById(id) {
    try {
      const response = await axios.get(`${API_URL}/districts/${id}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  async searchProvinces(searchTerm) {
    try {
      const response = await axios.get(`${API_URL}/search`, {
        params: { q: searchTerm }
      });
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  async searchDistricts(searchTerm, provinceId = null) {
    try {
      const params = { q: searchTerm };
      if (provinceId) {
        params.province_id = provinceId;
      }
      const response = await axios.get(`${API_URL}/districts/search`, { params });
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
}

export default new ProvinceService();
