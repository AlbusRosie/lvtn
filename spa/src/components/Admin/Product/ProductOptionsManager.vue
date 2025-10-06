<template>
  <div class="options-manager">
    <div class="header">
      <h4>Tùy chọn sản phẩm</h4>
      <button 
        type="button" 
        @click="addNewOption" 
        class="btn-add"
        :disabled="loading"
      >
        <i class="fas fa-plus"></i> Thêm
      </button>
    </div>

    <div v-if="options.length === 0" class="empty">
      <p>Chưa có tùy chọn nào</p>
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
            <input
              v-model="option.name"
              type="text"
              class="name-input"
              placeholder="Tên tùy chọn (VD: Size, Gia vị)"
              @blur="validateOption(index)"
            />
            <select v-model="option.type" class="type-select">
              <option value="select">Chọn 1</option>
              <option value="checkbox">Chọn nhiều</option>
            </select>
            <label class="required-label">
              <input v-model="option.required" type="checkbox" />
              <span>Bắt buộc</span>
            </label>
          </div>
          <div class="option-buttons">
            <button 
              type="button" 
              @click="toggleOptionExpanded(index)"
              class="btn-toggle"
            >
              <i class="fas" :class="option.expanded ? 'fa-chevron-up' : 'fa-chevron-down'"></i>
            </button>
            <button 
              type="button" 
              @click="removeOption(index)"
              class="btn-delete"
              :disabled="loading"
            >
              <i class="fas fa-trash"></i>
            </button>
          </div>
        </div>

        <!-- Chi tiết các giá trị (collapsed) -->
        <div v-show="option.expanded" class="option-details">
          <div class="details-header">
            <span>Các lựa chọn:</span>
            <button 
              type="button" 
              @click="addOptionValue(index)"
              class="btn-add-value"
            >
              <i class="fas fa-plus"></i> Thêm
            </button>
          </div>

          <div class="values">
            <div 
              v-for="(value, valueIndex) in option.values" 
              :key="value.id || `temp-${valueIndex}`"
              class="value-row"
            >
              <input
                v-model="value.value"
                type="text"
                class="value-input"
                placeholder="Giá trị (VD: S, M, L)"
                @blur="validateOption(index)"
              />
              <!-- Nhãn đã loại bỏ ở DB, ẩn ô nhập -->
              <input
                v-model.number="value.price_modifier"
                type="number"
                class="price-input"
                placeholder="0"
                step="1000"
              />
              <button 
                type="button" 
                @click="removeOptionValue(index, valueIndex)"
                class="btn-delete-value"
                title="Xóa"
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
  
  // Reset display_order for remaining options
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
  
  // Reset display_order for remaining values in this option
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

// Auto-expand when option is added
watch(() => props.options.length, (newLength, oldLength) => {
  if (newLength > oldLength) {
    // New option was added, expand it
    const updatedOptions = [...props.options];
    updatedOptions[newLength - 1].expanded = true;
    emit('update:options', updatedOptions);
  }
});

// Ensure each option has at least one value row visible when expanded or on initial load
watch(() => props.options, (opts) => {
  if (!Array.isArray(opts)) return;
  let changed = false;
  const updated = opts.map((o, idx) => {
    if (!o.values || o.values.length === 0) {
      changed = true;
      return {
        ...o,
        values: [
          { id: null, value: '', price_modifier: 0, display_order: 0 }
        ],
      };
    }
    return o;
  });
  if (changed) emit('update:options', updated);
}, { immediate: true, deep: true });
</script>

<style scoped>
.options-manager {
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #e9ecef;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.header h4 {
  margin: 0;
  color: #495057;
  font-size: 15px;
}

.btn-add {
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 6px 10px;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 5px;
}

.btn-add:hover {
  background: #0056b3;
}

.empty {
  text-align: center;
  padding: 20px;
  color: #6c757d;
  font-size: 14px;
}

.options {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.option {
  border: 1px solid #e9ecef;
  border-radius: 4px;
  background: #f8f9fa;
}

.option-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 12px;
  gap: 10px;
}

.option-info {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 1;
}

.name-input {
  flex: 1;
  min-width: 120px;
  border: 1px solid #ced4da;
  border-radius: 3px;
  padding: 5px 7px;
  font-size: 12px;
}

.name-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 1px rgba(0, 123, 255, 0.25);
}

.type-select {
  border: 1px solid #ced4da;
  border-radius: 3px;
  padding: 5px 7px;
  font-size: 12px;
  min-width: 85px;
}

.required-label {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #495057;
  cursor: pointer;
  white-space: nowrap;
}

.required-label input {
  margin: 0;
}

.option-buttons {
  display: flex;
  gap: 5px;
}

.btn-toggle, .btn-delete {
  background: none;
  border: none;
  color: #6c757d;
  cursor: pointer;
  padding: 3px;
  border-radius: 2px;
  font-size: 11px;
}

.btn-toggle:hover {
  background: #e9ecef;
}

.btn-delete:hover {
  background: #f8d7da;
  color: #dc3545;
}

.option-details {
  padding: 10px 12px;
  background: white;
  border-top: 1px solid #e9ecef;
}

.details-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.details-header span {
  font-size: 12px;
  color: #6c757d;
  font-weight: 500;
}

.btn-add-value {
  background: #28a745;
  color: white;
  border: none;
  border-radius: 3px;
  padding: 3px 7px;
  font-size: 11px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 3px;
}

.btn-add-value:hover {
  background: #1e7e34;
}

.values {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.value-row {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px;
  background: #f8f9fa;
  border-radius: 3px;
  border: 1px solid #e9ecef;
}

.value-input, .label-input {
  flex: 1;
  min-width: 70px;
  border: 1px solid #dee2e6;
  border-radius: 2px;
  padding: 4px 6px;
  font-size: 11px;
}

.price-input {
  width: 70px;
  border: 1px solid #dee2e6;
  border-radius: 2px;
  padding: 4px 6px;
  font-size: 11px;
}

.value-input:focus, .label-input:focus, .price-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 1px rgba(0, 123, 255, 0.25);
}

.btn-delete-value {
  background: none;
  border: none;
  color: #dc3545;
  cursor: pointer;
  padding: 3px;
  border-radius: 2px;
  font-size: 10px;
}

.btn-delete-value:hover {
  background: #f8d7da;
}

/* Responsive */
@media (max-width: 768px) {
  .option-header {
    flex-direction: column;
    align-items: stretch;
    gap: 6px;
  }
  
  .option-info {
    flex-direction: column;
    gap: 6px;
  }
  
  .value-row {
    flex-direction: column;
    gap: 4px;
  }
  
  .price-input {
    width: 100%;
  }
  
  .header {
    flex-direction: column;
    gap: 8px;
    align-items: start;
  }
}
</style>