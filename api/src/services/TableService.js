const knex = require('../database/knex');
const ApiError = require('../api-error');

class TableService {

  async getAllTables(branchId = null) {
    try {
      let query = knex('tables')
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

      if (branchId) {
        query = query.where('tables.branch_id', branchId);
      }

      const tables = await query;
      return tables;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getTableById(id) {
    try {
      const table = await knex('tables')
        .select(
          'tables.*',
          'branches.name as branch_name',
          'floors.name as floor_name',
          'floors.floor_number'
        )
        .join('branches', 'tables.branch_id', 'branches.id')
        .join('floors', 'tables.floor_id', 'floors.id')
        .where('tables.id', id)
        .first();

      if (!table) {
        throw new ApiError(404, 'Table not found');
      }

      return table;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getTablesByStatus(status, branchId = null) {
    try {
      const validStatuses = ['available', 'occupied', 'reserved', 'maintenance'];
      if (!validStatuses.includes(status)) {
        throw new ApiError(400, 'Invalid status value');
      }

      let query = knex('tables')
        .select(
          'tables.*',
          'branches.name as branch_name',
          'floors.name as floor_name',
          'floors.floor_number'
        )
        .join('branches', 'tables.branch_id', 'branches.id')
        .join('floors', 'tables.floor_id', 'floors.id')
        .where('tables.status', status)
        .orderBy('branches.name', 'asc')
        .orderBy('floors.floor_number', 'asc')
        .orderBy('tables.table_number', 'asc');

      if (branchId) {
        query = query.where('tables.branch_id', branchId);
      }

      const tables = await query;
      return tables;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getAvailableTables(branchId = null) {
    try {
      let query = knex('tables')
        .select(
          'tables.*',
          'branches.name as branch_name',
          'floors.name as floor_name',
          'floors.floor_number'
        )
        .join('branches', 'tables.branch_id', 'branches.id')
        .join('floors', 'tables.floor_id', 'floors.id')
        .where('tables.status', 'available')
        .orderBy('branches.name', 'asc')
        .orderBy('floors.floor_number', 'asc')
        .orderBy('tables.table_number', 'asc');

      if (branchId) {
        query = query.where('tables.branch_id', branchId);
      }

      const tables = await query;
      return tables;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async createTable(tableData) {
    try {

      const existingTable = await knex('tables')
        .where('branch_id', tableData.branch_id)
        .where('floor_id', tableData.floor_id)
        .where('table_number', tableData.table_number)
        .first();

      if (existingTable) {
        throw new ApiError(400, 'Table number already exists in this floor');
      }

      const branch = await knex('branches').where('id', tableData.branch_id).first();
      if (!branch) {
        throw new ApiError(400, 'Branch not found');
      }

      const floor = await knex('floors').where('id', tableData.floor_id).first();
      if (!floor) {
        throw new ApiError(400, 'Floor not found');
      }

      if (parseInt(floor.branch_id) !== parseInt(tableData.branch_id)) {
        throw new ApiError(400, 'Floor does not belong to the specified branch');
      }

      const [tableId] = await knex('tables')
        .insert(tableData)
        .returning('id');

      return this.getTableById(tableId);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async updateTable(id, tableData) {
    try {

      const existingTable = await knex('tables')
        .where('id', id)
        .first();

      if (!existingTable) {
        throw new ApiError(404, 'Table not found');
      }

      if (tableData.table_number && tableData.table_number !== existingTable.table_number) {
        const floorId = tableData.floor_id || existingTable.floor_id;
        const numberConflict = await knex('tables')
          .where('branch_id', existingTable.branch_id)
          .where('floor_id', floorId)
          .where('table_number', tableData.table_number)
          .whereNot('id', id)
          .first();

        if (numberConflict) {
          throw new ApiError(400, 'Table number already exists in this floor');
        }
      }

      if (tableData.branch_id || tableData.floor_id) {
        const branchId = tableData.branch_id || existingTable.branch_id;
        const floorId = tableData.floor_id || existingTable.floor_id;

        const branch = await knex('branches').where('id', branchId).first();
        if (!branch) {
          throw new ApiError(400, 'Branch not found');
        }

        const floor = await knex('floors').where('id', floorId).first();
        if (!floor) {
          throw new ApiError(400, 'Floor not found');
        }

        if (floor.branch_id !== branchId) {
          throw new ApiError(400, 'Floor does not belong to the specified branch');
        }
      }

      await knex('tables')
        .where('id', id)
        .update(tableData);

      return this.getTableById(id);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async updateTableStatus(id, status) {
    try {

      const existingTable = await knex('tables')
        .where('id', id)
        .first();

      if (!existingTable) {
        throw new ApiError(404, 'Table not found');
      }

      const validStatuses = ['available', 'occupied', 'reserved', 'maintenance'];
      if (!validStatuses.includes(status)) {
        throw new ApiError(400, 'Invalid status value');
      }

      await knex('tables')
        .where('id', id)
        .update({ status });

      return this.getTableById(id);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async deleteTable(id) {
    try {

      const existingTable = await knex('tables')
        .where('id', id)
        .first();

      if (!existingTable) {
        throw new ApiError(404, 'Table not found');
      }

      if (existingTable.status === 'occupied' || existingTable.status === 'reserved') {
        throw new ApiError(400, 'Cannot delete table that is currently occupied or reserved');
      }

      await knex('tables')
        .where('id', id)
        .del();

      return { message: 'Table deleted successfully' };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getTableStatistics(branchId = null) {
    try {
      let query = knex('tables')
        .select('status')
        .count('* as count')
        .groupBy('status');

      if (branchId) {
        query = query.where('branch_id', branchId);
      }

      const stats = await query;

      const result = {
        total: 0,
        available: 0,
        occupied: 0,
        reserved: 0,
        maintenance: 0
      };

      stats.forEach(stat => {
        result[stat.status] = parseInt(stat.count);
        result.total += parseInt(stat.count);
      });

      return result;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getAllBranches() {
    try {
      const branches = await knex('branches')
        .select('*')
        .where('status', 'active')
        .orderBy('name', 'asc');

      return branches;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getFloorsByBranch(branchId) {
    try {
      const floors = await knex('floors')
        .select('*')
        .where('branch_id', branchId)
        .where('status', 'active')
        .orderBy('floor_number', 'asc');

      return floors;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getTablesByBranchAndFloor(branchId, floorId) {
    try {
      const tables = await knex('tables')
        .select(
          'tables.*',
          'branches.name as branch_name',
          'floors.name as floor_name',
          'floors.floor_number'
        )
        .join('branches', 'tables.branch_id', 'branches.id')
        .join('floors', 'tables.floor_id', 'floors.id')
        .where('tables.branch_id', branchId)
        .where('tables.floor_id', floorId)
        .orderBy('tables.table_number', 'asc');

      return tables;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async generateNextTableNumber(branchId, floorId) {
    try {
      const tables = await this.getTablesByBranchAndFloor(branchId, floorId);

      let maxNumber = 0;
      tables.forEach(table => {
        const tableNumber = table.table_number;
        if (tableNumber.startsWith('T')) {
          const numberPart = parseInt(tableNumber.substring(1));
          if (!isNaN(numberPart) && numberPart > maxNumber) {
            maxNumber = numberPart;
          }
        }
      });

      const nextNumber = maxNumber + 1;
      return {
        nextTableNumber: `T${String(nextNumber).padStart(2, '0')}`,
        currentTableCount: tables.length,
        maxNumber: maxNumber
      };
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getTableByNumber(branchId, tableNumber) {
    try {
      const table = await knex('tables')
        .select(
          'tables.*',
          'branches.name as branch_name',
          'floors.name as floor_name',
          'floors.floor_number'
        )
        .join('branches', 'tables.branch_id', 'branches.id')
        .join('floors', 'tables.floor_id', 'floors.id')
        .where('tables.branch_id', branchId)
        .where('tables.table_number', tableNumber)
        .first();

      if (!table) {
        throw new ApiError(404, 'Table not found');
      }

      return table;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }
}

module.exports = TableService;