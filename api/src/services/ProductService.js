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

async function getProductsByBranch(query) {
    const { branch_id, page = 1, limit = 20 } = query;
    const paginator = new Paginator(page, limit);

    if (!branch_id) {
        throw new Error('Branch ID is required');
    }

    const branchId = parseInt(branch_id);
    
    const queryBuilder = knex('products')
        .leftJoin('categories', 'products.category_id', 'categories.id')
        .leftJoin('branch_products', function() {
            this.on('products.id', '=', 'branch_products.product_id')
                .andOn('branch_products.branch_id', '=', branchId);
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
                    WHEN branch_products.status = 'out_of_stock' THEN 'out_of_stock'
                    WHEN branch_products.status = 'temporarily_unavailable' THEN 'temporarily_unavailable'
                    ELSE 'available'
                END as final_status
            `),
            
            knex.raw(`
                COALESCE(branch_products.price, products.base_price) as display_price
            `)
        );

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

async function getProducts(query) {
    const { page = 1, limit = 20 } = query;
    const paginator = new Paginator(page, limit);
    
    const queryBuilder = knex('products')
        .leftJoin('categories', 'products.category_id', 'categories.id')
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
            knex.raw('products.base_price as display_price')
        );

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

async function getNotAddedProductsByBranch(query) {
    const { branch_id, page = 1, limit = 20 } = query;
    const paginator = new Paginator(page, limit);

    if (!branch_id) {
        throw new Error('Branch ID is required');
    }

    const branchId = parseInt(branch_id);
    
    const queryBuilder = knex('products')
        .leftJoin('categories', 'products.category_id', 'categories.id')
        .leftJoin('branch_products', function() {
            this.on('products.id', '=', 'branch_products.product_id')
                .andOn('branch_products.branch_id', '=', branchId);
        })
        .whereNull('branch_products.id')
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
            knex.raw('products.base_price as display_price')
        );

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
    if (globalChanges.is_global_available === 0 || globalChanges.status === 'inactive') {
        await knex('branch_products')
            .where('product_id', productId)
            .del();
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

    let id;
    if (existingBranchProduct) {
        await knex('branch_products')
            .where('id', existingBranchProduct.id)
            .update({
                price: branchProductData.price || product.base_price,
                is_available: branchProductData.is_available !== undefined ? branchProductData.is_available : 1,
                status: branchProductData.status || 'available',
                notes: branchProductData.notes || null,
                updated_at: new Date()
            });
        id = existingBranchProduct.id;
    } else {
        [id] = await knex('branch_products').insert({
            branch_id: branchId,
            product_id: productId,
            price: branchProductData.price || product.base_price,
            is_available: branchProductData.is_available !== undefined ? branchProductData.is_available : 1,
            status: branchProductData.status || 'available',
            notes: branchProductData.notes || null
        });
    }

    return await knex('branch_products')
        .join('products', 'branch_products.product_id', 'products.id')
        .join('categories', 'products.category_id', 'categories.id')
        .where('branch_products.id', id)
        .select(
            'branch_products.*',
            'products.name',
            'products.description',
            'products.base_price',
            'products.image',
            'products.status as product_status',
            'categories.name as category_name'
        )
        .first();
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

    // Nếu status là discontinued, xóa luôn record thay vì update
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

        await knex('branch_products')
            .where('id', branchProductId)
            .del();

        return { message: 'Product removed from branch successfully' };
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
        const validStatuses = ['available', 'out_of_stock', 'temporarily_unavailable'];
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

    return await knex('branch_products')
        .join('products', 'branch_products.product_id', 'products.id')
        .join('categories', 'products.category_id', 'categories.id')
        .where('branch_products.id', branchProductId)
        .select(
            'branch_products.*',
            'products.name',
            'products.description',
            'products.base_price',
            'products.image',
            'products.status as product_status',
            'categories.name as category_name'
        )
        .first();
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
        .del();

    if (deletedCount === 0) {
        throw new Error('Product not found in this branch');
    }

    return { message: 'Product removed from branch successfully' };
}

module.exports = {
    createProduct,
    getProducts,
    getProductsByBranch,
    getNotAddedProductsByBranch,
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