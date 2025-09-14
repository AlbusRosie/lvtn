<template>
  <div class="table-card" :class="statusClass">
    <div class="table-header">
      <div class="table-title">
        <h3 class="table-number">{{ table.table_number }}</h3>
        <span class="table-location" :class="getBranchColorClass()">{{ getTableLocationShort() }}</span>
      </div>
      <span class="status-badge" :class="`status-${table.status}`">
        {{ getStatusLabel(table.status) }}
      </span>
    </div>

    <div class="table-info">
      <div class="info-item">
        <i class="fas fa-building"></i>
        <span>{{ table.branch_name }}</span>
      </div>

      <div class="info-item">
        <i class="fas fa-layer-group"></i>
        <span>{{ table.floor_name }}</span>
      </div>

      <div class="info-item">
        <i class="fas fa-users"></i>
        <span>Sức chứa: {{ table.capacity }} người</span>
      </div>

      <div class="info-item" v-if="table.location">
        <i class="fas fa-map-marker-alt"></i>
        <span>{{ table.location }}</span>
      </div>

      <div class="info-item">
        <i class="fas fa-calendar"></i>
        <span>Tạo: {{ formatDate(table.created_at) }}</span>
      </div>
    </div>

    <div class="table-actions" v-if="isAdmin">
      <TableActionMenu
        :table="table"
        @edit="$emit('edit', table)"
        @delete="$emit('delete', table)"
        @updateStatus="(tableId, status) => $emit('updateStatus', tableId, status)"
      />
    </div>
  </div>
</template>

<script>
import TableService from '@/services/TableService';
import TableActionMenu from './TableActionMenu.vue';

export default {
  name: 'TableCard',
  components: {
    TableActionMenu
  },
  props: {
    table: {
      type: Object,
      required: true
    },
    isAdmin: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    statusClass() {
      return `status-${this.table.status}`;
    }
  },
  methods: {
    getStatusLabel(status) {
      return TableService.getStatusLabel(status);
    },
    formatDate(dateString) {
      return new Date(dateString).toLocaleDateString('vi-VN');
    },
    getTableLocationShort() {
      let branchShort = '';
      let floorShort = '';

      if (this.table.branch_name) {
        const branchName = this.table.branch_name.toLowerCase();
        
        if (branchName.includes('quận 1')) {
          branchShort = 'Q1';
        } else if (branchName.includes('quận 7')) {
          branchShort = 'Q7';
        } else if (branchName.includes('quận 3')) {
          branchShort = 'Q3';
        } else if (branchName.includes('quận 2')) {
          branchShort = 'Q2';
        } else if (branchName.includes('quận')) {
          const match = branchName.match(/quận (\d+)/);
          if (match) {
            branchShort = `Q${match[1]}`;
          }
        } else if (branchName.includes('hà nội')) {
          branchShort = 'HN';
        } else if (branchName.includes('đà nẵng')) {
          branchShort = 'DN';
        } else if (branchName.includes('cần thơ')) {
          branchShort = 'CT';
        } else {
          const words = this.table.branch_name.split(' ').filter(word => 
            !['chi', 'nhánh', 'của', 'tại', 'ở'].includes(word.toLowerCase())
          );
          if (words.length > 0) {
            branchShort = words[0].substring(0, 2).toUpperCase();
          }
        }
      }

      if (this.table.floor_number) {
        floorShort = `F${this.table.floor_number}`;
      }

      return branchShort && floorShort ? `${branchShort}${floorShort}` : '';
    },
    getBranchColorClass() {
      if (!this.table.branch_name) return '';
      
      const branchName = this.table.branch_name.toLowerCase();
      
      if (branchName.includes('quận 1')) {
        return 'branch-q1';
      } else if (branchName.includes('quận 7')) {
        return 'branch-q7';
      } else if (branchName.includes('quận 3')) {
        return 'branch-q3';
      } else if (branchName.includes('hà nội')) {
        return 'branch-hn';
      } else if (branchName.includes('đà nẵng')) {
        return 'branch-dn';
      } else {
        return 'branch-default';
      }
    }
  }
};
</script>

<style scoped>
.table-card {
  background: white;
  border-radius: 8px;
  padding: 16px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border-left: 4px solid #ddd;
  transition: all 0.3s ease;
}

.table-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.table-title {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
}

.table-number {
  font-size: 1.2rem;
  font-weight: bold;
  margin: 0;
  color: #333;
  line-height: 1.2;
}

.table-location {
  font-size: 0.75rem;
  font-weight: 500;
  padding: 2px 6px;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.025em;
  transition: all 0.2s ease;
}

/* Màu sắc phân biệt theo chi nhánh */
.table-location.branch-q1 {
  background: #dbeafe;
  color: #1d4ed8;
  border: 1px solid #93c5fd;
}

.table-location.branch-q7 {
  background: #dcfce7;
  color: #166534;
  border: 1px solid #86efac;
}

.table-location.branch-q3 {
  background: #fef3c7;
  color: #92400e;
  border: 1px solid #fcd34d;
}

.table-location.branch-hn {
  background: #fce7f3;
  color: #be185d;
  border: 1px solid #f9a8d4;
}

.table-location.branch-dn {
  background: #e0f2fe;
  color: #0e7490;
  border: 1px solid #67e8f9;
}

.table-location.branch-default {
  background: #f3f4f6;
  color: #6b7280;
  border: 1px solid #d1d5db;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
  text-transform: uppercase;
}

.status-available {
  border-left-color: #10b981;
}

.status-available .status-badge {
  background: #d1fae5;
  color: #065f46;
}

.status-occupied {
  border-left-color: #ef4444;
}

.status-occupied .status-badge {
  background: #fee2e2;
  color: #991b1b;
}

.status-reserved {
  border-left-color: #f59e0b;
}

.status-reserved .status-badge {
  background: #fef3c7;
  color: #92400e;
}

.status-maintenance {
  border-left-color: #6b7280;
}

.status-maintenance .status-badge {
  background: #f3f4f6;
  color: #374151;
}

.table-info {
  margin-bottom: 16px;
}

.info-item {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  font-size: 0.9rem;
  color: #666;
}

.info-item i {
  width: 16px;
  margin-right: 8px;
  color: #999;
}

.table-actions {
  border-top: 1px solid #e5e7eb;
  padding-top: 16px;
  margin-top: 16px;
  display: flex;
  justify-content: center;
}
</style>