const knex = require('../database/knex');
const Paginator = require('./Paginator');

function floorRepository() {
    return knex('floors');
}

function readFloor(payload) {
    return {
        branch_id: payload.branch_id,
        floor_number: payload.floor_number,
        name: payload.name,
        description: payload.description || null,
        capacity: payload.capacity || 0,
        status: payload.status || 'active',
        design_data: payload.design_data || null
    };
}

async function createFloor(payload) {
    if (!payload.branch_id || !payload.floor_number || !payload.name) {
        throw new Error('Branch ID, floor number and name are required');
    }

    const existingFloor = await floorRepository()
        .where('branch_id', payload.branch_id)
        .where('floor_number', payload.floor_number)
        .where('status', 'active')
        .first();

    if (existingFloor) {
        throw new Error('Active floor with this number already exists in this branch');
    }

    const branch = await knex('branches').where('id', payload.branch_id).first();
    if (!branch) {
        throw new Error('Branch not found');
    }

    const floor = readFloor(payload);
    const [id] = await floorRepository().insert(floor);
    return { id, ...floor };
}

async function getAllFloors(status, branchId) {
    let query = floorRepository()
        .select('floors.*', 'branches.name as branch_name')
        .join('branches', 'floors.branch_id', 'branches.id');

    if (status) {
        query = query.where('floors.status', status);
    }
    if (branchId) {
        query = query.where('floors.branch_id', branchId);
    }

    return await query
        .orderBy('branches.name', 'asc')
        .orderBy('floors.floor_number', 'asc');
}

async function getFloorById(id) {
    return floorRepository()
        .select('floors.*', 'branches.name as branch_name')
        .join('branches', 'floors.branch_id', 'branches.id')
        .where('floors.id', id)
        .first();
}

async function updateFloor(id, payload) {
    const updatedFloor = await floorRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!updatedFloor) {
        return null;
    }

    if (payload.floor_number && payload.floor_number !== updatedFloor.floor_number) {
        const branchId = payload.branch_id || updatedFloor.branch_id;
        const numberConflict = await floorRepository()
            .where('branch_id', branchId)
            .where('floor_number', payload.floor_number)
            .where('status', 'active')
            .whereNot('id', id)
            .first();

        if (numberConflict) {
            throw new Error('Active floor with this number already exists in this branch');
        }
    }

    if (payload.branch_id) {
        const branch = await knex('branches').where('id', payload.branch_id).first();
        if (!branch) {
            throw new Error('Branch not found');
        }
    }

    const update = readFloor(payload);
    await floorRepository().where('id', id).update(update);
    return { ...updatedFloor, ...update };
}

async function deleteFloor(id) {
    const deletedFloor = await floorRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!deletedFloor) {
        return null;
    }

    const activeTables = await knex('tables')
        .where('floor_id', id)
        .whereIn('status', ['occupied', 'reserved'])
        .first();

    if (activeTables) {
        throw new Error('Cannot delete floor that has occupied or reserved tables');
    }

    const maxFloorNumber = await floorRepository()
        .where('branch_id', deletedFloor.branch_id)
        .max('floor_number as max_floor')
        .first();

    if (maxFloorNumber && deletedFloor.floor_number < maxFloorNumber.max_floor) {
        throw new Error(`Cannot delete floor ${deletedFloor.floor_number}. You can only delete the highest floor number (${maxFloorNumber.max_floor}) in this branch. Please delete from highest to lowest floor.`);
    }

    await floorRepository().where('id', id).del();
    return { 
        ...deletedFloor,
        message: 'Floor deleted successfully'
    };
}

async function getFloorsByBranch(branchId) {
    return floorRepository()
        .select('*')
        .where('branch_id', branchId)
        .orderBy('floor_number', 'asc');
}

async function getActiveFloors(branchId = null) {
    let query = floorRepository()
        .select('*')
        .where('status', 'active')
        .orderBy('floor_number', 'asc');

    if (branchId) {
        query = query.where('branch_id', branchId);
    }

    return await query;
}

async function getFloorStatistics(branchId = null) {
    let query = floorRepository()
        .select('status')
        .count('* as count')
        .groupBy('status');

    if (branchId) {
        query = query.where('branch_id', branchId);
    }

    const stats = await query;

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

async function generateNextFloorNumber(branchId) {
    const floors = await getFloorsByBranch(branchId);

    let maxNumber = 0;
    floors.forEach(floor => {
        const floorNumber = floor.floor_number;
        if (floorNumber && floorNumber > maxNumber) {
            maxNumber = floorNumber;
        }
    });

    const nextNumber = maxNumber + 1;
    return {
        nextFloorNumber: nextNumber,
        currentFloorCount: floors.length,
        maxNumber: maxNumber
    };
}

module.exports = {
    createFloor,
    getAllFloors,
    getFloorById,
    updateFloor,
    deleteFloor,
    getFloorsByBranch,
    getActiveFloors,
    getFloorStatistics,
    generateNextFloorNumber
};