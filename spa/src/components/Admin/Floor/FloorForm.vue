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
        <div class="floor-number-input">
          <input
            id="floor_number"
            v-model.number="form.floor_number"
            type="number"
            min="1"
            required
            placeholder="VD: 1, 2, 3..."
            :disabled="isEditing"
          />
          <button 
            v-if="!isEditing && form.branch_id" 
            type="button" 
            @click="generateFloorNumber"
            class="btn btn-auto-generate"
            title="Tự động tạo số tầng"
          >
            <i class="fas fa-magic"></i>
          </button>
        </div>
        <small class="form-text">
          Số tầng phải là duy nhất trong chi nhánh. 
          <span v-if="!isEditing && form.branch_id">
            Click nút <i class="fas fa-magic"></i> để tự động tạo số tầng.
          </span>
          <span v-if="floorCount > 0" class="floor-count-info">
            Hiện tại có {{ floorCount }} tầng trong chi nhánh này.
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
      floorCount: 0
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
          // Load thông tin chi nhánh khi edit
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
        console.error('Error loading branches:', error);
      }
    },
    
    async loadBranchInfo(branchId) {
      try {
        const BranchService = await import('@/services/BranchService');
        const branch = await BranchService.default.getBranchById(branchId);
        // Có thể sử dụng thông tin chi nhánh để hiển thị thêm thông tin nếu cần
        console.log('Loaded branch info:', branch);
      } catch (error) {
        console.error('Error loading branch info:', error);
      }
    },
    
    getBranchName(branchId) {
      const branch = this.branches.find(b => b.id === branchId);
      return branch ? branch.name : 'Không xác định';
    },
    
    handleBranchChange() {
      // Chỉ tự động tạo số tầng khi thêm mới, không phải khi edit
      if (!this.isEditing && this.form.branch_id) {
        this.generateFloorNumber();
      }
    },
    
    async generateFloorNumber() {
      if (!this.form.branch_id) {
        return;
      }

      try {
        const FloorService = await import('@/services/FloorService');
        const result = await FloorService.default.generateNextFloorNumber(this.form.branch_id);
        
        // Cập nhật số lượng tầng hiện tại
        this.floorCount = result.currentFloorCount;
        
        // Tạo số tầng mới
        this.form.floor_number = result.nextFloorNumber;
        
        // Hiển thị thông báo thành công
        if (this.$toast) {
          this.$toast.success(`Đã tạo số tầng: ${result.nextFloorNumber}`);
        }
      } catch (error) {
        console.error('Error generating floor number:', error);
        // Fallback: tạo số tầng mặc định
        this.form.floor_number = 1;
        this.floorCount = 0;
      }
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
    },
    
    handleSubmit() {
      console.log('FloorForm.handleSubmit called');
      
      // Kiểm tra xem form có hợp lệ không
      if (!this.form.branch_id || !this.form.floor_number || !this.form.name || !this.form.capacity) {
        console.error('Form validation failed:', this.form);
        if (this.$toast) {
          this.$toast.error('Vui lòng điền đầy đủ thông tin bắt buộc');
        }
        return;
      }
      
      // Khi edit, đảm bảo chi nhánh và số tầng không bị thay đổi
      if (this.isEditing && this.floor) {
        if (this.form.branch_id !== this.floor.branch_id) {
          console.error('Branch ID cannot be changed when editing floor');
          if (this.$toast) {
            this.$toast.error('Không thể thay đổi chi nhánh khi chỉnh sửa tầng');
          }
          return;
        }
        if (this.form.floor_number !== this.floor.floor_number) {
          console.error('Floor number cannot be changed when editing floor');
          if (this.$toast) {
            this.$toast.error('Không thể thay đổi số tầng khi chỉnh sửa');
          }
          return;
        }
      }
      
      const formData = { ...this.form };
      
      console.log('FloorForm submitting data:', formData);
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

.floor-number-input {
  display: flex;
  gap: 8px;
  align-items: center;
}

.floor-number-input input {
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