const CategoryService = require('../services/CategoryService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

async function createCategory(req, res, next) {
  try {
    const { name, description } = req.body;

    if (!name || !name.trim()) {
      throw new ApiError(400, 'Category name is required');
    }
    
    const categoryData = {
      name: name.trim(),
      description: description ? description.trim() : null
    };

    const category = await CategoryService.createCategory(categoryData);
    res.status(201).json(success(category, 'Category created successfully'));
  } catch (error) {
    next(error);
  }
}

async function getAllCategories(req, res, next) {
  try {
    const categories = await CategoryService.getAllCategories();
    res.json(success(categories));
  } catch (error) {
    next(error);
  }
}

async function getCategoryById(req, res, next) {
  try {
    const { id } = req.params;
    const category = await CategoryService.getCategoryById(id);
    res.json(success(category));
  } catch (error) {
    next(error);
  }
}

async function updateCategory(req, res, next) {
  try {
    const { id } = req.params;
    const { name, description } = req.body;

    if (name !== undefined && (!name || !name.trim())) {
      throw new ApiError(400, 'Category name cannot be empty');
    }

    const categoryData = {};
    if (name !== undefined) categoryData.name = name.trim();
    if (description !== undefined) categoryData.description = description ? description.trim() : null;

    const category = await CategoryService.updateCategory(id, categoryData);
    res.json(success(category, 'Category updated successfully'));
  } catch (error) {
    next(error);
  }
}

async function deleteCategory(req, res, next) {
  try {
    const { id } = req.params;
    const result = await CategoryService.deleteCategory(id);
    res.json(success(result, result.message));
  } catch (error) {
    next(error);
  }
}

async function getCategoriesWithProductCount(req, res, next) {
  try {
    const categories = await CategoryService.getCategoriesWithProductCount();
    res.json(success(categories));
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createCategory,
  getAllCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
  getCategoriesWithProductCount
};