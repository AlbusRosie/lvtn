<template>
  <div class="table-form">
    <h2>{{ isEditing ? 'Chỉnh sửa bàn' : 'Thêm bàn mới' }}</h2>
    
    <form class="form" @keydown.enter.prevent>
      <div class="form-group">
        <label for="branch_id">Chi nhánh *</label>
        <select
          id="branch_id"
          v-model="form.branch_id"
          required
          @change="handleBranchChange"
        >
          <option value="">Chọn chi nhánh</option>
          <option v-for="branch in branches" :key="branch.id" :value="branch.id">
            {{ branch.name }}
          </option>
        </select>
      </div>

      <div class="form-group">
        <label for="floor_id">Tầng *</label>
        <select
          id="floor_id"
          v-model="form.floor_id"
          required
          :disabled="!form.branch_id"
          @change="handleFloorChange"
        >
          <option value="">Chọn tầng</option>
          <option v-for="floor in floors" :key="floor.id" :value="floor.id">
            {{ floor.name }}
          </option>
        </select>
      </div>

      <div class="form-group">
        <label for="table_number">Số bàn *</label>
        <div class="table-number-input">
          <input
            id="table_number"
            v-model="form.table_number"
            type="text"
            required
            placeholder="VD: T01, T02..."
            :disabled="isEditing"
          />
          <button 
            v-if="!isEditing && form.branch_id && form.floor_id" 
            type="button" 
            @click="generateTableNumber"
            class="btn btn-auto-generate"
            title="Tự động tạo số bàn"
          >
            <i class="fas fa-magic"></i>
          </button>
        </div>
        <small class="form-text">
          Số bàn phải là duy nhất trong tầng. 
          <span v-if="!isEditing && form.branch_id && form.floor_id">
            Click nút <i class="fas fa-magic"></i> để tự động tạo số bàn.
          </span>
          <span v-if="tableCount > 0" class="table-count-info">
            Hiện tại có {{ tableCount }} bàn trong tầng này.
          </span>
        </small>
      </div>

      <div class="form-group">
        <label for="capacity">Sức chứa *</label>
        <input
          id="capacity"
          v-model.number="form.capacity"
          type="number"
          min="1"
          max="20"
          required
          placeholder="Số người tối đa"
        />
      </div>

      <div class="form-group">
        <label for="location">Vị trí</label>
        <input
          id="location"
          v-model="form.location"
          type="text"
          placeholder="VD: Gần cửa sổ, Góc yên tĩnh"
        />
      </div>

      <div class="form-group" v-if="isEditing">
        <label for="status">Trạng thái</label>
        <select id="status" v-model="form.status" required>
          <option value="available">Có sẵn</option>
          <option value="occupied">Đang sử dụng</option>
          <option value="reserved">Đã đặt trước</option>
          <option value="maintenance">Bảo trì</option>
        </select>
      </div>

      <div class="form-actions">
        <button type="button" @click="$emit('cancel')" class="btn btn-secondary">
          Hủy
        </button>
        <button type="button" @click="handleSubmit" class="btn btn-primary" :disabled="loading">
          <span v-if="loading">Đang xử lý...</span>
          <span v-else>{{ isEditing ? 'Cập nhật' : 'Tạo bàn' }}</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  name: 'TableForm',
  props: {
    table: {
      type: Object,
      default: null
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      form: {
        branch_id: '',
        floor_id: '',
        table_number: '',
        capacity: 4,
        location: '',
        status: 'available'
      },
      branches: [],
      floors: [],
      tableCount: 0
    };
  },
  computed: {
    isEditing() {
      return !!this.table;
    }
  },
  async mounted() {
    await this.loadBranches();
  },
  watch: {
    table: {
      handler(newTable) {
        if (newTable) {
          this.form = {
            branch_id: newTable.branch_id,
            floor_id: newTable.floor_id,
            table_number: newTable.table_number,
            capacity: newTable.capacity,
            location: newTable.location || '',
            status: newTable.status
          };
          this.loadFloors(newTable.branch_id);
        } else {
          this.resetForm();
        }
      },
      immediate: true
    }
  },
  methods: {
    async loadBranches() {
      try {
        const TableService = await import('@/services/TableService');
        this.branches = await TableService.default.getAllBranches();
      } catch (error) {
        console.error('Error loading branches:', error);
      }
    },
    async loadFloors(branchId) {
      if (!branchId) {
        this.floors = [];
        return;
      }
      try {
        const TableService = await import('@/services/TableService');
        this.floors = await TableService.default.getFloorsByBranch(branchId);
      } catch (error) {
        console.error('Error loading floors:', error);
      }
    },
    handleFloorChange() {
      // Tự động tạo số bàn khi chọn tầng (chỉ khi tạo mới)
      if (!this.isEditing && this.form.branch_id && this.form.floor_id) {
        this.generateTableNumber();
      }
    },
    handleBranchChange() {
      this.form.floor_id = '';
      this.form.table_number = '';
      this.floors = [];
      this.tableCount = 0;
      if (this.form.branch_id) {
        this.loadFloors(this.form.branch_id);
      }
    },
    resetForm() {
      this.form = {
        branch_id: '',
        floor_id: '',
        table_number: '',
        capacity: 4,
        location: '',
        status: 'available'
      };
      this.floors = [];
      this.tableCount = 0;
    },
    async generateTableNumber() {
      if (!this.form.branch_id || !this.form.floor_id) {
        return;
      }

      try {
        const TableService = await import('@/services/TableService');
        const result = await TableService.default.generateNextTableNumber(this.form.branch_id, this.form.floor_id);
        
        // Cập nhật số lượng bàn hiện tại
        this.tableCount = result.currentTableCount;
        
        // Tạo số bàn mới
        this.form.table_number = result.nextTableNumber;
        
        // Hiển thị thông báo nếu đây là bàn đầu tiên
        if (result.maxNumber === 0) {
          console.log('Đây là bàn đầu tiên của tầng này');
        }
        
        // Hiển thị thông báo thành công
        if (this.$toast) {
          this.$toast.success(`Đã tạo số bàn: ${result.nextTableNumber}`);
        }
      } catch (error) {
        console.error('Error generating table number:', error);
        // Fallback: tạo số bàn mặc định
        this.form.table_number = 'T01';
        this.tableCount = 0;
      }
    },
    handleSubmit() {
      console.log('TableForm.handleSubmit called');
      
      // Kiểm tra xem form có hợp lệ không
      if (!this.form.branch_id || !this.form.floor_id || !this.form.table_number || !this.form.capacity) {
        console.error('Form validation failed:', this.form);
        if (this.$toast) {
          this.$toast.error('Vui lòng điền đầy đủ thông tin bắt buộc');
        }
        return;
      }
      
      const formData = { ...this.form };
      
      // Ensure status is set for new tables
      if (!this.isEditing) {
        formData.status = 'available';
      }
      
      console.log('TableForm submitting data:', formData);
      this.$emit('submit', formData);
    }
  }
};
</script>

<style scoped>
.table-form {
  background: white;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.table-form h2 {
  margin: 0 0 24px 0;
  color: #333;
  font-size: 1.5rem;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-weight: 500;
  color: #374151;
  font-size: 0.9rem;
}

.form-group input,
.form-group select {
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 0.9rem;
  transition: border-color 0.2s ease;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-group input:disabled {
  background-color: #f9fafb;
  color: #6b7280;
  cursor: not-allowed;
}

.form-text {
  font-size: 0.8rem;
  color: #6b7280;
  margin-top: 4px;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 8px;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn:hover:not(:disabled) {
  transform: translateY(-1px);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2563eb;
}

.btn-secondary {
  background: #6b7280;
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background: #4b5563;
}

.table-number-input {
  display: flex;
  gap: 8px;
  align-items: center;
}

.table-number-input input {
  flex: 1;
}

.btn-auto-generate {
  padding: 10px 12px;
  background: #10b981;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 0.9rem;
}

.btn-auto-generate:hover {
  background: #059669;
  transform: translateY(-1px);
}

.form-text i {
  color: #10b981;
  margin: 0 2px;
}

.table-count-info {
  color: #6b7280;
  font-style: italic;
  margin-left: 8px;
}
</style> 