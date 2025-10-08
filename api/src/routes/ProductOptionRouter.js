const express = require('express');
const ProductOptionController = require('../controllers/ProductOptionController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken } = require('../middlewares/AuthMiddleware');

const router = express.Router({ mergeParams: true });

module.exports.setup = (app) => {
    app.use('/api/products/:productId/options', router);

    router.get('/', ProductOptionController.getProductOptions);
    router.get('/:optionTypeId', ProductOptionController.getProductOption);
    
    router.post('/', verifyToken, ProductOptionController.createProductOption);
    router.put('/:optionTypeId', verifyToken, ProductOptionController.updateProductOption);
    router.delete('/:optionTypeId', verifyToken, ProductOptionController.deleteProductOption);

    router.all('/', methodNotAllowed);
    router.all('/:optionTypeId', methodNotAllowed);
};
