const knex = require('../database/knex');
const Paginator = require('./Paginator');

function branchRepository() {
    return knex('branches');
}

function readBranch(payload) {
    return {
        name: payload.name,
        province_id: payload.province_id || null,
        district_id: payload.district_id || null,
        address_detail: payload.address_detail || null,
        phone: payload.phone,
        email: payload.email || null,
        manager_id: payload.manager_id || null,
        status: payload.status || 'active',
        opening_hours: payload.opening_hours || null,
        description: payload.description || null,
        image: payload.image || null
    };
}

async function createBranch(payload) {
    if (!payload.name || !payload.phone) {
        throw new Error('Branch name and phone are required');
    }

    const existingBranch = await branchRepository()
        .where('name', payload.name)
        .first();

    if (existingBranch) {
        throw new Error('Branch name already exists');
    }

    const existingEmail = await branchRepository()
        .where('email', payload.email)
        .first();

    if (existingEmail) {
        throw new Error('Branch email already exists');
    }

    if (payload.manager_id) {
        const manager = await knex('users').where('id', payload.manager_id).first();
        if (!manager) {
            throw new Error('Manager not found');
        }
    }

    const branch = readBranch(payload);
    const [id] = await branchRepository().insert(branch);
    return { id, ...branch };
}

async function getAllBranches(status, search, province_id, district_id) {
    let query = branchRepository()
        .select(
            'branches.*',
            'provinces.name as province_name',
            'districts.name as district_name'
        )
        .leftJoin('provinces', 'branches.province_id', 'provinces.id')
        .leftJoin('districts', 'branches.district_id', 'districts.id');

    if (status) {
        query = query.where('branches.status', status);
    }

    if (search) {
        query = query.where(function() {
            this.where('branches.name', 'like', `%${search}%`)
                .orWhere('branches.address_detail', 'like', `%${search}%`)
                .orWhere('provinces.name', 'like', `%${search}%`)
                .orWhere('districts.name', 'like', `%${search}%`);
        });
    }

    if (province_id) {
        query = query.where('branches.province_id', province_id);
    }

    if (district_id) {
        query = query.where('branches.district_id', district_id);
    }

    return await query.orderBy('branches.name', 'asc');
}

async function getBranchById(id) {
    return branchRepository()
        .select(
            'branches.*',
            'provinces.name as province_name',
            'districts.name as district_name'
        )
        .leftJoin('provinces', 'branches.province_id', 'provinces.id')
        .leftJoin('districts', 'branches.district_id', 'districts.id')
        .where('branches.id', id)
        .first();
}

async function updateBranch(id, payload) {
    const updatedBranch = await branchRepository()
        .where('id', id)
        .select('*')
        .first();
        
    if (!updatedBranch) {
        return null;
    }

    if (payload.name && payload.name !== updatedBranch.name) {
        const nameConflict = await branchRepository()
            .where('name', payload.name)
            .whereNot('id', id)
            .first();

        if (nameConflict) {
            throw new Error('Branch name already exists');
        }
    }

    if (payload.email && payload.email !== updatedBranch.email) {
        const emailConflict = await branchRepository()
            .where('email', payload.email)
            .whereNot('id', id)
            .first();

        if (emailConflict) {
            throw new Error('Branch email already exists');
        }
    }

    if (payload.manager_id) {
        const manager = await knex('users').where('id', payload.manager_id).first();
        if (!manager) {
            throw new Error('Manager not found');
        }
    }

    const update = readBranch(payload);
    await branchRepository().where('id', id).update(update);
    return { ...updatedBranch, ...update };
}

async function deleteBranch(id) {
    const deletedBranch = await branchRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!deletedBranch) {
        return null;
    }

    const occupiedTables = await knex('tables')
        .where('branch_id', id)
        .whereIn('status', ['occupied', 'reserved'])
        .first();

    if (occupiedTables) {
        throw new Error('Cannot delete branch that has occupied or reserved tables');
    }

    await knex('order_details')
        .whereIn('order_id', function() {
            this.select('id').from('orders').where('branch_id', id);
        })
        .del();

    await knex('orders')
        .where('branch_id', id)
        .del();

    await knex('reservations')
        .where('branch_id', id)
        .del();

    await knex('reviews')
        .where('branch_id', id)
        .del();

    await knex('branch_products')
        .where('branch_id', id)
        .del();

    await knex('tables')
        .where('branch_id', id)
        .del();

    const deletedFloors = await knex('floors')
        .where('branch_id', id)
        .del();

    await branchRepository().where('id', id).del();

    return { 
        ...deletedBranch,
        message: `Branch deleted successfully! Deleted ${deletedFloors} floors and all related data.`,
        deletedFloors 
    };
}


async function getBranchStatistics() {
    const stats = await branchRepository()
        .select('status')
        .count('* as count')
        .groupBy('status');

    const result = {
        total: 0,
        active: 0,
        inactive: 0,
        maintenance: 0
    };

    stats.forEach(stat => {
        result[stat.status] = parseInt(stat.count);
        result.total += parseInt(stat.count);
    });

    return result;
}

async function getActiveBranches() {
    return branchRepository()
        .select('*')
        .where('status', 'active')
        .orderBy('name', 'asc');
}

async function getManagers() {
    return knex('users')
        .join('roles', 'users.role_id', 'roles.id')
        .select('users.id', 'users.username', 'users.email', 'users.name', 'users.branch_id')
        .where('roles.name', 'manager')
        .where('users.status', 'active')
        .orderBy('users.name', 'asc');
}

module.exports = {
    createBranch,
    getAllBranches,
    getBranchById,
    updateBranch,
    deleteBranch,
    
    getActiveBranches,
    getBranchStatistics,
    getManagers
};