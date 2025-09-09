const knex = require('../database/knex');
const ApiError = require('../api-error');

class BranchService {

  async getAllBranches(status = null, searchTerm = null, provinceId = null, districtId = null) {
    try {
      let query = knex('branches')
        .select(
          'branches.*',
          'provinces.name as province_name',
          'districts.name as district_name'
        )
        .leftJoin('provinces', 'branches.province_id', 'provinces.id')
        .leftJoin('districts', 'branches.district_id', 'districts.id')
        .orderBy('branches.name', 'asc');

      if (status) {
        query = query.where('branches.status', status);
      }

      if (searchTerm) {
        query = query.where(function() {
          this.where('branches.name', 'like', `%${searchTerm}%`)
            .orWhere('branches.address_detail', 'like', `%${searchTerm}%`)
            .orWhere('provinces.name', 'like', `%${searchTerm}%`)
            .orWhere('districts.name', 'like', `%${searchTerm}%`);
        });
      }

      if (provinceId) {
        query = query.where('branches.province_id', provinceId);
      }

      if (districtId) {
        query = query.where('branches.district_id', districtId);
      }

      const branches = await query;
      return branches;
    } catch (error) {
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async getBranchById(id) {
    try {
      const branch = await knex('branches')
        .select(
          'branches.*',
          'provinces.name as province_name',
          'districts.name as district_name'
        )
        .leftJoin('provinces', 'branches.province_id', 'provinces.id')
        .leftJoin('districts', 'branches.district_id', 'districts.id')
        .where('branches.id', id)
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

  async createBranch(branchData) {
    try {

      const existingBranch = await knex('branches')
        .where('name', branchData.name)
        .first();

      if (existingBranch) {
        throw new ApiError(400, 'Branch name already exists');
      }

      const existingEmail = await knex('branches')
        .where('email', branchData.email)
        .first();

      if (existingEmail) {
        throw new ApiError(400, 'Branch email already exists');
      }

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

  async updateBranch(id, branchData) {
    try {
      console.log('Updating branch:', id, branchData);

      const existingBranch = await knex('branches')
        .where('id', id)
        .first();

      if (!existingBranch) {
        throw new ApiError(404, 'Branch not found');
      }

      if (branchData.name && branchData.name !== existingBranch.name) {
        const nameConflict = await knex('branches')
          .where('name', branchData.name)
          .whereNot('id', id)
          .first();

        if (nameConflict) {
          throw new ApiError(400, 'Branch name already exists');
        }
      }

      if (branchData.email && branchData.email !== existingBranch.email) {
        const emailConflict = await knex('branches')
          .where('email', branchData.email)
          .whereNot('id', id)
          .first();

        if (emailConflict) {
          throw new ApiError(400, 'Branch email already exists');
        }
      }

      if (branchData.manager_id) {
        const manager = await knex('users').where('id', branchData.manager_id).first();
        if (!manager) {
          throw new ApiError(400, 'Manager not found');
        }
      }

      await knex('branches')
        .where('id', id)
        .update(branchData);

      console.log('Branch updated successfully, fetching updated data...');
      const updatedBranch = await this.getBranchById(id);
      console.log('Updated branch data:', updatedBranch);
      return updatedBranch;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

  async deleteBranch(id) {
    try {
      console.log('Deleting branch:', id);

      const existingBranch = await knex('branches')
        .where('id', id)
        .first();

      if (!existingBranch) {
        throw new ApiError(404, 'Branch not found');
      }

      // Kiểm tra xem có bàn đang được sử dụng không
      const occupiedTables = await knex('tables')
        .where('branch_id', id)
        .whereIn('status', ['occupied', 'reserved'])
        .first();

      if (occupiedTables) {
        throw new ApiError(400, 'Cannot delete branch that has occupied or reserved tables');
      }

      // Xóa tất cả dữ liệu liên quan theo thứ tự dependency
      console.log('Deleting related data...');
      
      // 1. Xóa order_details (có foreign key đến orders)
      await knex('order_details')
        .whereIn('order_id', function() {
          this.select('id').from('orders').where('branch_id', id);
        })
        .del();

      // 2. Xóa orders
      await knex('orders')
        .where('branch_id', id)
        .del();

      // 3. Xóa reservations
      await knex('reservations')
        .where('branch_id', id)
        .del();

      // 4. Xóa reviews
      await knex('reviews')
        .where('branch_id', id)
        .del();

      // 5. Xóa branch_products
      await knex('branch_products')
        .where('branch_id', id)
        .del();

      // 6. Xóa tables
      await knex('tables')
        .where('branch_id', id)
        .del();

      // 7. Xóa floors
      const deletedFloors = await knex('floors')
        .where('branch_id', id)
        .del();

      console.log(`Deleted ${deletedFloors} floors`);

      // 8. Cuối cùng xóa branch
      await knex('branches')
        .where('id', id)
        .del();

      console.log('Branch deleted successfully');
      return { 
        message: `Branch deleted successfully! Deleted ${deletedFloors} floors and all related data.`,
        deletedFloors 
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Database error: ' + error.message);
    }
  }

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