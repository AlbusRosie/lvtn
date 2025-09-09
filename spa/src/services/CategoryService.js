import axios from 'axios';
import { API_BASE_URL } from '@/constants';

const API_URL = `${API_BASE_URL}/categories`;

class CategoryService {
  async getAllCategories() {
    try {
      const response = await axios.get(API_URL);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getCategoriesWithProductCount() {
    try {
      const response = await axios.get(`${API_URL}/with-count`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async getCategoryById(id) {
    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }
  async createCategory(categoryData, token) {
    try {
      const response = await axios.post(API_URL, categoryData, {
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
        throw new Error('Có lỗi xảy ra khi tạo danh mục');
      }
    }
  }
  async updateCategory(id, categoryData, token) {
    try {
      const response = await axios.put(`${API_URL}/${id}`, categoryData, {
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
        throw new Error('Có lỗi xảy ra khi cập nhật danh mục');
      }
    }
  }
  async deleteCategory(id, token) {
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
        throw new Error('Có lỗi xảy ra khi xóa danh mục');
      }
    }
  }

}

export default new CategoryService();