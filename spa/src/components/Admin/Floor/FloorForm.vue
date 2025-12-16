<template>
  <div class="floor-form">
    <form class="form" @keydown.enter.prevent>
      <!-- Thông tin cơ bản -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-layer-group"></i>
          <h3>Basic Information</h3>
        </div>
        <div class="card-content">
          <div class="form-group">
            <label for="name">Floor Name *</label>
            <input
              id="name"
              v-model="form.name"
              type="text"
              required
              placeholder="E.g: Floor 1, Upper Floor, VIP Floor..."
            />
            <small class="form-text">
              <i class="fas fa-info-circle"></i>
              Floor name will be automatically generated when selecting a branch, or you can enter a custom name.
              <span v-if="form.branch_id && form.floor_number" class="name-preview">
                Example: <strong>Floor {{ form.floor_number }} - {{ getBranchName(form.branch_id) }}</strong>
              </span>
            </small>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label for="capacity">Capacity *</label>
              <input
                id="capacity"
                v-model.number="form.capacity"
                type="number"
                min="1"
                max="1000"
                required
                placeholder="Maximum number of people"
              />
            </div>
            <div class="form-group" v-if="isEditing">
              <label for="status">Status</label>
              <select id="status" v-model="form.status" required>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="maintenance">Maintenance</option>
              </select>
            </div>
            <div v-else class="form-group"></div>
          </div>
        </div>
      </div>
      <!-- Thông tin chi nhánh và số tầng -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-building"></i>
          <h3>Branch Information</h3>
        </div>
        <div class="card-content">
          <div class="form-group">
            <label for="branch_id">Branch *</label>
            <select
              id="branch_id"
              v-model="form.branch_id"
              required
              @change="handleBranchChange"
              :disabled="isEditing || isManagerView"
            >
              <option value="">Select Branch</option>
              <option v-for="branch in branches" :key="branch.id" :value="branch.id">
                {{ branch.name }}
              </option>
            </select>
            <small v-if="isEditing && form.branch_id" class="form-text">
              <i class="fas fa-building"></i> Editing floor number <strong>{{ form.floor_number }}</strong> of branch:
              <strong>{{ getBranchName(form.branch_id) }}</strong>
            </small>
          </div>
          <div class="form-group">
            <label for="floor_number">Floor Number *</label>
            <div class="floor-number-display">
              <div class="floor-number-value">
                <i class="fas fa-hashtag"></i>
                <span v-if="form.floor_number">{{ form.floor_number }}</span>
                <span v-else class="placeholder">Creating...</span>
              </div>
            </div>
            <small class="form-text">
              <i class="fas fa-info-circle"></i>
              Floor number is automatically generated based on existing floors in the branch.
              <span v-if="floorCount > 0" class="floor-count-info">
                Currently {{ floorCount }} floor(s) in this branch.
                <span v-if="nextFloorNumber">Next floor number: <strong>{{ nextFloorNumber }}</strong></span>
              </span>
              <span v-if="!isEditing && form.branch_id && !form.floor_number" class="loading-info">
                <i class="fas fa-spinner fa-spin"></i> Creating floor number...
              </span>
            </small>
          </div>
        </div>
      </div>
      <!-- Mô tả -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-info-circle"></i>
          <h3>Description</h3>
        </div>
        <div class="card-content">
          <div class="form-group">
            <label for="description">Description</label>
            <textarea
              id="description"
              v-model="form.description"
              rows="3"
              placeholder="Detailed description of the floor..."
            ></textarea>
          </div>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" @click="$emit('cancel')" class="btn btn-secondary">
          Cancel
        </button>
        <button type="button" @click="handleSubmit" class="btn btn-primary" :disabled="loading">
          <span v-if="loading">Processing...</span>
          <span v-else>{{ isEditing ? 'Update' : 'Create Floor' }}</span>
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
    },
    isManagerView: {
      type: Boolean,
      default: false
    },
    managerBranchId: {
      type: Number,
      default: null
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
    if (this.isManagerView && this.managerBranchId && !this.isEditing) {
      this.form.branch_id = this.managerBranchId;
      await this.handleBranchChange();
    }
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
      this.form.name = `Floor ${this.form.floor_number} - ${branchName}`;
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
          this.$toast.error('Please select a branch');
        }
        return;
      }
      if (this.form.floor_number === null || this.form.floor_number === undefined || this.form.floor_number === '') {
        if (this.$toast) {
          this.$toast.error('Please select a branch to auto-generate floor number');
        }
        return;
      }
      if (!this.form.name) {
        if (this.$toast) {
          this.$toast.error('Please enter floor name');
        }
        return;
      }
      if (this.form.capacity === null || this.form.capacity === undefined || this.form.capacity === '') {
        if (this.$toast) {
          this.$toast.error('Please enter capacity');
        }
        return;
      }
      if (this.isEditing && this.floor) {
        if (this.form.branch_id !== this.floor.branch_id) {
          if (this.$toast) {
            this.$toast.error('Cannot change branch when editing floor');
          }
          return;
        }
        if (this.form.floor_number !== this.floor.floor_number) {
          if (this.$toast) {
            this.$toast.error('Cannot change floor number when editing');
          }
          return;
        }
      }
      let formData = { ...this.form };
      if (this.isEditing && this.floor) {
        const changedFields = {};
        let hasChanges = false;
        if (formData.name !== this.floor.name) {
          changedFields.name = formData.name;
          hasChanges = true;
        }
        if (formData.capacity !== this.floor.capacity) {
          changedFields.capacity = formData.capacity;
          hasChanges = true;
        }
        if (formData.description !== (this.floor.description || '')) {
          changedFields.description = formData.description;
          hasChanges = true;
        }
        if (formData.status !== this.floor.status) {
          changedFields.status = formData.status;
          hasChanges = true;
        }
        if (!hasChanges) {
          if (this.$toast) {
            this.$toast.info('No changes to update');
          }
          return;
        }
        formData = changedFields;
        }
      this.$emit('submit', formData);
      }
  }
};
</script>
<style scoped>
.floor-form {
  background: white;
  padding: 0;
}
.form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.info-card {
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  overflow: hidden;
}
.card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.card-header i {
  color: #F59E0B;
  font-size: 14px;
}
.card-header h3 {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.2px;
}
.card-content {
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.form-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.form-group label {
  font-size: 12px;
  font-weight: 500;
  color: #64748B;
  letter-spacing: 0;
}
.form-group input,
.form-group select,
.form-group textarea {
  padding: 10px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1E293B;
  font-weight: 500;
  transition: all 0.2s ease;
}
.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #F59E0B;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
}
.form-group input:disabled,
.form-group select:disabled {
  background-color: #F9FAFB;
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
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #E2E8F0;
}
.btn {
  padding: 12px 24px;
  border: 2px solid #F0E6D9;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
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
  background: #F59E0B;
  color: white;
  border-color: #F59E0B;
}
.btn-primary:hover:not(:disabled) {
  background: #D97706;
  border-color: #D97706;
}
.btn-secondary {
  background: white;
  color: #666;
  border-color: #E5E7EB;
}
.btn-secondary:hover:not(:disabled) {
  background: #FFF9F5;
  border-color: #FF8C42;
  color: #D35400;
}
</style>
