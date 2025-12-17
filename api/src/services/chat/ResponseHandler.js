const knex = require('../../database/knex');
const BranchIntentHandler = require('./handlers/BranchIntentHandler');
const BranchHandler = BranchIntentHandler.instance;
const ConversationService = require('./ConversationService');
const Utils = require('./Utils');
class ResponseHandler {
    async getSuggestions(intent, branchId) {
        const suggestions = [];
        switch (intent) {
            case 'greeting':
            case 'hello':
                suggestions.push(
                    { text: 'Đặt bàn', action: 'book_table', data: { branch_id: branchId } },
                    { text: 'Xem menu', action: 'view_menu', data: { branch_id: branchId } },
                    { text: 'Xem chi nhánh', action: 'view_branches', data: {} }
                );
                break;
            case 'book_table_partial':
            case 'ask_info':
            case 'ask_time_period':
                break;
            case 'confirm_booking':
            case 'book_table_confirmed':
                suggestions.push(
                    { text: 'Tạo đặt bàn ngay', action: 'confirm_booking', data: { branch_id: branchId } },
                    { text: 'Thêm ghi chú', action: 'add_note', data: {} },
                    { text: 'Thay đổi thời gian', action: 'modify_booking', data: {} }
                );
                break;
            case 'cancel_booking':
            case 'book_table_cancelled':
                suggestions.push(
                    { text: 'Đặt bàn mới', action: 'book_table', data: { branch_id: branchId } },
                    { text: 'Xem menu', action: 'view_menu', data: { branch_id: branchId } }
                );
                break;
            case 'search_food':
                suggestions.push(
                    { text: 'Tìm kiếm khác', action: 'search_food', data: { branch_id: branchId } },
                    { text: 'Xem toàn bộ menu', action: 'view_menu', data: { branch_id: branchId } },
                    { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: branchId } }
                );
                break;
            case 'view_menu_specific_branch':
                suggestions.push(
                    { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: branchId } },
                    { text: 'Đặt bàn', action: 'book_table', data: { branch_id: branchId } },
                    { text: 'Xem chi nhánh khác', action: 'view_branches', data: {} }
                );
                break;
            case 'order_food_specific_branch':
                suggestions.push(
                    { text: 'Xem giỏ hàng', action: 'view_cart', data: { branch_id: branchId } },
                    { text: 'Xem menu đầy đủ', action: 'view_menu', data: { branch_id: branchId } }
                );
                break;
            case 'book_table_specific_branch':
                break;
            case 'find_nearest_branch':
                suggestions.push(
                    { text: 'Đặt bàn tại chi nhánh này', action: 'book_table', data: {} },
                    { text: 'Xem menu', action: 'view_menu', data: {} },
                    { text: 'Xem tất cả chi nhánh', action: 'view_branches', data: {} }
                );
                break;
            case 'find_first_branch':
                suggestions.push(
                    { text: 'Đặt bàn tại chi nhánh này', action: 'book_table', data: {} },
                    { text: 'Xem menu', action: 'view_menu', data: {} },
                    { text: 'Xem tất cả chi nhánh', action: 'view_branches', data: {} }
                );
                break;
            case 'view_menu':
                if (!branchId) {
                    try {
                        const { suggestions: branchSuggestions } = await BranchHandler.getBranchesWithSuggestions('view_menu');
                        if (branchSuggestions.length > 0) {
                            suggestions.push(...branchSuggestions);
                        } else {
                            suggestions.push(
                                { text: 'Xem menu', action: 'view_menu', data: {} }
                            );
                        }
                    } catch (error) {
                        console.error('[ResponseHandler] Error getting branch suggestions:', error.message);
                        suggestions.push(
                            { text: 'Xem menu', action: 'view_menu', data: {} }
                        );
                    }
                } else {
                    try {
                        const categories = await knex('categories')
                            .select('id', 'name')
                            .where('status', 'active')
                            .orderBy('name', 'asc')
                            .limit(5); 
                        categories.forEach(cat => {
                            suggestions.push({
                                text: cat.name,
                                action: 'view_category',
                                data: { category: cat.name }
                            });
                        });
                    } catch (error) {
                        console.error('[ResponseHandler] Error getting categories:', error.message);
                        suggestions.push(
                            { text: 'Xem menu', action: 'view_menu', data: { branch_id: branchId } }
                        );
                    }
                }
                break;
            case 'order_food':
                suggestions.push(
                    { text: 'Xem giỏ hàng', action: 'view_cart', data: { branch_id: branchId } },
                    { text: 'Xem menu', action: 'view_menu', data: { branch_id: branchId } }
                );
                break;
            case 'book_table':
                break;
            case 'ask_branch':
                suggestions.push(
                    { text: 'Chi nhánh gần nhất', action: 'find_nearest_branch', data: {} },
                    { text: 'Chi nhánh đầu tiên', action: 'find_first_branch', data: {} },
                    { text: 'Xem tất cả chi nhánh', action: 'view_branches', data: {} }
                );
                break;
            case 'show_booking_info':
                suggestions.push(
                    { text: 'Xác nhận đặt bàn', action: 'confirm_booking', data: {} },
                    { text: 'Thay đổi thông tin', action: 'modify_booking', data: {} },
                    { text: 'Hủy đặt bàn', action: 'cancel_booking', data: {} }
                );
                break;
            case 'reservation_created':
                suggestions.push(
                    { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: branchId } },
                    { text: 'Xem menu đầy đủ', action: 'view_menu', data: { branch_id: branchId } },
                    { text: 'Gọi điện xác nhận', action: 'call_confirmation', data: {} }
                );
                break;
            case 'reservation_failed':
                suggestions.push(
                    { text: 'Thử lại', action: 'book_table', data: { branch_id: branchId } },
                    { text: 'Gọi đặt bàn', action: 'call_booking', data: {} },
                    { text: 'Chọn chi nhánh khác', action: 'select_branch', data: {} }
                );
                break;
            default:
                suggestions.push(
                    { text: 'Xem menu', action: 'view_menu', data: { branch_id: branchId } },
                    { text: 'Đặt bàn', action: 'book_table', data: { branch_id: branchId } },
                    { text: 'Chi nhánh gần tôi', action: 'find_nearest_branch', data: {} }
                );
        }
        return suggestions;
    }
    determineAction(intent, entities) {
        switch (intent) {
            case 'view_menu':
                return {
                    name: 'navigate_menu',
                    data: entities,
                };
            case 'confirm_booking':
            case 'book_table_confirmed':
                return {
                    name: 'confirm_booking',
                    data: entities,
                };
            case 'cancel_booking':
            case 'book_table_cancelled':
                return {
                    name: 'cancel_booking',
                    data: {},
                };
            case 'view_orders':
                return {
                    name: 'navigate_orders',
                    data: {},
                };
            case 'reservation_created':
                return {
                    name: 'show_reservation_details',
                    data: entities,
                };
            case 'order_food':
                return {
                    name: 'navigate_menu',
                    data: entities,
                };
            default:
                return null;
        }
    }
    getMessageType(intent) {
        const typeMap = {
            'view_menu': 'menu',
            'order_food': 'order',
            'book_table': 'reservation',
            'confirm_booking': 'reservation',
            'cancel_booking': 'reservation',
            'book_table_confirmed': 'reservation',
            'book_table_cancelled': 'reservation',
            'reservation_created': 'reservation',
            'reservation_failed': 'reservation',
            'show_booking_info': 'reservation',
            'view_orders': 'order',
        };
        return typeMap[intent] || 'text';
    }
    getDefaultSuggestions(branchId) {
        return [
            { text: 'Xem menu', action: 'view_menu', data: { branch_id: branchId } },
            { text: 'Tìm kiếm món', action: 'search_food', data: { branch_id: branchId } },
            { text: 'Đặt bàn', action: 'book_table', data: { branch_id: branchId } },
            { text: 'Chi nhánh gần tôi', action: 'find_branch', data: {} },
            { text: 'Đơn hàng của tôi', action: 'view_orders', data: {} },
        ];
    }

    /**
     * Build and save response - merged from ResponseComposer
     * @param {object} conversation - Conversation object
     * @param {object} context - Context object
     * @param {object} result - Result object with response, intent, entities, suggestions
     * @param {number} userId - User ID
     * @param {number} branchId - Branch ID
     * @returns {Promise<object>} Response object
     */
    async buildAndSave(conversation, context, result, userId, branchId) {
        const message = result.response || result.message || 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.';
        if (!message || message.trim() === '') {
            console.error('[ResponseHandler] Empty message in result:', result);
        }
        const intent = result.intent || 'general';
        const entities = result.entities || {};
        const resultSuggestions = result.suggestions;
        const suggestions = Object.prototype.hasOwnProperty.call(result, 'suggestions')
            ? resultSuggestions
            : await this.getSuggestions(intent, branchId);
        const action = this.determineAction(intent, entities);
        const cleanedMessage = Utils.cleanMessage(message);
        const response = {
            message: cleanedMessage,
            intent,
            entities,
            suggestions,
            action: action?.name,
            action_data: action?.data,
            type: this.getMessageType(intent),
            conversation_id: conversation.session_id,
        };
        await ConversationService.saveMessage(
            conversation.id,
            'bot',
            response.message,
            response.intent,
            response.entities,
            response.action,
            response.suggestions
        );
        const normalizedEntities = Utils.normalizeEntityFields(response.entities);
        const mergedEntities = {
            ...context.conversationContext?.lastEntities || {},
            ...normalizedEntities
        };
        const currentLastIntent = context.conversationContext?.lastIntent;
        const currentLastBranchId = context.conversationContext?.lastBranchId;
        const isBookingFlow = currentLastIntent === 'book_table' && currentLastBranchId;
        let finalIntent = response.intent;
        if (isBookingFlow && response.intent === 'ask_info') {
            finalIntent = 'book_table';
        }
        await ConversationService.updateConversationContext(conversation.id, {
            lastIntent: finalIntent,
            lastBranch: normalizedEntities?.branch_name || context.conversationContext?.lastBranch,
            lastBranchId: normalizedEntities?.branch_id || context.conversationContext?.lastBranchId,
            lastReservationId: normalizedEntities?.reservation_id || context.conversationContext?.lastReservationId,
            lastAction: response.action,
            lastEntities: mergedEntities,
            time_hour: normalizedEntities?.time_hour || context.conversationContext?.time_hour || null
        }, userId);
        return response;
    }
}
module.exports = new ResponseHandler();
