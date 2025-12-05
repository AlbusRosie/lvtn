<template>
  <div class="table-filter">
    <div class="filter-row">
      <div class="search-box">
        <input
          v-model="searchTerm"
          type="text"
          placeholder="Tìm kiếm theo số bàn..."
          @input="handleSearch"
        />
        <i class="fas fa-search"></i>
      </div>
      <div class="filter-controls">
        <select v-model="branchFilter" @change="handleFilter">
          <option value="">Tất cả chi nhánh</option>
          <option v-for="branch in branches" :key="branch.id" :value="branch.id">
            {{ branch.name }}
          </option>
        </select>
        <select v-model="statusFilter" @change="handleFilter">
          <option value="">Tất cả trạng thái</option>
          <option value="available">Có sẵn</option>
          <option value="occupied">Đang sử dụng</option>
          <option value="reserved">Đã đặt trước</option>
          <option value="maintenance">Bảo trì</option>
        </select>
        <select v-model="capacityFilter" @change="handleFilter">
          <option value="">Tất cả sức chứa</option>
          <option value="1-2">1-2 người</option>
          <option value="3-4">3-4 người</option>
          <option value="5-6">5-6 người</option>
          <option value="7+">7+ người</option>
        </select>
        <select v-model="floorFilter" @change="handleFilter">
          <option value="">Tất cả tầng</option>
          <option v-for="floor in floors" :key="floor.id" :value="floor.id">
            {{ floor.name }} ({{ getBranchName(floor.branch_id) }})
          </option>
        </select>
        <button @click="resetFilters" class="btn btn-reset">
          <i class="fas fa-undo"></i>
          Đặt lại
        </button>
      </div>
    </div>
    <div class="filter-stats" v-if="showStats">
      <div class="stat-item">
        <span class="stat-label">Tổng số bàn:</span>
        <span class="stat-value">{{ stats.total }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Có sẵn:</span>
        <span class="stat-value available">{{ stats.available }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Đang sử dụng:</span>
        <span class="stat-value occupied">{{ stats.occupied }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Đã đặt trước:</span>
        <span class="stat-value reserved">{{ stats.reserved }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Bảo trì:</span>
        <span class="stat-value maintenance">{{ stats.maintenance }}</span>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'TableFilter',
  props: {
    stats: {
      type: Object,
      default: () => ({
        total: 0,
        available: 0,
        occupied: 0,
        reserved: 0,
        maintenance: 0
      })
    },
    showStats: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      searchTerm: '',
      branchFilter: '',
      statusFilter: '',
      capacityFilter: '',
      floorFilter: '',
      branches: [],
      floors: []
    };
  },
  async mounted() {
    await this.loadBranches();
    await this.loadFloors();
  },
  computed: {
  },
  methods: {
    async loadBranches() {
      try {
        const BranchService = await import('@/services/BranchService');
        const branches = await BranchService.default.getAllBranches();
        this.branches = branches || [];
      } catch (error) {
        this.branches = [];
      }
    },
    async loadFloors() {
      try {
        const FloorService = await import('@/services/FloorService');
        const floors = await FloorService.default.getAllFloors();
        this.floors = floors || [];
      } catch (error) {
        this.floors = [];
      }
    },
    getBranchName(branchId) {
      const branch = this.branches.find(b => b.id == branchId);
      return branch ? branch.name : `Chi nhánh ${branchId}`;
    },
    handleSearch() {
      this.$emit('search', this.searchTerm);
    },
    handleFilter() {
      this.$emit('filter', {
        branch: this.branchFilter,
        status: this.statusFilter,
        capacity: this.capacityFilter,
        floor: this.floorFilter
      });
    },
    resetFilters() {
      this.searchTerm = '';
      this.branchFilter = '';
      this.statusFilter = '';
      this.capacityFilter = '';
      this.floorFilter = '';
      this.$emit('reset');
    }
  }
};
</script>
<style scoped>
.table-filter {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
  width: 100%;
  box-sizing: border-box;
  overflow-x: hidden;
}
.filter-row {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
  width: 100%;
}
.search-box {
  position: relative;
  flex: 1;
  min-width: 180px;
  max-width: 250px;
}
.search-box input {
  width: 100%;
  padding: 8px 12px 8px 40px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.2s ease;
}
.search-box input:focus {
  outline: none;
  border-color: #007bff;
}
.search-box i {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
}
.filter-controls {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
  flex: 2;
  min-width: 0;
}
.filter-controls select {
  padding: 8px 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  background: white;
  cursor: pointer;
  transition: border-color 0.2s ease;
  flex: 1;
  min-width: 120px;
  max-width: 200px;
}
.filter-controls select:focus {
  outline: none;
  border-color: #007bff;
}
.btn-reset {
  padding: 8px 12px;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 4px;
  white-space: nowrap;
  flex-shrink: 0;
}
.btn-reset:hover {
  background: #5a6268;
}
.filter-stats {
  display: flex;
  gap: 20px;
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid #e5e7eb;
  flex-wrap: wrap;
}
.stat-item {
  display: flex;
  align-items: center;
  gap: 8px;
}
.stat-label {
  font-size: 0.9rem;
  color: #6b7280;
}
.stat-value {
  font-weight: 600;
  font-size: 1rem;
  color: #374151;
}
.stat-value.available {
  color: #10b981;
}
.stat-value.occupied {
  color: #ef4444;
}
.stat-value.reserved {
  color: #f59e0b;
}
.stat-value.maintenance {
  color: #6b7280;
}
@media (max-width: 1200px) {
  .filter-row {
    flex-wrap: wrap;
    gap: 8px;
    width: 100%;
  }
  .search-box {
    flex: 1 1 200px;
    min-width: 200px;
    max-width: 300px;
  }
  .filter-controls {
    flex: 1 1 100%;
    justify-content: flex-start;
    gap: 8px;
    margin-top: 8px;
  }
  .filter-controls select {
    flex: 1 1 150px;
    min-width: 120px;
    max-width: 180px;
  }
}
@media (max-width: 768px) {
  .filter-row {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
    width: 100%;
  }
  .search-box {
    min-width: auto;
    max-width: none;
    flex: none;
    width: 100%;
  }
  .filter-controls {
    justify-content: flex-start;
    flex-wrap: wrap;
    flex: none;
    gap: 8px;
    width: 100%;
  }
  .filter-controls select {
    flex: 1 1 140px;
    min-width: 120px;
    max-width: 160px;
  }
  .btn-reset {
    flex: 1 1 auto;
    min-width: 120px;
  }
  .filter-stats {
    justify-content: center;
    flex-wrap: wrap;
    gap: 12px;
  }
}
</style>
