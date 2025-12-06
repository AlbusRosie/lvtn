const knex = require('../database/knex');
const Paginator = require('./Paginator');
function branchRepository() {
    return knex('branches');
}
function readBranch(payload) {
    const result = {};
    if (payload.name !== undefined) {
        result.name = payload.name;
    }
    if (payload.address_detail !== undefined) {
        result.address_detail = payload.address_detail || null;
    }
    if (payload.phone !== undefined) {
        result.phone = payload.phone;
    }
    if (payload.email !== undefined) {
        result.email = payload.email || null;
    }
    if (payload.manager_id !== undefined) {
        result.manager_id = payload.manager_id || null;
    }
    if (payload.status !== undefined) {
        result.status = payload.status || 'active';
    }
    if (payload.opening_hours !== undefined) {
        result.opening_hours = payload.opening_hours || 7;
    }
    if (payload.close_hours !== undefined) {
        result.close_hours = payload.close_hours || 22;
    }
    if (payload.description !== undefined) {
        result.description = payload.description || null;
    }
    if (payload.image !== undefined) {
        result.image = payload.image || null;
    }
    if (payload.latitude !== undefined) {
        result.latitude = payload.latitude ? parseFloat(payload.latitude) : null;
    }
    if (payload.longitude !== undefined) {
        result.longitude = payload.longitude ? parseFloat(payload.longitude) : null;
    }
    return result;
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
async function getAllBranches(status, search) {
    let query = branchRepository()
        .select('branches.*');
    if (status) {
        query = query.where('branches.status', status);
    }
    if (search) {
        query = query.where(function() {
            this.where('branches.name', 'like', `%${search}%`)
                .orWhere('branches.address_detail', 'like', `%${search}%`);
        });
    }
    return await query.orderBy('branches.name', 'asc');
}
async function getBranchById(id) {
    return branchRepository()
        .select('branches.*')
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
    try {
        const branches = await branchRepository()
            .select('*')
            .where('status', 'active')
            .orderBy('name', 'asc');
        return branches || [];
    } catch (error) {
        console.error('Error in getActiveBranches service:', error);
        throw error;
    }
}
async function getManagers() {
    return knex('users')
        .join('roles', 'users.role_id', 'roles.id')
        .select('users.id', 'users.username', 'users.email', 'users.name', 'users.branch_id')
        .where('roles.name', 'manager')
        .where('users.status', 'active')
        .orderBy('users.name', 'asc');
}
async function getNearbyBranches(userLat, userLng, maxDistanceKm = null) {
    if (userLat == null || userLng == null) {
        throw new Error('Latitude and longitude are required');
    }
    const query = branchRepository()
        .select(
            'branches.*',
            knex.raw(
                `CASE 
                    WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN
                        6371 * ACOS(
                            COS(RADIANS(?)) *
                            COS(RADIANS(latitude)) *
                            COS(RADIANS(longitude) - RADIANS(?)) +
                            SIN(RADIANS(?)) *
                            SIN(RADIANS(latitude))
                        )
                    ELSE NULL
                END AS distance_km`,
                [userLat, userLng, userLat]
            )
        )
        .where('status', 'active') 
        .orderByRaw('CASE WHEN distance_km IS NULL THEN 1 ELSE 0 END ASC, distance_km ASC'); 
    if (maxDistanceKm != null) {
        query.havingRaw('distance_km IS NULL OR distance_km <= ?', [maxDistanceKm]);
    }
    const results = await query;
    return results;
}
module.exports = {
    createBranch,
    getAllBranches,
    getBranchById,
    updateBranch,
    deleteBranch,
    getActiveBranches,
    getBranchStatistics,
    getManagers,
    getNearbyBranches
};