const express = require('express');
const CategoryController = require('../controllers/CategoryController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');
const { optionalCategoryImageUpload } = require('../middlewares/CategoryUpload');

const router = express.Router();

module.exports.setup = (app) => {
    app.use('/api/categories', router);

    router.get('/', CategoryController.getAllCategories);
    router.get('/with-count', CategoryController.getCategoriesWithProductCount);
    router.get('/:id', CategoryController.getCategoryById);

    router.use(verifyToken);
    router.use(requireRole(['admin']));
    router.post('/', optionalCategoryImageUpload, CategoryController.createCategory);
    router.put('/:id', optionalCategoryImageUpload, CategoryController.updateCategory);
    router.delete('/:id', CategoryController.deleteCategory);
    
    router.all('/', methodNotAllowed);
    router.all('/with-count', methodNotAllowed);
    router.all('/:id', methodNotAllowed);
}