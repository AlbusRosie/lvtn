const FloorService = require('../services/FloorService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

class FloorController {
  constructor() {
    this.floorService = new FloorService();
  }

  // Get all floors
  async getAllFloors(req, res, next) {
    try {
      const { status, branch_id } = req.query;
      const floors = await this.floorService.getAllFloors(status, branch_id);
      res.json(success(floors));
    } catch (error) {
      next(error);
    }
  }

  // Get floor by ID
  async getFloorById(req, res, next) {
    try {
      const { id } = req.params;
      const floor = await this.floorService.getFloorById(id);
      res.json(success(floor));
    } catch (error) {
      next(error);
    }
  }

  // Get floors by branch
  async getFloorsByBranch(req, res, next) {
    try {
      const { branch_id } = req.params;
      const floors = await this.floorService.getFloorsByBranch(branch_id);
      res.json(success(floors));
    } catch (error) {
      next(error);
    }
  }

  // Create new floor
  async createFloor(req, res, next) {
    try {
      console.log('Create floor request body:', req.body);
      const { branch_id, floor_number, name, description, capacity, status } = req.body;

      // Validation
      console.log('Validating branch_id:', branch_id, 'type:', typeof branch_id);
      if (!branch_id || branch_id === '') {
        throw new ApiError(400, 'Branch ID is required');
      }

      console.log('Validating floor_number:', floor_number, 'type:', typeof floor_number);
      if (!floor_number || floor_number < 1) {
        throw new ApiError(400, 'Floor number must be at least 1');
      }

      console.log('Validating name:', name, 'type:', typeof name);
      if (!name || !name.trim()) {
        throw new ApiError(400, 'Floor name is required');
      }

      console.log('Validating capacity:', capacity, 'type:', typeof capacity);
      if (!capacity || capacity < 1) {
        throw new ApiError(400, 'Capacity must be at least 1');
      }

      // Validate status if provided
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

      console.log('Floor data to create:', floorData);

      const floor = await this.floorService.createFloor(floorData);
      res.status(201).json(success(floor, 'Floor created successfully'));
    } catch (error) {
      console.error('Error creating floor:', error);
      next(error);
    }
  }

  // Update floor
  async updateFloor(req, res, next) {
    try {
      const { id } = req.params;
      const { branch_id, floor_number, name, description, capacity, status } = req.body;

      // Validation
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

      const floor = await this.floorService.updateFloor(id, floorData);
      res.json(success(floor, 'Floor updated successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Delete floor
  async deleteFloor(req, res, next) {
    try {
      const { id } = req.params;
      const result = await this.floorService.deleteFloor(id);
      res.json(success(result, 'Floor deleted successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Get floor statistics
  async getFloorStatistics(req, res, next) {
    try {
      const { branch_id } = req.query;
      const stats = await this.floorService.getFloorStatistics(branch_id);
      res.json(success(stats));
    } catch (error) {
      next(error);
    }
  }

  // Get active floors
  async getActiveFloors(req, res, next) {
    try {
      const { branch_id } = req.query;
      const floors = await this.floorService.getActiveFloors(branch_id);
      res.json(success(floors));
    } catch (error) {
      next(error);
    }
  }

  // Generate next floor number
  async generateNextFloorNumber(req, res, next) {
    try {
      const { branch_id } = req.params;
      
      if (!branch_id) {
        throw new ApiError(400, 'Branch ID is required');
      }

      const result = await this.floorService.generateNextFloorNumber(branch_id);
      res.json(success(result));
    } catch (error) {
      next(error);
    }
  }
}

module.exports = FloorController; 