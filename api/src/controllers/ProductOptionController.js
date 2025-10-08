const ProductOptionService = require('../services/ProductOptionService');
const ApiError = require('../api-error');
const { success } = require('../jsend');

async function getProductOptions(req, res, next) {
  try {
    const { productId } = req.params;
    const options = await ProductOptionService.getProductOptions(productId);
    res.json(success(options));
  } catch (error) {
    next(new ApiError(500, error.message));
  }
}

async function createProductOption(req, res, next) {
  try {
    const { productId } = req.params;
    const optionData = req.body;

    if (!optionData.name || !optionData.name.trim()) {
      throw new ApiError(400, 'Option name is required');
    }

    if (!['select', 'checkbox'].includes(optionData.type)) {
      throw new ApiError(400, 'Invalid option type. Must be "select" or "checkbox"');
    }

    if (!Array.isArray(optionData.values) || optionData.values.length === 0) {
      throw new ApiError(400, 'At least one option value is required');
    }

    for (const value of optionData.values) {
      if (!value.value) {
        throw new ApiError(400, 'Each option value must have "value"');
      }
      if (value.price_modifier === undefined || value.price_modifier === null) {
        value.price_modifier = 0;
      }
    }

    const option = await ProductOptionService.createProductOption(productId, optionData);
    res.status(201).json(success(option, 'Product option created successfully'));
  } catch (error) {
    if (error instanceof ApiError) {
      next(error);
    } else {
      next(new ApiError(500, error.message));
    }
  }
}

async function updateProductOption(req, res, next) {
  try {
    const { optionTypeId } = req.params;
    const optionData = req.body;

    if (!optionData.name || !optionData.name.trim()) {
      throw new ApiError(400, 'Option name is required');
    }

    if (!['select', 'checkbox'].includes(optionData.type)) {
      throw new ApiError(400, 'Invalid option type. Must be "select" or "checkbox"');
    }

    if (!Array.isArray(optionData.values) || optionData.values.length === 0) {
      throw new ApiError(400, 'At least one option value is required');
    }

    for (const value of optionData.values) {
      if (!value.value) {
        throw new ApiError(400, 'Each option value must have "value"');
      }
      if (value.price_modifier === undefined || value.price_modifier === null) {
        value.price_modifier = 0;
      }
    }

    const option = await ProductOptionService.updateProductOption(optionTypeId, optionData);
    res.json(success(option, 'Product option updated successfully'));
  } catch (error) {
    if (error instanceof ApiError) {
      next(error);
    } else {
      next(new ApiError(500, error.message));
    }
  }
}

async function deleteProductOption(req, res, next) {
  try {
    const { optionTypeId } = req.params;
    const deleted = await ProductOptionService.deleteOptionType(optionTypeId);
    
    if (!deleted) {
      throw new ApiError(404, 'Product option not found');
    }
    
    res.json(success(null, 'Product option deleted successfully'));
  } catch (error) {
    if (error instanceof ApiError) {
      next(error);
    } else {
      next(new ApiError(500, error.message));
    }
  }
}

async function getProductOption(req, res, next) {
  try {
    const { optionTypeId } = req.params;
    const option = await ProductOptionService.getOptionTypeWithValues(optionTypeId);
    
    if (!option) {
      throw new ApiError(404, 'Product option not found');
    } 
    
    res.json(success(option));
  } catch (error) {
    if (error instanceof ApiError) {
      next(error);
    } else {
      next(new ApiError(500, error.message));
    }
  }
}

module.exports = {
  getProductOptions,
  createProductOption,
  updateProductOption,
  deleteProductOption,
  getProductOption
};
