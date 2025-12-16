require('dotenv').config();
const { createServer } = require('http');
const { Server } = require('socket.io');
const app = require('./src/app');
const CleanupService = require('./src/services/CleanupService');
const jwt = require('jsonwebtoken');
const knex = require('./src/database/knex');

const PORT = process.env.PORT || 3000;
const httpServer = createServer(app);

// Setup Socket.io
const io = new Server(httpServer, {
    cors: {
        origin: process.env.FRONTEND_URL ? process.env.FRONTEND_URL.split(',') : ["http://localhost:5173", "http://localhost:3000"],
        credentials: true
    }
});

// Socket.io authentication middleware
io.use(async (socket, next) => {
    try {
        const token = socket.handshake.auth.token;
        if (!token) {
            return next(new Error('Authentication error: No token provided'));
        }

        // Verify JWT token
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
        
        // Get user from database
        const user = await knex('users')
            .select('id', 'role_id', 'branch_id', 'username', 'name', 'status')
            .where('id', decoded.id)
            .first();

        if (!user || user.status !== 'active') {
            return next(new Error('Authentication error: User not found or inactive'));
        }

        // Attach user info to socket
        socket.user = user;
        next();
    } catch (error) {
        next(new Error('Authentication error: Invalid token'));
    }
});

// Socket.io connection handler
io.on('connection', (socket) => {
    console.log('User connected:', socket.id, 'User:', socket.user?.username, 'Role:', socket.user?.role_id, 'Branch:', socket.user?.branch_id);

    // Join branch room if user has branch_id (for Manager, Cashier, Kitchen Staff)
    // All staff with branch_id should see orders from their branch
    if (socket.user?.branch_id) {
        socket.join(`branch:${socket.user.branch_id}`);
        console.log(`User ${socket.user.username} (${socket.id}) joined branch:${socket.user.branch_id}`);
    }

    // Join admin room if user is admin (role_id === 1)
    if (socket.user?.role_id === 1) {
        socket.join('admin');
        console.log(`User ${socket.user.username} (${socket.id}) joined admin room`);
    }

    // Join delivery staff room if user is delivery staff (role_id === 7)
    // Delivery staff will receive notifications for orders assigned to them
    if (socket.user?.role_id === 7) {
        socket.join(`delivery:${socket.user.id}`);
        console.log(`User ${socket.user.username} (${socket.id}) joined delivery room: delivery:${socket.user.id}`);
    }

    // Join user-specific room for customer notifications
    socket.join(`user:${socket.user.id}`);

    // Handle explicit join-branch event (for reconnection or manual join)
    socket.on('join-branch', (branchId) => {
        if (socket.user?.branch_id === branchId || socket.user?.role_id === 1) {
            socket.join(`branch:${branchId}`);
            console.log(`User ${socket.user.username} (${socket.id}) joined branch:${branchId}`);
        } else {
            console.warn(`User ${socket.user.username} (${socket.id}) attempted to join branch:${branchId} but doesn't have access`);
        }
    });

    // Handle explicit join-admin event (for reconnection or manual join)
    socket.on('join-admin', () => {
        if (socket.user?.role_id === 1) {
            socket.join('admin');
            console.log(`User ${socket.user.username} (${socket.id}) joined admin room`);
        } else {
            console.warn(`User ${socket.user.username} (${socket.id}) attempted to join admin room but is not admin`);
        }
    });

    // Handle explicit join-delivery event (for reconnection or manual join)
    socket.on('join-delivery', () => {
        if (socket.user?.role_id === 7) {
            socket.join(`delivery:${socket.user.id}`);
            console.log(`User ${socket.user.username} (${socket.id}) joined delivery room: delivery:${socket.user.id}`);
        } else {
            console.warn(`User ${socket.user.username} (${socket.id}) attempted to join delivery room but is not delivery staff`);
        }
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

// Export io for use in services
module.exports.io = io;

// Set io instance in all services that need real-time updates
const OrderService = require('./src/services/OrderService');
const ReservationService = require('./src/services/ReservationService');
const ProductService = require('./src/services/ProductService');
const BranchService = require('./src/services/BranchService');
const CategoryService = require('./src/services/CategoryService');
const TableService = require('./src/services/TableService');
const FloorService = require('./src/services/FloorService');
const UserService = require('./src/services/UserService');

OrderService.setSocketIO(io);
if (ReservationService.setSocketIO) {
    ReservationService.setSocketIO(io);
}
if (ProductService.setSocketIO) {
    ProductService.setSocketIO(io);
}
if (BranchService.setSocketIO) {
    BranchService.setSocketIO(io);
}
if (CategoryService.setSocketIO) {
    CategoryService.setSocketIO(io);
}
if (TableService.setSocketIO) {
    TableService.setSocketIO(io);
}
if (FloorService.setSocketIO) {
    FloorService.setSocketIO(io);
}
if (UserService.setSocketIO) {
    UserService.setSocketIO(io);
}

httpServer.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Socket.io server ready`);
    CleanupService.startCleanupJob(30);
});
