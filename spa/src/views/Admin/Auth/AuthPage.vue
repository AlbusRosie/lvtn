<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { Form, Field, ErrorMessage } from 'vee-validate';
import { toTypedSchema } from '@vee-validate/zod';
import { z } from 'zod';
import authService from '@/services/AuthService';
import usersService from '@/services/UserService';
import { useToast } from 'vue-toastification';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import RoleInfo from '@/components/RoleInfo.vue';
import UserInfo from '@/components/UserInfo.vue';

const router = useRouter();
const toast = useToast();
const isLogin = ref(true);
const isLoading = ref(false);
const message = ref('');
const currentUser = ref(null);
const checkLoggedInUser = () => {
  const userStr = localStorage.getItem('currentUser');
  if (userStr) {
    currentUser.value = JSON.parse(userStr);
  }
};
checkLoggedInUser();
const loginSchema = toTypedSchema(
  z.object({
    username: z
      .string()
      .min(3, { message: 'Tên đăng nhập phải ít nhất 3 ký tự.' })
      .max(50, { message: 'Tên đăng nhập có nhiều nhất 50 ký tự.' }),
    password: z
      .string()
      .min(6, { message: 'Mật khẩu phải ít nhất 6 ký tự.' })
      .max(50, { message: 'Mật khẩu có nhiều nhất 50 ký tự.' }),
  })
);

const registerSchema = toTypedSchema(
  z.object({
    username: z
      .string()
      .min(3, { message: 'Tên đăng nhập phải ít nhất 3 ký tự.' })
      .max(50, { message: 'Tên đăng nhập có nhiều nhất 50 ký tự.' }),
    password: z
      .string()
      .min(6, { message: 'Mật khẩu phải ít nhất 6 ký tự.' })
      .max(50, { message: 'Mật khẩu có nhiều nhất 50 ký tự.' }),
    confirmPassword: z
      .string()
      .min(6, { message: 'Xác nhận mật khẩu phải ít nhất 6 ký tự.' }),
    name: z
      .string()
      .min(2, { message: 'Họ tên phải ít nhất 2 ký tự.' })
      .max(100, { message: 'Họ tên có nhiều nhất 100 ký tự.' }),
    email: z
      .string()
      .email({ message: 'Email không hợp lệ.' }),
    phone: z
      .string()
      .min(10, { message: 'Số điện thoại phải ít nhất 10 ký tự.' })
      .max(15, { message: 'Số điện thoại có nhiều nhất 15 ký tự.' }),
  }).refine((data) => data.password === data.confirmPassword, {
    message: "Mật khẩu xác nhận không khớp",
    path: ["confirmPassword"],
  })
);

const currentSchema = computed(() => isLogin.value ? loginSchema : registerSchema);

async function onLogin(values) {
  isLoading.value = true;
  message.value = '';

  try {
    const result = await authService.login(values.username, values.password);
    const userRole = result.user.role_id;
    const userName = result.user.name;

    if (userRole === 1) {
      toast.success(`Đăng nhập thành công! Chào mừng Admin ${userName}!`);
      router.push('/');
      return; // Dừng hàm ở đây
    } else {
      const roleName = userRole === 2 ? 'Customer' : 'Seller';
      toast.success(`Đăng nhập thành công! Chào mừng ${roleName} ${userName}!`);
      localStorage.setItem('currentUser', JSON.stringify(result.user));
      currentUser.value = result.user;
    }
  } catch (error) {
    message.value = error.message;
    toast.error('Đăng nhập thất bại!');
  } finally {
    isLoading.value = false;
  }
}

async function onRegister(values) {
  isLoading.value = true;
  message.value = '';

  try {
    const formData = new FormData();
    formData.append('username', values.username);
    formData.append('password', values.password);
    formData.append('name', values.name);
    formData.append('email', values.email);
    formData.append('phone', values.phone);
    formData.append('role_id', '2'); // Customer role
    formData.append('avatar', 'public/images/blank-profile-picture.png');
    formData.append('address', '');
    formData.append('favorite', '0');

    await usersService.createUser(formData);
    toast.success('Đăng ký thành công! Vui lòng đăng nhập.');
    isLogin.value = true;
  } catch (error) {
    message.value = error.message;
    toast.error('Đăng ký thất bại!');
  } finally {
    isLoading.value = false;
  }
}

function onSubmit(values) {
  if (isLogin.value) {
    onLogin(values);
  } else {
    onRegister(values);
  }
}

function toggleMode() {
  isLogin.value = !isLogin.value;
  message.value = '';
}

function handleLogout() {
  currentUser.value = null;
}
</script>

<template>
  <div class="auth-container">
    <!-- Hiển thị thông tin user nếu đã đăng nhập -->
    <UserInfo v-if="currentUser" @logout="handleLogout" />

    <!-- Hiển thị form đăng nhập/đăng ký nếu chưa đăng nhập -->
    <div v-else class="auth-card">
      <div class="auth-header">
        <h2 class="auth-title">{{ isLogin ? 'Đăng nhập' : 'Đăng ký' }}</h2>
        <p class="auth-subtitle">
          {{ isLogin ? 'Chào mừng bạn quay trở lại!' : 'Tạo tài khoản mới' }}
        </p>
      </div>

      <Form :validation-schema="currentSchema" @submit="onSubmit" class="auth-form">
        <!-- Username field -->
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

        <!-- Password field -->
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

        <!-- Register only fields -->
        <template v-if="!isLogin">
          <div class="form-group">
            <label for="confirmPassword" class="form-label">Xác nhận mật khẩu</label>
            <Field
              name="confirmPassword"
              type="password"
              class="form-control"
              placeholder="Nhập lại mật khẩu"
            />
            <ErrorMessage name="confirmPassword" class="error-message" />
          </div>

          <div class="form-group">
            <label for="name" class="form-label">Họ và tên</label>
            <Field
              name="name"
              type="text"
              class="form-control"
              placeholder="Nhập họ và tên"
            />
            <ErrorMessage name="name" class="error-message" />
          </div>

          <div class="form-group">
            <label for="email" class="form-label">Email</label>
            <Field
              name="email"
              type="email"
              class="form-control"
              placeholder="Nhập email"
            />
            <ErrorMessage name="email" class="error-message" />
          </div>

          <div class="form-group">
            <label for="phone" class="form-label">Số điện thoại</label>
            <Field
              name="phone"
              type="tel"
              class="form-control"
              placeholder="Nhập số điện thoại"
            />
            <ErrorMessage name="phone" class="error-message" />
          </div>
        </template>

        <!-- Submit button -->
        <button
          type="submit"
          class="submit-btn"
          :disabled="isLoading"
        >
          <LoadingSpinner v-if="isLoading" text="" />
          <span v-else>{{ isLogin ? 'Đăng nhập' : 'Đăng ký' }}</span>
        </button>

        <!-- Error message -->
        <div v-if="message" class="error-alert">
          {{ message }}
        </div>
      </Form>

      <!-- Toggle mode -->
      <div class="auth-footer">
        <p class="toggle-text">
          {{ isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?' }}
          <button
            type="button"
            class="toggle-btn"
            @click="toggleMode"
          >
            {{ isLogin ? 'Đăng ký ngay' : 'Đăng nhập' }}
          </button>
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
@import '@/assets/auth.css';

.auth-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.auth-card {
  background: white;
  border-radius: 20px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  padding: 40px;
  width: 100%;
  max-width: 450px;
  animation: slideUp 0.6s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.auth-header {
  text-align: center;
  margin-bottom: 30px;
}

.auth-title {
  color: #333;
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 8px;
}

.auth-subtitle {
  color: #666;
  font-size: 16px;
  margin: 0;
}

.auth-form {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-label {
  display: block;
  margin-bottom: 8px;
  color: #333;
  font-weight: 600;
  font-size: 14px;
}

.form-control {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e1e5e9;
  border-radius: 10px;
  font-size: 16px;
  transition: all 0.3s ease;
  background: #f8f9fa;
}

.form-control:focus {
  outline: none;
  border-color: #667eea;
  background: white;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-control::placeholder {
  color: #999;
}

.error-message {
  color: #e74c3c;
  font-size: 12px;
  margin-top: 5px;
  display: block;
}

.submit-btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.submit-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
}

.submit-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
  transform: none;
}

.error-alert {
  background: #fee;
  color: #e74c3c;
  padding: 12px;
  border-radius: 8px;
  margin-top: 15px;
  font-size: 14px;
  border: 1px solid #fcc;
}

.auth-footer {
  text-align: center;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.toggle-text {
  color: #666;
  font-size: 14px;
  margin: 0;
}

.toggle-btn {
  background: none;
  border: none;
  color: #667eea;
  font-weight: 600;
  cursor: pointer;
  text-decoration: underline;
  margin-left: 5px;
  transition: color 0.3s ease;
}

.toggle-btn:hover {
  color: #764ba2;
}

@media (max-width: 480px) {
  .auth-card {
    padding: 30px 20px;
    margin: 10px;
  }

  .auth-title {
    font-size: 24px;
  }

  .form-control {
    padding: 10px 14px;
    font-size: 14px;
  }
}
</style>