import 'bootstrap/dist/css/bootstrap.min.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
import { VueQueryPlugin } from '@tanstack/vue-query';
import Toast, { POSITION } from 'vue-toastification';
import 'vue-toastification/dist/index.css';

import { createApp } from 'vue';
import App from './App.vue';
import router from './router';

const app = createApp(App);
app.use(router);
app.use(VueQueryPlugin);
app.use(Toast, {
  position: POSITION.TOP_RIGHT,
  timeout: 3000,
});
app.mount('#app');