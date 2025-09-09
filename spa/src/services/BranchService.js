import axios from 'axios';
import { API_BASE_URL } from '@/constants';

const API_URL = `${API_BASE_URL}/branches`;

class BranchService {

  async getAllBranches(searchTerm = null, provinceId = null, districtId = null, status = null) {
    try {
      const params = {};
      if (searchTerm) params.search = searchTerm;
      if (provinceId) params.province_id = provinceId;
      if (districtId) params.district_id = districtId;
      if (status) params.status = status;

      const response = await axios.get(API_URL, { params });
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  async getBranchById(id) {
    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  async createBranch(branchData, token) {
    try {
      const response = await axios.post(API_URL, branchData, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      return response.data.data;
    } catch (error) {
      if (error.response?.data?.message) {
        throw new Error(error.response.data.message);
      } else if (error.response?.data?.error) {
        throw new Error(error.response.data.error);
      } else if (error.message) {
        throw new Error(error.message);
      } else {
        throw new Error('Có lỗi xảy ra khi tạo chi nhánh');
      }
    }
  }

  async updateBranch(id, branchData, token) {
    try {
      const response = await axios.put(`${API_URL}/${id}`, branchData, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      return response.data.data;
    } catch (error) {
      if (error.response?.data?.message) {
        throw new Error(error.response.data.message);
      } else if (error.response?.data?.error) {
        throw new Error(error.response.data.error);
      } else if (error.message) {
        throw new Error(error.message);
      } else {
        throw new Error('Có lỗi xảy ra khi cập nhật chi nhánh');
      }
    }
  }

  async deleteBranch(id, token) {
    try {
      const response = await axios.delete(`${API_URL}/${id}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      return response.data.data;
    } catch (error) {
      if (error.response?.data?.message) {
        throw new Error(error.response.data.message);
      } else if (error.response?.data?.error) {
        throw new Error(error.response.data.error);
      } else if (error.message) {
        throw new Error(error.message);
      } else {
        throw new Error('Có lỗi xảy ra khi xóa chi nhánh');
      }
    }
  }

  async getBranchStatistics() {
    try {
      const response = await axios.get(`${API_URL}/statistics`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  async getActiveBranches() {
    try {
      const response = await axios.get(`${API_URL}/active`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
}

export default new BranchService();