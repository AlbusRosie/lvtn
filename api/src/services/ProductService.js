const knex = require('../database/knex');
const Paginator = require('./Paginator');
const { unlink } = require('node:fs');

function productRepository() {
    return knex('products');
}

function readProduct(payload) {
    return {
        category_id: payload.category_id,
        name: payload.name,
        base_price: payload.base_price,
        description: payload.description,
        image: payload.image,
        is_global_available: payload.is_global_available,
        status: payload.status
    };
}

async function autoCreateBranchProducts(productId, basePrice) {
    const activeBranches = await knex('branches')
        .where('status', 'active')
        .select('id');
    
    if (activeBranches.length > 0) {
        const branchProducts = activeBranches.map(branch => ({
            branch_id: branch.id,
            product_id: productId,
            price: basePrice,
            is_available: 1,
            status: 'available',
            created_at: new Date(),
            updated_at: new Date()
        }));
        
        await knex('branch_products').insert(branchProducts);
    }
}

async function createBranchProductsForSelectedBranches(productId, basePrice, selectedBranchIds) {
    const validBranches = await knex('branches')
        .whereIn('id', selectedBranchIds)
        .where('status', 'active')
        .select('id');
    
    if (validBranches.length === 0) {
        throw new Error('No valid active branches found');
    }
    
    const existingBranchProducts = await knex('branch_products')
        .where('product_id', productId)
        .whereIn('branch_id', validBranches.map(b => b.id))
        .select('branch_id');
    
    const existingBranchIds = existingBranchProducts.map(bp => bp.branch_id);
    const newBranchIds = validBranches
        .map(b => b.id)
        .filter(id => !existingBranchIds.includes(id));
    
    if (newBranchIds.length > 0) {
        const branchProducts = newBranchIds.map(branchId => ({
            branch_id: branchId,
            product_id: productId,
            price: basePrice,
            is_available: 1,
            status: 'available',
            created_at: new Date(),
            updated_at: new Date()
        }));
        
        await knex('branch_products').insert(branchProducts);
    }
    
    return {
        added: newBranchIds.length,
        skipped: existingBranchIds.length,
        total: validBranches.length
    };
}

async function createProduct(payload) {
    if (!payload.category_id || !payload.name || payload.base_price === undefined) {
        throw new Error('Missing required fields');
    }

    if (payload.base_price <= 0) {
        throw new Error('Base price must be positive');
    }

    const product = readProduct(payload);
    const [id] = await productRepository().insert(product);
    
    if (product.is_global_available === 1) {
        await autoCreateBranchProducts(id, product.base_price);
    } else {
        if (payload.selected_branches && payload.selected_branches.length > 0) {
            await createBranchProductsForSelectedBranches(id, product.base_price, payload.selected_branches);
        }
    }
    
    return {
        id,
        ...product
    };
}

async function getManyProducts(query) {
    const { name, category_id, min_price, max_price, status, is_available, branch_id, page = 1, limit = 10 } = query;
    const paginator = new Paginator(page, limit);

    let queryBuilder;

    if (branch_id) {
        const branchId = parseInt(branch_id);
        queryBuilder = knex('products')
            .leftJoin('branch_products', function() {
                this.on('products.id', '=', 'branch_products.product_id')
                    .andOn('branch_products.branch_id', '=', branchId);
            })
            .join('categories', 'products.category_id', 'categories.id')
            .where('products.is_global_available', 1)
            .where('products.status', 'active')
            .where((builder) => {
                if (name) {
                    builder.where('products.name', 'like', `%${name}%`);
                }
                if (category_id) {
                    builder.where('products.category_id', category_id);
                }
                if (min_price) {
                    builder.where(function() {
                        this.where('branch_products.price', '>=', min_price)
                            .orWhere(function() {
                                this.whereNull('branch_products.price')
                                    .andWhere('products.base_price', '>=', min_price);
                            });
                    });
                }
                if (max_price) {
                    builder.where(function() {
                        this.where('branch_products.price', '<=', max_price)
                            .orWhere(function() {
                                this.whereNull('branch_products.price')
                                    .andWhere('products.base_price', '<=', max_price);
                            });
                    });
                }
                if (status) {
                    if (status === 'not_added') {
                        builder.whereNull('branch_products.id');
                    } else {
                        builder.where('branch_products.status', status);
                    }
                }
                if (is_available !== undefined) {
                    const available = is_available === 'true' || is_available === true ? 1 : 0;
                    if (available) {
                        builder.where(function() {
                            this.where('branch_products.is_available', 1)
                                .orWhereNull('branch_products.id');
                        });
                    } else {
                        builder.where('branch_products.is_available', 0);
                    }
                }
            })
            .select(
                knex.raw('count(products.id) OVER() AS recordCount'),
                'products.id',
                'products.name',
                'products.base_price',
                'products.description',
                'products.image',
                'products.is_global_available',
                'products.status as global_status',
                'products.created_at',
                'categories.name as category_name',
                'categories.id as category_id',
                
                'branch_products.id as branch_product_id',
                'branch_products.price as branch_price',
                'branch_products.is_available as branch_available',
                'branch_products.status as branch_status',
                'branch_products.notes as branch_notes',
                'branch_products.created_at as added_to_branch_at',
                
                knex.raw(`
                    CASE 
                        WHEN branch_products.id IS NULL THEN 'not_added'
                        WHEN branch_products.is_available = 0 THEN 'unavailable'
                        WHEN branch_products.status = 'discontinued' THEN 'discontinued'
                        WHEN branch_products.status = 'out_of_stock' THEN 'out_of_stock'
                        WHEN branch_products.status = 'temporarily_unavailable' THEN 'temporarily_unavailable'
                        ELSE 'available'
                    END as final_status
                `),
                
                knex.raw(`
                    COALESCE(branch_products.price, products.base_price) as display_price
                `)
            );
    } else {
        queryBuilder = productRepository()
            .join('categories', 'products.category_id', 'categories.id')
            .where((builder) => {
                if (name) {
                    builder.where('products.name', 'like', `%${name}%`);
                }
                if (category_id) {
                    builder.where('products.category_id', category_id);
                }
                if (min_price) {
                    builder.where('products.base_price', '>=', min_price);
                }
                if (max_price) {
                    builder.where('products.base_price', '<=', max_price);
                }
                if (status) {
                    builder.where('products.status', status);
                }
                if (is_available !== undefined) {
                    builder.where('products.is_global_available', is_available === 'true' || is_available === true ? 1 : 0);
                }
            })
            .select(
                knex.raw('count(products.id) OVER() AS recordCount'),
                'products.id',
                'products.name',
                'products.base_price',
                'products.description',
                'products.image',
                'products.is_global_available',
                'products.status',
                'products.created_at',
                'categories.name as category_name',
                'categories.id as category_id'
            );
    }

    let results = await queryBuilder
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
            'products.base_price',
            'products.description',
            'products.image',
            'products.is_global_available',
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

    if (update.base_price !== undefined) {
        const price = parseFloat(update.base_price);
        if (isNaN(price) || price <= 0) {
            throw new Error('Base price must be a positive number');
        }
    }

    if (update.status && !['active', 'inactive'].includes(update.status)) {
        throw new Error('Invalid status value');
    }

    if (update.category_id !== undefined) {
        const category = await knex('categories')
            .where('id', update.category_id)
            .first();
        if (!category) {
            throw new Error('Category not found');
        }
    }

    await productRepository().where('id', id).update(update);

    if (update.is_global_available !== undefined || update.status !== undefined) {
        await updateAllBranchProductsForGlobalChange(id, update);
    }

    return { ...existingProduct, ...update };
}

async function updateAllBranchProductsForGlobalChange(productId, globalChanges) {
    const updateFields = {};
    
    if (globalChanges.is_global_available === 0 || globalChanges.status === 'inactive') {
        updateFields.is_available = 0;
        updateFields.status = 'discontinued';
        updateFields.updated_at = new Date();
    }
    else if (globalChanges.is_global_available === 1 && globalChanges.status === 'active') {
        updateFields.is_available = 1;
        updateFields.status = 'available';
        updateFields.updated_at = new Date();
    }
    
    if (Object.keys(updateFields).length > 0) {
        await knex('branch_products')
            .where('product_id', productId)
            .update(updateFields);
    }
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

async function addProductToBranch(branchId, productId, branchProductData) {
    const branch = await knex('branches').where('id', branchId).first();
    if (!branch) {
        throw new Error('Branch not found');
    }

    const product = await knex('products').where('id', productId).first();
    if (!product) {
        throw new Error('Product not found');
    }

    const existingBranchProduct = await knex('branch_products')
        .where('branch_id', branchId)
        .where('product_id', productId)
        .first();

    if (existingBranchProduct) {
        throw new Error('Product already exists in this branch');
    }

    const [id] = await knex('branch_products').insert({
        branch_id: branchId,
        product_id: productId,
        price: branchProductData.price || product.base_price,
        is_available: branchProductData.is_available !== undefined ? branchProductData.is_available : 1,
        status: branchProductData.status || 'available',
        notes: branchProductData.notes || null
    });

    return getBranchProductById(id);
}

async function updateBranchProduct(branchProductId, updateData) {
    const existingBranchProduct = await knex('branch_products')
        .join('products', 'branch_products.product_id', 'products.id')
        .where('branch_products.id', branchProductId)
        .first();

    if (!existingBranchProduct) {
        throw new Error('Branch product not found');
    }

    if (existingBranchProduct.is_global_available === 0 || existingBranchProduct.status === 'inactive') {
        throw new Error('Cannot update branch product: Global product is disabled');
    }

    if (updateData.status === 'discontinued') {
        const pendingOrders = await knex('order_details')
            .join('orders', 'order_details.order_id', 'orders.id')
            .where('order_details.product_id', existingBranchProduct.product_id)
            .where('orders.branch_id', existingBranchProduct.branch_id)
            .whereIn('orders.status', ['pending', 'preparing'])
            .count('* as count')
            .first();
        
        if (pendingOrders.count > 0) {
            throw new Error('Cannot discontinue product: There are pending orders');
        }
    }

    const updateFields = {};
    if (updateData.price !== undefined) {
        if (updateData.price <= 0) {
            throw new Error('Price must be positive');
        }
        updateFields.price = updateData.price;
    }
    if (updateData.is_available !== undefined) updateFields.is_available = updateData.is_available;
    if (updateData.status !== undefined) {
        const validStatuses = ['available', 'out_of_stock', 'temporarily_unavailable', 'discontinued'];
        if (!validStatuses.includes(updateData.status)) {
            throw new Error('Invalid status value');
        }
        updateFields.status = updateData.status;
    }
    if (updateData.notes !== undefined) updateFields.notes = updateData.notes;

    if (Object.keys(updateFields).length === 0) {
        throw new Error('No valid fields to update');
    }

    updateFields.updated_at = new Date();

    await knex('branch_products')
        .where('id', branchProductId)
        .update(updateFields);

    return getBranchProductById(branchProductId);
}

async function removeProductFromBranch(branchId, productId) {
    const pendingOrders = await knex('order_details')
        .join('orders', 'order_details.order_id', 'orders.id')
        .where('order_details.product_id', productId)
        .where('orders.branch_id', branchId)
        .whereIn('orders.status', ['pending', 'preparing'])
        .count('* as count')
        .first();
    
    if (pendingOrders.count > 0) {
        throw new Error('Cannot remove product: There are pending orders');
    }

    const deletedCount = await knex('branch_products')
        .where('branch_id', branchId)
        .where('product_id', productId)
        .update({
            is_available: 0,
            status: 'discontinued',
            updated_at: new Date()
        });

    if (deletedCount === 0) {
        throw new Error('Product not found in this branch');
    }

    return { message: 'Product removed from branch successfully' };
}

module.exports = {
    createProduct,
    getManyProducts,
    getProductById,
    updateProduct,
    deleteProduct,
    addProductToBranch,
    updateBranchProduct,
    removeProductFromBranch,
    autoCreateBranchProducts,
    createBranchProductsForSelectedBranches,
    updateAllBranchProductsForGlobalChange,
};