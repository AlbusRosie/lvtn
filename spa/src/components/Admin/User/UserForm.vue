<script setup>
import { ref, watch } from 'vue';
import { Form, Field, ErrorMessage } from 'vee-validate';
import { toTypedSchema } from '@vee-validate/zod';
import { z } from 'zod';
import { USER_ROLES, ROLE_NAMES } from '@/constants';

const props = defineProps({
  user: { type: Object, required: true }
});

const avatarFileInput = ref(null);
const avatarFile = ref(props.user?.avatar || '');
const $emit = defineEmits(['submit:user', 'delete:user']);

const validationSchema = toTypedSchema(
  z.object({
    username: z
      .string()
      .min(3, { message: 'Tên đăng nhập phải ít nhất 3 ký tự.' })
      .max(50, { message: 'Tên đăng nhập có nhiều nhất 50 ký tự.' }),
    password: z
      .string()
      .min(6, { message: 'Mật khẩu phải ít nhất 6 ký tự.' })
      .max(50, { message: 'Mật khẩu có nhiều nhất 50 ký tự.' }),
    role_id: z.number().min(1, { message: 'Vui lòng chọn vai trò.' }),
    name: z
      .string()
      .min(2, { message: 'Tên phải ít nhất 2 ký tự.' })
      .max(100, { message: 'Tên có nhiều nhất 100 ký tự.' }),
    email: z
      .string()
      .email({ message: 'E-mail không đúng.' })
      .max(100, { message: 'E-mail tối đa 100 ký tự.' }),
    address: z.string().max(255, { message: 'Địa chỉ tối đa 255 ký tự.' }).optional(),
    phone: z
      .string()
      .regex(/^[0-9]{10,11}$/, {
        message: 'Số điện thoại phải có 10-11 số.'
      })
      .max(15, { message: 'Số điện thoại tối đa 15 ký tự.' })
      .optional(),
    favorite: z.number().optional(),
    avatarFile: z.instanceof(File).optional()
  })
);

watch(
  () => props.user,
  (newUser) => {
    avatarFile.value = newUser?.avatar || '';
  },
  { immediate: true }
);

function previewAvatarFile(event) {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (evt) => {
    avatarFile.value = evt.target.result;
  };
  reader.readAsDataURL(file);
}

function submitUser(values) {
  const formData = new FormData();

  formData.append('username', values.username || '');
  formData.append('password', values.password || '');
  formData.append('role_id', values.role_id || '');
  formData.append('name', values.name || '');
  formData.append('email', values.email || '');

  if (values.address) formData.append('address', values.address);
  if (values.phone) formData.append('phone', values.phone);
  if (values.favorite !== undefined) formData.append('favorite', values.favorite);
  if (values.avatarFile) formData.append('avatarFile', values.avatarFile);

  for (let pair of formData.entries()) {

  }

  $emit('submit:user', formData);
}

function deleteUser() {
  $emit('delete:user', props.user.id);
}
</script>

<template>
  <Form :validation-schema="validationSchema" @submit="submitUser">
    <div class="mb-3 w-50 h-50">
      <img
        class="img-fluid img-thumbnail"
        :src="avatarFile"
        alt="Avatar"
        @click="avatarFileInput?.click()"
      />
      <Field name="avatarFile" v-slot="{ handleChange }">
        <input
          type="file"
          class="d-none"
          ref="avatarFileInput"
          accept="image/*"
          @change="
            (event) => {
              handleChange(event);
              previewAvatarFile(event);
            }
          "
        />
      </Field>
    </div>
    <div class="mb-3">
      <label for="username" class="form-label">Tên đăng nhập <span class="text-danger">*</span></label>
      <Field name="username" type="text" class="form-control" :value="user?.username" />
      <ErrorMessage name="username" class="error-feedback" />
    </div>
    <div class="mb-3">
      <label for="password" class="form-label">Mật khẩu <span class="text-danger">*</span></label>
      <Field name="password" type="password" class="form-control" />
      <ErrorMessage name="password" class="error-feedback" />
    </div>
    <div class="mb-3">
      <label for="role_id" class="form-label">Vai trò <span class="text-danger">*</span></label>
      <Field name="role_id" as="select" class="form-control" :value="user?.role_id">
        <option value="">Chọn vai trò</option>
        <option :value="USER_ROLES.ADMIN">{{ ROLE_NAMES[USER_ROLES.ADMIN] }}</option>
        <option :value="USER_ROLES.CUSTOMER">{{ ROLE_NAMES[USER_ROLES.CUSTOMER] }}</option>
        <option :value="USER_ROLES.STAFF">{{ ROLE_NAMES[USER_ROLES.STAFF] }}</option>
      </Field>
      <ErrorMessage name="role_id" class="error-feedback" />
    </div>
    <div class="mb-3">
      <label for="name" class="form-label">Tên <span class="text-danger">*</span></label>
      <Field name="name" type="text" class="form-control" :value="user?.name" />
      <ErrorMessage name="name" class="error-feedback" />
    </div>
    <div class="mb-3">
      <label for="email" class="form-label">E-mail <span class="text-danger">*</span></label>
      <Field name="email" type="email" class="form-control" :value="user?.email" />
      <ErrorMessage name="email" class="error-feedback" />
    </div>
    <div class="mb-3">
      <label for="address" class="form-label">Địa chỉ</label>
      <Field name="address" type="text" class="form-control" :value="user?.address" />
      <ErrorMessage name="address" class="error-feedback" />
    </div>
    <div class="mb-3">
      <label for="phone" class="form-label">Điện thoại</label>
      <Field name="phone" type="tel" class="form-control" :value="user?.phone" />
      <ErrorMessage name="phone" class="error-feedback" />
    </div>
    <div class="mb-3 form-check">
      <Field
        name="favorite"
        type="checkbox"
        class="form-check-input"
        :model-value="user?.favorite"
        :value="1"
        :unchecked-value="0"
      />
      <label for="favorite" class="form-check-label">
        <strong>Liên hệ yêu thích</strong>
      </label>
    </div>
    <div class="mb-3">
      <button type="submit" class="btn btn-primary">
        <i class="fas fa-save"></i> Lưu
      </button>
      <button v-if="user?.id" type="button" class="ms-2 btn btn-danger" @click="deleteUser">
        <i class="fas fa-trash"></i> Xóa
      </button>
    </div>
  </Form>
</template>

<style scoped>
@import '@/assets/form.css';
</style>