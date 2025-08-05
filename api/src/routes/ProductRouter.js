const express = require('express');
const ProductController = require('../controllers/ProductController');
const AuthMiddleware = require('../middlewares/AuthMiddleware');
const { imageUpload } = require('../middlewares/AvatarUpload');

function setup(app) {
    const router = express.Router();

    /**
     * @swagger
     * components:
     *   schemas:
     *     Product:
     *       type: object
     *       required:
     *         - category_id
     *         - name
     *         - price
     *         - stock
     *       properties:
     *         id:
     *           type: integer
     *           description: ID tự động của sản phẩm
     *         category_id:
     *           type: integer
     *           description: ID của danh mục
     *         name:
     *           type: string
     *           description: Tên sản phẩm
     *         price:
     *           type: number
     *           format: decimal
     *           description: Giá sản phẩm
     *         stock:
     *           type: integer
     *           description: Số lượng tồn kho
     *         description:
     *           type: string
     *           description: Mô tả sản phẩm
     *         image:
     *           type: string
     *           description: Đường dẫn ảnh sản phẩm
     *         is_available:
     *           type: boolean
     *           description: Trạng thái có sẵn
     *         created_at:
     *           type: string
     *           format: date-time
     *           description: Thời gian tạo
     *         category_name:
     *           type: string
     *           description: Tên danh mục
     */

    /**
     * @swagger
     * /api/products:
     *   get:
     *     summary: Lấy danh sách sản phẩm
     *     tags: [Products]
     *     parameters:
     *       - in: query
     *         name: name
     *         schema:
     *           type: string
     *         description: Tìm kiếm theo tên sản phẩm
     *       - in: query
     *         name: category_id
     *         schema:
     *           type: integer
     *         description: Lọc theo danh mục
     *       - in: query
     *         name: min_price
     *         schema:
     *           type: number
     *         description: Giá tối thiểu
     *       - in: query
     *         name: max_price
     *         schema:
     *           type: number
     *         description: Giá tối đa
     *       - in: query
     *         name: is_available
     *         schema:
     *           type: boolean
     *         description: Lọc theo trạng thái có sẵn
     *       - in: query
     *         name: page
     *         schema:
     *           type: integer
     *           default: 1
     *         description: Trang hiện tại
     *       - in: query
     *         name: limit
     *         schema:
     *           type: integer
     *           default: 10
     *         description: Số lượng sản phẩm mỗi trang
     *     responses:
     *       200:
     *         description: Thành công
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   example: success
     *                 data:
     *                   type: object
     *                   properties:
     *                     metadata:
     *                       type: object
     *                     products:
     *                       type: array
     *                       items:
     *                         $ref: '#/components/schemas/Product'
     */
    router.get('/products', ProductController.getProducts);

    /**
     * @swagger
     * /api/products/available:
     *   get:
     *     summary: Lấy danh sách sản phẩm có sẵn
     *     tags: [Products]
     *     parameters:
     *       - in: query
     *         name: name
     *         schema:
     *           type: string
     *         description: Tìm kiếm theo tên sản phẩm
     *       - in: query
     *         name: category_id
     *         schema:
     *           type: integer
     *         description: Lọc theo danh mục
     *       - in: query
     *         name: min_price
     *         schema:
     *           type: number
     *         description: Giá tối thiểu
     *       - in: query
     *         name: max_price
     *         schema:
     *           type: number
     *         description: Giá tối đa
     *       - in: query
     *         name: page
     *         schema:
     *           type: integer
     *           default: 1
     *         description: Trang hiện tại
     *       - in: query
     *         name: limit
     *         schema:
     *           type: integer
     *           default: 10
     *         description: Số lượng sản phẩm mỗi trang
     *     responses:
     *       200:
     *         description: Thành công
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   example: success
     *                 data:
     *                   type: object
     *                   properties:
     *                     metadata:
     *                       type: object
     *                     products:
     *                       type: array
     *                       items:
     *                         $ref: '#/components/schemas/Product'
     */
    router.get('/products/available', ProductController.getAvailableProducts);

    /**
     * @swagger
     * /api/products/{id}:
     *   get:
     *     summary: Lấy thông tin sản phẩm theo ID
     *     tags: [Products]
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *         description: ID của sản phẩm
     *     responses:
     *       200:
     *         description: Thành công
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   example: success
     *                 data:
     *                   $ref: '#/components/schemas/Product'
     *       404:
     *         description: Không tìm thấy sản phẩm
     */
    router.get('/products/:id', ProductController.getProduct);

    /**
     * @swagger
     * /api/products/category/{categoryId}:
     *   get:
     *     summary: Lấy sản phẩm theo danh mục
     *     tags: [Products]
     *     parameters:
     *       - in: path
     *         name: categoryId
     *         required: true
     *         schema:
     *           type: integer
     *         description: ID của danh mục
     *     responses:
     *       200:
     *         description: Thành công
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   example: success
     *                 data:
     *                   type: array
     *                   items:
     *                     $ref: '#/components/schemas/Product'
     */
    router.get('/products/category/:categoryId', ProductController.getProductsByCategory);

    /**
     * @swagger
     * /api/products:
     *   post:
     *     summary: Tạo sản phẩm mới
     *     tags: [Products]
     *     security:
     *       - bearerAuth: []
     *     requestBody:
     *       required: true
     *       content:
     *         multipart/form-data:
     *           schema:
     *             type: object
     *             required:
     *               - category_id
     *               - name
     *               - price
     *               - stock
     *             properties:
     *               category_id:
     *                 type: integer
     *                 description: ID của danh mục
     *               name:
     *                 type: string
     *                 description: Tên sản phẩm
     *               price:
     *                 type: number
     *                 format: decimal
     *                 description: Giá sản phẩm
     *               stock:
     *                 type: integer
     *                 description: Số lượng tồn kho
     *               description:
     *                 type: string
     *                 description: Mô tả sản phẩm
     *               is_available:
     *                 type: boolean
     *                 description: Trạng thái có sẵn
     *               imageFile:
     *                 type: string
     *                 format: binary
     *                 description: Ảnh sản phẩm
     *     responses:
     *       201:
     *         description: Tạo sản phẩm thành công
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   example: success
     *                 data:
     *                   $ref: '#/components/schemas/Product'
     *                 message:
     *                   type: string
     *                   example: Product created successfully
     *       400:
     *         description: Dữ liệu không hợp lệ
     *       401:
     *         description: Không có quyền truy cập
     */
    router.post('/products', AuthMiddleware.verifyToken, imageUpload, ProductController.createProduct);

    /**
     * @swagger
     * /api/products/{id}:
     *   put:
     *     summary: Cập nhật sản phẩm
     *     tags: [Products]
     *     security:
     *       - bearerAuth: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *         description: ID của sản phẩm
     *     requestBody:
     *       required: true
     *       content:
     *         multipart/form-data:
     *           schema:
     *             type: object
     *             properties:
     *               category_id:
     *                 type: integer
     *                 description: ID của danh mục
     *               name:
     *                 type: string
     *                 description: Tên sản phẩm
     *               price:
     *                 type: number
     *                 format: decimal
     *                 description: Giá sản phẩm
     *               stock:
     *                 type: integer
     *                 description: Số lượng tồn kho
     *               description:
     *                 type: string
     *                 description: Mô tả sản phẩm
     *               is_available:
     *                 type: boolean
     *                 description: Trạng thái có sẵn
     *               imageFile:
     *                 type: string
     *                 format: binary
     *                 description: Ảnh sản phẩm
     *     responses:
     *       200:
     *         description: Cập nhật thành công
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   example: success
     *                 data:
     *                   $ref: '#/components/schemas/Product'
     *                 message:
     *                   type: string
     *                   example: Product updated successfully
     *       400:
     *         description: Dữ liệu không hợp lệ
     *       401:
     *         description: Không có quyền truy cập
     *       404:
     *         description: Không tìm thấy sản phẩm
     */
    router.put('/products/:id', AuthMiddleware.verifyToken, imageUpload, ProductController.updateProduct);

    /**
     * @swagger
     * /api/products/{id}:
     *   delete:
     *     summary: Xóa sản phẩm
     *     tags: [Products]
     *     security:
     *       - bearerAuth: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *         description: ID của sản phẩm
     *     responses:
     *       200:
     *         description: Xóa thành công
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   example: success
     *                 message:
     *                   type: string
     *                   example: Product deleted successfully
     *       401:
     *         description: Không có quyền truy cập
     *       404:
     *         description: Không tìm thấy sản phẩm
     */
    router.delete('/products/:id', AuthMiddleware.verifyToken, ProductController.deleteProduct);

    /**
     * @swagger
     * /api/products:
     *   delete:
     *     summary: Xóa tất cả sản phẩm
     *     tags: [Products]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       200:
     *         description: Xóa thành công
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   example: success
     *                 message:
     *                   type: string
     *                   example: All products deleted successfully
     *       401:
     *         description: Không có quyền truy cập
     */
    router.delete('/products', AuthMiddleware.verifyToken, ProductController.deleteAllProducts);

    app.use('/api', router);
}

module.exports = { setup };
