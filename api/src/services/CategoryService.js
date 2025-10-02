const knex = require('../database/knex');
const Paginator = require('./Paginator');
const { unlink } = require('node:fs');

function categoryRepository() {
    return knex('categories');
}

function readCategory(payload) {
    return {
        name: payload.name,
        description: payload.description || null
    };
}

async function createCategory(payload) {
    if (!payload.name || !payload.name.trim()) {
        throw new Error('Category name is required');
    }

    const existingCategory = await categoryRepository()
        .where('name', payload.name)
        .first();

    if (existingCategory) {
        throw new Error('Category name already exists');
    }

    const category = readCategory(payload);
    const [id] = await categoryRepository().insert(category);
    return { id, ...category };
}

async function getAllCategories() {
    return categoryRepository()
        .select('*')
        .orderBy('name', 'asc');
}

async function getCategoryById(id) {
    return categoryRepository().where('id', id).select('*').first();
}

async function updateCategory(id, payload) {
    const updatedCategory = await categoryRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!updatedCategory) {
        return null;
    }

    if (payload.name && payload.name !== updatedCategory.name) {
        const nameConflict = await categoryRepository()
            .where('name', payload.name)
            .whereNot('id', id)
            .first();

        if (nameConflict) {
            throw new Error('Category name already exists');
        }
    }

    const update = readCategory(payload);
    await categoryRepository().where('id', id).update(update);
    return { ...updatedCategory, ...update };
}

async function deleteCategory(id) {
    const deletedCategory = await categoryRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!deletedCategory) {
        return null;
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

        products.forEach((product) => {
            if (product.image && product.image.startsWith('/public/uploads')) {
                unlink(`.${product.image}`, (err) => {
                    if (err) {
                      // Continue silently
                    }
                });
            }
        });
    }

    await categoryRepository().where('id', id).del();
    return { 
        ...deletedCategory,
        message: 'Category and all related products deleted successfully',
        deletedProductsCount: products.length
    };
}

async function getCategoriesWithProductCount() {
    const categories = await categoryRepository()
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
}

module.exports = {
    createCategory,
    getAllCategories,
    getCategoryById,
    updateCategory,
    deleteCategory,
    getCategoriesWithProductCount
};