const knex = require('../database/knex');
const Paginator = require('./Paginator');
const { unlink } = require('node:fs');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { JWT_SECRET, JWT_EXPIRES_IN } = require('../middlewares/AuthMiddleware');

function userRepository() {
    return knex('users');
}

function readUser(payload) {
    const user = {
        username: payload.username,
        email: payload.email,
        name: payload.name,
        address: payload.address || null,
        phone: payload.phone || null,
        favorite: payload.favorite !== undefined ? payload.favorite : 0,
        avatar: payload.avatar || null,
        role_id: payload.role_id
    };

    // Only include password if it's provided
    if (payload.password) {
        user.password = bcrypt.hashSync(payload.password, 10);
    }

    return user;
}

async function createUser(payload) {
    // Validate required fields
    if (!payload.username || !payload.password || !payload.email || !payload.name || !payload.role_id) {
        throw new Error('Missing required fields');
    }

    // Check if username or email already exists
    const existingUser = await userRepository()
        .where('username', payload.username)
        .orWhere('email', payload.email)
        .first();

    if (existingUser) {
        throw new Error('Username or email already exists');
    }

    const user = readUser(payload);
    const [id] = await userRepository().insert(user);
    return {    
        id,
        ...user,
        password: undefined
    };
}

async function getManyUsers(query) {
    const { favorite, name, phone, role_id, page = 1, limit = 5 } = query;
    const paginator = new Paginator(page, limit);
    let results = await userRepository().where((builder) => {
        if(name){
            builder.where('name', 'like', `%${name}%`);
        }
        if(phone){
            builder.where('phone', 'like', `%${phone}%`);
        }
        if(role_id){
            builder.where('role_id', role_id);
        }
        if( favorite !== undefined && 
            favorite !== '0' &&
            favorite !== 'false'){
            builder.where('favorite', 1);
        }
    }).select(
        knex.raw('count(id) OVER() AS recordCount'),
        'id',
        'username',
        'name',
        'email',
        'address',
        'phone',
        'favorite',
        'avatar',
        'role_id',
        'created_at'
        )
        .limit(paginator.limit)
        .offset(paginator.offset);
    let totalRecords = 0;
    results = results.map((result) => {
        totalRecords = result.recordCount;
        delete result.recordCount;
        return result;
    });
    return {
        metadata: paginator.getMetadata(totalRecords),
        users: results,
    };
};

async function getUserById(id) {
    return userRepository()
        .where('id', id)
        .select('id', 'username', 'name', 'email', 'address', 'phone', 'favorite', 'avatar', 'role_id', 'created_at')
        .first();
}

async function updateUser(id, payload) {
    const updatedUser = await userRepository()
    .where('id', id)
    .select('*')
    .first();
    if (!updatedUser) {
        return null;
    }
    const update = readUser(payload);
    if (!update.avatar) {
        delete update.avatar;
    }
    await userRepository().where('id', id).update(update);
    if (
        update.avatar &&
        updatedUser.avatar &&
        update.avatar !== updatedUser.avatar &&
        updatedUser.avatar.startsWith('/public/uploads')
    ) {
        unlink(`.${updatedUser.avatar}`, (err) => {});
    }
    return { ...updatedUser, ...update };
}   

async function deleteUser(id) {
    const deletedUser = await userRepository()
    .where('id', id)
    .select('avatar')
    .first();
    if (!deletedUser) {
        return null;
    }    
    await userRepository().where('id', id).del();
    if (
        deletedUser.avatar &&
        deletedUser.avatar.startsWith('/public/uploads')
    ) {
        unlink(`.${deletedUser.avatar}`, (err) => {});
    }
    return deletedUser;
}

async function deleteAllUsers() {
    const users = await userRepository().select('avatar');
    await userRepository().del();
    users.forEach((user) => {
        if (user.avatar && user.avatar.startsWith('/public/uploads')) {
            unlink(`.${user.avatar}`, (err) => {});
        }
    });
}

async function login(username, password) {
    const user = await userRepository()
        .where('username', username)
        .select('*')
        .first();

    if (!user || !bcrypt.compareSync(password, user.password)) {
        throw new Error('Invalid credentials');
    }

    const token = jwt.sign(
        { 
            id: user.id,
            username: user.username,
            role_id: user.role_id
        },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
    );

    return {
        token,
        user: {
            id: user.id,
            username: user.username,
            email: user.email,
            name: user.name,
            address: user.address,
            phone: user.phone,
            favorite: user.favorite,
            avatar: user.avatar,
            role_id: user.role_id
        }
    };
}

module.exports = {
    createUser,
    getManyUsers,
    getUserById,
    updateUser, 
    deleteUser,
    deleteAllUsers,
    login,
};