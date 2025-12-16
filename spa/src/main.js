import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import '@fortawesome/fontawesome-free/css/all.min.css';
import { VueQueryPlugin } from '@tanstack/vue-query';
import Toast, { POSITION } from 'vue-toastification';
import 'vue-toastification/dist/index.css';
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import AuthService from './services/AuthService';
import SocketService from './services/SocketService';

const app = createApp(App);
app.use(router);
app.use(VueQueryPlugin);
app.use(Toast, {
  position: POSITION.TOP_RIGHT,
  timeout: 3000,
});

// Connect socket when app starts if authenticated
if (AuthService.isAuthenticated()) {
  SocketService.connect();
}

app.mount('#app');