const knex = require('../database/knex');
const { unlink } = require('node:fs');
let io = null;

// Function to set io instance (called from server.js)
function setSocketIO(socketIO) {
    io = socketIO;
}
function categoryRepository() {
    return knex('categories');
}
function readCategory(payload) {
    return {
        name: payload.name,
        description: payload.description || null,
        image: payload.image || null
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
    const newCategory = { id, ...category };
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io) {
        io.to('admin').emit('category-created', {
            categoryId: id,
            category: newCategory,
            timestamp: new Date().toISOString()
        });
    }
    
    return newCategory;
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
    const updated = { ...updatedCategory, ...update };
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io) {
        io.to('admin').emit('category-updated', {
            categoryId: id,
            category: updated,
            timestamp: new Date().toISOString()
        });
    }
    
    return updated;
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
                        }
                });
            }
        });
    }
    await categoryRepository().where('id', id).del();
    const result = { 
        ...deletedCategory,
        message: 'Category and all related products deleted successfully',
        deletedProductsCount: products.length
    };
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io) {
        io.to('admin').emit('category-deleted', {
            categoryId: id,
            category: deletedCategory,
            deletedProductsCount: products.length,
            timestamp: new Date().toISOString()
        });
    }
    
    return result;
}
async function getCategoriesWithProductCount() {
    const categories = await categoryRepository()
        .select(
            'categories.id',
            'categories.name',
            'categories.description',
            'categories.image',
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
    getCategoriesWithProductCount,
    setSocketIO
};