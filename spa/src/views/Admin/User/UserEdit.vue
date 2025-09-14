<script setup>
import { ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import UserForm from '@/components/Admin/User/UserForm.vue';
import usersService from '@/services/UserService';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';

const props = defineProps({
  userId: { type: String, required: true }
});

const router = useRouter();
const route = useRoute();
const queryClient = useQueryClient();
const message = ref('');

const { data: user, isError, isLoading } = useQuery({
  queryKey: ['user', props.userId],
  queryFn: () => usersService.fetchUser(props.userId),
  onError: (error) => {
    router.push({
      name: 'notfound',
      params: { pathMatch: route.path.split('/').slice(1) },
      query: route.query,
      hash: route.hash,
    });
  },
});

const updateMutation = useMutation({
  mutationFn: (updatedUser) => usersService.updateUser(props.userId, updatedUser),
  onSuccess: () => {
    message.value = 'Tài khoản được cập nhật thành công.';
    queryClient.invalidateQueries(['user', props.userId]);
  },
  onError: (error) => {
    message.value = 'Lỗi cập nhật tài khoản.';
  },
});

const deleteMutation = useMutation({
  mutationFn: (id) => usersService.deleteUser(id),
  onSuccess: () => {
    router.push({ name: 'home' });
  },
  onError: (error) => {
  },
});

const onUpdateUser = (user) => {
  updateMutation.mutate(user);
};

const onDeleteUser = () => {
  if (confirm('Bạn muốn xóa tài khoản này?')) {
    deleteMutation.mutate(props.userId);
  }
};
</script>

<template>
  <div v-if="!isLoading && !isError" class="page">
    <h4>Hiệu chỉnh tài khoản</h4>
    <UserForm
      :user="user"
      @submit:user="onUpdateUser"
      @delete:user="onDeleteUser"
    />
    <p>{{ message }}</p>
  </div>

  <div v-else-if="isLoading">
    <p>Đang tải dữ liệu...</p>
  </div>

  <div v-else>
    <p>Có lỗi xảy ra khi tải tài khoản.</p>
  </div>
</template>
