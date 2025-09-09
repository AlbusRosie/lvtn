const express = require('express');
const ProductController = require('../controllers/ProductController');
const AuthMiddleware = require('../middlewares/AuthMiddleware');
const { imageUpload } = require('../middlewares/AvatarUpload');
const { productUpload } = require('../middlewares/ProductUpload');

function setup(app) {
    const router = express.Router();

    router.get('/products', ProductController.getProducts);

    router.get('/products/available', ProductController.getAvailableProducts);

    router.get('/products/:id', ProductController.getProduct);

    router.get('/products/category/:categoryId', ProductController.getProductsByCategory);

    router.post('/products', AuthMiddleware.verifyToken, productUpload, ProductController.createProduct);

    router.put('/products/:id', AuthMiddleware.verifyToken, productUpload, ProductController.updateProduct);

    router.delete('/products/:id', AuthMiddleware.verifyToken, ProductController.deleteProduct);

    router.delete('/products', AuthMiddleware.verifyToken, ProductController.deleteAllProducts);

    app.use('/api', router);
}

module.exports = { setup };
