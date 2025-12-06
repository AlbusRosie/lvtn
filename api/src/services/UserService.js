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
    const user = {};
    // Chỉ thêm những trường có trong payload (partial update)
    if (payload.username !== undefined) {
        user.username = payload.username;
    }
    if (payload.email !== undefined) {
        user.email = payload.email;
    }
    if (payload.name !== undefined) {
        user.name = payload.name;
    }
    if (payload.address !== undefined) {
        user.address = payload.address || null;
    }
    if (payload.phone !== undefined) {
        user.phone = payload.phone || null;
    }
    if (payload.avatar !== undefined) {
        user.avatar = payload.avatar || null;
    }
    if (payload.role_id !== undefined) {
        user.role_id = payload.role_id;
    }
    if (payload.branch_id !== undefined) {
        user.branch_id = payload.branch_id ? parseInt(payload.branch_id) : null;
    }
    if (payload.password) {
        user.password = bcrypt.hashSync(payload.password, 10);
    }
    return user;
}
async function createUser(payload) {
    if (!payload.username || !payload.password || !payload.email || !payload.name || !payload.role_id) {
        throw new Error('Missing required fields');
    }
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
    const { name, phone, role_id, not_role_id, branch_id, recent, page = 1, limit = 5 } = query;
    const paginator = new Paginator(page, limit);
    let results = await userRepository()
        .leftJoin('branches as b', 'users.branch_id', 'b.id')
        .where((builder) => {
        if(name){
            builder.where('users.name', 'like', `%${name}%`);
        }
        if(phone){
            builder.where('users.phone', 'like', `%${phone}%`);
        }
        if(role_id){
            builder.where('users.role_id', role_id);
        }
        if (not_role_id) {
            builder.whereNot('users.role_id', not_role_id);
        }
        if(branch_id){
            if (branch_id === 'none') {
                builder.whereNull('users.branch_id');
            } else {
                builder.where('users.branch_id', branch_id);
            }
        }
        if (recent === '7d') {
            const sevenDaysAgo = knex.raw(`DATE_SUB(NOW(), INTERVAL 7 DAY)`);
            builder.where('users.created_at', '>=', sevenDaysAgo);
        } else if (recent === '3d') {
            const threeDaysAgo = knex.raw(`DATE_SUB(NOW(), INTERVAL 3 DAY)`);
            builder.where('users.created_at', '>=', threeDaysAgo);
        }
    }).select(
        knex.raw('count(users.id) OVER() AS recordCount'),
        'users.id',
        'users.username',
        'users.name',
        'users.email',
        'users.address',
        'users.phone',
        'users.avatar',
        'users.role_id',
        'users.branch_id',
        'users.created_at',
        'b.name as branch_name'
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
        .leftJoin('branches as b', 'users.branch_id', 'b.id')
        .where('users.id', id)
        .select(
            'users.id', 
            'users.username', 
            'users.name', 
            'users.email', 
            'users.address', 
            'users.phone', 
            'users.avatar', 
            'users.role_id', 
            'users.branch_id',
            'users.created_at',
            'b.name as branch_name'
        )
        .first();
}
async function updateUser(id, payload) {
    const existingUser = await userRepository()
    .where('id', id)
    .select('*')
    .first();
    if (!existingUser) {
        return null;
    }
    const update = readUser(payload);
    // Chỉ xóa avatar nếu không có trong update và không phải là null
    if (update.avatar === undefined) {
        delete update.avatar;
    }
    // Chỉ update những trường có trong update object
    if (Object.keys(update).length > 0) {
        await userRepository().where('id', id).update(update);
    }
    // Xóa avatar cũ nếu có avatar mới
    if (
        update.avatar &&
        existingUser.avatar &&
        update.avatar !== existingUser.avatar &&
        existingUser.avatar.startsWith('/public/uploads')
    ) {
        unlink(`.${existingUser.avatar}`, (err) => {});
    }
    // Lấy user đã được cập nhật từ DB để đảm bảo có đầy đủ dữ liệu
    const updatedUser = await userRepository()
        .where('id', id)
        .select('*')
        .first();
    return updatedUser;
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
        .leftJoin('branches as b', 'users.branch_id', 'b.id')
        .where('users.username', username)
        .select(
            'users.*',
            'b.name as branch_name'
        )
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
            avatar: user.avatar,
            role_id: user.role_id,
            branch_id: user.branch_id,
            branch_name: user.branch_name
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