const knex = require('../database/knex');
const ApiError = require('../api-error');

class FloorService {

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

  async createFloor(floorData) {
    try {
      const existingFloor = await knex('floors')
        .where('branch_id', floorData.branch_id)
        .where('floor_number', floorData.floor_number)
        .where('status', 'active')
        .first();

      if (existingFloor) {
        throw new ApiError(400, 'Active floor with this number already exists in this branch');
      }

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

  async updateFloor(id, floorData) {
    try {

      const existingFloor = await knex('floors')
        .where('id', id)
        .first();

      if (!existingFloor) {
        throw new ApiError(404, 'Floor not found');
      }

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

  async deleteFloor(id) {
    try {
      const existingFloor = await knex('floors')
        .where('id', id)
        .first();

      if (!existingFloor) {
        throw new ApiError(404, 'Floor not found');
      }

      // Kiểm tra có bàn đang sử dụng không
      const activeTables = await knex('tables')
        .where('floor_id', id)
        .whereIn('status', ['occupied', 'reserved'])
        .first();

      if (activeTables) {
        throw new ApiError(400, 'Không thể xóa tầng có bàn đang sử dụng hoặc đã đặt!');
      }

      // Kiểm tra quy tắc xóa tầng: chỉ được xóa tầng có số tầng lớn nhất
      const maxFloorNumber = await knex('floors')
        .where('branch_id', existingFloor.branch_id)
        .max('floor_number as max_floor')
        .first();

      if (maxFloorNumber && existingFloor.floor_number < maxFloorNumber.max_floor) {
        throw new ApiError(400, `Không thể xóa tầng ${existingFloor.floor_number}. Bạn chỉ có thể xóa tầng có số tầng lớn nhất (${maxFloorNumber.max_floor}) trong chi nhánh này. Vui lòng xóa từ tầng cao nhất xuống tầng thấp nhất.`);
      }

      await knex('floors')
        .where('id', id)
        .del();

      return { 
        message: 'Floor deleted successfully',
        deletedFloorNumber: existingFloor.floor_number,
        branchId: existingFloor.branch_id
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

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

  async generateNextFloorNumber(branchId) {
    try {
      const floors = await this.getFloorsByBranch(branchId);

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
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }
}

module.exports = FloorService;