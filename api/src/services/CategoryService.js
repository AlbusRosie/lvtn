const knex = require('../database/knex');
const ApiError = require('../api-error');

class CategoryService {

  async getAllCategories() {
    try {
      const categories = await knex('categories')
        .select('id', 'name', 'description', 'created_at')
        .orderBy('name', 'asc');

      return categories;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getCategoryById(id) {
    try {
      const category = await knex('categories')
        .select('id', 'name', 'description', 'created_at')
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

  async createCategory(categoryData) {
    try {

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

  async updateCategory(id, categoryData) {
    try {

      const existingCategory = await knex('categories')
        .where('id', id)
        .first();

      if (!existingCategory) {
        throw new ApiError(404, 'Category not found');
      }

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

      return this.getCategoryById(id);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async deleteCategory(id) {
    try {

      const existingCategory = await knex('categories')
        .where('id', id)
        .first();

      if (!existingCategory) {
        throw new ApiError(404, 'Category not found');
      }

      const products = await knex('products')
        .where('category_id', id)
        .select('id', 'image');

      if (products.length > 0) {
        await knex('branch_products')
          .whereIn('product_id', products.map(p => p.id))
          .del();

        await knex('order_details')
          .whereIn('product_id', products.map(p => p.id))
          .del();

        await knex('reviews')
          .whereIn('product_id', products.map(p => p.id))
          .del();

        await knex('products')
          .where('category_id', id)
          .del();

        const { unlink } = require('node:fs');
        products.forEach((product) => {
          if (product.image && product.image.startsWith('/public/uploads')) {
            unlink(`.${product.image}`, (err) => {
              if (err) console.log('Error deleting product image:', err);
            });
          }
        });
      }

      await knex('categories')
        .where('id', id)
        .del();

      return { 
        message: 'Category and all related products deleted successfully',
        deletedProductsCount: products.length
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getCategoriesWithProductCount() {
    try {
      const categories = await knex('categories')
        .select(
          'categories.id',
          'categories.name',
          'categories.description',
          'categories.created_at',
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