const ProductService = require('../services/ProductService');
const ProductOptionService = require('../services/ProductOptionService');
const JSend = require('../jsend');
const ApiError = require('../api-error');
const knex = require('../database/knex');

async function createProduct(req, res, next) {
    try {
        const requiredFields = ['category_id', 'name', 'base_price'];
        const missingFields = requiredFields.filter(field => !req.body[field]);

        if (missingFields.length > 0) {
            return next(new ApiError(400, `Missing required fields: ${missingFields.join(', ')}`));
        }

        if (req.body.base_price <= 0) {
            return next(new ApiError(400, 'Base price must be positive'));
        }

        const is_global_available = req.body.is_global_available === 'true' || req.body.is_global_available === true ? 1 : 0;
        
        let selected_branches = [];
        if (req.body.selected_branches) {
            if (typeof req.body.selected_branches === 'string') {
                try {
                    selected_branches = JSON.parse(req.body.selected_branches);
                } catch (e) {
                    selected_branches = req.body.selected_branches.split(',').map(id => parseInt(id.trim()));
                }
            } else if (Array.isArray(req.body.selected_branches)) {
                selected_branches = req.body.selected_branches.map(id => parseInt(id));
            }
        }

        if (is_global_available === 0 && selected_branches.length === 0) {
            return next(new ApiError(400, 'Vui lòng chọn ít nhất một chi nhánh để thêm sản phẩm'));
        }

        const product = await ProductService.createProduct({
            ...req.body,
            category_id: parseInt(req.body.category_id),
            base_price: parseFloat(req.body.base_price),
            is_global_available: is_global_available,
            image: req.file ? `/public/uploads/${req.file.filename}` : null,
            selected_branches: selected_branches,
        });

        res.status(201).json(JSend.success(product, 'Product created successfully'));
    } catch (error) {
        next(new ApiError(400, error.message));
    }
}

async function getProducts(req, res, next) {
    try {
        let result;
        if (req.query.branch_id) {
            result = await ProductService.getProductsByBranch(req.query);
        } else {
            result = await ProductService.getProducts(req.query);
        }
        res.json(JSend.success(result));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function getNotAddedProducts(req, res, next) {
    try {
        const result = await ProductService.getNotAddedProductsByBranch(req.query);
        res.json(JSend.success(result));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function getProduct(req, res, next) {
    try {
        const product = await ProductService.getProductById(req.params.id);
        if (!product) {
            return next(new ApiError(404, 'Product not found'));
        }
        const options = await ProductOptionService.getProductOptions(req.params.id);
        res.json(JSend.success({ product, options }));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function updateProduct(req, res, next) {
    try {
        if (req.body.price !== undefined) {
            const price = parseFloat(req.body.price);
            if (isNaN(price) || price <= 0) {
                return next(new ApiError(400, 'Price must be a positive number'));
            }
        }
        if (req.body.stock !== undefined) {
            const stock = parseInt(req.body.stock);
            if (isNaN(stock) || stock < 0) {
                return next(new ApiError(400, 'Stock must be a non-negative number'));
            }
        }

        if (req.body.status && !['active', 'inactive', 'out_of_stock'].includes(req.body.status)) {
            return next(new ApiError(400, 'Invalid status value'));
        }

        const updateData = { ...req.body };
        if (req.file) {
            updateData.image = `/public/uploads/${req.file.filename}`;
        }

        if (updateData.is_available !== undefined) {
            updateData.is_available = updateData.is_available === 'true' || updateData.is_available === true ? 1 : 0;
        }

        const { id } = req.params;
        const product = await ProductService.updateProduct(id, updateData);

        if (!product) {
            return next(new ApiError(404, 'Product not found'));
        }

        res.json(JSend.success(product, 'Product updated successfully'));
    } catch (error) {
        if (error.message === 'No valid fields to update') {
            return next(new ApiError(400, 'No changes detected. Please modify at least one field.'));
        }
        if (error.message === 'Stock must be greater than 0 when status is active') {
            return next(new ApiError(400, 'Số lượng sản phẩm phải lớn hơn 0 khi trạng thái là hoạt động'));
        }
        next(error);
    }
}

async function deleteProduct(req, res, next) {
    try {
        const product = await ProductService.deleteProduct(req.params.id);
        if (!product) {
            return next(new ApiError(404, 'Product not found'));
        }
        res.json(JSend.success(null, 'Product deleted successfully'));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function addProductToBranch(req, res, next) {
    try {
        const { branchId, productId } = req.params;
        const branchProductData = req.body;

        if (!branchProductData.price || branchProductData.price <= 0) {
            return next(new ApiError(400, 'Valid price is required'));
        }

        const result = await ProductService.addProductToBranch(
            parseInt(branchId), 
            parseInt(productId), 
            branchProductData
        );
        
        res.status(201).json(JSend.success(result, 'Product added to branch successfully'));
    } catch (error) {
        if (error.message === 'Branch not found' || error.message === 'Product not found') {
            return next(new ApiError(404, error.message));
        }
        if (error.message === 'Product already exists in this branch') {
            return next(new ApiError(409, error.message));
        }
        next(new ApiError(500, error.message));
    }
}

async function updateBranchProduct(req, res, next) {
    try {
        const { branchProductId } = req.params;
        const updateData = req.body;

        if (updateData.price !== undefined && updateData.price <= 0) {
            return next(new ApiError(400, 'Price must be positive'));
        }

        const result = await ProductService.updateBranchProduct(
            parseInt(branchProductId), 
            updateData
        );
        
        res.json(JSend.success(result, 'Branch product updated successfully'));
    } catch (error) {
        if (error.message === 'Branch product not found') {
            return next(new ApiError(404, error.message));
        }
        if (error.message === 'No valid fields to update') {
            return next(new ApiError(400, error.message));
        }
        next(new ApiError(500, error.message));
    }
}

async function removeProductFromBranch(req, res, next) {
    try {
        const { branchId, productId } = req.params;
        
        const result = await ProductService.removeProductFromBranch(
            parseInt(branchId), 
            parseInt(productId)
        );
        
        res.json(JSend.success(result));
    } catch (error) {
        if (error.message === 'Product not found in this branch') {
            return next(new ApiError(404, error.message));
        }
        next(new ApiError(500, error.message));
    }
}




async function getProductBranchPrice(req, res, next) {
    try {
        const { product_id, cart_id } = req.params;
        
        const cart = await knex('carts').where('id', cart_id).first();
        if (!cart) {
            return next(new ApiError(404, 'Cart not found'));
        }
        
        const branchProduct = await knex('branch_products')
            .where('branch_id', cart.branch_id)
            .where('product_id', product_id)
            .first();
            
        if (!branchProduct) {
            return next(new ApiError(404, 'Product not available in this branch'));
        }
        
        res.json(JSend.success({
            base_price: branchProduct.price,
            branch_id: cart.branch_id
        }));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

module.exports = {
    createProduct,
    getProducts,
    getNotAddedProducts,
    getProduct,
    getProductBranchPrice,
    updateProduct,
    deleteProduct,
    addProductToBranch,
    updateBranchProduct,
    removeProductFromBranch,
};
