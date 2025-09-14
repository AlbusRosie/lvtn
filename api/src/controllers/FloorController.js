const FloorService = require('../services/FloorService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

async function createFloor(req, res, next) {
  try {
    const { branch_id, floor_number, name, description, capacity, status } = req.body;

    if (!branch_id || branch_id === '') {
      throw new ApiError(400, 'Branch ID is required');
    }

    if (!floor_number || floor_number < 1) {
      throw new ApiError(400, 'Floor number must be at least 1');
    }

    if (!name || !name.trim()) {
      throw new ApiError(400, 'Floor name is required');
    }

    if (!capacity || capacity < 1) {
      throw new ApiError(400, 'Capacity must be at least 1');
    }

    if (status && !['active', 'inactive', 'maintenance'].includes(status)) {
      throw new ApiError(400, 'Invalid status value');
    }

    const floorData = {
      branch_id: parseInt(branch_id),
      floor_number: parseInt(floor_number),
      name: name.trim(),
      description: description ? description.trim() : null,
      capacity: parseInt(capacity),
      status: status || 'active'
    };

    const floor = await FloorService.createFloor(floorData);
    res.status(201).json(success(floor, 'Floor created successfully'));
  } catch (error) {
    next(error);
  }
}

async function getAllFloors(req, res, next) {
  try {
    const { status, branch_id } = req.query;
    const floors = await FloorService.getAllFloors(status, branch_id);
    res.json(success(floors));
  } catch (error) {
    next(error);
  }
}

async function getFloorById(req, res, next) {
  try {
    const { id } = req.params;
    const floor = await FloorService.getFloorById(id);
    res.json(success(floor));
  } catch (error) {
    next(error);
  }
}

async function updateFloor(req, res, next) {
  try {
    const { id } = req.params;
    const { branch_id, floor_number, name, description, capacity, status } = req.body;

    if (branch_id !== undefined && !branch_id) {
      throw new ApiError(400, 'Branch ID cannot be empty');
    }

    if (floor_number !== undefined && floor_number < 1) {
      throw new ApiError(400, 'Floor number must be at least 1');
    }

    if (name !== undefined && (!name || !name.trim())) {
      throw new ApiError(400, 'Floor name cannot be empty');
    }

    if (capacity !== undefined && capacity < 1) {
      throw new ApiError(400, 'Capacity must be at least 1');
    }

    if (status !== undefined && !['active', 'inactive', 'maintenance'].includes(status)) {
      throw new ApiError(400, 'Invalid status value');
    }

    const floorData = {};
    if (branch_id !== undefined) floorData.branch_id = parseInt(branch_id);
    if (floor_number !== undefined) floorData.floor_number = parseInt(floor_number);
    if (name !== undefined) floorData.name = name.trim();
    if (description !== undefined) floorData.description = description ? description.trim() : null;
    if (capacity !== undefined) floorData.capacity = parseInt(capacity);
    if (status !== undefined) floorData.status = status;

    const floor = await FloorService.updateFloor(id, floorData);
    res.json(success(floor, 'Floor updated successfully'));
  } catch (error) {
    next(error);
  }
}

async function deleteFloor(req, res, next) {
  try {
    const { id } = req.params;
    const result = await FloorService.deleteFloor(id);
    res.json(success(result, 'Floor deleted successfully'));
  } catch (error) {
    next(error);
  }
}

async function getFloorsByBranch(req, res, next) {
  try {
    const { branch_id } = req.params;
    const floors = await FloorService.getFloorsByBranch(branch_id);
    res.json(success(floors));
  } catch (error) {
    next(error);
  }
}

async function getActiveFloors(req, res, next) {
  try {
    const { branch_id } = req.query;
    const floors = await FloorService.getActiveFloors(branch_id);
    res.json(success(floors));
  } catch (error) {
    next(error);
  }
}

async function getFloorStatistics(req, res, next) {
  try {
    const { branch_id } = req.query;
    const stats = await FloorService.getFloorStatistics(branch_id);
    res.json(success(stats));
  } catch (error) {
    next(error);
  }
}

async function generateNextFloorNumber(req, res, next) {
  try {
    const { branch_id } = req.params;

    if (!branch_id) {
      throw new ApiError(400, 'Branch ID is required');
    }

    const result = await FloorService.generateNextFloorNumber(branch_id);
    res.json(success(result));
  } catch (error) {
    next(error);
  }
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