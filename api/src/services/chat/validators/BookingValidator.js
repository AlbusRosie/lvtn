const Utils = require('../Utils');
const REQUIRED_FIELDS = ['people', 'date', 'time', 'branch_name'];
class BookingValidator {
    static validate(rawEntities = {}) {
        const entities = Utils.normalizeEntityFields(rawEntities || {});
        const normalized = {
            people: entities.people || entities.number_of_people || entities.guest_count || null,
            date: entities.date || entities.reservation_date || entities.booking_date || null,
            time: entities.time || entities.reservation_time || entities.time_slot || null,
            branch_id: entities.branch_id || null,
            branch_name: entities.branch_name || entities.branch || null,
            district_id: entities.district_id || null,
        };
        const missing = REQUIRED_FIELDS.filter((field) => !normalized[field]);
        if (missing.length > 0) {
            return {
                status: 'ask_missing',
                missing,
                entities: normalized,
            };
        }
        return {
            status: 'ready',
            entities: normalized,
        };
    }
    static buildMissingInfoPrompt(missing = [], entities = {}) {
        const normalized = Utils.normalizeEntityFields(entities || {});
        const labels = {
            people: 'Số người',
            date: 'Ngày',
            time: 'Giờ',
            branch_name: 'Chi nhánh',
        };
        const valueLabels = {
            people: (val) => `Số người: ${val}`,
            date: (val) => `Ngày: ${val}`,
            time: (val) => `Giờ: ${val}`,
            branch_name: (val) => `Chi nhánh: ${val}`,
        };
        const provided = [];
        if (normalized.people || normalized.number_of_people || normalized.guest_count) {
            provided.push(valueLabels.people(normalized.people || normalized.number_of_people || normalized.guest_count));
        }
        if (normalized.date || normalized.reservation_date || normalized.booking_date) {
            provided.push(valueLabels.date(normalized.date || normalized.reservation_date || normalized.booking_date));
        }
        if (normalized.time || normalized.reservation_time || normalized.time_slot) {
            provided.push(valueLabels.time(normalized.time || normalized.reservation_time || normalized.time_slot));
        }
        if (normalized.branch_name || normalized.branch) {
            provided.push(valueLabels.branch_name(normalized.branch_name || normalized.branch));
        }
        const mapped = missing.map((field) => labels[field] || field);
        let message = 'Tôi cần thêm thông tin để đặt bàn:\n\n';
        if (provided.length > 0) {
            message += `Đã có:\n${provided.join('\n')}\n\n`;
        }
        if (mapped.length > 0) {
            message += `Thiếu: ${mapped.join(', ')}\n\nVui lòng bổ sung giúp tôi nhé.`;
        } else {
            message += 'Vui lòng bổ sung thông tin còn thiếu.';
        }
        return message;
    }
}
module.exports = BookingValidator;
