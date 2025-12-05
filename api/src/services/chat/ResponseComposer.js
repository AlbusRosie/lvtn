const MessageService = require('./MessageService');
const ResponseHandler = require('./ResponseHandler');
const ConversationService = require('./ConversationService');
const Utils = require('./Utils');
class ResponseComposer {
    async buildAndSave(conversation, context, result, userId, branchId) {
        const message = result.response || result.message;
        const intent = result.intent;
        const entities = result.entities || {};
        const resultSuggestions = result.suggestions;
        const suggestions = Object.prototype.hasOwnProperty.call(result, 'suggestions')
            ? resultSuggestions
            : await ResponseHandler.getSuggestions(intent, branchId);
        const action = ResponseHandler.determineAction(intent, entities);
        const cleanedMessage = Utils.cleanMessage(message);
        const response = {
            message: cleanedMessage,
            intent,
            entities,
            suggestions,
            action: action?.name,
            action_data: action?.data,
            type: ResponseHandler.getMessageType(intent),
            conversation_id: conversation.session_id,
        };
        await MessageService.saveMessage(
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
module.exports = new ResponseComposer();
