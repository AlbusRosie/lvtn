<script setup>
import { ROLE_NAMES, USER_ROLES, DEFAULT_AVATAR } from '@/constants';
const props = defineProps({
  user: { type: Object, required: true },
});
const emit = defineEmits(['delete', 'view']);
function handleDelete() {
  emit('delete', props.user);
}
function handleView() {
  emit('view', props.user);
}
</script>
<template>
  <div class="user-card">
    <div class="user-header">
      <div class="user-avatar-wrapper">
        <div class="user-avatar">
          <img 
            :src="user.avatar || DEFAULT_AVATAR" 
            alt="Avatar" 
          />
        </div>
      </div>
      <div class="user-info">
        <h4>{{ user.name }}</h4>
        <span class="role-badge" :class="{
          'role-admin': user.role_id === USER_ROLES.ADMIN,
          'role-manager': user.role_id === USER_ROLES.MANAGER,
          'role-staff': user.role_id === USER_ROLES.STAFF,
          'role-customer': user.role_id === USER_ROLES.CUSTOMER,
          'role-kitchen': user.role_id === USER_ROLES.KITCHEN_STAFF,
          'role-cashier': user.role_id === USER_ROLES.CASHIER,
          'role-delivery': user.role_id === USER_ROLES.DELIVERY_STAFF
        }">
          {{ ROLE_NAMES[user.role_id] || 'Không xác định' }}
        </span>
      </div>
    </div>
    <div class="user-details">
      <div class="detail-item">
        <i class="fas fa-user detail-icon"></i>
        <span class="detail-label">Username:</span>
        <span class="detail-value">{{ user.username }}</span>
      </div>
      <div class="detail-item">
        <i class="fas fa-envelope detail-icon"></i>
        <span class="detail-label">Email:</span>
        <span class="detail-value">{{ user.email }}</span>
      </div>
      <div class="detail-item">
        <i class="fas fa-phone detail-icon"></i>
        <span class="detail-label">Điện thoại:</span>
        <span class="detail-value">{{ user.phone || 'Chưa cập nhật' }}</span>
      </div>
      <div v-if="user.branch_name" class="detail-item">
        <i class="fas fa-building detail-icon"></i>
        <span class="detail-label">Chi nhánh:</span>
        <span class="detail-value">{{ user.branch_name }}</span>
      </div>
    </div>
    <div class="user-actions">
      <button @click="handleView" class="action-btn view-btn" title="Xem và chỉnh sửa">
        <i class="fas fa-eye"></i>
      </button>
      <button @click="handleDelete" class="action-btn delete-btn" title="Xóa">
        <i class="fas fa-trash"></i>
      </button>
    </div>
  </div>
</template>
<style scoped>
.user-card {
  background: white;
  border: 1px solid #F0E6D9;
  border-radius: 12px;
  padding: 16px;
  transition: border-color 0.2s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  position: relative;
  overflow: hidden;
}
.user-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, #FF8C42, #E67E22);
  opacity: 0;
  transition: opacity 0.2s ease;
}
.user-card:hover {
  border-color: #FF8C42;
}
.user-card:hover::before {
  opacity: 1;
}
.user-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 14px;
  padding-bottom: 14px;
  border-bottom: 1px solid #F0E6D9;
}
.user-avatar-wrapper {
  position: relative;
}
.user-avatar {
  width: 50px;
  height: 50px;
  border-radius: 12px;
  overflow: hidden;
  background: linear-gradient(135deg, #FF8C42, #E67E22);
  padding: 2px;
  box-shadow: 0 1px 3px rgba(255, 140, 66, 0.12);
}
.user-avatar img {
  width: 100%;
  height: 100%;
  border-radius: 12px;
  object-fit: cover;
}
.user-info {
  flex: 1;
}
.user-info h4 {
  margin: 0 0 6px 0;
  color: #333;
  font-size: 16px;
  font-weight: 700;
  line-height: 1.3;
}
.role-badge {
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  display: inline-block;
}
.role-admin {
  background: #fee2e2;
  color: #dc2626;
}
.role-manager {
  background: #f3e8ff;
  color: #7c3aed;
}
.role-staff {
  background: #fef3c7;
  color: #d97706;
}
.role-customer {
  background: #dbeafe;
  color: #2563eb;
}
.role-kitchen {
  background: #fef2f2;
  color: #ef4444;
}
.role-cashier {
  background: #ecfdf5;
  color: #059669;
}
.role-delivery {
  background: #f0f9ff;
  color: #0284c7;
}
.user-details {
  margin-bottom: 14px;
}
.detail-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
  padding: 6px 0;
  border-bottom: 1px solid #F8F8F8;
}
.detail-item:last-child {
  border-bottom: none;
  margin-bottom: 0;
}
.detail-icon {
  width: 16px;
  text-align: center;
  color: #FF8C42;
  font-size: 12px;
  flex-shrink: 0;
}
.detail-label {
  font-size: 12px;
  color: #999;
  font-weight: 500;
  min-width: 70px;
  flex-shrink: 0;
}
.detail-value {
  font-size: 12px;
  color: #333;
  font-weight: 600;
  flex: 1;
  text-align: right;
  word-break: break-word;
}
.user-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
  padding-top: 12px;
  border-top: 1px solid #F0E6D9;
}
.action-btn {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  border: 2px solid #F0E6D9;
  background: white;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  position: relative;
}
.view-btn:hover {
  background: #E3F2FD;
  border-color: #2196F3;
  color: #2196F3;
}
.edit-btn:hover {
  background: #FFF3E0;
  border-color: #FF8C42;
  color: #FF8C42;
}
.delete-btn:hover {
  background: #FFEBEE;
  border-color: #ef4444;
  color: #ef4444;
}
@media (max-width: 768px) {
  .user-card {
    padding: 15px;
  }
  .user-header {
    flex-direction: column;
    text-align: center;
    gap: 10px;
  }
  .user-actions {
    justify-content: center;
  }
}
</style>
