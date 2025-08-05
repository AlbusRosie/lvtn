const TableService = require('../services/TableService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

class TableController {
  constructor() {
    this.tableService = new TableService();
  }

  // Get all tables
  async getAllTables(req, res, next) {
    try {
      const { branch_id } = req.query;
      const tables = await this.tableService.getAllTables(branch_id);
      res.json(success(tables));
    } catch (error) {
      next(error);
    }
  }

  // Get tables by status
  async getTablesByStatus(req, res, next) {
    try {
      const { status } = req.params;
      const { branch_id } = req.query;
      const tables = await this.tableService.getTablesByStatus(status, branch_id);
      res.json(success(tables));
    } catch (error) {
      next(error);
    }
  }

  // Get table by ID
  async getTableById(req, res, next) {
    try {
      const { id } = req.params;
      const table = await this.tableService.getTableById(id);
      res.json(success(table));
    } catch (error) {
      next(error);
    }
  }

  // Create new table
  async createTable(req, res, next) {
    try {
      const { branch_id, floor_id, table_number, capacity, location, status } = req.body;

      console.log('Create table request body:', req.body);

      // Validation
      console.log('Validating branch_id:', branch_id, 'type:', typeof branch_id);
      if (!branch_id || branch_id === '') {
        throw new ApiError(400, 'Branch ID is required');
      }

      console.log('Validating floor_id:', floor_id, 'type:', typeof floor_id);
      if (!floor_id || floor_id === '') {
        throw new ApiError(400, 'Floor ID is required');
      }

      console.log('Validating table_number:', table_number, 'type:', typeof table_number);
      if (!table_number || !table_number.trim()) {
        throw new ApiError(400, 'Table number is required');
      }

      console.log('Validating capacity:', capacity, 'type:', typeof capacity);
      if (!capacity || capacity < 1) {
        throw new ApiError(400, 'Capacity must be at least 1');
      }

      // Validate status if provided
      if (status && !['available', 'occupied', 'reserved', 'maintenance'].includes(status)) {
        throw new ApiError(400, 'Invalid status value');
      }

      const tableData = {
        branch_id: parseInt(branch_id),
        floor_id: parseInt(floor_id),
        table_number: table_number.trim(),
        capacity: parseInt(capacity),
        location: location ? location.trim() : null,
        status: status || 'available'
      };

      console.log('Table data to create:', tableData);

      const table = await this.tableService.createTable(tableData);
      res.status(201).json(success(table, 'Table created successfully'));
    } catch (error) {
      console.error('Error creating table:', error);
      next(error);
    }
  }

  // Update table
  async updateTable(req, res, next) {
    try {
      const { id } = req.params;
      const { branch_id, floor_id, table_number, capacity, status, location } = req.body;

      // Validation
      if (branch_id !== undefined && !branch_id) {
        throw new ApiError(400, 'Branch ID cannot be empty');
      }

      if (floor_id !== undefined && !floor_id) {
        throw new ApiError(400, 'Floor ID cannot be empty');
      }

      if (table_number !== undefined && (!table_number || !table_number.trim())) {
        throw new ApiError(400, 'Table number cannot be empty');
      }

      if (capacity !== undefined && capacity < 1) {
        throw new ApiError(400, 'Capacity must be at least 1');
      }

      if (status !== undefined && !['available', 'occupied', 'reserved', 'maintenance'].includes(status)) {
        throw new ApiError(400, 'Invalid status value');
      }

      const tableData = {};
      if (branch_id !== undefined) tableData.branch_id = parseInt(branch_id);
      if (floor_id !== undefined) tableData.floor_id = parseInt(floor_id);
      if (table_number !== undefined) tableData.table_number = table_number.trim();
      if (capacity !== undefined) tableData.capacity = parseInt(capacity);
      if (status !== undefined) tableData.status = status;
      if (location !== undefined) tableData.location = location ? location.trim() : null;

      const table = await this.tableService.updateTable(id, tableData);
      res.json(success(table, 'Table updated successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Update table status
  async updateTableStatus(req, res, next) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (!status || !['available', 'occupied', 'reserved', 'maintenance'].includes(status)) {
        throw new ApiError(400, 'Valid status is required');
      }

      const table = await this.tableService.updateTableStatus(id, status);
      res.json(success(table, 'Table status updated successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Delete table
  async deleteTable(req, res, next) {
    try {
      const { id } = req.params;
      const result = await this.tableService.deleteTable(id);
      res.json(success(result, 'Table deleted successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Get available tables
  async getAvailableTables(req, res, next) {
    try {
      const { branch_id } = req.query;
      const tables = await this.tableService.getAvailableTables(branch_id);
      res.json(success(tables));
    } catch (error) {
      next(error);
    }
  }

  // Get all branches
  async getAllBranches(req, res, next) {
    try {
      const branches = await this.tableService.getAllBranches();
      res.json(success(branches));
    } catch (error) {
      next(error);
    }
  }

  // Get floors by branch
  async getFloorsByBranch(req, res, next) {
    try {
      const { branch_id } = req.params;
      const floors = await this.tableService.getFloorsByBranch(branch_id);
      res.json(success(floors));
    } catch (error) {
      next(error);
    }
  }

  // Get tables by branch and floor
  async getTablesByBranchAndFloor(req, res, next) {
    try {
      const { branch_id, floor_id } = req.params;
      const tables = await this.tableService.getTablesByBranchAndFloor(branch_id, floor_id);
      res.json(success(tables));
    } catch (error) {
      next(error);
    }
  }

  // Get table statistics
  async getTableStatistics(req, res, next) {
    try {
      const { branch_id } = req.query;
      const stats = await this.tableService.getTableStatistics(branch_id);
      res.json(success(stats));
    } catch (error) {
      next(error);
    }
  }

  // Generate next table number
  async generateNextTableNumber(req, res, next) {
    try {
      const { branch_id, floor_id } = req.params;
      
      if (!branch_id || !floor_id) {
        throw new ApiError(400, 'Branch ID and Floor ID are required');
      }

      const result = await this.tableService.generateNextTableNumber(branch_id, floor_id);
      res.json(success(result));
    } catch (error) {
      next(error);
    }
  }

  // Get table by number and branch
  async getTableByNumber(req, res, next) {
    try {
      const { branch_id, table_number } = req.params;
      
      if (!branch_id || !table_number) {
        throw new ApiError(400, 'Branch ID and Table Number are required');
      }

      const table = await this.tableService.getTableByNumber(branch_id, table_number);
      res.json(success(table));
    } catch (error) {
      next(error);
    }
  }
}

module.exports = TableController; 