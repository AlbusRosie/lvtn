const knex = require('../database/knex');

class ProductOptionService {

  static async getProductOptions(productId) {
    const optionTypes = await knex('product_option_types')
      .where('product_id', productId)
      .orderBy('display_order')
      .select('*');

    const results = [];
    for (const optionType of optionTypes) {
      const values = await knex('product_option_values')
        .where('option_type_id', optionType.id)
        .orderBy('display_order')
        .select('*');

      results.push({
        ...optionType,
        values
      });
    }

    return results;
  }

  static async createOptionType(productId, optionTypeData) {
    const { name, type = 'select', required = false, display_order = 0 } = optionTypeData;

    const [id] = await knex('product_option_types')
      .insert({
        product_id: productId,
        name,
        type,
        required,
        display_order
      });

    return await knex('product_option_types').where('id', id).first();
  }

  static async createOptionValue(optionTypeId, optionValueData) {
    const { value, price_modifier = 0, display_order = 0 } = optionValueData;

    const [id] = await knex('product_option_values')
      .insert({
        option_type_id: optionTypeId,
        value,
        price_modifier,
        display_order
      });

    return await knex('product_option_values').where('id', id).first();
  }

  static async updateOptionType(optionTypeId, updateData) {
    await knex('product_option_types')
      .where('id', optionTypeId)
      .update(updateData);

    return await knex('product_option_types').where('id', optionTypeId).first();
  }

  static async updateOptionValue(optionValueId, updateData) {
    const { value, price_modifier, display_order } = updateData;
    await knex('product_option_values')
      .where('id', optionValueId)
      .update({ value, price_modifier, display_order });

    return await knex('product_option_values').where('id', optionValueId).first();
  }

  static async deleteOptionType(optionTypeId) {
    const deletedCount = await knex('product_option_types')
      .where('id', optionTypeId)
      .del();

    return deletedCount > 0;
  }

  static async deleteOptionValue(optionValueId) {
    const deletedCount = await knex('product_option_values')
      .where('id', optionValueId)
      .del();

    return deletedCount > 0;
  }

  static async createProductOption(productId, optionData) {
    const { name, type, required, display_order, values = [] } = optionData;
    
    const optionType = await this.createOptionType(productId, {
      name, type, required, display_order
    });

    const optionValues = [];
    for (const valueData of values) {
      const value = await this.createOptionValue(optionType.id, valueData);
      optionValues.push(value);
    }

    return {
      ...optionType,
      values: optionValues
    };
  }

  static async updateProductOption(optionTypeId, optionData) {
    const { name, type, required, display_order, values = [] } = optionData;
    
    await this.updateOptionType(optionTypeId, {
      name, type, required, display_order
    });

    await knex('product_option_values')
      .where('option_type_id', optionTypeId)
      .del();

    const optionValues = [];
    for (const valueData of values) {
      const value = await this.createOptionValue(optionTypeId, valueData);
      optionValues.push(value);
    }

    return {
      id: optionTypeId,
      name, type, required, display_order,
      values: optionValues
    };
  }

  static async getOptionTypeWithValues(optionTypeId) {
    const optionType = await knex('product_option_types')
      .where('id', optionTypeId)
      .first();

    if (!optionType) return null;

    const values = await knex('product_option_values')
      .where('option_type_id', optionTypeId)
      .orderBy('display_order');

    return {
      ...optionType,
      values
    };
  }
}

module.exports = ProductOptionService;
