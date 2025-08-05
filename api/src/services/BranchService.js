const knex = require('../database/knex');
const ApiError = require('../api-error');

class BranchService {
  // Get all branches
  async getAllBranches(status = null) {
    try {
      let query = knex('branches')
        .select('*')
        .orderBy('name', 'asc');

      if (status) {
        query = query.where('status', status);
      }

      const branches = await query;
      return branches;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get branch by ID
  async getBranchById(id) {
    try {
      const branch = await knex('branches')
        .where('id', id)
        .first();

      if (!branch) {
        throw new ApiError(404, 'Branch not found');
      }

      return branch;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Create new branch
  async createBranch(branchData) {
    try {
      console.log('BranchService.createBranch called with:', branchData);

      // Check if branch name already exists
      const existingBranch = await knex('branches')
        .where('name', branchData.name)
        .first();

      if (existingBranch) {
        throw new ApiError(400, 'Branch name already exists');
      }

      // Check if branch email already exists
      const existingEmail = await knex('branches')
        .where('email', branchData.email)
        .first();

      if (existingEmail) {
        throw new ApiError(400, 'Branch email already exists');
      }

      // Validate manager exists if provided
      if (branchData.manager_id) {
        const manager = await knex('users').where('id', branchData.manager_id).first();
        if (!manager) {
          throw new ApiError(400, 'Manager not found');
        }
      }

      const [branchId] = await knex('branches')
        .insert(branchData)
        .returning('id');

      return this.getBranchById(branchId);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Update branch
  async updateBranch(id, branchData) {
    try {
      // Check if branch exists
      const existingBranch = await knex('branches')
        .where('id', id)
        .first();

      if (!existingBranch) {
        throw new ApiError(404, 'Branch not found');
      }

      // Check if new name conflicts with other branches
      if (branchData.name && branchData.name !== existingBranch.name) {
        const nameConflict = await knex('branches')
          .where('name', branchData.name)
          .whereNot('id', id)
          .first();

        if (nameConflict) {
          throw new ApiError(400, 'Branch name already exists');
        }
      }

      // Check if new email conflicts with other branches
      if (branchData.email && branchData.email !== existingBranch.email) {
        const emailConflict = await knex('branches')
          .where('email', branchData.email)
          .whereNot('id', id)
          .first();

        if (emailConflict) {
          throw new ApiError(400, 'Branch email already exists');
        }
      }

      // Validate manager exists if being updated
      if (branchData.manager_id) {
        const manager = await knex('users').where('id', branchData.manager_id).first();
        if (!manager) {
          throw new ApiError(400, 'Manager not found');
        }
      }

      await knex('branches')
        .where('id', id)
        .update(branchData);

      return this.getBranchById(id);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Delete branch
  async deleteBranch(id) {
    try {
      // Check if branch exists
      const existingBranch = await knex('branches')
        .where('id', id)
        .first();

      if (!existingBranch) {
        throw new ApiError(404, 'Branch not found');
      }

      // Check if branch has active floors
      const activeFloors = await knex('floors')
        .where('branch_id', id)
        .where('status', 'active')
        .first();

      if (activeFloors) {
        throw new ApiError(400, 'Cannot delete branch that has active floors');
      }

      // Check if branch has active tables
      const activeTables = await knex('tables')
        .where('branch_id', id)
        .whereIn('status', ['occupied', 'reserved'])
        .first();

      if (activeTables) {
        throw new ApiError(400, 'Cannot delete branch that has occupied or reserved tables');
      }

      await knex('branches')
        .where('id', id)
        .del();

      return { message: 'Branch deleted successfully' };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get branch statistics
  async getBranchStatistics() {
    try {
      const stats = await knex('branches')
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
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  // Get active branches
  async getActiveBranches() {
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
}

module.exports = BranchService; 