<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
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
  return `${window.location.origin}/public/images/bg.jpg`;
});

onMounted(() => {
  // Add class to body and html
  document.body.classList.add('auth-page');
  document.documentElement.classList.add('auth-page');
  
  // Hide pagination with inline style for maximum priority
  const style = document.createElement('style');
  style.id = 'auth-hide-pagination';
  style.textContent = `
    .auth-layout .pagination,
    .auth-content .pagination,
    .auth-container .pagination,
    .login-container .pagination,
    .login-wrapper .pagination,
    .login-card .pagination,
    body.auth-page .pagination,
    html.auth-page .pagination,
    body.auth-page .pagination-section,
    html.auth-page .pagination-section,
    body.auth-page .pagination-nav,
    html.auth-page .pagination-nav,
    body.auth-page .pagination-controls,
    html.auth-page .pagination-controls,
    body.auth-page .pagination-buttons,
    html.auth-page .pagination-buttons,
    body.auth-page .pagination-info,
    html.auth-page .pagination-info,
    body.auth-page .pagination-label,
    html.auth-page .pagination-label,
    body.auth-page .pagination-select,
    html.auth-page .pagination-select,
    body.auth-page nav.pagination,
    html.auth-page nav.pagination {
      display: none !important;
      visibility: hidden !important;
      opacity: 0 !important;
      height: 0 !important;
      width: 0 !important;
      margin: 0 !important;
      padding: 0 !important;
      overflow: hidden !important;
      position: absolute !important;
      left: -9999px !important;
      pointer-events: none !important;
    }
  `;
  document.head.appendChild(style);
  
  // Set theme color to white for status bar
  const themeColorMeta = document.querySelector('meta[name="theme-color"]');
  if (themeColorMeta) {
    themeColorMeta.setAttribute('content', '#FFFFFF');
  } else {
    const meta = document.createElement('meta');
    meta.name = 'theme-color';
    meta.content = '#FFFFFF';
    document.head.appendChild(meta);
  }
  
  // Ensure status bar is visible
  // Set a white background for status bar area
  const statusBarHeight = window.visualViewport ? 
    (window.visualViewport.offsetTop > 0 ? window.visualViewport.offsetTop : 44) : 
    (window.innerHeight >= 812 ? 44 : 20);
  
  // Create a white overlay for status bar area if needed
  const existingOverlay = document.querySelector('.status-bar-white-overlay');
  if (!existingOverlay && statusBarHeight > 0) {
    const overlay = document.createElement('div');
    overlay.className = 'status-bar-white-overlay';
    overlay.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      height: ${statusBarHeight}px;
      background: #FFFFFF;
      z-index: 10001;
      pointer-events: none;
    `;
    document.body.appendChild(overlay);
  }
  
  // Apply background to body and html to ensure full coverage
  const bgUrl = backgroundImageUrl.value;
  
  // Set background on html (covers everything including status bar area)
  document.documentElement.style.backgroundImage = `url(${bgUrl})`;
  document.documentElement.style.backgroundSize = 'cover';
  document.documentElement.style.backgroundPosition = 'center';
  document.documentElement.style.backgroundRepeat = 'no-repeat';
  document.documentElement.style.backgroundAttachment = 'fixed';
  document.documentElement.style.margin = '0';
  document.documentElement.style.padding = '0';
  document.documentElement.style.width = '100%';
  document.documentElement.style.minHeight = '100vh';
  document.documentElement.style.height = '100%';
  document.documentElement.style.overflow = 'hidden';
  
  // Set background on body
  document.body.style.backgroundImage = `url(${bgUrl})`;
  document.body.style.backgroundSize = 'cover';
  document.body.style.backgroundPosition = 'center';
  document.body.style.backgroundRepeat = 'no-repeat';
  document.body.style.backgroundAttachment = 'fixed';
  document.body.style.margin = '0';
  document.body.style.padding = '0';
  document.body.style.width = '100%';
  document.body.style.minHeight = '100vh';
  document.body.style.height = '100%';
  document.body.style.overflow = 'hidden';
  
  // Also set on admin-layout and all parent containers
  const adminLayout = document.querySelector('.admin-layout.auth-layout');
  if (adminLayout) {
    adminLayout.style.backgroundImage = `url(${bgUrl})`;
    adminLayout.style.backgroundSize = 'cover';
    adminLayout.style.backgroundPosition = 'center';
    adminLayout.style.backgroundRepeat = 'no-repeat';
    adminLayout.style.backgroundAttachment = 'fixed';
    adminLayout.style.height = '100vh';
  }
  
  const authContent = document.querySelector('.auth-content');
  if (authContent) {
    authContent.style.backgroundImage = `url(${bgUrl})`;
    authContent.style.backgroundSize = 'cover';
    authContent.style.backgroundPosition = 'center';
    authContent.style.backgroundRepeat = 'no-repeat';
    authContent.style.backgroundAttachment = 'fixed';
  }
  
  const authContainer = document.querySelector('.auth-container');
  if (authContainer) {
    authContainer.style.backgroundImage = `url(${bgUrl})`;
    authContainer.style.backgroundSize = 'cover';
    authContainer.style.backgroundPosition = 'center';
    authContainer.style.backgroundRepeat = 'no-repeat';
    authContainer.style.backgroundAttachment = 'fixed';
  }
});

onUnmounted(() => {
  // Remove class from body and html
  document.body.classList.remove('auth-page');
  document.documentElement.classList.remove('auth-page');
  
  // Reset theme color
  const themeColorMeta = document.querySelector('meta[name="theme-color"]');
  if (themeColorMeta) {
    themeColorMeta.setAttribute('content', '#FDFBF8');
  }
  
  // Reset body and html styles
  document.body.style.backgroundImage = '';
  document.body.style.backgroundSize = '';
  document.body.style.backgroundPosition = '';
  document.body.style.backgroundRepeat = '';
  document.body.style.backgroundAttachment = '';
  document.body.style.margin = '';
  document.body.style.padding = '';
  document.body.style.width = '';
  document.body.style.minHeight = '';
  document.body.style.height = '';
  document.body.style.overflow = '';
  
  document.documentElement.style.margin = '';
  document.documentElement.style.padding = '';
  document.documentElement.style.width = '';
  document.documentElement.style.minHeight = '';
  document.documentElement.style.height = '';
  document.documentElement.style.overflow = '';
  document.documentElement.style.backgroundImage = '';
  document.documentElement.style.backgroundSize = '';
  document.documentElement.style.backgroundPosition = '';
  document.documentElement.style.backgroundRepeat = '';
  document.documentElement.style.backgroundAttachment = '';
  
  // Reset container styles
  const adminLayout = document.querySelector('.admin-layout.auth-layout');
  if (adminLayout) {
    adminLayout.style.backgroundImage = '';
    adminLayout.style.backgroundSize = '';
    adminLayout.style.backgroundPosition = '';
    adminLayout.style.backgroundRepeat = '';
    adminLayout.style.backgroundAttachment = '';
    adminLayout.style.height = '';
  }
  
  const authContent = document.querySelector('.auth-content');
  if (authContent) {
    authContent.style.backgroundImage = '';
    authContent.style.backgroundSize = '';
    authContent.style.backgroundPosition = '';
    authContent.style.backgroundRepeat = '';
    authContent.style.backgroundAttachment = '';
  }
  
  const authContainer = document.querySelector('.auth-container');
  if (authContainer) {
    authContainer.style.backgroundImage = '';
    authContainer.style.backgroundSize = '';
    authContainer.style.backgroundPosition = '';
    authContainer.style.backgroundRepeat = '';
    authContainer.style.backgroundAttachment = '';
  }
  
  // Remove status bar overlay
  const statusBarOverlay = document.querySelector('.status-bar-white-overlay');
  if (statusBarOverlay) {
    statusBarOverlay.remove();
  }
  
  // Remove pagination hide style
  const paginationStyle = document.getElementById('auth-hide-pagination');
  if (paginationStyle) {
    paginationStyle.remove();
  }
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
  height: 100vh;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  padding: 20px;
  margin: 0;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  background-attachment: fixed;
  box-sizing: border-box;
  position: relative;
}
.login-container::before {
  content: '';
  position: absolute;
  top: env(safe-area-inset-top, 44px);
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(3px);
  pointer-events: none;
  z-index: 0;
}
.login-container::after {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: env(safe-area-inset-top, 44px);
  min-height: 20px;
  background: #FFFFFF;
  z-index: 10001;
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

/* Hide pagination on login page */
.login-container .pagination,
.login-container .pagination-section,
.login-container .pagination-nav,
.login-container .pagination-controls,
.login-container .pagination-buttons,
.login-container .pagination-info,
.login-container .pagination-label,
.login-container .pagination-select,
.login-wrapper .pagination,
.login-wrapper .pagination-section,
.login-wrapper .pagination-nav,
.login-wrapper .pagination-controls,
.login-wrapper .pagination-buttons,
.login-wrapper .pagination-info,
.login-wrapper .pagination-label,
.login-wrapper .pagination-select,
.login-card .pagination,
.login-card .pagination-section,
.login-card .pagination-nav,
.login-card .pagination-controls,
.login-card .pagination-buttons,
.login-card .pagination-info,
.login-card .pagination-label,
.login-card .pagination-select,
.login-container nav.pagination,
.login-wrapper nav.pagination,
.login-card nav.pagination {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
  height: 0 !important;
  width: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  overflow: hidden !important;
  position: absolute !important;
  left: -9999px !important;
}
</style>