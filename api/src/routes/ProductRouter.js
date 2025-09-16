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
    router.get('/:id', ProductController.getProduct);
    
    router.all('/', methodNotAllowed);
    router.all('/branches/:branchId/products/:productId', methodNotAllowed);
    router.all('/:id', methodNotAllowed);

    // Admin nhé
    router.use(verifyToken);

    router.post('/', productUpload, ProductController.createProduct);
    router.put('/:id', productUpload, ProductController.updateProduct);
    router.delete('/:id', ProductController.deleteProduct);
    router.post('/branches/:branchId/products/:productId', ProductController.addProductToBranch);
    router.put('/branch-products/:branchProductId', ProductController.updateBranchProduct);
    router.delete('/branches/:branchId/products/:productId', ProductController.removeProductFromBranch);
    
    router.all('/:id', methodNotAllowed);
}
