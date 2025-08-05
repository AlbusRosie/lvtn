const BranchService = require('../services/BranchService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

class BranchController {
  constructor() {
    this.branchService = new BranchService();
  }

  // Get all branches
  async getAllBranches(req, res, next) {
    try {
      const { status } = req.query;
      const branches = await this.branchService.getAllBranches(status);
      res.json(success(branches));
    } catch (error) {
      next(error);
    }
  }

  // Get branch by ID
  async getBranchById(req, res, next) {
    try {
      const { id } = req.params;
      const branch = await this.branchService.getBranchById(id);
      res.json(success(branch));
    } catch (error) {
      next(error);
    }
  }

  // Create new branch
  async createBranch(req, res, next) {
    try {
      console.log('Create branch request body:', req.body);
      const { name, address, phone, email, manager_id, status, opening_hours, description } = req.body;

      // Validation
      console.log('Validating name:', name, 'type:', typeof name);
      if (!name || !name.trim()) {
        throw new ApiError(400, 'Branch name is required');
      }

      console.log('Validating address:', address, 'type:', typeof address);
      if (!address || !address.trim()) {
        throw new ApiError(400, 'Branch address is required');
      }

      console.log('Validating phone:', phone, 'type:', typeof phone);
      if (!phone || !phone.trim()) {
        throw new ApiError(400, 'Branch phone is required');
      }

      console.log('Validating email:', email, 'type:', typeof email);
      if (!email || !email.trim()) {
        throw new ApiError(400, 'Branch email is required');
      }

      // Validate status if provided
      if (status && !['active', 'inactive', 'maintenance'].includes(status)) {
        throw new ApiError(400, 'Invalid status value');
      }

      const branchData = {
        name: name.trim(),
        address: address.trim(),
        phone: phone.trim(),
        email: email.trim(),
        manager_id: manager_id ? parseInt(manager_id) : null,
        status: status || 'active',
        opening_hours: opening_hours ? opening_hours.trim() : null,
        description: description ? description.trim() : null
      };

      console.log('Branch data to create:', branchData);

      const branch = await this.branchService.createBranch(branchData);
      res.status(201).json(success(branch, 'Branch created successfully'));
    } catch (error) {
      console.error('Error creating branch:', error);
      next(error);
    }
  }

  // Update branch
  async updateBranch(req, res, next) {
    try {
      const { id } = req.params;
      const { name, address, phone, email, manager_id, status, opening_hours, description } = req.body;

      // Validation
      if (name !== undefined && (!name || !name.trim())) {
        throw new ApiError(400, 'Branch name cannot be empty');
      }

      if (address !== undefined && (!address || !address.trim())) {
        throw new ApiError(400, 'Branch address cannot be empty');
      }

      if (phone !== undefined && (!phone || !phone.trim())) {
        throw new ApiError(400, 'Branch phone cannot be empty');
      }

      if (email !== undefined && (!email || !email.trim())) {
        throw new ApiError(400, 'Branch email cannot be empty');
      }

      if (status !== undefined && !['active', 'inactive', 'maintenance'].includes(status)) {
        throw new ApiError(400, 'Invalid status value');
      }

      const branchData = {};
      if (name !== undefined) branchData.name = name.trim();
      if (address !== undefined) branchData.address = address.trim();
      if (phone !== undefined) branchData.phone = phone.trim();
      if (email !== undefined) branchData.email = email.trim();
      if (manager_id !== undefined) branchData.manager_id = manager_id ? parseInt(manager_id) : null;
      if (status !== undefined) branchData.status = status;
      if (opening_hours !== undefined) branchData.opening_hours = opening_hours ? opening_hours.trim() : null;
      if (description !== undefined) branchData.description = description ? description.trim() : null;

      const branch = await this.branchService.updateBranch(id, branchData);
      res.json(success(branch, 'Branch updated successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Delete branch
  async deleteBranch(req, res, next) {
    try {
      const { id } = req.params;
      const result = await this.branchService.deleteBranch(id);
      res.json(success(result, 'Branch deleted successfully'));
    } catch (error) {
      next(error);
    }
  }

  // Get branch statistics
  async getBranchStatistics(req, res, next) {
    try {
      const stats = await this.branchService.getBranchStatistics();
      res.json(success(stats));
    } catch (error) {
      next(error);
    }
  }

  // Get active branches
  async getActiveBranches(req, res, next) {
    try {
      const branches = await this.branchService.getActiveBranches();
      res.json(success(branches));
    } catch (error) {
      next(error);
    }
  }
}

module.exports = BranchController; 