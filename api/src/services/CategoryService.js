const knex = require('../database/knex');
const ApiError = require('../api-error');

class CategoryService {
  // Get all categories
  async getAllCategories() {
    try {
      const categories = await knex('categories')
        .select('*')
        .orderBy('name', 'asc');
      
      return categories;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get category by ID
  async getCategoryById(id) {
    try {
      const category = await knex('categories')
        .select('*')
        .where('id', id)
        .first();
      
      if (!category) {
        throw new ApiError(404, 'Category not found');
      }
      
      return category;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Create new category
  async createCategory(categoryData) {
    try {
      // Check if category name already exists
      const existingCategory = await knex('categories')
        .where('name', categoryData.name)
        .first();
      
      if (existingCategory) {
        throw new ApiError(400, 'Category name already exists');
      }
      
      const [categoryId] = await knex('categories')
        .insert(categoryData)
        .returning('id');
      
      return this.getCategoryById(categoryId);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Update category
  async updateCategory(id, categoryData) {
    try {
      // Check if category exists
      const existingCategory = await knex('categories')
        .where('id', id)
        .first();
      
      if (!existingCategory) {
        throw new ApiError(404, 'Category not found');
      }
      
      // Check if new name conflicts with other categories
      if (categoryData.name && categoryData.name !== existingCategory.name) {
        const nameConflict = await knex('categories')
          .where('name', categoryData.name)
          .whereNot('id', id)
          .first();
        
        if (nameConflict) {
          throw new ApiError(400, 'Category name already exists');
        }
      }
      
      await knex('categories')
        .where('id', id)
        .update(categoryData);
      
      if (categoryData.status === 'inactive') {
        await knex('products')
          .where('category_id', id)
          .update({ status: 'inactive' });
      }

      return this.getCategoryById(id);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Delete category
  async deleteCategory(id) {
    try {
      // Check if category exists
      const existingCategory = await knex('categories')
        .where('id', id)
        .first();
      
      if (!existingCategory) {
        throw new ApiError(404, 'Category not found');
      }
      
      // Check if category has products
      const productsCount = await knex('products')
        .where('category_id', id)
        .count('* as count')
        .first();
      
      if (productsCount.count > 0) {
        throw new ApiError(400, 'Cannot delete category that has products');
      }
      
      await knex('categories')
        .where('id', id)
        .del();
      
      return { message: 'Category deleted successfully' };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get categories with product count
  async getCategoriesWithProductCount() {
    try {
      const categories = await knex('categories')
        .select(
          'categories.*',
          knex.raw('COUNT(products.id) as product_count')
        )
        .leftJoin('products', 'categories.id', 'products.category_id')
        .groupBy('categories.id')
        .orderBy('categories.name', 'asc');
      
      return categories.map(category => ({
        ...category,
        product_count: parseInt(category.product_count)
      }));
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }
}

module.exports = CategoryService; 