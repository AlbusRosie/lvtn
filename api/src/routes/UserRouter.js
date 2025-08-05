const express = require('express');
const UserController = require('../controllers/UserController');
const { methodNotAllowed } = require('../controllers/ErrorController');
const { avatarUpload } = require('../middlewares/AvatarUpload');
const router = express.Router();
const { verifyToken } = require('../middlewares/AuthMiddleware');

module.exports.setup = (app) => {
    app.use('/api/users', router);

    /**
     * @swagger
     * /api/users/login:
     *   post:
     *     summary: Login user
     *     description: Login with username and password
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required:
     *               - username
     *               - password
     *             properties:
     *               username:
     *                 type: string
     *               password:
     *                 type: string
     *     tags:
     *       - users
     *     responses:
     *       200:
     *         description: Login successful
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   enum: [success]
     *                 data:
     *                   type: object
     *                   properties:
     *                     token:
     *                       type: string
     *                     user:
     *                       $ref: '#/components/schemas/User'
     *       401:
     *         description: Invalid credentials
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     *       500:
     *         description: Internal server error
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     */
    router.post('/login', UserController.login);

    /**
     * @swagger
     * /api/users:
     *   get:
     *     summary: Get all users
     *     description: Get all users with optional filtering
     *     parameters:
     *       - in: query
     *         name: favorite
     *         schema:
     *           type: boolean
     *         description: Filter by favorite status
     *       - in: query
     *         name: name
     *         schema:
     *           type: string
     *         description: Filter by user name
     *       - in: query
     *         name: phone
     *         schema:
     *           type: string
     *         description: Filter by phone number
     *       - in: query
     *         name: role_id
     *         schema:
     *           type: integer
     *         description: Filter by role ID
     *       - $ref: '#/components/parameters/limitParam'
     *       - $ref: '#/components/parameters/pageParam'
     *     tags:
     *       - users
     *     responses:
     *       200:
     *         description: A list of users
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                  status:
     *                    type: string
     *                    description: The status of the response
     *                    enum: [success]
     *                  data:
     *                    type: object
     *                    properties:
     *                      users:
     *                        type: array
     *                        items:
     *                          $ref: '#/components/schemas/User'
     *                      metadata:
     *                        $ref: '#/components/schemas/PaginationMetadata'
     *       500:
     *         description: Internal server error
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     */
    router.get('/', verifyToken, UserController.getUsersByFilter);

    /**
     * @swagger
     * /api/users/register:
     *   post:
     *     summary: Create a new user
     *     description: Create a new user with the given information
     *     requestBody:
     *       required: true
     *       content:
     *         multipart/form-data:
     *           schema:
     *             $ref: '#/components/schemas/User'
     *     tags:
     *       - users
     *     responses:
     *       201:
     *         description: A user registered
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                  status:
     *                    type: string
     *                    description: The status of the response
     *                    enum: [success]
     *                  data:
     *                    type: object
     *                    properties:
     *                      user:
     *                        $ref: '#/components/schemas/User'
     *       400:
     *         description: Bad request - Missing required fields or invalid data
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     *       500:
     *         description: Internal server error
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     */
    router.post('/register', avatarUpload, UserController.createUser);

    /**
     * @swagger
     * /api/users:
     *   delete:
     *     summary: Delete all users
     *     description: Delete all users
     *     tags:
     *       - users
     *     responses:
     *       200:
     *         description: All users deleted
     *         $ref: '#/components/responses/200NoData'
     *       500:
     *         description: Internal server error
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     */
    router.delete('/', verifyToken, UserController.deleteAllUsers);
    router.all('/', methodNotAllowed);

    /**
     * @swagger
     * /api/users/{id}:
     *   get:
     *     summary: Get a user by ID
     *     description: Get a user by ID
     *     parameters:
     *       - $ref: '#/components/parameters/userIdParam'
     *     tags:
     *       - users
     *     responses:
     *       200:
     *         description: A user
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   description: The status of the response
     *                   enum: [success]
     *                 data:
     *                   type: object
     *                   properties:
     *                     user:
     *                       $ref: '#/components/schemas/User'
     *       404:
     *         description: User not found
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     *       500:
     *         description: Internal server error
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     */
    router.get('/:id', verifyToken, UserController.getUser);

    /**
     * @swagger
     * /api/users/{id}:
     *   put:
     *     summary: Update a user by ID
     *     description: Update a user by ID
     *     parameters:
     *       - $ref: '#/components/parameters/userIdParam'
     *     requestBody:
     *       required: true
     *       content:
     *         multipart/form-data:
     *           schema:
     *             $ref: '#/components/schemas/User'
     *     tags:
     *       - users
     *     responses:
     *       200:
     *         description: A user updated
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 status:
     *                   type: string
     *                   description: The status of the response
     *                   enum: [success]
     *                 data:
     *                   type: object
     *                   properties:
     *                     user:
     *                       $ref: '#/components/schemas/User'
     *       400:
     *         description: Bad request - No data to update or invalid data
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     *       404:
     *         description: User not found
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     *       500:
     *         description: Internal server error
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     */
    router.put('/:id',verifyToken,avatarUpload, UserController.updateUser);

    /**
     * @swagger
     * /api/users/{id}:
     *   delete:
     *     summary: Delete a user by ID
     *     description: Delete a user by ID
     *     parameters:
     *       - $ref: '#/components/parameters/userIdParam'
     *     tags:
     *       - users
     *     responses:
     *       200:
     *         description: A user deleted
     *         $ref: '#/components/responses/200NoData'
     *       404:
     *         description: User not found
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     *       500:
     *         description: Internal server error
     *         content:
     *           application/json:
     *             schema:
     *               $ref: '#/components/schemas/Error'
     */
    router.delete('/:id', verifyToken, UserController.deleteUser);
    router.all('/:id', methodNotAllowed);
}
