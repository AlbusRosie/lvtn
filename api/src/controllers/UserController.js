const JSend = require('../jsend');
const UserService = require('../services/UserService');
const ApiError = require('../api-error');
const jwt = require('jsonwebtoken');
const SECRET_KEY = process.env.JWT_SECRET;
const EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1d';

async function createUser(req, res, next) {
    try {

        const requiredFields = ['username', 'password', 'email', 'name', 'role_id'];
        const missingFields = requiredFields.filter(field => !req.body[field]);

        if (missingFields.length > 0) {
            return next(new ApiError(400, `Missing required fields: ${missingFields.join(', ')}`));
        }

        if (isNaN(parseInt(req.body.role_id))) {
            return next(new ApiError(400, 'Invalid role_id'));
        }

        if (req.body.phone && !/^[0-9]{10,11}$/.test(req.body.phone)) {
            return next(new ApiError(400, 'Invalid phone number format'));
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(req.body.email)) {
            return next(new ApiError(400, 'Invalid email format'));
        }

        const user = await UserService.createUser({
            ...req.body,
            role_id: parseInt(req.body.role_id),
            favorite: req.body.favorite === 'true' || req.body.favorite === true ? 1 : 0,
            avatar: req.file ? `/public/uploads/${req.file.filename}` : null,
        });

        return res.status(201).set({
            Location: `${req.baseUrl}/${user.id}`
        }).json(JSend.success({
            user,
        }));
    } catch (error) {
        if (error.message === 'Username or email already exists') {
            return next(new ApiError(400, error.message));
        }
        if (error.message === 'Missing required fields') {
            return next(new ApiError(400, error.message));
        }
        return next(
            new ApiError(500, 'An error occurred while creating the user')
        );
    }
}

async function login(req, res, next) {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return next(new ApiError(400, 'Username and password are required'));
        }

        const result = await UserService.login(username, password);
        const token = jwt.sign({ 
            id: result.user.id, 
            username: result.user.username, 
            role_id: result.user.role_id
        },
            SECRET_KEY,
        { 
            expiresIn: EXPIRES_IN 
        });
        return res.json({
            status: 'success',
            data: { token, user: result.user }
        });
    } catch (error) {
        if (error.message === 'Invalid credentials') {
            return next(new ApiError(401, error.message));
        }
        return next(new ApiError(500, 'An error occurred during login'));
    }
}

async function getUser(req, res, next) {
    const { id } = req.params;

    try {
        const user = await UserService.getUserById(id);
        if(!user) {
            return next(new ApiError(404, 'User not found'));
        }
        return res.json(JSend.success({
            user,
        }));
    } catch (error) {
        return next(
            new ApiError(500, 'An error occurred while retrieving the user')
        );
    }
}

async function getUsersByFilter(req, res, next) {
    let result = {
        users: [],
        metadata:{
            totalRecords: 0,
            firstPage: 1,
            lastPage: 1,
            page: 1,
            limit: 5,
        }
    };
    try {
        result = await UserService.getManyUsers(req.query);
    } catch (error) {
        return next(
            new ApiError(500, 'An error occurred while retrieving users')
        );
    }
    return res.json(JSend.success({
        users: result.users,
        metadata: result.metadata,
    }));
}

async function updateUser(req, res, next) {
    if(Object.keys(req.body).length === 0 && !req.file) {
        return next(new ApiError(400, 'No data to update'));
    }
    const { id } = req.params;

    try {

        if (req.body.phone && !/^[0-9]{10,11}$/.test(req.body.phone)) {
            return next(new ApiError(400, 'Invalid phone number format'));
        }

        if (req.body.email) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(req.body.email)) {
                return next(new ApiError(400, 'Invalid email format'));
            }
        }

        const updateData = {
            ...req.body,
            avatar: req.file ? `/public/uploads/${req.file.filename}` : null,
        };

        if (req.body.favorite !== undefined) {
            updateData.favorite = req.body.favorite === 'true' || req.body.favorite === true ? 1 : 0;
        }

        const updated = await UserService.updateUser(id, updateData);
        if (!updated) {
            return next(new ApiError(404, 'User not found'));
        }
        return res.json(JSend.success({
            user: updated,
        }));
    } catch (error) {
        return next(
            new ApiError(500, 'An error occurred while updating the user')
        );
    }
}

async function deleteUser(req, res, next) {
    const { id } = req.params;
    try {
        const deleted = await UserService.deleteUser(id);
        if (!deleted) {
            return next(new ApiError(404, 'User not found'));
        }
        return res.json(JSend.success());
    } catch (error) {
        return next(
            new ApiError(500, 'An error occurred while deleting the user')
        );
    }
}

async function deleteAllUsers(req, res, next) {
    try {
        await UserService.deleteAllUsers();
        return res.json(JSend.success());
    } catch (error) {
        return next(
            new ApiError(500, 'An error occurred while deleting all users')
        );
    }
}

module.exports = {
    login,
    getUser,
    createUser,
    getUsersByFilter,
    updateUser,
    deleteUser,
    deleteAllUsers,
};