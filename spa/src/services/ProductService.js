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

    // Add auth token to requests
    this.api.interceptors.request.use((config) => {
      const token = localStorage.getItem('auth_token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    });
  }

  // Get all products with filters
  async getProducts(params = {}) {
    try {
      const response = await this.api.get('', { params });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Get available products only
  async getAvailableProducts(params = {}) {
    try {
      const response = await this.api.get('/available', { params });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Get product by ID
  async getProduct(id) {
    try {
      const response = await this.api.get(`/${id}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Create new product with image upload
  async createProduct(productData) {
    try {
      // Create FormData for file upload
      const formData = new FormData();
      
      // Add all product data to FormData
      Object.keys(productData).forEach(key => {
        if (key === 'imageFile' && productData[key] instanceof File) {
          formData.append(key, productData[key]);
        } else if (key !== 'imageFile') {
          formData.append(key, productData[key]);
        }
      });

      const response = await this.api.post('', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Update product with image upload
  async updateProduct(id, productData) {
    try {
      // Create FormData for file upload
      const formData = new FormData();
      
      // Add all product data to FormData
      Object.keys(productData).forEach(key => {
        if (key === 'imageFile' && productData[key] instanceof File) {
          formData.append(key, productData[key]);
        } else if (key !== 'imageFile') {
          formData.append(key, productData[key]);
        }
      });

      const response = await this.api.put(`/${id}`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Delete product
  async deleteProduct(id) {
    try {
      const response = await this.api.delete(`/${id}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Get products by category
  async getProductsByCategory(categoryId) {
    try {
      const response = await this.api.get(`/category/${categoryId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Delete all products
  async deleteAllProducts() {
    try {
      const response = await this.api.delete('');
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Search products by name
  async searchProducts(name, params = {}) {
    try {
      const searchParams = { ...params, name };
      const response = await this.api.get('', { params: searchParams });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Filter products by price range
  async filterProductsByPrice(minPrice, maxPrice, params = {}) {
    try {
      const filterParams = { ...params, min_price: minPrice, max_price: maxPrice };
      const response = await this.api.get('', { params: filterParams });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Filter products by availability
  async filterProductsByAvailability(isAvailable, params = {}) {
    try {
      const filterParams = { ...params, is_available: isAvailable };
      const response = await this.api.get('', { params: filterParams });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // Handle API errors
  handleError(error) {
    if (error.response) {
      // Server responded with error status
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
      // Network error
      return new Error('Network error. Please check your connection.');
    } else {
      // Other error
      return new Error('An unexpected error occurred');
    }
  }
}

export default new ProductService(); 