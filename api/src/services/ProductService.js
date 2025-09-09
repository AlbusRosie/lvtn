const knex = require('../database/knex');
const Paginator = require('./Paginator');
const { unlink } = require('node:fs');

function productRepository() {
    return knex('products');
}

function readProduct(payload) {
    const product = {};

    if (payload.category_id !== undefined) {
        product.category_id = payload.category_id;
    }
    if (payload.name !== undefined) {
        product.name = payload.name;
    }
    if (payload.base_price !== undefined) {
        product.base_price = payload.base_price;
    }
    if (payload.description !== undefined) {
        product.description = payload.description;
    }
    if (payload.image !== undefined) {
        product.image = payload.image;
    }
    if (payload.is_global_available !== undefined) {
        product.is_global_available = payload.is_global_available;
    }

    return product;
}

async function createProduct(payload) {

    if (!payload.category_id || !payload.name || !payload.base_price === undefined) {
        throw new Error('Missing required fields');
    }

    if (payload.base_price <= 0) {
        throw new Error('Base price must be positive');
    }

    const product = readProduct(payload);
    const [id] = await productRepository().insert(product);
    return {
        id,
        ...product
    };
}

async function getManyProducts(query) {
    const { name, category_id, min_price, max_price, status, is_available, page = 1, limit = 10 } = query;
    const paginator = new Paginator(page, limit);

    let results = await productRepository()
        .join('categories', 'products.category_id', 'categories.id')
        .where((builder) => {
            if (name) {
                builder.where('products.name', 'like', `%${name}%`);
            }
            if (category_id) {
                builder.where('products.category_id', category_id);
            }
            if (min_price) {
                builder.where('products.price', '>=', min_price);
            }
            if (max_price) {
                builder.where('products.price', '<=', max_price);
            }
            if (status) {
                builder.where('products.status', status);
            }
            if (is_available !== undefined) {
                builder.where('products.is_available', is_available === 'true' || is_available === true ? 1 : 0);
            }
        })
        .select(
            knex.raw('count(products.id) OVER() AS recordCount'),
            'products.id',
            'products.name',
            'products.price',
            'products.stock',
            'products.description',
            'products.image',
            'products.is_available',
            'products.status',
            'products.created_at',
            'categories.name as category_name',
            'categories.id as category_id'
        )
        .orderBy('products.created_at', 'desc')
        .limit(paginator.limit)
        .offset(paginator.offset);

    let totalRecords = 0;
    results = results.map((result) => {
        totalRecords = result.recordCount;
        delete result.recordCount;
        return result;
    });

    return {
        metadata: paginator.getMetadata(totalRecords),
        products: results,
    };
}

async function getProductById(id) {
    return productRepository()
        .join('categories', 'products.category_id', 'categories.id')
        .where('products.id', id)
        .select(
            'products.id',
            'products.name',
            'products.price',
            'products.stock',
            'products.description',
            'products.image',
            'products.is_available',
            'products.status',
            'products.created_at',
            'categories.name as category_name',
            'categories.id as category_id'
        )
        .first();
}

async function updateProduct(id, payload) {
    const existingProduct = await productRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!existingProduct) {
        return null;
    }

    const update = readProduct(payload);

    if (Object.keys(update).length === 0) {
        throw new Error('No valid fields to update');
    }

    if (update.price !== undefined) {
        const price = parseFloat(update.price);
        if (isNaN(price) || price <= 0) {
            throw new Error('Price must be a positive number');
        }
    }
    if (update.stock !== undefined) {
        const stock = parseInt(update.stock);
        if (isNaN(stock) || stock < 0) {
            throw new Error('Stock must be a non-negative number');
        }
    }

    if (update.status && !['active', 'inactive', 'out_of_stock'].includes(update.status)) {
        throw new Error('Invalid status value');
    }

    if (update.status) {
        if (update.status === 'out_of_stock') {
            update.stock = 0;
            update.is_available = false;
        } else if (update.status === 'active') {
            const currentStock = update.stock !== undefined ? update.stock : existingProduct.stock;
            if (currentStock <= 0) {
                throw new Error('Stock must be greater than 0 when status is active');
            }
            update.is_available = true;
        } else if (update.status === 'inactive') {
            update.is_available = false;
        }
    }

    if (update.category_id !== undefined) {
        const category = await knex('categories')
            .where('id', update.category_id)
            .first();
        if (!category) {
            throw new Error('Category not found');
        }
    }

    const [updatedProduct] = await productRepository()
        .where('id', id)
        .update(update)
        .returning('*');

    return updatedProduct;
}

async function deleteProduct(id) {
    const deletedProduct = await productRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!deletedProduct) {
        return null;
    }

    await productRepository().where('id', id).del();

    if (deletedProduct.image && deletedProduct.image.startsWith('/public/uploads')) {
        unlink(`.${deletedProduct.image}`, (err) => {});
    }

    return deletedProduct;
}

async function deleteAllProducts() {
    const products = await productRepository().select('image');
    await productRepository().del();

    products.forEach((product) => {
        if (product.image && product.image.startsWith('/public/uploads')) {
            unlink(`.${product.image}`, (err) => {});
        }
    });

    return true;
}

async function getProductsByCategory(categoryId) {
    return productRepository()
        .join('categories', 'products.category_id', 'categories.id')
        .where('products.category_id', categoryId)
        .select(
            'products.id',
            'products.name',
            'products.price',
            'products.stock',
            'products.description',
            'products.image',
            'products.is_available',
            'products.status',
            'products.created_at',
            'categories.name as category_name',
            'categories.id as category_id'
        )
        .orderBy('products.created_at', 'desc');
}

async function getAvailableProducts(query) {
    const { name, category_id, min_price, max_price, page = 1, limit = 10 } = query;
    const paginator = new Paginator(page, limit);

    let results = await productRepository()
        .join('categories', 'products.category_id', 'categories.id')
        .where('products.is_available', 1)
        .where((builder) => {
            if (name) {
                builder.where('products.name', 'like', `%${name}%`);
            }
            if (category_id) {
                builder.where('products.category_id', category_id);
            }
            if (min_price) {
                builder.where('products.price', '>=', min_price);
            }
            if (max_price) {
                builder.where('products.price', '<=', max_price);
            }
        })
        .select(
            knex.raw('count(products.id) OVER() AS recordCount'),
            'products.id',
            'products.name',
            'products.price',
            'products.stock',
            'products.description',
            'products.image',
            'products.created_at',
            'categories.name as category_name',
            'categories.id as category_id'
        )
        .orderBy('products.created_at', 'desc')
        .limit(paginator.limit)
        .offset(paginator.offset);

    let totalRecords = 0;
    results = results.map((result) => {
        totalRecords = result.recordCount;
        delete result.recordCount;
        return result;
    });

    return {
        metadata: paginator.getMetadata(totalRecords),
        products: results,
    };
}

module.exports = {
    createProduct,
    getManyProducts,
    getProductById,
    updateProduct,
    deleteProduct,
    deleteAllProducts,
    getProductsByCategory,
    getAvailableProducts,
};