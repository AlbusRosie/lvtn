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
      branches: []
    };
  },
  async mounted() {
    await this.loadBranches();
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
    handleSearch() {
      this.$emit('search', this.searchTerm);
    },
    handleFilter() {
      this.$emit('filter', {
        branch: this.branchFilter,
        status: this.statusFilter,
        capacity: this.capacityFilter
      });
    },
    resetFilters() {
      this.searchTerm = '';
      this.branchFilter = '';
      this.statusFilter = '';
      this.capacityFilter = '';
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
}

.filter-row {
  display: flex;
  gap: 20px;
  align-items: center;
  flex-wrap: wrap;
}

.search-box {
  position: relative;
  flex: 1;
  min-width: 250px;
}

.search-box input {
  width: 100%;
  padding: 10px 12px 10px 40px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 0.9rem;
  transition: border-color 0.2s ease;
}

.search-box input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
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
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
}

.filter-controls select {
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 0.9rem;
  background: white;
  cursor: pointer;
  transition: border-color 0.2s ease;
}

.filter-controls select:focus {
  outline: none;
  border-color: #3b82f6;
}

.btn-reset {
  padding: 8px 16px;
  background: #6b7280;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}

.btn-reset:hover {
  background: #4b5563;
  transform: translateY(-1px);
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

@media (max-width: 768px) {
  .filter-row {
    flex-direction: column;
    align-items: stretch;
  }
  
  .search-box {
    min-width: auto;
  }
  
  .filter-controls {
    justify-content: center;
  }
  
  .filter-stats {
    justify-content: center;
  }
}
</style> 