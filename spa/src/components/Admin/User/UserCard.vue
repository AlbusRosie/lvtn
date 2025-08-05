
<script setup>
import { ROLE_NAMES } from '@/constants';

defineProps({
  user: { type: Object, required: true },
});
</script>

<template>
  <div>
    <div class="p-1 w-75 h-75">
      <img class="img-fluid img-thumbnail" :src="user.avatar" alt="Avatar" />
    </div>
    <div class="p-1">
      <strong>Tên đăng nhập:</strong>
      {{ user.username }}
    </div>
    <div class="p-1">
      <strong>Tên:</strong>
      {{ user.name }}
    </div>
    <div class="p-1">
      <strong>Vai trò:</strong>
      <span class="badge" :class="{
        'bg-danger': user.role_id === 1,
        'bg-primary': user.role_id === 2,
        'bg-warning': user.role_id === 3
      }">
        {{ ROLE_NAMES[user.role_id] || 'Không xác định' }}
      </span>
    </div>
    <div class="p-1">
      <strong>E-mail:</strong>
      {{ user.email }}
    </div>
    <div class="p-1">
      <strong>Địa chỉ:</strong>
      {{ user.address || 'Chưa cập nhật' }}
    </div>
    <div class="p-1">
      <strong>Điện thoại:</strong>
      {{ user.phone || 'Chưa cập nhật' }}
    </div>
    <div class="p-1">
      <strong>Liên hệ yêu thích:&nbsp;</strong>
      <i v-if="user.favorite" class="fas fa-check text-success"></i>
      <i v-else class="fas fa-times text-danger"></i>
    </div>
  </div>
</template>
