import { efetch } from './BaseService';
function makeMapService() {
    async function getMapboxApiKey() {
        try {
            const response = await efetch('/api/config/mapbox-key');
            const apiKey = response?.apiKey || response?.data?.apiKey || null;
            + '...' : 'null');
            return apiKey;
        } catch (error) {
            throw error;
        }
    }
    return {
        getMapboxApiKey
    };
}
export default makeMapService();
