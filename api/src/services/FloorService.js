const knex = require('../database/knex');
const Paginator = require('./Paginator');
let io = null;

// Function to set io instance (called from server.js)
function setSocketIO(socketIO) {
    io = socketIO;
}
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
    const newFloor = { id, ...floor };
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io) {
        io.to('admin').emit('floor-created', {
            floorId: id,
            floor: newFloor,
            branchId: payload.branch_id,
            timestamp: new Date().toISOString()
        });
        
        io.to(`branch:${payload.branch_id}`).emit('floor-created', {
            floorId: id,
            floor: newFloor,
            branchId: payload.branch_id,
            timestamp: new Date().toISOString()
        });
    }
    
    return newFloor;
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
    const updated = { ...updatedFloor, ...update };
    const branchId = update.branch_id || updatedFloor.branch_id;
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io) {
        io.to('admin').emit('floor-updated', {
            floorId: id,
            floor: updated,
            branchId: branchId,
            timestamp: new Date().toISOString()
        });
        
        io.to(`branch:${branchId}`).emit('floor-updated', {
            floorId: id,
            floor: updated,
            branchId: branchId,
            timestamp: new Date().toISOString()
        });
    }
    
    return updated;
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
    const result = { 
        ...deletedFloor,
        message: 'Floor deleted successfully'
    };
    
    // ✅ EMIT REAL-TIME NOTIFICATION
    if (io) {
        io.to('admin').emit('floor-deleted', {
            floorId: id,
            floor: deletedFloor,
            branchId: deletedFloor.branch_id,
            timestamp: new Date().toISOString()
        });
        
        io.to(`branch:${deletedFloor.branch_id}`).emit('floor-deleted', {
            floorId: id,
            floor: deletedFloor,
            branchId: deletedFloor.branch_id,
            timestamp: new Date().toISOString()
        });
    }
    
    return result;
}
async function getFloorsByBranch(branchId) {
    return floorRepository()
        .select('*')
        .where('branch_id', branchId)
        .orderBy('floor_number', 'asc');
}
// Removed unused functions:
// - getActiveFloors() - not used anywhere
// - getFloorStatistics() - not used anywhere
// - generateNextFloorNumber() - not used anywhere
module.exports = {
    createFloor,
    getAllFloors,
    getFloorById,
    updateFloor,
    deleteFloor,
    getFloorsByBranch,
    // Removed unused exports:
    // - getActiveFloors
    // - getFloorStatistics
    // - generateNextFloorNumber
    setSocketIO
};