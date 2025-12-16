<template>
  <div class="options-manager">
    <div class="header">
      <div class="header-title">
        <i class="fas fa-list-ul"></i>
        <h4>Product Options</h4>
      </div>
      <button 
        type="button" 
        @click="addNewOption" 
        class="btn-add"
        :disabled="loading"
      >
        <i class="fas fa-plus"></i>
        <span>Add Option</span>
      </button>
    </div>
    <div v-if="options.length === 0" class="empty">
      <i class="fas fa-inbox"></i>
      <p>No options yet</p>
      <span>Click "Add Option" to get started</span>
    </div>
    <div v-else class="options">
      <div 
        v-for="(option, index) in options" 
        :key="option.id || `temp-${index}`"
        class="option"
      >
        <!-- Header với thông tin cơ bản -->
        <div class="option-header">
          <div class="option-info">
            <div class="input-group">
              <label class="input-label">
                <i class="fas fa-tag"></i>
                Option Name <span class="required">*</span>
              </label>
              <div class="input-wrapper">
                <i class="fas fa-tag input-icon"></i>
                <input
                  v-model="option.name"
                  type="text"
                  class="name-input"
                  :name="`option_${index}_name`"
                  placeholder="Option name (e.g.: Size, Flavor)"
                  @blur="validateOption(index)"
                />
              </div>
            </div>
            <div class="select-group">
              <label class="select-label">
              <i class="fas fa-list"></i>
                Type
              </label>
              <div class="select-wrapper">
                <i class="fas fa-list select-icon"></i>
              <select v-model="option.type" class="type-select">
                  <option value="select">Select One</option>
                  <option value="checkbox">Select Multiple</option>
              </select>
              </div>
            </div>
            <div class="checkbox-group">
            <label class="required-label">
              <input v-model="option.required" type="checkbox" class="checkbox-input" />
              <i class="fas fa-asterisk"></i>
                <span>Required</span>
            </label>
            </div>
          </div>
          <div class="option-buttons">
            <button 
              type="button" 
              @click="toggleOptionExpanded(index)"
              class="btn-toggle"
              :title="option.expanded ? 'Collapse' : 'Expand'"
            >
              <i class="fas" :class="option.expanded ? 'fa-chevron-up' : 'fa-chevron-down'"></i>
            </button>
            <button 
              type="button" 
              @click="removeOption(index)"
              class="btn-delete"
              :disabled="loading"
              title="Delete Option"
            >
              <i class="fas fa-trash"></i>
            </button>
          </div>
        </div>
        <!-- Chi tiết các giá trị (collapsed) -->
        <div v-show="option.expanded" class="option-details">
          <div class="details-header">
            <div class="details-title">
              <i class="fas fa-list-check"></i>
              <span>Options:</span>
            </div>
            <button 
              type="button" 
              @click="addOptionValue(index)"
              class="btn-add-value"
            >
              <i class="fas fa-plus"></i>
              <span>Add Value</span>
            </button>
          </div>
          <div class="values">
            <div 
              v-for="(value, valueIndex) in option.values" 
              :key="value.id || `temp-${valueIndex}`"
              class="value-row"
            >
              <div class="value-input-group">
                <label class="value-label">
                  <i class="fas fa-tag"></i>
                  Value <span class="required">*</span>
                </label>
                <div class="value-wrapper">
                  <i class="fas fa-tag value-icon"></i>
                  <input
                    v-model="value.value"
                    type="text"
                    class="value-input"
                    :name="`option_${index}_value_${valueIndex}`"
                    placeholder="Value (e.g.: S, M, L)"
                    @blur="validateOption(index)"
                  />
                </div>
              </div>
              <div class="price-input-group">
                <label class="price-label">
                <i class="fas fa-dollar-sign"></i>
                  Price
                </label>
                <div class="price-wrapper">
                  <i class="fas fa-dollar-sign price-icon"></i>
                <input
                  v-model.number="value.price_modifier"
                  type="number"
                  class="price-input"
                  :name="`option_${index}_price_${valueIndex}`"
                  placeholder="0"
                  step="1000"
                  min="0"
                />
                </div>
              </div>
              <button 
                type="button" 
                @click="removeOptionValue(index, valueIndex)"
                class="btn-delete-value"
                title="Delete Value"
              >
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, reactive, watch } from 'vue';
const props = defineProps({
  options: {
    type: Array,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
});
const emit = defineEmits(['update:options', 'validate-option']);
const addNewOption = () => {
  const newOption = {
    id: null,
    name: '',
    type: 'select',
    required: false,
    display_order: props.options.length,
    expanded: true,
    values: [
      {
        id: null,
        value: '',
        label: '',
        price_modifier: 0,
        display_order: 0
      }
    ]
  };
  const updatedOptions = [...props.options, newOption];
  emit('update:options', updatedOptions);
};
const removeOption = (index) => {
  const updatedOptions = props.options.filter((_, i) => i !== index);
  updatedOptions.forEach((option, i) => {
    option.display_order = i;
  });
  emit('update:options', updatedOptions);
};
const toggleOptionExpanded = (index) => {
  const updatedOptions = [...props.options];
  if (!updatedOptions[index].values || updatedOptions[index].values.length === 0) {
    updatedOptions[index].values = [
      {
        id: null,
        value: '',
        price_modifier: 0,
        display_order: 0,
      }
    ];
  }
  updatedOptions[index].expanded = !updatedOptions[index].expanded;
  emit('update:options', updatedOptions);
};
const addOptionValue = (optionIndex) => {
  const updatedOptions = [...props.options];
  const newValue = {
    id: null,
    value: '',
    label: '',
    price_modifier: 0,
    display_order: updatedOptions[optionIndex].values.length
  };
  updatedOptions[optionIndex].values.push(newValue);
  emit('update:options', updatedOptions);
};
const removeOptionValue = (optionIndex, valueIndex) => {
  const updatedOptions = [...props.options];
  updatedOptions[optionIndex].values.splice(valueIndex, 1);
  updatedOptions[optionIndex].values.forEach((value, i) => {
    value.display_order = i;
  });
  emit('update:options', updatedOptions);
};
const validateOption = (index) => {
  const option = props.options[index];
  const isValid = option.name.trim() !== '' && 
                  option.values.length > 0 && 
                  option.values.every(v => v.value.trim() !== '');
  emit('validate-option', { index, isValid, option });
};
watch(() => props.options.length, (newLength, oldLength) => {
  if (newLength > oldLength) {
    const updatedOptions = [...props.options];
    updatedOptions[newLength - 1].expanded = true;
    emit('update:options', updatedOptions);
  }
});
watch(() => props.options, (opts) => {
  if (!Array.isArray(opts)) return;
  let changed = false;
  const updated = opts.map((o, idx) => {
    if ((!o.id || o.id === null) && (!o.values || o.values.length === 0)) {
      changed = true;
      return {
        ...o,
        values: [
          { id: null, value: '', price_modifier: 0, display_order: 0 }
        ],
      };
    }
    if (!o.values || !Array.isArray(o.values)) {
      changed = true;
      return {
        ...o,
        values: []
      };
    }
    return o;
  });
  if (changed) emit('update:options', updated);
}, { immediate: false, deep: false });
</script>
<style scoped>
.options-manager {
  margin-top: 24px;
  padding-top: 24px;
  border-top: 2px solid #F0E6D9;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}
.header-title {
  display: flex;
  align-items: center;
  gap: 10px;
}
.header-title i {
  color: #FF8C42;
  font-size: 16px;
}
.header h4 {
  margin: 0;
  color: #1a1a1a;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.2px;
}
.btn-add {
  background: white;
  color: #10B981;
  border: 2px solid #10B981;
  border-radius: 10px;
  padding: 10px 18px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
}
.btn-add:hover:not(:disabled) {
  background: #ECFDF5;
  border-color: #059669;
  color: #059669;
}
.btn-add:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-add i {
  font-size: 12px;
}
.empty {
  text-align: center;
  padding: 40px 20px;
  background: #FFF9F5;
  border: 2px dashed #F0E6D9;
  border-radius: 12px;
  color: #6B7280;
}
.empty i {
  font-size: 48px;
  color: #D1D5DB;
  margin-bottom: 12px;
  display: block;
}
.empty p {
  margin: 0 0 8px 0;
  font-size: 14px;
  font-weight: 600;
  color: #1a1a1a;
}
.empty span {
  font-size: 12px;
  color: #9CA3AF;
}
.options {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.option {
  border: 2px solid #F0E6D9;
  border-radius: 12px;
  background: #FFF9F5;
  overflow: hidden;
}
.option-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 16px;
  gap: 12px;
  background: white;
  border-bottom: 2px solid #F0E6D9;
}
.option-info {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  flex: 1;
  flex-wrap: nowrap;
}
.input-group {
  flex: 1;
  min-width: 200px;
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.select-group {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 140px;
}
.select-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
  margin: 0;
  height: 20px;
}
.select-label i {
  color: #FF8C42;
  font-size: 11px;
}
.select-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}
.select-icon {
  position: absolute;
  left: 12px;
  color: #FF8C42;
  font-size: 12px;
  z-index: 1;
  pointer-events: none;
}
.checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 120px;
}
.checkbox-group::before {
  content: '';
  display: block;
  height: 20px;
}
.input-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
  margin: 0;
}
.input-label i {
  color: #FF8C42;
  font-size: 11px;
}
.input-label .required,
.value-label .required {
  color: #EF4444;
  font-weight: 700;
  margin-left: 2px;
}
.name-input {
  width: 100%;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  padding: 10px 12px 10px 36px;
  font-size: 13px;
  font-weight: 500;
  background: white;
  color: #1a1a1a;
  transition: all 0.2s ease;
  position: relative;
}
.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}
.input-icon {
  position: absolute;
  left: 12px;
  color: #FF8C42;
  font-size: 12px;
  z-index: 1;
  pointer-events: none;
}
.name-input:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.name-input::placeholder {
  color: #9CA3AF;
  font-weight: 400;
}
.type-select {
  width: 100%;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  padding: 10px 12px 10px 36px;
  font-size: 13px;
  font-weight: 500;
  background: white;
  color: #1a1a1a;
  cursor: pointer;
  transition: all 0.2s ease;
}
.type-select:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.required-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #1a1a1a;
  cursor: pointer;
  white-space: nowrap;
  padding: 10px 12px;
  background: #FFF9F5;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  transition: all 0.2s ease;
  height: 40px;
  box-sizing: border-box;
}
.required-label:hover {
  background: #FFF5ED;
  border-color: #FF8C42;
}
.checkbox-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
}
.required-label i {
  color: #EF4444;
  font-size: 11px;
}
.option-buttons {
  display: flex;
  gap: 8px;
  align-items: flex-start;
  padding-top: 20px;
}
.btn-toggle, .btn-delete {
  width: 40px;
  height: 40px;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 10px;
  color: #6B7280;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  font-size: 14px;
  flex-shrink: 0;
}
.btn-toggle:hover {
  background: #F9FAFB;
  border-color: #D1D5DB;
  color: #4B5563;
}
.btn-delete:hover {
  background: #FEF2F2;
  border-color: #EF4444;
  color: #EF4444;
}
.option-details {
  padding: 16px;
  background: white;
}
.details-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 2px solid #F0E6D9;
}
.details-title {
  display: flex;
  align-items: center;
  gap: 8px;
}
.details-title i {
  color: #FF8C42;
  font-size: 14px;
}
.details-header span {
  font-size: 13px;
  color: #1a1a1a;
  font-weight: 600;
}
.btn-add-value {
  background: white;
  color: #10B981;
  border: 2px solid #10B981;
  border-radius: 8px;
  padding: 8px 14px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
}
.btn-add-value:hover {
  background: #ECFDF5;
  border-color: #059669;
  color: #059669;
}
.btn-add-value i {
  font-size: 11px;
}
.values {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.value-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px;
  background: #FFF9F5;
  border-radius: 10px;
  border: 2px solid #F0E6D9;
}
.value-input-group {
  flex: 1;
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.value-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
  margin: 0;
}
.value-label i {
  color: #FF8C42;
  font-size: 11px;
}
.value-label .required {
  color: #EF4444;
  font-weight: 700;
  margin-left: 2px;
}
.value-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}
.value-icon {
  position: absolute;
  left: 12px;
  color: #FF8C42;
  font-size: 12px;
  z-index: 1;
  pointer-events: none;
}
.value-input {
  width: 100%;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  padding: 10px 12px 10px 36px;
  font-size: 13px;
  font-weight: 500;
  background: white;
  color: #1a1a1a;
  transition: all 0.2s ease;
}
.value-input:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.value-input::placeholder {
  color: #9CA3AF;
  font-weight: 400;
}
.price-input-group {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 150px;
}
.price-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
  margin: 0;
  height: 20px;
}
.price-label i {
  color: #FF8C42;
  font-size: 11px;
}
.price-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}
.price-icon {
  position: absolute;
  left: 12px;
  color: #FF8C42;
  font-size: 12px;
  z-index: 1;
  pointer-events: none;
}
.price-input {
  width: 100%;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  padding: 10px 12px 10px 36px;
  font-size: 13px;
  font-weight: 500;
  background: white;
  color: #1a1a1a;
  transition: all 0.2s ease;
}
.price-input:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.price-input::placeholder {
  color: #9CA3AF;
  font-weight: 400;
}
.btn-delete-value {
  width: 36px;
  height: 40px;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 8px;
  color: #EF4444;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  font-size: 14px;
  flex-shrink: 0;
  margin-top: 20px;
}
.btn-delete-value:hover {
  background: #FEF2F2;
  border-color: #EF4444;
  color: #DC2626;
}
@media (max-width: 768px) {
  .option-header {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  .option-info {
    flex-direction: column;
    gap: 12px;
  }
  .input-group,
  .select-group {
    width: 100%;
  }
  .required-label {
    width: 100%;
    justify-content: center;
  }
  .value-row {
    flex-direction: column;
    gap: 10px;
  }
  .value-input-group,
  .price-input-group {
    width: 100%;
  }
  .price-input {
    width: 100%;
  }
  .btn-delete-value {
    width: 100%;
  }
  .header {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
  }
  .header-title {
    width: 100%;
  }
  .btn-add {
    width: 100%;
    justify-content: center;
  }
}
</style>