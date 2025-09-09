import axios from 'axios';
import { API_BASE_URL } from '@/constants';

const API_URL = `${API_BASE_URL}/floors`;

class FloorService {
  async getAllFloors() {
    try {
      const response = await axios.get(API_URL);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getFloorById(id) {
    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getFloorsByBranch(branchId) {
    try {
      const response = await axios.get(`${API_URL}/branch/${branchId}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async createFloor(floorData, token) {
    try {
      const response = await axios.post(API_URL, floorData, {
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
        throw new Error('Có lỗi xảy ra khi tạo tầng');
      }
    }
  }
  async updateFloor(id, floorData, token) {
    try {
      const response = await axios.put(`${API_URL}/${id}`, floorData, {
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
        throw new Error('Có lỗi xảy ra khi cập nhật tầng');
      }
    }
  }
  async deleteFloor(id, token) {
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
        throw new Error('Có lỗi xảy ra khi xóa tầng');
      }
    }
  }
  async getFloorStatistics(branchId = null) {
    try {
      const url = branchId ? `${API_URL}/statistics?branch_id=${branchId}` : `${API_URL}/statistics`;
      const response = await axios.get(url);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getActiveFloors(branchId = null) {
    try {
      const url = branchId ? `${API_URL}/active?branch_id=${branchId}` : `${API_URL}/active`;
      const response = await axios.get(url);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async generateNextFloorNumber(branchId) {
    try {
      const floors = await this.getFloorsByBranch(branchId);
      let maxNumber = 0;
      floors.forEach(floor => {
        const floorNumber = floor.floor_number;
        if (floorNumber && floorNumber > maxNumber) {
          maxNumber = floorNumber;
        }
      });
      const nextNumber = maxNumber + 1;
      return {
        nextFloorNumber: nextNumber,
        currentFloorCount: floors.length,
        maxNumber: maxNumber
      };
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
}

export default new FloorService();