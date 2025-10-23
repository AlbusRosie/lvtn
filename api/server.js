require('dotenv').config();
const app = require('./src/app');
const CleanupService = require('./src/services/CleanupService');

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    CleanupService.startCleanupJob(30);
});
