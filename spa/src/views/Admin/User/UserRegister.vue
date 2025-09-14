<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import UserForm from '@/components/Admin/User/UserForm.vue';
import usersService from '@/services/UserService';
import { useMutation, useQueryClient } from '@tanstack/vue-query';

const router = useRouter();
const message = ref('');

const queryClient = useQueryClient();

const mutation = useMutation({
  mutationFn: usersService.createUser,
  onSuccess: () => {
    message.value = 'User được tạo thành công.';

    queryClient.invalidateQueries(['users']);

  },
  onError: (error) => {

    message.value = 'Đã có lỗi xảy ra.';
  }
});

function onCreateUser(user) {

  if (!user.get('username') || !user.get('password') || !user.get('role_id') || !user.get('name') || !user.get('email')) {
    message.value = 'Vui lòng điền đầy đủ thông tin bắt buộc.';
    return;
  }
  mutation.mutate(user);
}

const defaultUser = {
  avatar: 'public/images/blank-profile-picture.png',
  username: '',
  password: '',
  role_id: 2,
  name: '',
  email: '',
  address: '',
  phone: '',
  favorite: 0,
};
</script>

<template>
  <div>
    <h4>Thêm mới tài khoản</h4>
    <UserForm :user="defaultUser" @submit:user="onCreateUser" />
    <p>{{ message }}</p>
  </div>
</template>
