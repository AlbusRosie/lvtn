const CategoryService = require('../services/CategoryService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

class CategoryController {
  constructor() {
    this.categoryService = new CategoryService();
  }

  // Get all categories
  async getAllCategories(req, res, next) {
    try {
      const categories = await this.categoryService.getAllCategories();
      res.json(success(categories));
    } catch (error) {
      next(error);
    }
  }

  // Get categories with product count
  async getCategoriesWithProductCount(req, res, next) {
    try {
      const categories = await this.categoryService.getCategoriesWithProductCount();
      res.json(success(categories));
    } catch (error) {
      next(error);
    }
  }

  // Get category by ID
  async getCategoryById(req, res, next) {
    try {
      const { id } = req.params;
      const category = await this.categoryService.getCategoryById(id);
      res.json(success(category));
    } catch (error) {
      next(error);
    }
  }

  // Create new category
  async createCategory(req, res, next) {
    try {
      const { name, description, image } = req.body;

      // Validation
      if (!name || !name.trim()) {
        throw new ApiError(400, 'Category name is required');
      }

      const categoryData = {
        name: name.trim(),
        description: description ? description.trim() : null,
        image: image || null
      };

      const category = await this.categoryService.createCategory(categoryData);
      res.status(201).json(success(category, 'Category created successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Update category
  async updateCategory(req, res, next) {
    try {
      const { id } = req.params;
      const { name, description, image, status } = req.body;

      // Validation
      if (name !== undefined && (!name || !name.trim())) {
        throw new ApiError(400, 'Category name cannot be empty');
      }

      const categoryData = {};
      if (name !== undefined) categoryData.name = name.trim();
      if (description !== undefined) categoryData.description = description ? description.trim() : null;
      if (image !== undefined) categoryData.image = image;
      if (status !== undefined) categoryData.status = status;

      const category = await this.categoryService.updateCategory(id, categoryData);
      res.json(success(category, 'Category updated successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Delete category
  async deleteCategory(req, res, next) {
    try {
      const { id } = req.params;
      const result = await this.categoryService.deleteCategory(id);
      res.json(success(result, 'Category deleted successfully'));
    } catch (error) {
      next(error);
    }
  }
}

module.exports = CategoryController; 