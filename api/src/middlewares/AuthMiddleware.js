const jwt = require('jsonwebtoken');
const ApiError = require('../api-error');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

if (!JWT_SECRET) {
    process.exit(1);
}

function verifyToken(req, res, next) {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return next(new ApiError(401, 'No token provided'));
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        return next(new ApiError(401, 'Invalid token'));
    }
}

function requireRole(allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            return next(new ApiError(401, 'Authentication required'));
        }

        if (!req.user.role_id) {
            return next(new ApiError(403, 'Role information not found'));
        }

        const roleMap = {
            1: 'admin',
            2: 'customer',
            3: 'staff'
        };

        const userRole = roleMap[req.user.role_id];

        if (!userRole || !allowedRoles.includes(userRole)) {
            return next(new ApiError(403, 'Insufficient permissions'));
        }

        next();
    };
}

module.exports = {
    verifyToken,
    requireRole,
    JWT_SECRET,
    JWT_EXPIRES_IN
};