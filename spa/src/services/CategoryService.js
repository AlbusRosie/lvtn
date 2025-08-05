import axios from 'axios';
import { API_BASE_URL } from '@/constants';

const API_URL = `${API_BASE_URL}/categories`;

class CategoryService {

  // Get all categories
  async getAllCategories() {
    try {
      const response = await axios.get(API_URL);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  // Get categories with product count
  async getCategoriesWithProductCount() {
    try {
      const response = await axios.get(`${API_URL}/with-count`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  // Get category by ID
  async getCategoryById(id) {
    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return response.data.data;
    } catch (error) {
      throw error.response?.data || error.message;
    }
  }

  // Create new category
  async createCategory(categoryData, token) {
    try {
      console.log('CategoryService.createCategory called with:', categoryData);
      const response = await axios.post(API_URL, categoryData, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      console.log('CategoryService.createCategory response:', response.data);
      return response.data.data;
    } catch (error) {
      console.error('CategoryService.createCategory error:', error.response?.data || error);
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

  // Update category
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

  // Delete category
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