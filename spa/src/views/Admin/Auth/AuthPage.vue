<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { Form, Field, ErrorMessage } from 'vee-validate';
import { toTypedSchema } from '@vee-validate/zod';
import { z } from 'zod';
import authService from '@/services/AuthService';
import { useToast } from 'vue-toastification';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import { USER_ROLES } from '@/constants';
const router = useRouter();
const toast = useToast();
const isLoading = ref(false);
const message = ref('');
const usernameValue = ref('');
const passwordValue = ref('');
const usernameFocused = ref(false);
const passwordFocused = ref(false);
const backgroundImageUrl = computed(() => {
  return `${window.location.origin}/public/images/bg.jpeg`;
});
const loginSchema = toTypedSchema(
  z.object({
    username: z
      .string()
      .min(1, { message: 'Please enter username.' }),
    password: z
      .string()
      .min(1, { message: 'Please enter password.' }),
  })
);
async function onLogin(values) {
  isLoading.value = true;
  message.value = '';
  try {
    const result = await authService.login(values.username, values.password);
    const user = result.user;
    if (user.role_id === USER_ROLES.CUSTOMER) {
      authService.logout();
      message.value = 'Only staff or administrators are allowed to login.';
      toast.error('Access denied!');
      return;
    }
    toast.success('Login successful!');
    if (user.role_id === USER_ROLES.ADMIN) {
      router.push('/');
    } else if (user.role_id === USER_ROLES.STAFF) {
      router.push('/');
    } else if (user.role_id === USER_ROLES.KITCHEN_STAFF) {
      router.push('/employee/kitchen');
    } else if (user.role_id === USER_ROLES.CASHIER) {
      router.push('/employee/cashier');
    } else if (user.role_id === USER_ROLES.RECEPTIONIST) {
      router.push('/employee/reception');
    } else if (user.role_id === USER_ROLES.DELIVERY_STAFF) {
      router.push('/employee/delivery');
    } else if (user.role_id === USER_ROLES.MANAGER) {
      router.push('/employee/manager');
    } else {
      router.push('/employee');
    }
  } catch (error) {
    message.value = error.message;
    toast.error('Login failed!');
  } finally {
    isLoading.value = false;
  }
}
</script>
<template>
  <div class="login-container" :style="{ backgroundImage: `url(${backgroundImageUrl})` }">
    <div class="login-wrapper">
      <div class="login-card">
        <div class="login-header">
          <div class="logo-section">
            <img src="@/assets/logo.png" alt="Beast Bite" class="logo-img" />
          </div>
        </div>
        <Form :validation-schema="loginSchema" @submit="onLogin" class="login-form">
          <div class="form-group">
            <Field
              name="username"
              type="text"
              v-slot="{ field, value }"
            >
              <input
                v-bind="field"
                type="text"
                class="form-control"
                :value="value"
                @input="(e) => { field.onInput(e); usernameValue = e.target.value; }"
                @focus="usernameFocused = true"
                @blur="usernameFocused = false"
              />
            </Field>
            <label 
              for="username" 
              class="form-label"
              :class="{ 'label-floating': usernameFocused || usernameValue }"
            >
              Username or Email
            </label>
            <ErrorMessage name="username" class="error-message" />
          </div>
          <div class="form-group">
            <Field
              name="password"
              type="password"
              v-slot="{ field, value }"
            >
              <input
                v-bind="field"
                type="password"
                class="form-control"
                :value="value"
                @input="(e) => { field.onInput(e); passwordValue = e.target.value; }"
                @focus="passwordFocused = true"
                @blur="passwordFocused = false"
              />
            </Field>
            <label 
              for="password" 
              class="form-label"
              :class="{ 'label-floating': passwordFocused || passwordValue }"
            >
              Password
            </label>
            <ErrorMessage name="password" class="error-message" />
          </div>
          <button
            type="submit"
            class="login-btn"
            :disabled="isLoading"
          >
            <LoadingSpinner v-if="isLoading" text="" />
            <span v-if="isLoading">Logging in...</span>
            <span v-else>Log In</span>
          </button>
          <div v-if="message" class="error-alert">
            <span>{{ message }}</span>
          </div>
        </Form>
      </div>
    </div>
  </div>
</template>
<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  background-attachment: fixed;
  position: relative;
  overflow: hidden;
  padding: 20px;
}
.login-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(3px);
  pointer-events: none;
}
.login-wrapper {
  width: 100%;
  max-width: 400px;
  position: relative;
  z-index: 1;
}
.login-card {
  background: transparent;
  padding: 0;
  width: 100%;
  position: relative;
}
.login-header {
  text-align: center;
}
.logo-section {
  display: flex;
  justify-content: center;
}
.logo-img {
  width: 120px;
  height: 120px;
  object-fit: contain;
  filter: none;
}
.login-form {
  margin-bottom: 0;
}
.form-group {
  position: relative;
  margin-bottom: 32px;
}
.form-label {
  position: absolute;
  left: 0;
  top: 12px;
  color: rgba(255, 255, 255, 0.7);
  font-weight: 400;
  font-size: 15px;
  pointer-events: none;
  transition: all 0.2s ease;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.3);
}
.form-label.label-floating {
  top: -8px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.9);
}
.form-control {
  width: 100%;
  padding: 12px 0;
  border: none;
  border-bottom: 1px solid rgba(255, 255, 255, 0.5);
  border-radius: 0;
  font-size: 15px;
  font-weight: 400;
  transition: all 0.2s ease;
  box-sizing: border-box;
  background: transparent;
  color: #FFFFFF;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
  outline: none;
}
.form-control:focus,
.form-control:focus-visible,
.form-control:active {
  outline: none !important;
  border-bottom-color: rgba(255, 255, 255, 0.9);
  border-bottom-width: 2px;
  box-shadow: none;
}
.form-control::placeholder {
  color: transparent;
  font-weight: 400;
}
.error-message {
  color: #FFE5E5;
  font-size: 12px;
  margin-top: 8px;
  display: block;
  font-weight: 400;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}
.login-btn {
  width: 100%;
  padding: 16px;
  background: linear-gradient(90deg, #FFB84D 0%, #E67E22 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 400;
  cursor: pointer;
  transition: opacity 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 8px;
  text-shadow: none;
}
.login-btn:hover:not(:disabled) {
  opacity: 0.9;
}
.login-btn:active:not(:disabled) {
  opacity: 0.85;
}
.login-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.error-alert {
  background: rgba(220, 38, 38, 0.15);
  color: #FFE5E5;
  padding: 12px;
  border-radius: 6px;
  margin-top: 16px;
  font-size: 13px;
  text-align: center;
  font-weight: 400;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}
@media (max-width: 480px) {
  .login-wrapper {
    max-width: 100%;
  }
  .login-card {
    padding: 32px 24px;
    border-radius: 18px;
  }
  .login-header {
    margin-bottom: 16px;
  }
  .logo-icon {
    width: 80px;
    height: 80px;
  }
  .login-subtitle {
    font-size: 13px;
  }
  .form-group {
    margin-bottom: 18px;
  }
}
@media (max-width: 360px) {
  .login-card {
    padding: 28px 20px;
  }
}
</style>