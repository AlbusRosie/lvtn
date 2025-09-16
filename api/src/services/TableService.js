const knex = require('../database/knex');
const Paginator = require('./Paginator');

function tableRepository() {
    return knex('tables');
}

function readTable(payload) {
    return {
        branch_id: payload.branch_id,
        floor_id: payload.floor_id,
        table_number: payload.table_number,
        capacity: payload.capacity,
        status: payload.status || 'available',
        location: payload.location || null,
        position_x: payload.position_x || null,
        position_y: payload.position_y || null
    };
}

async function createTable(payload) {
    if (!payload.branch_id || !payload.floor_id || !payload.table_number || !payload.capacity) {
        throw new Error('Branch ID, floor ID, table number and capacity are required');
    }

    const existingTable = await tableRepository()
        .where('branch_id', payload.branch_id)
        .where('floor_id', payload.floor_id)
        .where('table_number', payload.table_number)
        .first();

    if (existingTable) {
        throw new Error('Table number already exists in this floor');
    }

    const branch = await knex('branches').where('id', payload.branch_id).first();
    if (!branch) {
        throw new Error('Branch not found');
    }

    const floor = await knex('floors').where('id', payload.floor_id).first();
    if (!floor) {
        throw new Error('Floor not found');
    }

    if (parseInt(floor.branch_id) !== parseInt(payload.branch_id)) {
        throw new Error('Floor does not belong to the specified branch');
    }

    const table = readTable(payload);
    const [id] = await tableRepository().insert(table);
    return { id, ...table };
}

async function getAllTables() {
    return tableRepository()
        .select(
            'tables.*',
            'branches.name as branch_name',
            'floors.name as floor_name',
            'floors.floor_number'
        )
        .join('branches', 'tables.branch_id', 'branches.id')
        .join('floors', 'tables.floor_id', 'floors.id')
        .orderBy('branches.name', 'asc')
        .orderBy('floors.floor_number', 'asc')
        .orderBy('tables.table_number', 'asc');
}

async function updateTable(id, payload) {
    const updatedTable = await tableRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!updatedTable) {
        return null;
    }

    if (payload.table_number && payload.table_number !== updatedTable.table_number) {
        const floorId = payload.floor_id || updatedTable.floor_id;
        const numberConflict = await tableRepository()
            .where('branch_id', updatedTable.branch_id)
            .where('floor_id', floorId)
            .where('table_number', payload.table_number)
            .whereNot('id', id)
            .first();

        if (numberConflict) {
            throw new Error('Table number already exists in this floor');
        }
    }

    if (payload.branch_id || payload.floor_id) {
        const branchId = payload.branch_id || updatedTable.branch_id;
        const floorId = payload.floor_id || updatedTable.floor_id;

        const branch = await knex('branches').where('id', branchId).first();
        if (!branch) {
            throw new Error('Branch not found');
        }

        const floor = await knex('floors').where('id', floorId).first();
        if (!floor) {
            throw new Error('Floor not found');
        }

        if (floor.branch_id !== branchId) {
            throw new Error('Floor does not belong to the specified branch');
        }
    }

    const update = readTable(payload);
    await tableRepository().where('id', id).update(update);
    return { ...updatedTable, ...update };
}

async function updateTableStatus(id, status) {
    const updatedTable = await tableRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!updatedTable) {
        return null;
    }

    const validStatuses = ['available', 'occupied', 'reserved', 'maintenance'];
    if (!validStatuses.includes(status)) {
        throw new Error('Invalid status value');
    }

    await tableRepository().where('id', id).update({ status });
    return { ...updatedTable, status };
}

async function deleteTable(id) {
    const deletedTable = await tableRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!deletedTable) {
        return null;
    }

    if (deletedTable.status === 'occupied' || deletedTable.status === 'reserved') {
        throw new Error('Cannot delete table that is currently occupied or reserved');
    }

    await tableRepository().where('id', id).del();
    return { ...deletedTable, message: 'Table deleted successfully' };
}

module.exports = {
    createTable,
    getAllTables,
    updateTable,
    updateTableStatus,
    deleteTable
};