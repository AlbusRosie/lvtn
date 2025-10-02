<template>
  <div class="table-action-menu" ref="menuContainer">
    
    <button 
      @click="toggleMenu"
      class="btn btn-action-toggle"
      :class="{ 'active': isMenuOpen }"
      title="Đổi trạng thái"
    >
      <i class="fas fa-exchange-alt"></i>
      <span>Đổi trạng thái</span>
      <i class="fas fa-chevron-down chevron" :class="{ 'rotated': isMenuOpen }"></i>
    </button>

    
    <div v-if="isMenuOpen" class="action-dropdown">
      <div class="action-group" v-if="availableStatuses.length > 0">
        <div class="group-title">Chọn trạng thái mới</div>
        <button
          v-for="status in availableStatuses"
          :key="status.value"
          @click="handleStatusChange(status.value)"
          class="action-item status-item"
          :class="`status-${status.value}`"
        >
          <i :class="status.icon"></i>
          <span>{{ status.label }}</span>
          <div class="status-indicator" :class="`indicator-${status.value}`"></div>
        </button>
      </div>
    </div>

    
    <div v-if="isMenuOpen" class="menu-backdrop" @click="closeMenu"></div>
  </div>
</template>

<script>
export default {
  name: 'TableActionMenu',
  props: {
    table: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      isMenuOpen: false
    };
  },
  computed: {
    availableStatuses() {
      const currentStatus = this.table.status;
      const allStatuses = [
        { 
          value: 'available', 
          label: 'Có sẵn',
          icon: 'fas fa-check' 
        },
        { 
          value: 'occupied', 
          label: 'Đang sử dụng',
          icon: 'fas fa-users' 
        },
        { 
          value: 'reserved', 
          label: 'Đã đặt trước',
          icon: 'fas fa-clock' 
        },
        { 
          value: 'maintenance', 
          label: 'Bảo trì',
          icon: 'fas fa-tools' 
        }
      ];

      return allStatuses.filter(status => status.value !== currentStatus);
    }
  },
  mounted() {
    document.addEventListener('click', this.handleClickOutside);
  },
  beforeUnmount() {
    document.removeEventListener('click', this.handleClickOutside);
  },
  methods: {
    toggleMenu() {
      this.isMenuOpen = !this.isMenuOpen;
    },
    closeMenu() {
      this.isMenuOpen = false;
    },
    handleClickOutside(event) {
      if (!this.$refs.menuContainer?.contains(event.target)) {
        this.closeMenu();
      }
    },
    handleStatusChange(status) {
      this.$emit('updateStatus', this.table.id, status);
      this.closeMenu();
    }
  }
};
</script>

<style scoped>
.table-action-menu {
  position: relative;
  display: inline-block;
}

.btn-action-toggle {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  color: #475569;
  font-size: 0.75rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
  min-width: 100px;
  justify-content: space-between;
}

.btn-action-toggle:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
  transform: translateY(-1px);
}

.btn-action-toggle.active {
  background: #3b82f6;
  color: white;
  border-color: #3b82f6;
}

.chevron {
  font-size: 0.7rem;
  transition: transform 0.2s ease;
}

.chevron.rotated {
  transform: rotate(180deg);
}

.action-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  margin-top: 4px;
  overflow: hidden;
  min-width: 200px;
}

.action-group {
  padding: 8px 0;
}

.action-group + .action-group {
  border-top: 1px solid #f1f5f9;
}

.group-title {
  padding: 8px 16px 4px;
  font-size: 0.7rem;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.action-item {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: 10px 16px;
  border: none;
  background: transparent;
  color: #374151;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.15s ease;
  text-align: left;
  position: relative;
}

.action-item:hover:not(:disabled) {
  background: #f8fafc;
  color: #1f2937;
}

.action-item:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.action-item i {
  width: 16px;
  font-size: 0.85rem;
  color: #6b7280;
}

.action-item:hover:not(:disabled) i {
  color: #374151;
}

.disabled-reason {
  display: block;
  font-size: 0.7rem;
  color: #ef4444;
  margin-top: 2px;
  font-style: italic;
}

.status-item {
  padding-right: 40px;
}

.status-indicator {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.indicator-available {
  background: #10b981;
}

.indicator-occupied {
  background: #ef4444;
}

.indicator-reserved {
  background: #f59e0b;
}

.indicator-maintenance {
  background: #6b7280;
}

.menu-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 999;
}

/* Responsive */
@media (max-width: 768px) {
  .action-dropdown {
    left: auto;
    right: 0;
    min-width: 180px;
  }
}
</style>
