require('dotenv').config();
const app = require('./src/app');
const CleanupService = require('./src/services/CleanupService');

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
    console.log(`Accessible from emulator at http://10.0.2.2:${PORT}`);
    
    CleanupService.startCleanupJob(30);
    console.log('Cleanup job started - running every 30 minutes');
});
