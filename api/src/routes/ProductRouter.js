const express = require('express');
const ProductController = require('../controllers/ProductController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken } = require('../middlewares/AuthMiddleware');
const { productUpload } = require('../middlewares/ProductUpload');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/products', router);

    // Public
    router.get('/', ProductController.getProducts);
    router.get('/available', ProductController.getAvailableProducts);
    router.get('/category/:categoryId', ProductController.getProductsByCategory);
    router.get('/branches/active', ProductController.getActiveBranches);
    router.get('/branches/:branchId/products', ProductController.getProductsByBranch);
    router.get('/branch-products/:branchProductId', ProductController.getBranchProduct);
    router.get('/:id', ProductController.getProduct);
    
    router.all('/', methodNotAllowed);
    router.all('/available', methodNotAllowed);
    router.all('/category/:categoryId', methodNotAllowed);
    router.all('/branches/active', methodNotAllowed);
    router.all('/branches/:branchId/products', methodNotAllowed);
    router.all('/branch-products/:branchProductId', methodNotAllowed);
    router.all('/branches/:branchId/products/:productId', methodNotAllowed);
    router.all('/:id', methodNotAllowed);

    // Admin nhé
    router.use(verifyToken);

    router.post('/', productUpload, ProductController.createProduct);
    router.put('/:id', productUpload, ProductController.updateProduct);
    router.delete('/:id', ProductController.deleteProduct);
    router.delete('/', ProductController.deleteAllProducts);
    router.post('/branches/:branchId/products/:productId', ProductController.addProductToBranch);
    router.put('/branch-products/:branchProductId', ProductController.updateBranchProduct);
    router.delete('/branches/:branchId/products/:productId', ProductController.removeProductFromBranch);
    
    router.all('/:id', methodNotAllowed);
}
