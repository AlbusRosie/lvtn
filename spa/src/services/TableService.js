import axios from 'axios';

const API_URL = 'http://localhost:3000/api/tables';

class TableService {
  async getAllTables() {
    try {
      const response = await axios.get(API_URL);
      return response.data.data;
    } catch (error) {
      if (error.response?.data?.message) {
        throw new Error(error.response.data.message);
      } else if (error.response?.data?.error) {
        throw new Error(error.response.data.error);
      } else if (error.message) {
        throw new Error(error.message);
      } else {
        throw new Error('Có lỗi xảy ra khi tải danh sách bàn');
      }
    }
  }
  async getAvailableTables() {
    try {
      const response = await axios.get(`${API_URL}/available`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getTablesByStatus(status) {
    try {
      const response = await axios.get(`${API_URL}/status/${status}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getTableById(id) {
    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getAllBranches() {
    try {
      const response = await axios.get(`${API_URL}/branches`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getFloorsByBranch(branchId) {
    try {
      const response = await axios.get(`${API_URL}/branches/${branchId}/floors`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getTablesByBranchAndFloor(branchId, floorId) {
    try {
      const response = await axios.get(`${API_URL}/branches/${branchId}/floors/${floorId}/tables`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async generateNextTableNumber(branchId, floorId) {
    try {
      const tables = await this.getTablesByBranchAndFloor(branchId, floorId);
      let maxNumber = 0;
      tables.forEach(table => {
        const tableNumber = table.table_number;
        if (tableNumber.startsWith('T')) {
          const numberPart = parseInt(tableNumber.substring(1));
          if (!isNaN(numberPart) && numberPart > maxNumber) {
            maxNumber = numberPart;
          }
        }
      });
      const nextNumber = maxNumber + 1;
      return {
        nextTableNumber: `T${String(nextNumber).padStart(2, '0')}`,
        currentTableCount: tables.length,
        maxNumber: maxNumber
      };
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async createTable(tableData, token) {
    try {
      const response = await axios.post(API_URL, tableData, {
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
        throw new Error('Có lỗi xảy ra khi tạo bàn');
      }
    }
  }
  async updateTable(id, tableData, token) {
    try {
      const response = await axios.put(`${API_URL}/${id}`, tableData, {
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
        throw new Error('Có lỗi xảy ra khi cập nhật bàn');
      }
    }
  }
  async updateTableStatus(id, status, token) {
    try {
      const response = await axios.patch(`${API_URL}/${id}/status`, { status }, {
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
        throw new Error('Có lỗi xảy ra khi cập nhật trạng thái bàn');
      }
    }
  }
  async deleteTable(id, token) {
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
        throw new Error('Có lỗi xảy ra khi xóa bàn');
      }
    }
  }
  getStatusOptions() {
    return [
      { value: 'available', label: 'Có sẵn', color: 'green' },
      { value: 'occupied', label: 'Đang sử dụng', color: 'red' },
      { value: 'reserved', label: 'Đã đặt trước', color: 'orange' },
      { value: 'maintenance', label: 'Bảo trì', color: 'gray' }
    ];
  }
  getStatusLabel(status) {
    const options = this.getStatusOptions();
    const option = options.find(opt => opt.value === status);
    return option ? option.label : status;
  }
  getStatusColor(status) {
    const options = this.getStatusOptions();
    const option = options.find(opt => opt.value === status);
    return option ? option.color : 'gray';
  }
}

export default new TableService();