class Utils {
    normalizeVietnamese(text) {
        if (!text) return text;
        const accents = {
            'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
            'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
            'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
            'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
            'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
            'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
            'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
            'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
            'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
            'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
            'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
            'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
            'đ': 'd'
        };
        return text.replace(/[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/g, 
            char => accents[char] || char);
    }
    cleanMessage(message) {
        if (!message) return message;
        let cleaned = message.replace(/\[INTENT:\s*[^\]]+\]/gi, '');
        cleaned = cleaned.replace(/\[ENTITIES:\s*[^\]]+\]/gi, '');
        cleaned = cleaned.replace(/\*\*([^*]+)\*\*/g, (match, text) => {
            return `\n${text}\n`;
        });
        cleaned = cleaned.replace(/\n{3,}/g, '\n\n');
        cleaned = cleaned.split('\n')
            .filter(line => line.trim() !== '')
            .join('\n')
            .trim();
        return cleaned;
    }
    safeJsonParse(jsonString, schema = null) {
        if (typeof jsonString !== 'string') return null;
        try {
            if (jsonString.length > 10000) {
                return null;
            }
            const parsed = JSON.parse(jsonString);
            if (schema) {
                if (schema === 'entities' && typeof parsed !== 'object') {
                    return null;
                }
                if (schema === 'context' && typeof parsed !== 'object') {
                    return null;
                }
            }
            if (parsed && typeof parsed === 'object' && parsed.constructor !== Object) {
                return null;
            }
            return parsed;
        } catch {
            return null;
        }
    }
    normalizeEntityFields(entities) {
        if (!entities) return {};
        const normalized = { ...entities };
        const peopleFields = ['people', 'number_of_people', 'guest_count', 'pax', 'quantity'];
        let peopleValue = null;
        for (const field of peopleFields) {
            if (normalized[field] && !peopleValue) {
                peopleValue = normalized[field];
            }
        }
        if (peopleValue) {
            normalized.people = peopleValue;
            normalized.number_of_people = peopleValue;
            normalized.guest_count = peopleValue;
        }
        const branchFields = ['branch_name', 'branch', 'branch_id'];
        let branchValue = null;
        for (const field of branchFields) {
            if (normalized[field] && !branchValue) {
                branchValue = normalized[field];
            }
        }
        if (branchValue) {
            normalized.branch_name = branchValue;
            normalized.branch = branchValue;
        }
        const timeFields = ['time', 'time_slot', 'reservation_time', 'hour'];
        let timeValue = null;
        for (const field of timeFields) {
            if (normalized[field] && !timeValue) {
                timeValue = normalized[field];
            }
        }
        if (timeValue) {
            normalized.time = timeValue;
            normalized.reservation_time = timeValue;
            normalized.time_slot = timeValue;
        }
        const dateFields = ['date', 'reservation_date', 'booking_date'];
        let dateValue = null;
        for (const field of dateFields) {
            if (normalized[field] && !dateValue) {
                dateValue = normalized[field];
            }
        }
        if (dateValue) {
            normalized.date = dateValue;
            normalized.reservation_date = dateValue;
            normalized.booking_date = dateValue;
        }
        return normalized;
    }

    /**
     * Merge và normalize nhiều entity objects
     * Loại bỏ duplicate code trong các handler
     * @param {object} entities - Entities hiện tại
     * @param {object} lastEntities - Entities từ context
     * @param {object} historyEntities - Entities từ history
     * @returns {object} Merged và normalized entities
     */
    mergeAndNormalizeEntities(entities = {}, lastEntities = {}, historyEntities = {}) {
        const normalizedEntities = this.normalizeEntityFields(entities);
        const normalizedLastEntities = this.normalizeEntityFields(lastEntities);
        const normalizedHistoryEntities = this.normalizeEntityFields(historyEntities);
        
        return {
            ...normalizedHistoryEntities,
            ...normalizedLastEntities,
            ...normalizedEntities
        };
    }

    /**
     * Format price theo định dạng Việt Nam
     * Loại bỏ duplicate code trong nhiều handlers
     * @param {number|string} price - Price cần format
     * @param {string} currency - Currency (default: 'VND')
     * @returns {string} Formatted price string
     */
    formatPrice(price, currency = 'VND') {
        if (price === null || price === undefined) return 'Liên hệ';
        
        try {
            const numPrice = typeof price === 'string' ? parseFloat(price) : price;
            if (isNaN(numPrice)) return 'Liên hệ';
            
            if (currency === 'VND') {
                return new Intl.NumberFormat('vi-VN').format(numPrice) + 'đ';
            }
            
            return new Intl.NumberFormat('vi-VN', { 
                style: 'currency', 
                currency: currency 
            }).format(numPrice);
        } catch (error) {
            console.error('[Utils] Error formatting price:', error);
            return 'Liên hệ';
        }
    }
}
module.exports = new Utils();
