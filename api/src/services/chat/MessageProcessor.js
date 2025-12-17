const ConversationService = require('./ConversationService');
const ContextService = require('./ContextService');
const IntentDetector = require('./fallback/IntentDetector');
const EntityExtractor = require('./fallback/EntityExtractor');
const ResponseHandler = require('./ResponseHandler');
const IntentRouter = require('./IntentRouter');
const Utils = require('./Utils');
const { GREETING_MESSAGE } = require('./constants/Messages');
const LLMOrchestrator = require('./ai/LLMOrchestrator');
const ResponseNormalizer = require('./helpers/ResponseNormalizer');
const knex = require('../../database/knex');

class AnalyticsService {
    constructor() {
        this.metrics = {
            messageCount: 0,
            toolCallCount: 0,
            averageResponseTime: 0,
        };
        this._tableExists = null; 
        this._tableCheckPromise = null; 
    }
    async _checkTableExists() {
        if (this._tableExists !== null) {
            return this._tableExists;
        }
        if (this._tableCheckPromise) {
            return this._tableCheckPromise;
        }
        this._tableCheckPromise = (async () => {
            try {
                const exists = await knex.schema.hasTable('analytics_events');
                this._tableExists = exists;
                return exists;
            } catch {
                this._tableExists = false;
                return false;
            } finally {
                this._tableCheckPromise = null;
            }
        })();
        return this._tableCheckPromise;
    }
    async trackEvent(userId, eventType, properties = {}) {
        try {
            const tableExists = await this._checkTableExists();
            if (!tableExists) {
                return; 
            }
            await knex('analytics_events').insert({
                user_id: userId,
                event_type: eventType,
                properties: JSON.stringify(properties),
                created_at: new Date()
            });
        } catch (error) {
            if (error.message && error.message.includes("doesn't exist")) {
                this._tableExists = false; 
                return; 
            }
        }
    }
    async trackMessage(userId, conversationId, intent, responseTime, success = true) {
        this.metrics.messageCount++;
        this.metrics.averageResponseTime = 
            (this.metrics.averageResponseTime + responseTime) / this.metrics.messageCount;
        await this.trackEvent(userId, 'message_processed', {
            conversationId,
            intent,
            responseTime,
            success,
            timestamp: new Date().toISOString()
        });
    }
    async trackToolCall(userId, toolName, success, duration, error = null) {
        this.metrics.toolCallCount++;
        await this.trackEvent(userId, 'tool_executed', {
            toolName,
            success,
            duration,
            error: error?.message,
            timestamp: new Date().toISOString()
        });
    }
    async trackBooking(event, userId, branchId, reservationId = null, details = {}) {
        await this.trackEvent(userId, `booking_${event}`, {
            branchId,
            reservationId,
            ...details,
            timestamp: new Date().toISOString()
        });
    }
}

class MessageProcessor {
    constructor() {
        this.intentRouter = new IntentRouter();
        this.analytics = new AnalyticsService();
    }

    async processMessage({ message, userId, branchId, conversationId }) {
        const startTime = Date.now();
        let conversation = await ConversationService.getOrCreateConversation(userId, conversationId, branchId);
        if (conversation && conversation.id) {
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
                await ConversationService.saveMessage(conversation.id, 'user', message);
            }
            return await ResponseHandler.buildAndSave(conversation, context, {
                response: GREETING_MESSAGE,
                intent: 'greeting',
                entities: {}
            }, userId, branchId);
        }
        
        await ConversationService.saveMessage(conversation.id, 'user', message);
        
        try {
            // Extract and merge entities
            const extractedEntities = await EntityExtractor.extractEntities(message);
            const normalizedExtractedEntities = Utils.normalizeEntityFields(extractedEntities);
            const lastEntities = context.conversationContext?.lastEntities || {};
            const mergedEntities = {
                ...Utils.normalizeEntityFields(lastEntities),
                ...normalizedExtractedEntities
            };
            
            // Check booking flow
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
                    return await ResponseHandler.buildAndSave(conversation, context, bookingResponse, userId, branchId);
                }
            }
            
            // Check nearest branch query
            const isNearestBranchQuery = /(chi nhánh gần nhất|gần nhất|gần tôi|nearest|closest|chi nhanh gan nhat|gan nhat|gan toi)/i.test(lowerMessage);
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
                    return await ResponseHandler.buildAndSave(conversation, context, nearestBranchResponse, userId, branchId);
                }
            }
            
            // LLM Pipeline
            const metadata = {
                isSearchQuery: this._isSearchQuery(message),
            };
            const llmResult = await LLMOrchestrator.orchestrate({
                message,
                context,
                metadata,
                mergedEntities,
            });
            
            // Route intent
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
            
            let routedResponse = null;
            try {
                routedResponse = await this.intentRouter.route(routerPayload);
            } catch (routerError) {
                console.error('[MessageProcessor] Error in IntentRouter:', routerError);
                // Continue with fallback
            }
            
            // Normalize response
            const finalPayload = ResponseNormalizer.normalize(routedResponse || llmResult, message, context);
            
            // Save and return
            const result = await ResponseHandler.buildAndSave(conversation, context, finalPayload, userId, branchId);
            const responseTime = Date.now() - startTime;
            try {
                await this.analytics.trackMessage(
                    userId || null,
                    conversation?.session_id || conversationId || null,
                    finalPayload?.intent || 'unknown',
                    responseTime,
                    true
                );
            } catch {
                // Ignore analytics error
            }
            return result;
        } catch (error) {
            const responseTime = Date.now() - startTime;
            try {
                await this.analytics.trackMessage(
                    userId || null,
                    conversation?.session_id || conversationId || null,
                    'error',
                    responseTime,
                    false
                );
                await this.analytics.trackEvent(
                    userId || null,
                    'message_processing_error',
                    {
                        error: error.message,
                        message: message.substring(0, 100),
                        conversationId: conversation?.session_id || conversationId
                    }
                );
            } catch {
                // Ignore analytics error
            }
            throw error;
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
            await ConversationService.saveMessage(
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

const messageProcessor = new MessageProcessor();
module.exports = messageProcessor;
// Export AnalyticsService instance để các file khác dùng (backward compatibility)
module.exports.AnalyticsService = messageProcessor.analytics;

