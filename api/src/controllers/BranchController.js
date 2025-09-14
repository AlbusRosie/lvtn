const BranchService = require('../services/BranchService');
const ApiError = require('../api-error');
const { success } = require('../jsend');


async function createBranch(req, res, next) {
  try {
    const { name, address_detail, phone, email, manager_id, status, opening_hours, description, province_id, district_id } = req.body;

    if (!name || !name.trim()) {
      throw new ApiError(400, 'Branch name is required');
    }

    if (!address_detail || !address_detail.trim()) {
      throw new ApiError(400, 'Branch address detail is required');
    } 

    if (!phone || !phone.trim()) {
      throw new ApiError(400, 'Branch phone is required');
    }

    if (!email || !email.trim()) {
      throw new ApiError(400, 'Branch email is required');
    }

    if (!province_id) {
      throw new ApiError(400, 'Province is required');
    }

    if (!district_id) {
      throw new ApiError(400, 'District is required');
    }

    if (status && !['active', 'inactive', 'maintenance'].includes(status)) {
      throw new ApiError(400, 'Invalid status value');
    }

    const currentUserId = req.user?.id;
    
    const branchData = {
      name: name.trim(),
      address_detail: address_detail.trim(),
      phone: phone.trim(),
      email: email.trim(),
      manager_id: manager_id ? parseInt(manager_id) : (currentUserId ? parseInt(currentUserId) : null),
      status: status || 'active',
      opening_hours: opening_hours ? opening_hours.trim() : null,
      description: description ? description.trim() : null,
      province_id: parseInt(province_id),
      district_id: parseInt(district_id)
    };

    const branch = await BranchService.createBranch(branchData);
    res.status(201).json(success(branch, 'Branch created successfully'));
  } catch (error) {
    next(error);
  }
}

async function getAllBranches(req, res, next) {
  try {
    const { status, search, province_id, district_id } = req.query;
    const branches = await BranchService.getAllBranches(status, search, province_id, district_id);
    res.json(success(branches));
  } catch (error) {
    next(error);
  }
}

async function getBranchById(req, res, next) {
  try {
    const { id } = req.params;
    const branch = await BranchService.getBranchById(id);
    res.json(success(branch));
  } catch (error) {
    next(error);
  }
}

async function updateBranch(req, res, next) {
  try {
    const { id } = req.params;
    const { name, address_detail, phone, email, manager_id, status, opening_hours, description, province_id, district_id } = req.body;

    if (name !== undefined && (!name || !name.trim())) {
      throw new ApiError(400, 'Branch name cannot be empty');
    }

    if (address_detail !== undefined && (!address_detail || !address_detail.trim())) {
      throw new ApiError(400, 'Branch address detail cannot be empty');
    }

    if (phone !== undefined && (!phone || !phone.trim())) {
      throw new ApiError(400, 'Branch phone cannot be empty');
    }

    if (email !== undefined && (!email || !email.trim())) {
      throw new ApiError(400, 'Branch email cannot be empty');
    }

    if (province_id !== undefined && !province_id) {
      throw new ApiError(400, 'Province is required');
    }

    if (district_id !== undefined && !district_id) {
      throw new ApiError(400, 'District is required');
    }

    if (status !== undefined && !['active', 'inactive', 'maintenance'].includes(status)) {
      throw new ApiError(400, 'Invalid status value');
    }

    const currentUserId = req.user?.id;
    
    const branchData = {};
    if (name !== undefined) branchData.name = name.trim();
    if (address_detail !== undefined) branchData.address_detail = address_detail.trim();
    if (phone !== undefined) branchData.phone = phone.trim();
    if (email !== undefined) branchData.email = email.trim();
    if (manager_id !== undefined) {
      branchData.manager_id = manager_id ? parseInt(manager_id) : (currentUserId ? parseInt(currentUserId) : null);
    }
    if (status !== undefined) branchData.status = status;
    if (opening_hours !== undefined) branchData.opening_hours = opening_hours ? opening_hours.trim() : null;
    if (description !== undefined) branchData.description = description ? description.trim() : null;
    if (province_id !== undefined) branchData.province_id = parseInt(province_id);
    if (district_id !== undefined) branchData.district_id = parseInt(district_id);

    const branch = await BranchService.updateBranch(id, branchData);
    res.json(success(branch, 'Branch updated successfully'));
  } catch (error) {
    next(error);
  }
}

async function deleteBranch(req, res, next) {
  try {
    const { id } = req.params;
    const result = await BranchService.deleteBranch(id);
    res.json(success(result, 'Branch deleted successfully'));
  } catch (error) {
    next(error);
  }
}

async function getActiveBranches(req, res, next) {
  try {
    const branches = await BranchService.getActiveBranches();
    res.json(success(branches));
  } catch (error) {
    next(error);
  }
}

async function getBranchStatistics(req, res, next) {
  try {
    const stats = await BranchService.getBranchStatistics();
    res.json(success(stats));
  } catch (error) {
    next(error);
  }
}

async function getManagers(req, res, next) {
  try {
    const managers = await BranchService.getManagers();
    res.json(success(managers));
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createBranch,
  getAllBranches,
  getBranchById,
  updateBranch,
  deleteBranch,
  getActiveBranches,
  getBranchStatistics,
  getManagers
};