<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { Form, Field, ErrorMessage } from 'vee-validate';
import { toTypedSchema } from '@vee-validate/zod';
import { z } from 'zod';
import authService from '@/services/AuthService';
import { useToast } from 'vue-toastification';
import LoadingSpinner from '@/components/LoadingSpinner.vue';

const router = useRouter();
const toast = useToast();
const isLoading = ref(false);
const message = ref('');

const loginSchema = toTypedSchema(
  z.object({
    username: z
      .string()
      .min(1, { message: 'Vui lòng nhập tên đăng nhập.' }),
    password: z
      .string()
      .min(1, { message: 'Vui lòng nhập mật khẩu.' }),
  })
);

async function onLogin(values) {
  isLoading.value = true;
  message.value = '';

  try {
    const result = await authService.login(values.username, values.password);
    const userRole = result.user.role_id;

    if (userRole === 1) {
      toast.success('Đăng nhập thành công!');
      router.push('/');
    } else {
      message.value = 'Chỉ admin mới được phép đăng nhập vào hệ thống này.';
      toast.error('Không có quyền truy cập!');
    }
  } catch (error) {
    message.value = error.message;
    toast.error('Đăng nhập thất bại!');
  } finally {
    isLoading.value = false;
  }
}
</script>

<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <h1 class="login-title">Login</h1>
        <p class="login-subtitle">Đăng nhập hệ thống quản lý</p>
      </div>

      <Form :validation-schema="loginSchema" @submit="onLogin" class="login-form">
        <div class="form-group">
          <label for="username" class="form-label">Tên đăng nhập</label>
          <Field
            name="username"
            type="text"
            class="form-control"
            placeholder="Nhập tên đăng nhập"
          />
          <ErrorMessage name="username" class="error-message" />
        </div>

        <div class="form-group">
          <label for="password" class="form-label">Mật khẩu</label>
          <Field
            name="password"
            type="password"
            class="form-control"
            placeholder="Nhập mật khẩu"
          />
          <ErrorMessage name="password" class="error-message" />
        </div>

        <button
          type="submit"
          class="login-btn"
          :disabled="isLoading"
        >
          <LoadingSpinner v-if="isLoading" text="" />
          <span v-else>Đăng nhập</span>
        </button>

        <div v-if="message" class="error-alert">
          {{ message }}
        </div>
      </Form>
    </div>
  </div>
</template>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f5f5f5;
  padding: 20px;
}

.login-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  padding: 40px;
  width: 100%;
  max-width: 400px;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-title {
  color: #333;
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 8px;
}

.login-subtitle {
  color: #666;
  font-size: 14px;
  margin: 0;
}

.login-form {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-label {
  display: block;
  margin-bottom: 6px;
  color: #333;
  font-weight: 500;
  font-size: 14px;
}

.form-control {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.3s ease;
  box-sizing: border-box;
}

.form-control:focus {
  outline: none;
  border-color: #007bff;
}

.form-control::placeholder {
  color: #999;
}

.error-message {
  color: #dc3545;
  font-size: 12px;
  margin-top: 4px;
  display: block;
}

.login-btn {
  width: 100%;
  padding: 12px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.login-btn:hover:not(:disabled) {
  background-color: #0056b3;
}

.login-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error-alert {
  background-color: #f8d7da;
  color: #721c24;
  padding: 12px;
  border-radius: 4px;
  margin-top: 15px;
  font-size: 14px;
  border: 1px solid #f5c6cb;
}

@media (max-width: 480px) {
  .login-card {
    padding: 30px 20px;
    margin: 10px;
  }

  .login-title {
    font-size: 20px;
  }
}
</style>