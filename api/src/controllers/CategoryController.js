const CategoryService = require('../services/CategoryService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

class CategoryController {
  constructor() {
    this.categoryService = new CategoryService();
  }

  async getAllCategories(req, res, next) {
    try {
      const categories = await this.categoryService.getAllCategories();
      res.json(success(categories));
    } catch (error) {
      next(error);
    }
  }

  async getCategoriesWithProductCount(req, res, next) {
    try {
      const categories = await this.categoryService.getCategoriesWithProductCount();
      res.json(success(categories));
    } catch (error) {
      next(error);
    }
  }

  async getCategoryById(req, res, next) {
    try {
      const { id } = req.params;
      const category = await this.categoryService.getCategoryById(id);
      res.json(success(category));
    } catch (error) {
      next(error);
    }
  }

  async createCategory(req, res, next) {
    try {
      const { name, description } = req.body;

      if (!name || !name.trim()) {
        throw new ApiError(400, 'Category name is required');
      }

      const categoryData = {
        name: name.trim(),
        description: description ? description.trim() : null
      };

      const category = await this.categoryService.createCategory(categoryData);
      res.status(201).json(success(category, 'Category created successfully'));
    } catch (error) {
      next(error);
    }
  }

  async updateCategory(req, res, next) {
    try {
      const { id } = req.params;
      const { name, description } = req.body;

      if (name !== undefined && (!name || !name.trim())) {
        throw new ApiError(400, 'Category name cannot be empty');
      }

      const categoryData = {};
      if (name !== undefined) categoryData.name = name.trim();
      if (description !== undefined) categoryData.description = description ? description.trim() : null;

      const category = await this.categoryService.updateCategory(id, categoryData);
      res.json(success(category, 'Category updated successfully'));
    } catch (error) {
      next(error);
    }
  }

  async deleteCategory(req, res, next) {
    try {
      const { id } = req.params;
      const result = await this.categoryService.deleteCategory(id);
      res.json(success(result, result.message));
    } catch (error) {
      next(error);
    }
  }
}

module.exports = CategoryController;