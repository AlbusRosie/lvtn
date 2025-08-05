const knex = require('../database/knex');
const Paginator = require('./Paginator');
const { unlink } = require('node:fs');

function productRepository() {
    return knex('products');
}

function readProduct(payload) {
    const product = {
        category_id: payload.category_id,
        name: payload.name,
        price: payload.price,
        stock: payload.stock,
        description: payload.description || null,
        image: payload.image || null,
        is_available: payload.is_available !== undefined ? payload.is_available : 1
    };

    return product;
}

async function createProduct(payload) {
    // Validate required fields
    if (!payload.category_id || !payload.name || !payload.price || !payload.stock === undefined) {
        throw new Error('Missing required fields');
    }

    // Validate price and stock are positive numbers
    if (payload.price <= 0 || payload.stock < 0) {
        throw new Error('Price must be positive and stock must be non-negative');
    }

    const product = readProduct(payload);
    const [id] = await productRepository().insert(product);
    return {    
        id,
        ...product
    };
}

async function getManyProducts(query) {
    const { name, category_id, min_price, max_price, is_available, page = 1, limit = 10 } = query;
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
    
    // Validate price and stock if provided
    if (update.price !== undefined && update.price <= 0) {
        throw new Error('Price must be positive');
    }
    if (update.stock !== undefined && update.stock < 0) {
        throw new Error('Stock must be non-negative');
    }

    await productRepository().where('id', id).update(update);
    
    // Delete old image if new image is uploaded
    if (update.image && existingProduct.image && update.image !== existingProduct.image && existingProduct.image.startsWith('/public/uploads')) {
        unlink(`.${existingProduct.image}`, (err) => {});
    }
    
    return { ...existingProduct, ...update };
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
    
    // Delete image file if exists
    if (deletedProduct.image && deletedProduct.image.startsWith('/public/uploads')) {
        unlink(`.${deletedProduct.image}`, (err) => {});
    }
    
    return deletedProduct;
}

async function deleteAllProducts() {
    const products = await productRepository().select('image');
    await productRepository().del();
    
    // Delete all image files
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