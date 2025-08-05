import axios from 'axios';
import { API_BASE_URL } from '@/constants';

const API_URL = `${API_BASE_URL}/branches`;

class BranchService {
  // Get all branches
  async getAllBranches() {
    try {
      const response = await axios.get(API_URL);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  // Get branch by ID
  async getBranchById(id) {
    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  // Create new branch
  async createBranch(branchData, token) {
    try {
      console.log('BranchService.createBranch called with:', branchData);
      const response = await axios.post(API_URL, branchData, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      console.log('BranchService.createBranch response:', response.data);
      return response.data.data;
    } catch (error) {
      console.error('BranchService.createBranch error:', error.response?.data || error);
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

  // Update branch
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

  // Delete branch
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

  // Get branch statistics
  async getBranchStatistics() {
    try {
      const response = await axios.get(`${API_URL}/statistics`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  // Get active branches
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