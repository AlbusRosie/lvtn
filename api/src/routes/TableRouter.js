const express = require('express');
const TableController = require('../controllers/TableController');
const { verifyToken, requireRole } = require('../middlewares/AuthMiddleware');

const router = express.Router();
const tableController = new TableController();

/**
 * @swagger
 * /api/tables:
 *   get:
 *     summary: Get all tables
 *     description: Get list of all tables with branch and floor information
 *     tags: [Tables]
 *     parameters:
 *       - in: query
 *         name: branch_id
 *         schema:
 *           type: integer
 *         description: Filter by branch ID
 *     responses:
 *       200:
 *         description: Success
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
 *                     $ref: '#/components/schemas/Table'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/', tableController.getAllTables.bind(tableController));

/**
 * @swagger
 * /api/tables/available:
 *   get:
 *     summary: Get available tables
 *     description: Get list of tables with available status
 *     tags: [Tables]
 *     parameters:
 *       - in: query
 *         name: branch_id
 *         schema:
 *           type: integer
 *         description: Filter by branch ID
 *     responses:
 *       200:
 *         description: Success
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
 *                     $ref: '#/components/schemas/Table'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/available', tableController.getAvailableTables.bind(tableController));

/**
 * @swagger
 * /api/tables/status/{status}:
 *   get:
 *     summary: Get tables by status
 *     description: Get list of tables by specific status
 *     tags: [Tables]
 *     parameters:
 *       - in: path
 *         name: status
 *         required: true
 *         schema:
 *           type: string
 *           enum: [available, occupied, reserved, maintenance]
 *         description: Table status
 *       - in: query
 *         name: branch_id
 *         schema:
 *           type: integer
 *         description: Filter by branch ID
 *     responses:
 *       200:
 *         description: Success
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
 *                     $ref: '#/components/schemas/Table'
 *       400:
 *         description: Invalid status
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/status/:status', tableController.getTablesByStatus.bind(tableController));

/**
 * @swagger
 * /api/tables/branches:
 *   get:
 *     summary: Get all branches
 *     description: Get list of all active branches
 *     tags: [Tables]
 *     responses:
 *       200:
 *         description: Success
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
 *                     $ref: '#/components/schemas/Branch'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/branches', tableController.getAllBranches.bind(tableController));

/**
 * @swagger
 * /api/tables/branches/{branch_id}/floors:
 *   get:
 *     summary: Get floors by branch
 *     description: Get list of all floors for a specific branch
 *     tags: [Tables]
 *     parameters:
 *       - in: path
 *         name: branch_id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Branch ID
 *     responses:
 *       200:
 *         description: Success
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
 *                     $ref: '#/components/schemas/Floor'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/branches/:branch_id/floors', tableController.getFloorsByBranch.bind(tableController));

/**
 * @swagger
 * /api/tables/branches/{branch_id}/floors/{floor_id}/tables:
 *   get:
 *     summary: Get tables by branch and floor
 *     description: Get list of all tables for a specific floor in a branch
 *     tags: [Tables]
 *     parameters:
 *       - in: path
 *         name: branch_id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Branch ID
 *       - in: path
 *         name: floor_id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Floor ID
 *     responses:
 *       200:
 *         description: Success
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
 *                     $ref: '#/components/schemas/Table'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/branches/:branch_id/floors/:floor_id/tables', tableController.getTablesByBranchAndFloor.bind(tableController));

/**
 * @swagger
 * /api/tables/branches/{branch_id}/tables/{table_number}:
 *   get:
 *     summary: Get table by number and branch
 *     description: Get detailed information of a table by table number in a specific branch
 *     tags: [Tables]
 *     parameters:
 *       - in: path
 *         name: branch_id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Branch ID
 *       - in: path
 *         name: table_number
 *         required: true
 *         schema:
 *           type: string
 *         description: Table number (e.g. T01, T02)
 *     responses:
 *       200:
 *         description: Success
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 data:
 *                   $ref: '#/components/schemas/Table'
 *       404:
 *         description: Table not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/branches/:branch_id/tables/:table_number', tableController.getTableByNumber.bind(tableController));

/**
 * @swagger
 * /api/tables/branches/{branch_id}/floors/{floor_id}/generate-number:
 *   get:
 *     summary: Generate next table number
 *     description: Generate next table number for a specific floor in a branch
 *     tags: [Tables]
 *     parameters:
 *       - in: path
 *         name: branch_id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Branch ID
 *       - in: path
 *         name: floor_id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Floor ID
 *     responses:
 *       200:
 *         description: Success
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
 *                     nextTableNumber:
 *                       type: string
 *                       example: T03
 *                     currentTableCount:
 *                       type: integer
 *                       example: 2
 *                     maxNumber:
 *                       type: integer
 *                       example: 2
 *       400:
 *         description: Invalid data
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/branches/:branch_id/floors/:floor_id/generate-number', tableController.generateNextTableNumber.bind(tableController));

/**
 * @swagger
 * /api/tables/statistics:
 *   get:
 *     summary: Get table statistics
 *     description: Get table statistics by status
 *     tags: [Tables]
 *     parameters:
 *       - in: query
 *         name: branch_id
 *         schema:
 *           type: integer
 *         description: Filter by branch ID
 *     responses:
 *       200:
 *         description: Success
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 data:
 *                   $ref: '#/components/schemas/TableStatistics'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/statistics', tableController.getTableStatistics.bind(tableController));

/**
 * @swagger
 * /api/tables/{id}:
 *   get:
 *     summary: Get table by ID
 *     description: Get detailed information of a specific table
 *     tags: [Tables]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Table ID
 *     responses:
 *       200:
 *         description: Success
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 data:
 *                   $ref: '#/components/schemas/Table'
 *       404:
 *         description: Table not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/:id', tableController.getTableById.bind(tableController));

// Protected routes (require authentication)
router.use(verifyToken);

/**
 * @swagger
 * /api/tables:
 *   post:
 *     summary: Create new table
 *     description: Create a new table (admin only)
 *     tags: [Tables]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/TableCreateRequest'
 *     responses:
 *       201:
 *         description: Table created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 data:
 *                   $ref: '#/components/schemas/Table'
 *                 message:
 *                   type: string
 *                   example: Table created successfully
 *       400:
 *         description: Invalid data
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/', requireRole(['admin']), tableController.createTable.bind(tableController));

/**
 * @swagger
 * /api/tables/{id}:
 *   put:
 *     summary: Update table
 *     description: Update information of a specific table (admin only)
 *     tags: [Tables]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Table ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/TableUpdateRequest'
 *     responses:
 *       200:
 *         description: Table updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 data:
 *                   $ref: '#/components/schemas/Table'
 *                 message:
 *                   type: string
 *                   example: Table updated successfully
 *       400:
 *         description: Invalid data
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Table not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.put('/:id', requireRole(['admin']), tableController.updateTable.bind(tableController));

/**
 * @swagger
 * /api/tables/{id}/status:
 *   patch:
 *     summary: Update table status
 *     description: Update status of a specific table (admin only)
 *     tags: [Tables]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Table ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/TableStatusUpdateRequest'
 *     responses:
 *       200:
 *         description: Table status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 data:
 *                   $ref: '#/components/schemas/Table'
 *                 message:
 *                   type: string
 *                   example: Table status updated successfully
 *       400:
 *         description: Invalid status
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Table not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.patch('/:id/status', requireRole(['admin']), tableController.updateTableStatus.bind(tableController));

/**
 * @swagger
 * /api/tables/{id}:
 *   delete:
 *     summary: Delete table
 *     description: Delete a specific table (admin only)
 *     tags: [Tables]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Table ID
 *     responses:
 *       200:
 *         description: Table deleted successfully
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
 *                     message:
 *                       type: string
 *                       example: Table deleted successfully
 *                 message:
 *                   type: string
 *                   example: Table deleted successfully
 *       400:
 *         description: Cannot delete table in use
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Table not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.delete('/:id', requireRole(['admin']), tableController.deleteTable.bind(tableController));

module.exports = router; 