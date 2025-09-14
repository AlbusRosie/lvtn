const knex = require('../database/knex');

async function getCurrentUser(req, res, next) {
    try {
        if (!req.user || !req.user.id) {
            return next();
        }

        const user = await knex('users')
            .select('id', 'username', 'email', 'name', 'role_id', 'branch_id', 'status')
            .where('id', req.user.id)
            .first();

        if (user) {
            req.currentUser = user;
        }
        next();
    } catch (error) {
        next(error);
    }
}

async function getManagers(req, res, next) {
    try {
        const managers = await knex('users')
            .join('roles', 'users.role_id', 'roles.id')
            .select('users.id', 'users.username', 'users.email', 'users.name', 'users.branch_id')
            .where('roles.name', 'manager')
            .where('users.status', 'active')
            .orderBy('users.name', 'asc');

        req.managers = managers;
        next();
    } catch (error) {
        next(error);
    }
}

module.exports = {
    getCurrentUser,
    getManagers
};
