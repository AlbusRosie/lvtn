const TableService = require('../services/TableService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

async function getAllTables(req, res, next) {
  try {
    const { branch_id } = req.query;
    const tables = await TableService.getAllTables(branch_id);
    res.json(success(tables));
  } catch (error) {
    next(error);
  }
}

async function getTablesByStatus(req, res, next) {
  try {
    const { status } = req.params;
    const { branch_id } = req.query;
    const tables = await TableService.getTablesByStatus(status, branch_id);
    res.json(success(tables));
  } catch (error) {
    next(error);
  }
}

async function getTableById(req, res, next) {
  try {
    const { id } = req.params;
    const table = await TableService.getTableById(id);
    res.json(success(table));
  } catch (error) {
    next(error);
  }
}

async function createTable(req, res, next) {
  try {
    const { branch_id, floor_id, table_number, capacity, location, status } = req.body;

    if (!branch_id || branch_id === '') {
      throw new ApiError(400, 'Branch ID is required');
    }
    if (!floor_id || floor_id === '') {
      throw new ApiError(400, 'Floor ID is required');
    }
    if (!table_number || !table_number.trim()) {
      throw new ApiError(400, 'Table number is required');
    }
    if (!capacity || capacity < 1) {
      throw new ApiError(400, 'Capacity must be at least 1');
    }

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
    const table = await TableService.createTable(tableData);
    res.status(201).json(success(table, 'Table created successfully'));
  } catch (error) {
    next(error);
  }
}

async function updateTable(req, res, next) {
  try {
    const { id } = req.params;
    const { branch_id, floor_id, table_number, capacity, status, location } = req.body;

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

    const table = await TableService.updateTable(id, tableData);
    res.json(success(table, 'Table updated successfully'));
  } catch (error) {
    next(error);
  }
}

async function updateTableStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['available', 'occupied', 'reserved', 'maintenance'].includes(status)) {
      throw new ApiError(400, 'Valid status is required');
    }

    const table = await TableService.updateTableStatus(id, status);
    res.json(success(table, 'Table status updated successfully'));
  } catch (error) {
    next(error);
  }
}

async function deleteTable(req, res, next) {
  try {
    const { id } = req.params;
    const result = await TableService.deleteTable(id);
    res.json(success(result, 'Table deleted successfully'));
  } catch (error) {
    next(error);
  }
}

async function getAvailableTables(req, res, next) {
  try {
    const { branch_id } = req.query;
    const tables = await TableService.getAvailableTables(branch_id);
    res.json(success(tables));
  } catch (error) {
    next(error);
  }
}

async function getAllBranches(req, res, next) {
  try {
    const branches = await TableService.getAllBranches();
    res.json(success(branches));
  } catch (error) {
    next(error);
  }
}

async function getFloorsByBranch(req, res, next) {
  try {
    const { branch_id } = req.params;
    const floors = await TableService.getFloorsByBranch(branch_id);
    res.json(success(floors));
  } catch (error) {
    next(error);
  }
}

async function getTablesByBranchAndFloor(req, res, next) {
  try {
    const { branch_id, floor_id } = req.params;
    const tables = await TableService.getTablesByBranchAndFloor(branch_id, floor_id);
    res.json(success(tables));
  } catch (error) {
    next(error);
  }
}

async function getTableStatistics(req, res, next) {
  try {
    const { branch_id } = req.query;
    const stats = await TableService.getTableStatistics(branch_id);
    res.json(success(stats));
  } catch (error) {
    next(error);
  }
}

async function generateNextTableNumber(req, res, next) {
  try {
    const { branch_id, floor_id } = req.params;

    if (!branch_id || !floor_id) {
      throw new ApiError(400, 'Branch ID and Floor ID are required');
    }

    const result = await TableService.generateNextTableNumber(branch_id, floor_id);
    res.json(success(result));
  } catch (error) {
    next(error);
  }
}

async function getTableByNumber(req, res, next) {
  try {
    const { branch_id, table_number } = req.params;

    if (!branch_id || !table_number) {
      throw new ApiError(400, 'Branch ID and Table Number are required');
    }

    const table = await TableService.getTableByNumber(branch_id, table_number);
    res.json(success(table));
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllTables,
  getTablesByStatus,
  getTableById,
  createTable,
  updateTable,
  updateTableStatus,
  deleteTable,
  getAvailableTables,
  getAllBranches,
  getFloorsByBranch,
  getTablesByBranchAndFloor,
  getTableStatistics,
  generateNextTableNumber,
  getTableByNumber
};