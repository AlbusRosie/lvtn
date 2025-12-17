const LegacyFallbackService = require('../fallback/LegacyFallbackService');

class ResponseNormalizer {
    normalize(payload, message, context) {
        let finalPayload = payload;
        
        // Ensure payload exists
        if (!finalPayload || (!finalPayload.response && !finalPayload.message)) {
            try {
                finalPayload = LegacyFallbackService.fallbackResponse(message, context);
            } catch {
                finalPayload = {
                    response: 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.',
                    intent: 'error',
                    entities: {},
                    suggestions: []
                };
            }
        }
        
        // Ensure we always have a message field
        if (!finalPayload) {
            finalPayload = {
                response: 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.',
                intent: 'error',
                entities: {},
                suggestions: []
            };
        }
        
        if (!finalPayload.response && !finalPayload.message) {
            finalPayload.message = 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.';
        }
        
        // Normalize: ensure both response and message fields exist
        if (finalPayload.response && !finalPayload.message) {
            finalPayload.message = finalPayload.response;
        }
        if (finalPayload.message && !finalPayload.response) {
            finalPayload.response = finalPayload.message;
        }
        
        return finalPayload;
    }
}

module.exports = new ResponseNormalizer();

