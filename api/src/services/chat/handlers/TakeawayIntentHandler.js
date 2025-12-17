const BaseIntentHandler = require('./BaseIntentHandler');
const BranchIntentHandler = require('./BranchIntentHandler');
const BranchHandler = BranchIntentHandler.instance;
const Utils = require('../Utils');
const ConversationService = require('../ConversationService');

class TakeawayIntentHandler extends BaseIntentHandler {
    constructor() {
        super();
        this.intentSet = new Set([
            'order_takeaway',
            'order_delivery',
            'takeaway',
            'delivery',
        ]);
    }
    canHandle(intent, context = {}) {
        if (intent === 'find_nearest_branch' || intent === 'find_first_branch' || intent === 'search_branches_by_location') {
            return false;
        }
        if (this.intentSet.has(intent)) {
            return true;
        }
        const lastIntent = context.conversationContext?.lastIntent;
        if (lastIntent && this.intentSet.has(lastIntent) && (!intent || intent === 'unknown' || intent === 'general')) {
            return true;
        }
        const message = context.message || '';
        const lowerMessage = message.toLowerCase();
        const takeawayKeywords = ['dat don', 'đặt đơn', 'takeaway', 'mang ve', 'mang về', 'giao hang', 'giao hàng', 'delivery'];
        if (takeawayKeywords.some(keyword => lowerMessage.includes(keyword))) {
            return true;
        }
        return false;
    }
    async handle({ intent, message, context, entities, userId, aiResponse }) {
        const isDelivery = intent === 'order_delivery' || 
                          intent === 'delivery' ||
                          (message && /giao hàng|giao hang|delivery/i.test(message));
        
        // Xử lý delivery address - extract thành method để tránh duplicate
        if (isDelivery) {
            const deliveryResponse = await this._handleDeliveryAddress(message, context, entities, userId);
            if (deliveryResponse) {
                return deliveryResponse;
            }
        }
        if (aiResponse && aiResponse.tool_results && aiResponse.tool_results.length > 0) {
            const normalized = Utils.normalizeEntityFields(entities || {});
            let suggestions = aiResponse.suggestions || [];
            const hasGetAllBranches = aiResponse.tool_results.some(r => r.tool === 'get_all_branches' && r.success);
            if (hasGetAllBranches) {
                try {
                    const { suggestions: branchSuggestions } = await BranchHandler.getBranchesWithSuggestions(
                        isDelivery ? 'order_delivery' : 'order_takeaway',
                        {
                            delivery_address: isDelivery ? (context.conversationContext?.lastDeliveryAddress || context.user?.address) : null
                        }
                    );
                    if (branchSuggestions.length > 0) {
                        suggestions = branchSuggestions;
                    }
                } catch (error) {
                    console.error('[TakeawayIntentHandler] Error getting branches:', error.message);
                }
            }
            const responseMessage = isDelivery 
                ? 'Bạn muốn đặt món giao hàng từ chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:'
                : 'Bạn muốn đặt món mang về từ chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:';
            return this.buildResponse({
                intent: aiResponse.intent || intent || (isDelivery ? 'order_delivery' : 'order_takeaway'),
                response: aiResponse.response || responseMessage,
                entities: normalized,
                suggestions: suggestions,
            });
        }
        const { branches: allBranches, suggestions: branchSuggestions } = await BranchHandler.getBranchesWithSuggestions(
            isDelivery ? 'order_delivery' : 'order_takeaway',
            {
                delivery_address: isDelivery ? (context.conversationContext?.lastDeliveryAddress || context.user?.address) : null
            }
        );
        if (allBranches.length === 0) {
            return this.buildResponse({
                intent: isDelivery ? 'order_delivery' : 'order_takeaway',
                response: 'Hiện tại không có chi nhánh nào. Vui lòng liên hệ trực tiếp với chúng tôi.',
                entities: entities || {},
                suggestions: [],
            });
        }
        const responseMessage = isDelivery 
            ? 'Bạn muốn đặt món giao hàng từ chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:'
            : 'Bạn muốn đặt món mang về từ chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:';
        return this.buildResponse({
            intent: isDelivery ? 'order_delivery' : 'order_takeaway',
            response: responseMessage,
            entities: entities || {},
            suggestions: branchSuggestions.length > 0 ? branchSuggestions : [],
        });
    }

    /**
     * Xử lý delivery address - extract method để tránh duplicate code
     * @private
     */
    async _handleDeliveryAddress(message, context, entities, userId) {
        const lastIntent = context.conversationContext?.lastIntent;
        const isEnteringAddress = lastIntent === 'order_delivery' && 
                                 (context.conversationContext?.waitingForAddress || false);
        
        // Nếu user đang nhập địa chỉ
        if (isEnteringAddress && message && message.trim().length > 10) {
            const conversationId = context.conversationId;
            if (conversationId) {
                await ConversationService.updateConversationContext(conversationId, {
                    lastDeliveryAddress: message.trim(),
                    deliveryAddress: message.trim(),
                    waitingForAddress: false,
                    lastIntent: 'order_delivery'
                }, userId);
            }
            return this.buildResponse({
                intent: 'order_delivery',
                response: `Địa chỉ giao hàng bạn vừa nhập:\n\n**${message.trim()}**\n\nBạn có muốn sử dụng địa chỉ này không?`,
                entities: { ...entities, order_type: 'delivery', delivery_address: message.trim() },
                suggestions: [
                    { text: 'Xác nhận địa chỉ này', action: 'confirm_delivery_address', data: { delivery_address: message.trim() } },
                    { text: 'Đổi địa chỉ khác', action: 'change_delivery_address', data: {} }
                ],
            });
        }
        
        // Kiểm tra địa chỉ đã có
        const userAddress = context.user?.address;
        const savedAddress = context.conversationContext?.deliveryAddress || context.conversationContext?.lastDeliveryAddress;
        const deliveryAddress = savedAddress || userAddress;
        
        // Nếu chưa có địa chỉ, yêu cầu nhập
        if (!deliveryAddress) {
            const conversationId = context.conversationId;
            if (conversationId) {
                await ConversationService.updateConversationContext(conversationId, {
                    waitingForAddress: true,
                    lastIntent: 'order_delivery'
                }, userId);
            }
            return this.buildResponse({
                intent: 'order_delivery',
                response: 'Để đặt món giao hàng, tôi cần biết địa chỉ giao hàng của bạn.\n\nVui lòng cho tôi biết địa chỉ bạn muốn nhận hàng (số nhà, tên đường, phường/xã, quận/huyện, thành phố).',
                entities: { ...entities, order_type: 'delivery' },
                suggestions: [
                    { text: 'Sử dụng địa chỉ đã lưu', action: 'use_saved_address', data: {} },
                    { text: 'Nhập địa chỉ mới', action: 'enter_delivery_address', data: {} }
                ],
            });
        }
        
        // Nếu có địa chỉ nhưng chưa xác nhận
        const lastDeliveryAddress = context.conversationContext?.lastDeliveryAddress;
        if (!lastDeliveryAddress || lastDeliveryAddress !== deliveryAddress) {
            return this.buildResponse({
                intent: 'order_delivery',
                response: `Địa chỉ giao hàng của bạn:\n\n**${deliveryAddress}**\n\nBạn có muốn sử dụng địa chỉ này không?`,
                entities: { ...entities, order_type: 'delivery', delivery_address: deliveryAddress },
                suggestions: [
                    { text: 'Xác nhận địa chỉ này', action: 'confirm_delivery_address', data: { delivery_address: deliveryAddress } },
                    { text: 'Đổi địa chỉ khác', action: 'change_delivery_address', data: {} }
                ],
            });
        }
        
        // Đã có địa chỉ và đã xác nhận, return null để tiếp tục flow
        return null;
    }
}
module.exports = TakeawayIntentHandler;
