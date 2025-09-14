const express = require('express');
const CategoryController = require('../controllers/CategoryController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();

router.get('/', CategoryController.getAllCategories);

router.get('/with-count', CategoryController.getCategoriesWithProductCount);

router.get('/:id', CategoryController.getCategoryById);

router.use(verifyToken);

router.post('/', requireRole(['admin']), CategoryController.createCategory);

router.put('/:id', requireRole(['admin']), CategoryController.updateCategory);

router.delete('/:id', requireRole(['admin']), CategoryController.deleteCategory);

module.exports = router;