const knex = require('../database/knex');
const ApiError = require('../api-error');

class FloorService {
  // Get all floors
  async getAllFloors(status = null, branchId = null) {
    try {
      let query = knex('floors')
        .select('floors.*', 'branches.name as branch_name')
        .join('branches', 'floors.branch_id', 'branches.id')
        .orderBy('branches.name', 'asc')
        .orderBy('floors.floor_number', 'asc');

      if (status) {
        query = query.where('floors.status', status);
      }

      if (branchId) {
        query = query.where('floors.branch_id', branchId);
      }

      const floors = await query;
      return floors;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get floor by ID
  async getFloorById(id) {
    try {
      const floor = await knex('floors')
        .select('floors.*', 'branches.name as branch_name')
        .join('branches', 'floors.branch_id', 'branches.id')
        .where('floors.id', id)
        .first();

      if (!floor) {
        throw new ApiError(404, 'Floor not found');
      }

      return floor;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get floors by branch
  async getFloorsByBranch(branchId) {
    try {
      const floors = await knex('floors')
        .select('*')
        .where('branch_id', branchId)
        .orderBy('floor_number', 'asc');

      return floors;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Create new floor
  async createFloor(floorData) {
    try {
      console.log('FloorService.createFloor called with:', floorData);

      // Check if floor number already exists in the same branch (only for active floors)
      const existingFloor = await knex('floors')
        .where('branch_id', floorData.branch_id)
        .where('floor_number', floorData.floor_number)
        .where('status', 'active')
        .first();

      if (existingFloor) {
        throw new ApiError(400, 'Active floor with this number already exists in this branch');
      }

      // Validate branch exists
      const branch = await knex('branches').where('id', floorData.branch_id).first();
      if (!branch) {
        throw new ApiError(400, 'Branch not found');
      }

      const [floorId] = await knex('floors')
        .insert(floorData)
        .returning('id');

      return this.getFloorById(floorId);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Update floor
  async updateFloor(id, floorData) {
    try {
      // Check if floor exists
      const existingFloor = await knex('floors')
        .where('id', id)
        .first();

      if (!existingFloor) {
        throw new ApiError(404, 'Floor not found');
      }

      // Check if new floor number conflicts with other active floors in the same branch
      if (floorData.floor_number && floorData.floor_number !== existingFloor.floor_number) {
        const branchId = floorData.branch_id || existingFloor.branch_id;
        const numberConflict = await knex('floors')
          .where('branch_id', branchId)
          .where('floor_number', floorData.floor_number)
          .where('status', 'active')
          .whereNot('id', id)
          .first();

        if (numberConflict) {
          throw new ApiError(400, 'Active floor with this number already exists in this branch');
        }
      }

      // Validate branch exists if being updated
      if (floorData.branch_id) {
        const branch = await knex('branches').where('id', floorData.branch_id).first();
        if (!branch) {
          throw new ApiError(400, 'Branch not found');
        }
      }

      await knex('floors')
        .where('id', id)
        .update(floorData);

      return this.getFloorById(id);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Delete floor
  async deleteFloor(id) {
    try {
      // Check if floor exists
      const existingFloor = await knex('floors')
        .where('id', id)
        .first();

      if (!existingFloor) {
        throw new ApiError(404, 'Floor not found');
      }

      // Check if floor has active tables
      const activeTables = await knex('tables')
        .where('floor_id', id)
        .whereIn('status', ['occupied', 'reserved'])
        .first();

      if (activeTables) {
        throw new ApiError(400, 'Cannot delete floor that has occupied or reserved tables');
      }

      await knex('floors')
        .where('id', id)
        .del();

      return { message: 'Floor deleted successfully' };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get floor statistics
  async getFloorStatistics(branchId = null) {
    try {
      let query = knex('floors')
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
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get active floors
  async getActiveFloors(branchId = null) {
    try {
      let query = knex('floors')
        .select('*')
        .where('status', 'active')
        .orderBy('floor_number', 'asc');

      if (branchId) {
        query = query.where('branch_id', branchId);
      }

      const floors = await query;
      return floors;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Generate next floor number for a branch
  async generateNextFloorNumber(branchId) {
    try {
      const floors = await this.getFloorsByBranch(branchId);
      
      // Tìm số tầng lớn nhất
      let maxNumber = 0;
      floors.forEach(floor => {
        const floorNumber = floor.floor_number;
        if (floorNumber && floorNumber > maxNumber) {
          maxNumber = floorNumber;
        }
      });

      // Tạo số tầng mới
      const nextNumber = maxNumber + 1;
      return {
        nextFloorNumber: nextNumber,
        currentFloorCount: floors.length,
        maxNumber: maxNumber
      };
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }
}

module.exports = FloorService; 