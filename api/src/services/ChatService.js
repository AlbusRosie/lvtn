const ConversationService = require('./chat/ConversationService');
const MessageService = require('./chat/MessageService');
const ContextService = require('./chat/ContextService');
const IntentDetector = require('./chat/IntentDetector');
const EntityExtractor = require('./chat/EntityExtractor');
const AIService = require('./chat/AIService');
const ResponseHandler = require('./chat/ResponseHandler');
const IntentRouter = require('./chat/IntentRouter');
const Utils = require('./chat/Utils');
const ResponseComposer = require('./chat/ResponseComposer');
const LegacyFallbackService = require('./chat/LegacyFallbackService');
const AnalyticsService = require('./chat/AnalyticsService');
const { GREETING_MESSAGE } = require('./chat/constants/Messages');
const knex = require('../database/knex');
class ChatService {
    constructor() {
        this.intentRouter = new IntentRouter();
    }
    async processMessage({ message, userId, branchId, conversationId }) {
        const startTime = Date.now();
        let conversation = await ConversationService.getOrCreateConversation(userId, conversationId, branchId);
        if (conversation && conversation.id) {
            const knex = require('../database/knex');
            const freshConversation = await knex('chat_conversations')
                .where({ id: conversation.id, user_id: userId })
                .first();
            if (freshConversation) {
                conversation = freshConversation;
            }
        }
            const context = await ContextService.buildContext(userId, branchId, conversation);
            const isNewConversation = !context.conversationHistory || context.conversationHistory.length === 0;
            const lowerMessage = message.toLowerCase().trim();
            const isGreeting = lowerMessage === '' || 
                              /^(xin chào|hello|hi|chào|chao|hey)$/i.test(lowerMessage) ||
                              IntentDetector.detectIntent(message) === 'greeting';
            if (isNewConversation && isGreeting) {
                if (message.trim()) {
                    await MessageService.saveMessage(conversation.id, 'user', message);
                }
                return await this._buildAndSaveResponse(conversation, context, {
                response: GREETING_MESSAGE,
                    intent: 'greeting',
                    entities: {}
                }, userId, branchId);
            }
            await MessageService.saveMessage(conversation.id, 'user', message);
        const suggestionMatch = this._matchSuggestionFromHistory(message, context);
        if (suggestionMatch) {
            try {
                if (suggestionMatch.action === 'confirm_booking') {
                    return await this._buildAndSaveResponse(conversation, context, {
                        message: 'Đặt bàn đã được xử lý. Vui lòng kiểm tra kết quả ở trên.',
                        intent: 'book_table',
                        entities: suggestionMatch.entities || {},
                        suggestions: []
                    }, userId, branchId);
                }
                if (suggestionMatch.action === 'select_branch_for_booking') {
                    let branchId = suggestionMatch.entities?.branch_id;
                    let branchName = suggestionMatch.entities?.branch_name;
                    if (!branchId && suggestionMatch.action_data) {
                        branchId = suggestionMatch.action_data.branch_id;
                        branchName = suggestionMatch.action_data.branch_name || branchName;
                    }
                    if (!branchId && branchName) {
                        try {
                            const BranchHandler = require('./chat/BranchHandler');
                            const foundBranch = await BranchHandler.getBranchByName(branchName);
                            if (foundBranch) {
                                branchId = foundBranch.id;
                                branchName = foundBranch.name;
                            }
                        } catch (error) {
                        }
                    }
                    if (branchId) {
                        await ConversationService.updateConversationContext(conversation.id, {
                            lastBranchId: branchId,
                            lastBranch: branchName,
                            lastIntent: 'book_table',
                            lastEntities: {
                                ...context.conversationContext?.lastEntities || {},
                                branch_id: branchId,
                                branch_name: branchName
                            }
                        }, userId);
                        const reloadedConversation = await ConversationService.getOrCreateConversation(userId, conversation.session_id, branchId);
                        const updatedContext = await ContextService.buildContext(userId, branchId, reloadedConversation);
                        const updatedRouterPayload = this._buildRouterPayload({
                            intent: suggestionMatch.intent || IntentDetector.detectIntent(message),
                            message,
                            context: updatedContext,
                            entities: {
                                ...suggestionMatch.entities,
                                branch_id: branchId,
                                branch_name: branchName
                            },
                            aiResponse: null,
                            metadata: { isSuggestionAction: true },
                            branchId,
                            userId,
                        });
                        const updatedRoutedResponse = await this.intentRouter.route(updatedRouterPayload);
                        const updatedFinalPayload = updatedRoutedResponse || await LegacyFallbackService.fallbackResponse(message, updatedContext);
                        return await this._buildAndSaveResponse(reloadedConversation, updatedContext, updatedFinalPayload, userId, branchId);
                    }
                }
                const routerPayload = this._buildRouterPayload({
                    intent: suggestionMatch.intent || IntentDetector.detectIntent(message),
                    message,
                    context,
                    entities: suggestionMatch.entities || {},
                    aiResponse: null,
                    metadata: { isSuggestionAction: true },
                    branchId,
                    userId,
                });
                const routedResponse = await this.intentRouter.route(routerPayload);
                const finalPayload = routedResponse || await LegacyFallbackService.fallbackResponse(message, context);
                return await this._buildAndSaveResponse(conversation, context, finalPayload, userId, branchId);
            } catch (error) {
            }
        }
        try {
            const extractedEntities = await EntityExtractor.extractEntities(message);
                const normalizedExtractedEntities = Utils.normalizeEntityFields(extractedEntities);
                            const lastEntities = context.conversationContext?.lastEntities || {};
                const mergedEntities = {
            ...Utils.normalizeEntityFields(lastEntities),
            ...normalizedExtractedEntities
        };
        const lastBranchId = context.conversationContext?.lastBranchId;
        const lastIntent = context.conversationContext?.lastIntent;
        const isBookingFlow = !!(lastBranchId && (
            lastIntent === 'book_table' || 
            (lastIntent === 'ask_info' && lastBranchId)
        ));
        const hasPeople = mergedEntities.people || mergedEntities.guest_count || mergedEntities.number_of_people;
        const hasTime = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                const hasDate = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
        const isTodayReference = /(hôm nay|hom nay|chiều nay|chieu nay|sáng nay|sang nay|tối nay|toi nay|bây giờ|bay gio)/i.test(message);
        const hasBookingInfo = !!((hasPeople && hasTime) || 
                              (hasPeople && hasDate) || 
                              (hasTime && hasDate) ||
                              (hasPeople && hasTime && isTodayReference));
        if (isBookingFlow && hasBookingInfo) {
            const bookingPayload = this._buildRouterPayload({
                intent: 'book_table',
                message,
                context,
                entities: {
                        ...mergedEntities,
                    branch_id: lastBranchId,
                    branch_name: context.conversationContext?.lastBranch
                },
                aiResponse: null,
                metadata: { isBookingWithBranch: true },
                branchId: lastBranchId,
                userId,
            });
            const bookingResponse = await this.intentRouter.route(bookingPayload);
            if (bookingResponse) {
                return await this._buildAndSaveResponse(conversation, context, bookingResponse, userId, branchId);
            }
        }
        const lowerMessage = message.toLowerCase().trim();
        const isNearestBranchQuery = /(chi nhánh gần nhất|gần nhất|gần tôi|nearest|closest|chi nhanh gan nhat|gan nhat|gan toi)/i.test(lowerMessage);
        if (conversation && conversation.id) {
            const freshConversation = await knex('chat_conversations')
                .where({ id: conversation.id, user_id: userId })
                .first();
            if (freshConversation && freshConversation.context_data) {
                try {
                    const parsedContext = typeof freshConversation.context_data === 'string' 
                        ? JSON.parse(freshConversation.context_data) 
                        : freshConversation.context_data;
                    context.conversationContext = parsedContext || {};
                } catch (e) {
                }
            }
        }
        const hasUserLocation = context.conversationContext?.userLatitude && context.conversationContext?.userLongitude;
        const hasDeliveryAddress = context.conversationContext?.lastDeliveryAddress || context.conversationContext?.deliveryAddress || context.user?.address;
        if (isNearestBranchQuery) {
            const nearestBranchPayload = this._buildRouterPayload({
                intent: 'find_nearest_branch',
                message,
                context,
                entities: mergedEntities,
                aiResponse: null,
                metadata: { isNearestBranchQuery: true },
                branchId,
                userId,
            });
            const nearestBranchResponse = await this.intentRouter.route(nearestBranchPayload);
            if (nearestBranchResponse) {
                return await this._buildAndSaveResponse(conversation, context, nearestBranchResponse, userId, branchId);
            }
        }
        const metadata = {
            isSearchQuery: this._isSearchQuery(message),
        };
        const llmResult = await this._orchestrateLLMPipeline({
            message,
            context,
            metadata,
            mergedEntities,
        });
        const routerPayload = this._buildRouterPayload({
            intent: llmResult.intent,
            message,
            context,
            entities: llmResult.entities,
            aiResponse: llmResult,
            metadata,
            branchId,
            userId,
        });
            const routedResponse = await this.intentRouter.route(routerPayload);
            const finalPayload = routedResponse || llmResult || await LegacyFallbackService.fallbackResponse(message, context);
            const result = await this._buildAndSaveResponse(conversation, context, finalPayload, userId, branchId);
            const responseTime = Date.now() - startTime;
            try {
                await AnalyticsService.trackMessage(
                    userId || null,
                    conversation?.session_id || conversationId || null,
                    finalPayload?.intent || 'unknown',
                    responseTime,
                    true
                );
            } catch (error) {
            }
            return result;
        } catch (error) {
            const responseTime = Date.now() - startTime;
            try {
                await AnalyticsService.trackMessage(
                    userId || null,
                    conversation?.session_id || conversationId || null,
                    'error',
                    responseTime,
                    false
                );
                await AnalyticsService.trackEvent(
                    userId || null,
                    'message_processing_error',
                    {
                        error: error.message,
                        message: message.substring(0, 100),
                        conversationId: conversation?.session_id || conversationId
                    }
                );
            } catch (analyticsError) {
            }
            throw error;
        }
    }
    async _orchestrateLLMPipeline({ message, context, metadata, mergedEntities }) {
        const llmStartTime = Date.now();
        try {
            const aiResult = await AIService.callAI(message, context, (msg, ctx) => LegacyFallbackService.fallbackResponse(msg, ctx));
            const normalizedAiEntities = Utils.normalizeEntityFields(aiResult?.entities || {});
            const llmDuration = Date.now() - llmStartTime;
            if (aiResult?.tool_results && aiResult.tool_results.length > 0) {
                for (const toolResult of aiResult.tool_results) {
                    try {
                        await AnalyticsService.trackToolCall(
                            context.user?.id || null,
                            toolResult.tool,
                            toolResult.success || false,
                            llmDuration / aiResult.tool_results.length,
                            toolResult.error || null
                        );
                    } catch (error) {
                    }
                }
            }
            return {
                ...aiResult,
                intent: aiResult?.intent || IntentDetector.detectIntent(message),
                entities: {
                    ...mergedEntities,
                    ...normalizedAiEntities
                },
                metadata
            };
        } catch (error) {
            try {
                await AnalyticsService.trackEvent(
                    context.user?.id || null,
                    'llm_error',
                    {
                        error: error.message,
                        message: message.substring(0, 100),
                        intent: IntentDetector.detectIntent(message)
                    }
                );
            } catch (analyticsError) {
            }
            const fallback = await LegacyFallbackService.fallbackResponse(message, context);
            return {
                ...fallback,
                intent: fallback?.intent || IntentDetector.detectIntent(message),
                entities: {
                    ...mergedEntities,
                    ...Utils.normalizeEntityFields(fallback?.entities || {})
                },
                metadata,
                source: 'fallback'
            };
        }
    }
    _buildRouterPayload({ intent, message, context, entities, aiResponse, metadata, branchId, userId }) {
        return {
                    intent,
            message,
            context,
            entities,
            aiResponse,
            metadata,
            branchId,
            userId,
        };
    }
    async _buildAndSaveResponse(conversation, context, result, userId, branchId) {
        return ResponseComposer.buildAndSave(conversation, context, result, userId, branchId);
    }
    _matchSuggestionFromHistory(message, context) {
        const hasSuggestionFormat = (message.includes('📍') || message.includes('🕐') || message.includes('📞') || 
                                     message.includes('🍽️') || message.includes('🪑') || message.includes('🔍')) &&
                                    message.split('\n').length >= 2;
        if (!hasSuggestionFormat && !context.conversationHistory) {
            return null;
        }
        if (context.conversationHistory && context.conversationHistory.length > 0) {
            for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                const msg = context.conversationHistory[i];
                if (msg.message_type === 'bot' && msg.suggestions) {
                    try {
                        const suggestions = typeof msg.suggestions === 'string' 
                            ? JSON.parse(msg.suggestions) 
                            : msg.suggestions;
                        if (Array.isArray(suggestions)) {
                            const messageFirstLine = message.split('\n')[0].trim();
                            const matchedSuggestion = suggestions.find(s => {
                                if (!s.text) return false;
                                const suggestionText = s.text.split('\n')[0].trim();
                                const isMatch = suggestionText === messageFirstLine || 
                                       suggestionText === message.trim() ||
                                       message.trim().includes(suggestionText) ||
                                       suggestionText.includes(messageFirstLine);
                                return isMatch;
                            });
                            if (matchedSuggestion && matchedSuggestion.action) {
                                const intent = this._getIntentFromAction(matchedSuggestion.action);
                                const entities = matchedSuggestion.data || {};
                                if (matchedSuggestion.action === 'view_branch_info' || 
                                    matchedSuggestion.action === 'select_branch_for_booking' ||
                                    matchedSuggestion.action === 'view_menu') {
                                    if (matchedSuggestion.data?.branch_id) {
                                        entities.branch_id = matchedSuggestion.data.branch_id;
                                        entities.branch_name = matchedSuggestion.data.branch_name || entities.branch_name;
                                    }
                                    const branchNameMatch = message.match(/📍\s*(.+?)(?:\n|$)/);
                                    if (branchNameMatch && !entities.branch_name) {
                                        entities.branch_name = branchNameMatch[1].trim();
                                    }
                                }
                        return {
                                    intent,
                                    entities,
                                    action: matchedSuggestion.action,
                                    action_data: matchedSuggestion.data
                                };
                            }
                        }
                    } catch (error) {
                    }
                }
            }
        }
        return null;
    }
    _getIntentFromAction(action) {
        const actionToIntentMap = {
            'book_table': 'book_table',
            'view_menu': 'view_menu',
            'view_branches': 'view_branches',
            'view_branch_info': 'ask_branch',
            'select_branch_for_booking': 'book_table',
            'search_food': 'search_food',
            'order_food': 'order_food',
            'view_orders': 'view_orders',
        };
        return actionToIntentMap[action] || 'general';
    }
    _isSearchQuery(message) {
        const lowerMessage = message.toLowerCase();
        const vietnameseNormalized = Utils.normalizeVietnamese(lowerMessage);
        const locationPatterns = [
            /(ở|o|tại|tai|gần|gan|trong|nằm|nam)\s+(quận|quan|q|district|huyện|huyen|h|tỉnh|tinh|thành phố|thanh pho|tp|province)/i,
            /(ở|o|tại|tai|gần|gan|trong|nằm|nam)\s+[a-zA-Zàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ\s]{2,}/i,
            /(o|ở)\s*(tinh|tỉnh|thanh pho|thành phố)/i
        ];
        const hasLocationKeywords = locationPatterns.some(pattern => pattern.test(lowerMessage) || pattern.test(vietnameseNormalized));
        if (hasLocationKeywords) {
            return true;
        }
        const searchKeywords = [
            'có món', 'co mon', 'tìm món', 'tim mon', 'món nào', 'mon nao',
            'có món gì', 'co mon gi', 'có gì', 'co gi',
            'món ăn', 'mon an', 'thức ăn', 'thuc an',
            'có không', 'co khong', 'còn không', 'con khong',
            'chi nhánh ở', 'chi nhanh o', 'chi nhánh tại', 'chi nhanh tai',
            'nhánh ở', 'nhanh o', 'nhánh tại', 'nhanh tai',
            'nap o', 'nằm ở', 'nam o',
            'ở đâu', 'o dau', 'gần', 'gan', 'xa',
            'thế nào', 'the nao', 'như thế nào', 'nhu the nao',
            'bao nhiêu', 'bao nhieu', 'giá', 'gia',
            'làm sao', 'lam sao',
            'bò', 'bo', 'gà', 'ga', 'hải sản', 'hai san', 'cá', 'ca',
            'salad', 'burger', 'pizza', 'mì', 'mi', 'cơm', 'com',
            'nước', 'nuoc', 'trà', 'tra', 'cà phê', 'ca phe', 'coffee'
        ];
        const notSearchKeywords = [
            'đặt bàn', 'dat ban', 'book', 'reservation',
            'xem menu', 'xem thực đơn', 'xem chi nhánh',
            'view menu', 'show menu',
            'giờ mở cửa', 'gio mo cua', 'giờ làm việc', 'gio lam viec',
            'có những chi nhánh', 'co nhung chi nhanh',
            'danh sách chi nhánh', 'danh sach chi nhanh',
            'các chi nhánh', 'cac chi nhanh'
        ];
        if (notSearchKeywords.some(keyword => lowerMessage.includes(keyword) || vietnameseNormalized.includes(keyword))) {
            return false;
        }
        return searchKeywords.some(keyword => lowerMessage.includes(keyword) || vietnameseNormalized.includes(keyword));
    }
    async getAllUserConversations(userId) {
        return ConversationService.getAllUserConversations(userId);
    }
    async getConversationHistory(conversationId, limit = 10, userId = null) {
        const messages = await ConversationService.getConversationHistory(conversationId, limit, userId);
        return messages.map(msg => {
            const cleaned = {
                ...msg,
                message_content: msg.message_type === 'bot' ? Utils.cleanMessage(msg.message_content) : msg.message_content
            };
            if (msg.suggestions) {
                try {
                    cleaned.suggestions = typeof msg.suggestions === 'string' 
                        ? JSON.parse(msg.suggestions) 
                        : msg.suggestions;
                } catch {
                    cleaned.suggestions = null;
                }
            }
            if (msg.entities) {
                try {
                    cleaned.entities = typeof msg.entities === 'string' 
                        ? JSON.parse(msg.entities) 
                        : msg.entities;
                } catch {
                    cleaned.entities = null;
                }
            }
            return cleaned;
        });
    }
    getDefaultSuggestions(branchId) {
        return ResponseHandler.getDefaultSuggestions(branchId);
    }
    async getWelcomeMessage(userId, branchId, conversationId = null) {
        const conversation = await ConversationService.getOrCreateConversation(userId, conversationId, branchId);
        const context = await ContextService.buildContext(userId, branchId, conversation);
        const hasWelcomeMessage = context.conversationHistory && 
            context.conversationHistory.some(msg => msg.message_type === 'bot' && msg.intent === 'greeting');
        if (!hasWelcomeMessage) {
            const suggestions = await ResponseHandler.getSuggestions('greeting', branchId);
            await MessageService.saveMessage(
                conversation.id, 
                'bot', 
                GREETING_MESSAGE,
                'greeting', 
                {}, 
                null, 
                suggestions
            );
            return {
                message: GREETING_MESSAGE,
                intent: 'greeting',
                entities: {},
                suggestions,
                action: null,
                action_data: null,
                type: 'text',
                conversation_id: conversation.session_id,
            };
        }
        const welcomeMessage = context.conversationHistory.find(msg => 
            msg.message_type === 'bot' && msg.intent === 'greeting'
        );
        if (welcomeMessage) {
            const suggestions = welcomeMessage.suggestions ? 
                (typeof welcomeMessage.suggestions === 'string' ? 
                    JSON.parse(welcomeMessage.suggestions) : 
                    welcomeMessage.suggestions) : 
                await ResponseHandler.getSuggestions('greeting', branchId);
            return {
                message: welcomeMessage.message_content,
                intent: 'greeting',
                entities: welcomeMessage.entities ? 
                    (typeof welcomeMessage.entities === 'string' ? 
                        JSON.parse(welcomeMessage.entities) : 
                        welcomeMessage.entities) : {},
                suggestions,
                action: welcomeMessage.action,
                action_data: null,
                type: 'text',
                conversation_id: conversation.session_id,
            };
        }
        const suggestions = await ResponseHandler.getSuggestions('greeting', branchId);
        return {
            message: GREETING_MESSAGE,
            intent: 'greeting',
            entities: {},
            suggestions,
            action: null,
            action_data: null,
            type: 'text',
            conversation_id: conversation.session_id,
        };
    }
    async resetConversation(conversationId, userId, deleteMessages = true) {
        return ConversationService.resetConversation(conversationId, userId, deleteMessages);
    }
}
module.exports = new ChatService();
