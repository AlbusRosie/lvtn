const express = require('express');
const CategoryController = require('../controllers/CategoryController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();
const categoryController = new CategoryController();

router.get('/', categoryController.getAllCategories.bind(categoryController));
router.get('/with-count', categoryController.getCategoriesWithProductCount.bind(categoryController));
router.get('/:id', categoryController.getCategoryById.bind(categoryController));

router.use(verifyToken);

router.post('/', requireRole(['admin']), categoryController.createCategory.bind(categoryController));
router.put('/:id', requireRole(['admin']), categoryController.updateCategory.bind(categoryController));
router.delete('/:id', requireRole(['admin']), categoryController.deleteCategory.bind(categoryController));

module.exports = router; 