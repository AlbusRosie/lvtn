import axios from 'axios';
import { API_BASE_URL } from '@/constants';

class ProductService {
  constructor() {
    this.api = axios.create({
      baseURL: `${API_BASE_URL}/products`,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.api.interceptors.request.use((config) => {
      const token = localStorage.getItem('auth_token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    });
  }

  async getProducts(params = {}) {
    try {
      const response = await this.api.get('', { params });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getAvailableProducts(params = {}) {
    try {
      const response = await this.api.get('/available', { params });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getProduct(id) {
    try {
      const response = await this.api.get(`/${id}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async createProduct(productData) {
    try {
      if (productData instanceof FormData) {
      } else {
      }

      const token = localStorage.getItem('auth_token');
      const response = await fetch(`${API_BASE_URL}/products`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: productData // productData is already FormData
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to create product');
      }

      const result = await response.json();
      return result;
    } catch (error) {

      throw error;
    }
  }

  async updateProduct(id, productData) {
    try {

      const formData = new FormData();

      for (const [key, value] of Object.entries(productData)) {
        if (key === 'imageFile' && value instanceof File) {
          formData.append(key, value);
        } else if (key !== 'imageFile') {
          formData.append(key, value);
        }
      }

      const token = localStorage.getItem('auth_token');
      const response = await fetch(`${API_BASE_URL}/products/${id}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to update product');
      }

      const result = await response.json();
      return result;
    } catch (error) {

      throw error;
    }
  }

  async deleteProduct(id) {
    try {
      const response = await this.api.delete(`/${id}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getProductsByCategory(categoryId) {
    try {
      const response = await this.api.get(`/category/${categoryId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async deleteAllProducts() {
    try {
      const response = await this.api.delete('');
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async searchProducts(name, params = {}) {
    try {
      const searchParams = { ...params, name };
      const response = await this.api.get('', { params: searchParams });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async filterProductsByPrice(minPrice, maxPrice, params = {}) {
    try {
      const filterParams = { ...params, min_price: minPrice, max_price: maxPrice };
      const response = await this.api.get('', { params: filterParams });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async filterProductsByAvailability(isAvailable, params = {}) {
    try {
      const filterParams = { ...params, is_available: isAvailable };
      const response = await this.api.get('', { params: filterParams });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  handleError(error) {
    if (error.response) {

      const { status, data } = error.response;

      switch (status) {
        case 400:
          return new Error(data.message || 'Invalid request data');
        case 401:
          return new Error('Unauthorized. Please login again.');
        case 403:
          return new Error('Forbidden. You do not have permission.');
        case 404:
          return new Error('Product not found');
        case 422:
          return new Error(data.message || 'Validation error');
        case 500:
          return new Error('Server error. Please try again later.');
        default:
          return new Error(data.message || 'An error occurred');
      }
    } else if (error.request) {

      return new Error('Network error. Please check your connection.');
    } else {

      return new Error('An unexpected error occurred');
    }
  }
}

export default new ProductService();