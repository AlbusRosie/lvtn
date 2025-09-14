<template>
  <div class="floor-form">
    <h2>
      {{ isEditing ? 'Chỉnh sửa tầng' : 'Thêm tầng mới' }}
      <span v-if="isEditing && form.branch_id && form.floor_number" class="floor-info">
        - Tầng {{ form.floor_number }} ({{ getBranchName(form.branch_id) }})
      </span>
    </h2>

    <div v-if="isEditing" class="edit-notice">
      <i class="fas fa-info-circle"></i>
      <span>Chỉ có thể thay đổi: Tên, sức chứa, mô tả, trạng thái</span>
    </div>

    <form class="form" @keydown.enter.prevent>
      <div class="form-group">
        <label for="branch_id">Chi nhánh *</label>
        <select
          id="branch_id"
          v-model="form.branch_id"
          required
          @change="handleBranchChange"
          :disabled="isEditing"
        >
          <option value="">Chọn chi nhánh</option>
          <option v-for="branch in branches" :key="branch.id" :value="branch.id">
            {{ branch.name }}
          </option>
        </select>
        <small v-if="isEditing && form.branch_id" class="form-text">
          <i class="fas fa-building"></i> Đang chỉnh sửa tầng số <strong>{{ form.floor_number }}</strong> thuộc chi nhánh:
          <strong>{{ getBranchName(form.branch_id) }}</strong>
        </small>
      </div>

      <div class="form-group">
        <label for="floor_number">Số tầng *</label>
        <div class="floor-number-display">
          <div class="floor-number-value">
            <i class="fas fa-hashtag"></i>
            <span v-if="form.floor_number">{{ form.floor_number }}</span>
            <span v-else class="placeholder">Đang tạo...</span>
          </div>
        </div>
        <small class="form-text">
          <i class="fas fa-info-circle"></i>
          Số tầng được tự động tạo dựa trên số tầng hiện có trong chi nhánh.
          <span v-if="floorCount > 0" class="floor-count-info">
            Hiện tại có {{ floorCount }} tầng trong chi nhánh này.
            <span v-if="nextFloorNumber">Số tầng tiếp theo: <strong>{{ nextFloorNumber }}</strong></span>
          </span>
          <span v-if="!isEditing && form.branch_id && !form.floor_number" class="loading-info">
            <i class="fas fa-spinner fa-spin"></i> Đang tạo số tầng...
          </span>
        </small>
      </div>

      <div class="form-group">
        <label for="name">Tên tầng *</label>
        <input
          id="name"
          v-model="form.name"
          type="text"
          required
          placeholder="VD: Tầng 1, Tầng lầu, Tầng VIP..."
        />
        <small class="form-text">
          <i class="fas fa-info-circle"></i>
          Tên tầng sẽ được tự động tạo khi chọn chi nhánh, hoặc bạn có thể nhập tên tùy chỉnh.
          <span v-if="form.branch_id && form.floor_number" class="name-preview">
            Ví dụ: <strong>Tầng {{ form.floor_number }} - {{ getBranchName(form.branch_id) }}</strong>
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
          max="1000"
          required
          placeholder="Số người tối đa"
        />
      </div>

      <div class="form-group">
        <label for="description">Mô tả</label>
        <textarea
          id="description"
          v-model="form.description"
          rows="3"
          placeholder="Mô tả chi tiết về tầng..."
        ></textarea>
      </div>

      <div class="form-group" v-if="isEditing">
        <label for="status">Trạng thái</label>
        <select id="status" v-model="form.status" required>
          <option value="active">Hoạt động</option>
          <option value="inactive">Không hoạt động</option>
          <option value="maintenance">Bảo trì</option>
        </select>
      </div>

      <div class="form-actions">
        <button type="button" @click="$emit('cancel')" class="btn btn-secondary">
          Hủy
        </button>
        <button type="button" @click="handleSubmit" class="btn btn-primary" :disabled="loading">
          <span v-if="loading">Đang xử lý...</span>
          <span v-else>{{ isEditing ? 'Cập nhật' : 'Tạo tầng' }}</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  name: 'FloorForm',
  props: {
    floor: {
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
        floor_number: '',
        name: '',
        capacity: 50,
        description: '',
        status: 'active'
      },
      branches: [],
      floorCount: 0,
      nextFloorNumber: null
    };
  },
  computed: {
    isEditing() {
      return !!this.floor;
    }
  },
  async mounted() {
    await this.loadBranches();
  },
  watch: {
    floor: {
      handler(newFloor) {
        if (newFloor) {
          this.form = {
            branch_id: newFloor.branch_id,
            floor_number: newFloor.floor_number,
            name: newFloor.name,
            capacity: newFloor.capacity,
            description: newFloor.description || '',
            status: newFloor.status
          };

          this.loadBranchInfo(newFloor.branch_id);
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
        const BranchService = await import('@/services/BranchService');
        this.branches = await BranchService.default.getAllBranches();
      } catch (error) {
      }
    },

    async loadBranchInfo(branchId) {
      try {
        const BranchService = await import('@/services/BranchService');
        const branch = await BranchService.default.getBranchById(branchId);

      } catch (error) {
      }
    },

    getBranchName(branchId) {
      const branch = this.branches.find(b => b.id === branchId);
      return branch ? branch.name : 'Không xác định';
    },

    async handleBranchChange() {
      if (!this.isEditing && this.form.branch_id) {
        this.form.floor_number = '';
        this.form.name = '';
        this.nextFloorNumber = null;
        this.floorCount = 0;
        
        await this.generateFloorNumber();
      } else if (!this.isEditing) {
        this.form.floor_number = '';
        this.form.name = '';
        this.nextFloorNumber = null;
        this.floorCount = 0;
      }
    },

    async generateFloorNumber() {
      if (!this.form.branch_id) {
        return;
      }

      try {
        const FloorService = await import('@/services/FloorService');
        const result = await FloorService.default.generateNextFloorNumber(this.form.branch_id);

        this.floorCount = result.currentFloorCount;
        this.nextFloorNumber = result.nextFloorNumber;
        this.form.floor_number = result.nextFloorNumber;
        
        this.generateFloorName();
      } catch (error) {
        console.error('Error generating floor number:', error);
        this.form.floor_number = 1;
        this.nextFloorNumber = 1;
        this.floorCount = 0;
      }
    },

    generateFloorName() {
      if (!this.form.branch_id || !this.form.floor_number) {
        return;
      }

      const branchName = this.getBranchName(this.form.branch_id);
      this.form.name = `Tầng ${this.form.floor_number} - ${branchName}`;
    },

    resetForm() {
      this.form = {
        branch_id: '',
        floor_number: '',
        name: '',
        capacity: 50,
        description: '',
        status: 'active'
      };
      this.floorCount = 0;
      this.nextFloorNumber = null;
    },

    handleSubmit() {
      if (!this.form.branch_id) {
        if (this.$toast) {
          this.$toast.error('Vui lòng chọn chi nhánh');
        }
        return;
      }

      if (!this.form.floor_number) {
        if (this.$toast) {
          this.$toast.error('Vui lòng chọn chi nhánh để tự động tạo số tầng');
        }
        return;
      }

      if (!this.form.name) {
        if (this.$toast) {
          this.$toast.error('Vui lòng điền tên tầng');
        }
        return;
      }

      if (!this.form.capacity) {
        if (this.$toast) {
          this.$toast.error('Vui lòng điền sức chứa');
        }
        return;
      }

      if (this.isEditing && this.floor) {
        if (this.form.branch_id !== this.floor.branch_id) {
          if (this.$toast) {
            this.$toast.error('Không thể thay đổi chi nhánh khi chỉnh sửa tầng');
          }
          return;
        }
        if (this.form.floor_number !== this.floor.floor_number) {
          if (this.$toast) {
            this.$toast.error('Không thể thay đổi số tầng khi chỉnh sửa');
          }
          return;
        }
      }

      const formData = { ...this.form };
      this.$emit('submit', formData);
    }
  }
};
</script>

<style scoped>
.floor-form {
  background: white;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.floor-form h2 {
  margin: 0 0 24px 0;
  color: #333;
  font-size: 1.5rem;
}

.floor-info {
  font-size: 1rem;
  color: #6b7280;
  font-weight: normal;
}

.edit-notice {
  background: #eff6ff;
  border: 1px solid #3b82f6;
  border-radius: 6px;
  padding: 12px;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 8px;
  color: #1e40af;
  font-size: 0.9rem;
}

.edit-notice i {
  color: #3b82f6;
  font-size: 1rem;
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
.form-group select,
.form-group textarea {
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 0.9rem;
  transition: border-color 0.2s ease;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-group input:disabled,
.form-group select:disabled {
  background-color: #f9fafb;
  color: #6b7280;
  cursor: not-allowed;
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.form-text {
  font-size: 0.8rem;
  color: #6b7280;
  margin-top: 4px;
}

.form-text i {
  color: #10b981;
  margin: 0 2px;
}

.form-text strong {
  color: #374151;
  font-weight: 600;
}

.form-text .fa-building {
  color: #3b82f6;
}

.form-text .fa-info-circle {
  color: #f59e0b;
}

.floor-count-info {
  color: #6b7280;
  font-style: italic;
  margin-left: 8px;
}

.loading-info {
  color: #3b82f6;
  font-weight: 500;
  margin-left: 8px;
}

.loading-info i {
  margin-right: 4px;
}

.floor-number-display {
  display: flex;
  align-items: center;
}

.floor-number-value {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  background-color: #f9fafb;
  color: #374151;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
  min-height: 42px;
}

.floor-number-value i {
  color: #6b7280;
  font-size: 0.9rem;
}

.floor-number-value .placeholder {
  color: #9ca3af;
  font-style: italic;
}


.name-preview {
  color: #6b7280;
  font-style: italic;
  margin-left: 8px;
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
</style>
