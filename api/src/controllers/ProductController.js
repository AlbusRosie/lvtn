const ProductService = require('../services/ProductService');
const JSend = require('../jsend');
const ApiError = require('../api-error');

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

        const product = await ProductService.createProduct({
            ...req.body,
            category_id: parseInt(req.body.category_id),
            base_price: parseFloat(req.body.base_price),
            is_global_available: is_global_available,
            image: req.file ? `/public/uploads/${req.file.filename}` : null,
        });

        res.status(201).json(JSend.success(product, 'Product created successfully'));
    } catch (error) {
        next(new ApiError(400, error.message));
    }
}

async function getProducts(req, res, next) {
    try {
        const result = await ProductService.getManyProducts(req.query);
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
        res.json(JSend.success(product));
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

async function deleteAllProducts(req, res, next) {
    try {
        await ProductService.deleteAllProducts();
        res.json(JSend.success(null, 'All products deleted successfully'));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function getProductsByCategory(req, res, next) {
    try {
        const products = await ProductService.getProductsByCategory(req.params.categoryId);
        res.json(JSend.success(products));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

async function getAvailableProducts(req, res, next) {
    try {
        const products = await ProductService.getAvailableProducts(req.query);
        res.json(JSend.success(products));
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}

module.exports = {
    createProduct,
    getProducts,
    getProduct,
    updateProduct,
    deleteProduct,
    deleteAllProducts,
    getProductsByCategory,
    getAvailableProducts,
};
