import { efetch } from './BaseService';
function makeMapService() {
    async function getMapboxApiKey() {
        try {
            const response = await efetch('/api/config/mapbox-key');
            // Response từ backend có dạng: { status: 'success', data: { apiKey: '...' } }
            const apiKey = response?.data?.apiKey || response?.apiKey || null;
            if (apiKey) {
                console.log('Mapbox API key retrieved successfully');
            } else {
                console.warn('Mapbox API key not found in response:', response);
            }
            return apiKey;
        } catch (error) {
            console.error('Error fetching Mapbox API key:', error);
            throw error;
        }
    }
    return {
        getMapboxApiKey
    };
}
export default makeMapService();
