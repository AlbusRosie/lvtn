const ProductService = require('../services/ProductService');
const JSend = require('../jsend');
const ApiError = require('../api-error');

async function createProduct(req, res, next) {
    try {
        // Validate required fields
        const requiredFields = ['category_id', 'name', 'price', 'stock'];
        const missingFields = requiredFields.filter(field => !req.body[field]);
        
        if (missingFields.length > 0) {
            return next(new ApiError(400, `Missing required fields: ${missingFields.join(', ')}`));
        }

        // Validate price and stock
        if (req.body.price <= 0) {
            return next(new ApiError(400, 'Price must be positive'));
        }
        if (req.body.stock < 0) {
            return next(new ApiError(400, 'Stock must be non-negative'));
        }

        const product = await ProductService.createProduct({
            ...req.body,
            category_id: parseInt(req.body.category_id),
            stock: parseInt(req.body.stock),
            price: parseFloat(req.body.price),
            is_available: req.body.is_available === 'true' || req.body.is_available === true ? 1 : 0,
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
        // Validate price and stock if provided
        if (req.body.price !== undefined && req.body.price <= 0) {
            return next(new ApiError(400, 'Price must be positive'));
        }
        if (req.body.stock !== undefined && req.body.stock < 0) {
            return next(new ApiError(400, 'Stock must be non-negative'));
        }

        const updateData = {
            ...req.body,
            image: req.file ? `/public/uploads/${req.file.filename}` : null,
        };

        // Convert data types if provided
        if (req.body.category_id !== undefined) {
            updateData.category_id = parseInt(req.body.category_id);
        }
        if (req.body.stock !== undefined) {
            updateData.stock = parseInt(req.body.stock);
        }
        if (req.body.price !== undefined) {
            updateData.price = parseFloat(req.body.price);
        }
        if (req.body.is_available !== undefined) {
            updateData.is_available = req.body.is_available === 'true' || req.body.is_available === true ? 1 : 0;
        }

        const product = await ProductService.updateProduct(req.params.id, updateData);
        if (!product) {
            return next(new ApiError(404, 'Product not found'));
        }
        res.json(JSend.success(product, 'Product updated successfully'));
    } catch (error) {
        next(new ApiError(400, error.message));
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
