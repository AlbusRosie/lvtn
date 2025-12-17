const axios = require('axios');

class GeocodingService {
    /**
     * Geocode địa chỉ thành tọa độ (latitude, longitude)
     * @param {string} address - Địa chỉ cần geocode
     * @param {object} options - Options: { timeout, country }
     * @returns {Promise<{lat: number, lng: number} | null>}
     */
    async geocodeAddress(address, options = {}) {
        if (!address || typeof address !== 'string' || address.trim().length === 0) {
            return null;
        }

        const mapboxKey = process.env.MAPBOX_KEY_PUBLIC || process.env.MAPBOX_KEY;
        if (!mapboxKey) {
            console.warn('[GeocodingService] Mapbox API key not found');
            return null;
        }

        try {
            const timeout = options.timeout || 5000;
            const country = options.country || 'VN';
            const encodedQuery = encodeURIComponent(address.trim());
            const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedQuery}.json?access_token=${mapboxKey}&country=${country}&limit=1`;
            
            const geocodeResponse = await axios.get(url, { timeout });
            
            if (geocodeResponse.data && 
                geocodeResponse.data.features && 
                geocodeResponse.data.features.length > 0) {
                const coordinates = geocodeResponse.data.features[0].geometry.coordinates;
                return {
                    lat: coordinates[1],
                    lng: coordinates[0]
                };
            }
            
            return null;
        } catch (error) {
            console.error('[GeocodingService] Geocode error:', error.message);
            return null;
        }
    }

    /**
     * Geocode địa chỉ và update conversation context
     * @param {string} address - Địa chỉ cần geocode
     * @param {string} conversationId - Conversation ID để update context
     * @param {number} userId - User ID
     * @returns {Promise<{lat: number, lng: number} | null>}
     */
    async geocodeAndUpdateContext(address, conversationId, userId) {
        const coordinates = await this.geocodeAddress(address);
        
        if (coordinates && conversationId) {
            try {
                const ConversationService = require('../ConversationService');
                await ConversationService.updateConversationContext(conversationId, {
                    userLatitude: coordinates.lat,
                    userLongitude: coordinates.lng
                }, userId);
            } catch (error) {
                console.error('[GeocodingService] Error updating context:', error.message);
            }
        }
        
        return coordinates;
    }
}

module.exports = new GeocodingService();