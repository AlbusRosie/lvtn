<template>
  <div class="role-info">
    <div class="role-badge" :class="roleClass">
      <i :class="roleIcon"></i>
      <span>{{ roleName }}</span>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { ROLE_NAMES } from '@/constants';

const props = defineProps({
  roleId: {
    type: Number,
    required: true
  }
});

const roleInfo = computed(() => {
  switch (props.roleId) {
    case 1:
      return {
        name: ROLE_NAMES[1],
        class: 'role-admin',
        icon: 'fas fa-crown'
      };
    case 2:
      return {
        name: ROLE_NAMES[2],
        class: 'role-customer',
        icon: 'fas fa-user'
      };
    case 3:
      return {
        name: ROLE_NAMES[3],
        class: 'role-staff',
        icon: 'fas fa-user-tie'
      };
    default:
      return {
        name: 'Không xác định',
        class: 'role-unknown',
        icon: 'fas fa-question'
      };
  }
});

const roleName = computed(() => roleInfo.value.name);
const roleClass = computed(() => roleInfo.value.class);
const roleIcon = computed(() => roleInfo.value.icon);
</script>

<style scoped>
.role-info {
  display: inline-block;
}

.role-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.role-admin {
  background: linear-gradient(135deg, #ff6b6b, #ee5a24);
  color: white;
}

.role-customer {
  background: linear-gradient(135deg, #4ecdc4, #44a08d);
  color: white;
}

.role-staff {
  background: linear-gradient(135deg, #f39c12, #e67e22);
  color: white;
}

.role-unknown {
  background: #95a5a6;
  color: white;
}

.role-badge i {
  font-size: 10px;
}
</style>
