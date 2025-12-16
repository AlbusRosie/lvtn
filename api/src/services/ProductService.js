const knex = require('../database/knex');
const Paginator = require('./Paginator');
const { unlink } = require('node:fs');
let io = null;

// Function to set io instance (called from server.js)
function setSocketIO(socketIO) {
    io = socketIO;
}
function productRepository() {
    return knex('products');
}
function readProduct(payload) {
    const product = {};
    const fields = [
        'category_id',
        'name',
        'base_price',
        'description',
        'image',
        'is_global_available',
        'status',
    ];
    for (const field of fields) {
        if (Object.prototype.hasOwnProperty.call(payload, field)) {
            product[field] = payload[field];
        }
    }
    return product;
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
            created_at: new Date()
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
            created_at: new Date()
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
    const { branch_id, page = 1, limit = 20, include_all = false, category_id } = query;
    const paginator = new Paginator(page, limit);
    if (!branch_id) {
        throw new Error('Branch ID is required');
    }
    const branchId = parseInt(branch_id);
    const includeAll = include_all === 'true' || include_all === true;
    const queryBuilder = knex('products')
        .leftJoin('categories', 'products.category_id', 'categories.id')
        .leftJoin('branch_products', function() {
            this.on('products.id', '=', 'branch_products.product_id')
                .andOn('branch_products.branch_id', '=', branchId);
        });
    if (!includeAll) {
        queryBuilder.whereNotNull('branch_products.id');
    }
    if (category_id) {
        queryBuilder.where('products.category_id', parseInt(category_id));
    }
    queryBuilder.select(
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
async function getAvailableProducts(query) {
    const { branch_id, page = 1, limit = 100 } = query;
    const paginator = new Paginator(page, limit);
    if (!branch_id) {
        throw new Error('Branch ID is required');
    }
    const branchId = parseInt(branch_id);
    const queryBuilder = knex('products')
        .innerJoin('categories', 'products.category_id', 'categories.id')
        .innerJoin('branch_products', function() {
            this.on('products.id', '=', 'branch_products.product_id')
                .andOn('branch_products.branch_id', '=', branchId);
        })
        .where('products.status', 'active')
        .where('branch_products.is_available', 1)
        .where('branch_products.status', 'available')
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
            'categories.image as category_image',
            'branch_products.id as branch_product_id',
            'branch_products.price as price',
            'branch_products.is_available as is_available',
            'branch_products.status as status',
            'branch_products.notes as notes',
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
    
    const updatedProduct = { ...existingProduct, ...update };
    
    // ✅ EMIT REAL-TIME NOTIFICATION for product updates
    if (io && (update.base_price !== undefined || update.status !== undefined)) {
        // Get all branch_products for this product
        const branchProducts = await knex('branch_products')
            .where('product_id', id)
            .select('branch_id', 'id');
        
        // Notify all branches that have this product
        branchProducts.forEach(bp => {
            io.to(`branch:${bp.branch_id}`).emit('product-updated', {
                productId: id,
                branchId: bp.branch_id,
                branchProductId: bp.id,
                basePrice: update.base_price !== undefined ? update.base_price : existingProduct.base_price,
                status: update.status !== undefined ? update.status : existingProduct.status,
                timestamp: new Date().toISOString()
            });
        });
        
        // Notify admin
        io.to('admin').emit('product-updated', {
            productId: id,
            basePrice: update.base_price !== undefined ? update.base_price : existingProduct.base_price,
            status: update.status !== undefined ? update.status : existingProduct.status,
            timestamp: new Date().toISOString()
        });
    }
    
    return updatedProduct;
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
                notes: branchProductData.notes || null
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
    if (updateData.status === 'discontinued') {
        const pendingOrders = await knex('order_details')
            .join('orders', 'order_details.order_id', 'orders.id')
            .join('branch_products', 'order_details.branch_product_id', 'branch_products.id')
            .where('branch_products.product_id', existingBranchProduct.product_id)
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
    await knex('branch_products')
        .where('id', branchProductId)
        .update(updateFields);
    
    const updatedBranchProduct = await knex('branch_products')
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
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io && updatedBranchProduct) {
        // Notify branch staff
        io.to(`branch:${updatedBranchProduct.branch_id}`).emit('product-price-updated', {
            branchProductId: branchProductId,
            productId: updatedBranchProduct.product_id,
            branchId: updatedBranchProduct.branch_id,
            price: updatedBranchProduct.price,
            isAvailable: updatedBranchProduct.is_available,
            status: updatedBranchProduct.status,
            productName: updatedBranchProduct.name,
            timestamp: new Date().toISOString()
        });
        
        // Notify admin
        io.to('admin').emit('product-price-updated', {
            branchProductId: branchProductId,
            productId: updatedBranchProduct.product_id,
            branchId: updatedBranchProduct.branch_id,
            price: updatedBranchProduct.price,
            isAvailable: updatedBranchProduct.is_available,
            status: updatedBranchProduct.status,
            productName: updatedBranchProduct.name,
            timestamp: new Date().toISOString()
        });
    }
    
    return updatedBranchProduct;
}
async function removeProductFromBranch(branchId, productId) {
    const pendingOrders = await knex('order_details')
        .join('orders', 'order_details.order_id', 'orders.id')
        .join('branch_products', 'order_details.branch_product_id', 'branch_products.id')
        .where('branch_products.product_id', productId)
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
async function getProductOptions(productId) {
    const optionTypes = await knex('product_option_types')
        .where('product_id', productId)
        .orderBy('display_order')
        .select('*');
    const results = [];
    for (const optionType of optionTypes) {
        const values = await knex('product_option_values')
            .where('option_type_id', optionType.id)
            .orderBy('display_order')
            .select('*');
        results.push({
            ...optionType,
            values
        });
    }
    return results;
}
async function createOptionType(productId, optionTypeData) {
    const { name, type = 'select', required = false, display_order = 0 } = optionTypeData;
    const [id] = await knex('product_option_types')
        .insert({
            product_id: productId,
            name,
            type,
            required,
            display_order
        });
    return await knex('product_option_types').where('id', id).first();
}
async function createOptionValue(optionTypeId, optionValueData) {
    const { value, price_modifier = 0, display_order = 0 } = optionValueData;
    const [id] = await knex('product_option_values')
        .insert({
            option_type_id: optionTypeId,
            value,
            price_modifier,
            display_order
        });
    return await knex('product_option_values').where('id', id).first();
}
async function updateOptionType(optionTypeId, updateData) {
    await knex('product_option_types')
        .where('id', optionTypeId)
        .update(updateData);
    return await knex('product_option_types').where('id', optionTypeId).first();
}
async function updateOptionValue(optionValueId, updateData) {
    const { value, price_modifier, display_order } = updateData;
    await knex('product_option_values')
        .where('id', optionValueId)
        .update({ value, price_modifier, display_order });
    return await knex('product_option_values').where('id', optionValueId).first();
}
async function deleteOptionType(optionTypeId) {
    const deletedCount = await knex('product_option_types')
        .where('id', optionTypeId)
        .del();
    return deletedCount > 0;
}
async function deleteOptionValue(optionValueId) {
    const deletedCount = await knex('product_option_values')
        .where('id', optionValueId)
        .del();
    return deletedCount > 0;
}
async function createProductOption(productId, optionData) {
    const { name, type, required, display_order, values = [] } = optionData;
    const optionType = await createOptionType(productId, {
        name, type, required, display_order
    });
    const optionValues = [];
    for (const valueData of values) {
        const value = await createOptionValue(optionType.id, valueData);
        optionValues.push(value);
    }
    return {
        ...optionType,
        values: optionValues
    };
}
async function updateProductOption(optionTypeId, optionData) {
    const { name, type, required, display_order, values = [] } = optionData;
    await updateOptionType(optionTypeId, {
        name, type, required, display_order
    });
    await knex('product_option_values')
        .where('option_type_id', optionTypeId)
        .del();
    const optionValues = [];
    for (const valueData of values) {
        const value = await createOptionValue(optionTypeId, valueData);
        optionValues.push(value);
    }
    return {
        id: optionTypeId,
        name, type, required, display_order,
        values: optionValues
    };
}
async function getOptionTypeWithValues(optionTypeId) {
    const optionType = await knex('product_option_types')
        .where('id', optionTypeId)
        .first();
    if (!optionType) return null;
    const values = await knex('product_option_values')
        .where('option_type_id', optionTypeId)
        .orderBy('display_order');
    return {
        ...optionType,
        values
    };
}
module.exports = {
    createProduct,
    getProducts,
    getProductsByBranch,
    getAvailableProducts,
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
    getProductOptions,
    createOptionType,
    createOptionValue,
    updateOptionType,
    updateOptionValue,
    deleteOptionType,
    deleteOptionValue,
    createProductOption,
    setSocketIO,
    updateProductOption,
    getOptionTypeWithValues
};