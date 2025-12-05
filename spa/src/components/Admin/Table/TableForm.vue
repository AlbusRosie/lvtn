<template>
  <div class="table-form">
    <h2>{{ isEditing ? 'Edit Table' : 'Add New Table' }}</h2>
    <form class="form" @keydown.enter.prevent>
      <div class="form-row">
        <div class="form-group">
          <label for="branch_id">Branch *</label>
          <select
            id="branch_id"
            v-model="form.branch_id"
            required
            :disabled="isManagerView"
            @change="handleBranchChange"
          >
            <option value="">Select Branch</option>
            <option v-for="branch in branches" :key="branch.id" :value="branch.id">
              {{ branch.name }}
            </option>
          </select>
        </div>
        <div class="form-group">
          <label for="floor_id">Floor *</label>
          <select
            id="floor_id"
            v-model="form.floor_id"
            required
            :disabled="!form.branch_id"
            @change="handleFloorChange"
          >
            <option value="">Select Floor</option>
            <option v-for="floor in floors" :key="floor.id" :value="floor.id">
              {{ floor.name }}
            </option>
          </select>
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label for="capacity">Capacity *</label>
          <input
            id="capacity"
            v-model.number="form.capacity"
            type="number"
            min="1"
            max="20"
            required
            placeholder="Maximum number of people"
          />
        </div>
        <div class="form-group">
          <label for="location">Location</label>
          <input
            id="location"
            v-model="form.location"
            type="text"
            placeholder="E.g: Near window, Quiet corner"
          />
        </div>
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
    },
    managerBranchId: {
      type: Number,
      default: null
    },
    isManagerView: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      form: {
        branch_id: '',
        floor_id: '',
        capacity: 4,
        location: ''
      },
      branches: [],
      floors: []
    };
  },
  computed: {
    isEditing() {
      return !!this.table;
    }
  },
  async mounted() {
    await this.loadBranches();
    if (this.isManagerView && this.managerBranchId && !this.table) {
      this.form.branch_id = this.managerBranchId;
      if (this.form.branch_id) {
        await this.loadFloors(this.form.branch_id);
      }
    }
  },
  watch: {
    table: {
      handler(newTable) {
        if (newTable) {
          this.form = {
            branch_id: newTable.branch_id,
            floor_id: newTable.floor_id,
            capacity: newTable.capacity,
            location: newTable.location || ''
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
        const BranchService = await import('@/services/BranchService');
        this.branches = await BranchService.default.getAllBranches();
      } catch (error) {
      }
    },
    async loadFloors(branchId) {
      if (!branchId) {
        this.floors = [];
        return;
      }
      try {
        const FloorService = await import('@/services/FloorService');
        this.floors = await FloorService.default.getFloorsByBranch(branchId);
      } catch (error) {
      }
    },
    handleFloorChange() {
    },
    handleBranchChange() {
      this.form.floor_id = '';
      this.floors = [];
      if (this.form.branch_id) {
        this.loadFloors(this.form.branch_id);
      }
    },
    resetForm() {
      this.form = {
        branch_id: '',
        floor_id: '',
        capacity: 4,
        location: ''
      };
      this.floors = [];
    },
    handleSubmit() {
      if (!this.form.branch_id || !this.form.floor_id || !this.form.capacity) {
        if (this.$toast) {
          this.$toast.error('Please fill in all required information');
        }
        return;
      }
      const formData = { ...this.form };
      if (!this.isEditing) {
        formData.status = 'available';
      }
      this.$emit('submit', formData);
    }
  }
};
</script>
<style scoped>
.table-form {
  background: white;
  padding: 0;
  width: 100%;
}
.table-form h2 {
  display: none; 
}
.form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
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
.btn {
  padding: 12px 24px;
  border: 2px solid #F0E6D9;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  justify-content: center;
}
.btn:hover:not(:disabled) {
  transform: none;
}
.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}
.btn-primary {
  background: #FF8C42;
  color: white;
  border: none;
}
.btn-primary:hover:not(:disabled) {
  background: #E67E22;
}
.btn-secondary {
  background: white;
  color: #666;
  border: 2px solid #F0E6D9;
}
.btn-secondary:hover:not(:disabled) {
  background: #FFF9F5;
  border-color: #FF8C42;
  color: #D35400;
}
</style>
