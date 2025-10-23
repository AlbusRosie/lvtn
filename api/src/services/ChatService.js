const axios = require('axios');
const knex = require('../database/knex');
const ReservationService = require('./ReservationService');
const CartService = require('./CartService');

class ChatService {
    constructor() {
        this.apiKey = process.env.OPENAI_API_KEY || '';
        this.apiUrl = 'https://api.openai.com/v1/chat/completions';
        this.model = 'gpt-4o-mini';
    }

    async processMessage({ message, userId, branchId, conversationId }) {
        try {
            const conversation = await this.getOrCreateConversation(userId, conversationId, branchId);
            
            const context = await this.buildContext(userId, branchId, conversation);
            
            await this.saveMessage(conversation.id, 'user', message);

            const quickIntent = this.detectIntent(message);
            if (quickIntent === 'confirm_booking' || quickIntent === 'cancel_booking') {
                const quickResult = await this.fallbackResponse(message, context);
                const quickAction = this.determineAction(quickResult.intent, quickResult.entities);
                const quickSuggestions = this.getSuggestions(quickResult.intent, branchId);

                const quickResponse = {
                    message: quickResult.response,
                    intent: quickResult.intent,
                    entities: quickResult.entities,
                    action: quickAction?.name,
                    action_data: quickAction?.data,
                    suggestions: quickSuggestions,
                    type: this.getMessageType(quickResult.intent),
                };

                await this.saveMessage(conversation.id, 'bot', quickResponse.message, quickResponse.intent, quickResponse.entities, quickResponse.action, quickResponse.suggestions);

                const normalizedQuickEntities = this.normalizeEntityFields(quickResponse.entities);
                const mergedEntities = {
                    ...context.conversationContext?.lastEntities || {},
                    ...normalizedQuickEntities
                };

                await this.updateConversationContext(conversation.id, {
                    lastIntent: quickResponse.intent,
                    lastBranch: normalizedQuickEntities?.branch_name || context.conversationContext.lastBranch,
                    lastAction: quickResponse.action,
                    lastEntities: mergedEntities,
                });

                return quickResponse;
            }
            
            if (this.apiKey) {
                try {
                    const aiResponse = await this.callAI(message, context);
                    const { intent, entities, response: aiMessage } = aiResponse;
                    const suggestions = this.getSuggestions(intent, branchId);
                    const action = this.determineAction(intent, entities);
                    
                    const response = {
                        message: aiMessage,
                        intent,
                        entities,
                        suggestions,
                        action: action?.name,
                        action_data: action?.data,
                        type: this.getMessageType(intent),
                    };
                    
                    await this.saveMessage(conversation.id, 'bot', response.message, response.intent, response.entities, response.action, response.suggestions);
                    
                    const normalizedAIEntities = this.normalizeEntityFields(response.entities);
                    const mergedEntities = {
                        ...context.conversationContext?.lastEntities || {},
                        ...normalizedAIEntities
                    };
                    
                    await this.updateConversationContext(conversation.id, {
                        lastIntent: response.intent,
                        lastBranch: normalizedAIEntities?.branch_name || context.conversationContext.lastBranch,
                        lastAction: response.action,
                        lastEntities: mergedEntities
                    });
                    
                    return response;
                } catch (aiError) {
                }
            }
            
            const fallbackResult = this.fallbackResponse(message, context);
            const action = this.determineAction(fallbackResult.intent, fallbackResult.entities);
            const suggestions = this.getSuggestions(fallbackResult.intent, branchId);
            
            const response = {
                message: fallbackResult.response,
                intent: fallbackResult.intent,
                entities: fallbackResult.entities,
                action: action?.name,
                action_data: action?.data,
                suggestions: suggestions,
                type: this.getMessageType(fallbackResult.intent),
            };
            
            await this.saveMessage(conversation.id, 'bot', response.message, response.intent, response.entities, response.action, response.suggestions);
            
            
            const mergedEntities = {
                ...context.conversationContext?.lastEntities || {},
                ...fallbackResult.entities
            };
            
            
            await this.updateConversationContext(conversation.id, {
                lastIntent: response.intent,
                lastBranch: fallbackResult.entities?.branch_name || context.conversationContext.lastBranch,
                lastAction: response.action,
                lastEntities: mergedEntities
            });
            
            return response;
            
        } catch (error) {
            throw new Error(`Failed to process message: ${error.message}`);
        }
    }

    async getOrCreateConversation(userId, conversationId, branchId) {
        try {
            let conversation = await knex('chat_conversations')
                .where({ user_id: userId, session_id: conversationId })
                .first();
            
            if (!conversation) {
                const [id] = await knex('chat_conversations').insert({
                    user_id: userId,
                    session_id: conversationId,
                    branch_id: branchId,
                    context_data: JSON.stringify({}),
                    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000)
                });
                
                conversation = await knex('chat_conversations')
                    .where({ id })
                    .first();
            } else {
                if (conversation.branch_id !== branchId) {
                    await knex('chat_conversations')
                        .where({ id: conversation.id })
                        .update({ 
                            branch_id: branchId,
                            updated_at: new Date()
                        });
                    conversation.branch_id = branchId;
                }
            }
            
            return conversation;
        } catch (error) {
            throw error;
        }
    }

    async saveMessage(conversationId, messageType, content, intent = null, entities = null, action = null, suggestions = null) {
        try {
            await knex('chat_messages').insert({
                conversation_id: conversationId,
                message_type: messageType,
                message_content: content,
                intent: intent,
                entities: entities ? JSON.stringify(entities) : null,
                action: action,
                suggestions: suggestions ? JSON.stringify(suggestions) : null
            });
        } catch (error) {
        }
    }

    async getConversationHistory(conversationId, limit = 10) {
        try {
            const messages = await knex('chat_messages')
                .where({ conversation_id: conversationId })
                .orderBy('created_at', 'desc')
                .limit(limit);
            
            return messages.reverse();
        } catch (error) {
            return [];
        }
    }

    async updateConversationContext(conversationId, contextData) {
        try {
            
            const existing = await knex('chat_conversations')
                .where({ id: conversationId })
                .first();
            let currentContext = {};
            if (existing && existing.context_data) {
                try { 
                    if (typeof existing.context_data === 'string') {
                        currentContext = JSON.parse(existing.context_data) || {}; 
                    } else if (typeof existing.context_data === 'object') {
                        currentContext = existing.context_data || {};
                        } else {
                            currentContext = {};
                        }
                } catch (e) { 
                    currentContext = {}; 
                }
            }


            const merged = this.deepMerge(currentContext, contextData);

            const contextString = typeof merged === 'string' ? merged : JSON.stringify(merged);
            
            await knex('chat_conversations')
                .where({ id: conversationId })
                .update({ 
                    context_data: contextString,
                    updated_at: new Date()
                });
            
        } catch (error) {
        }
    }

    deepMerge(target, source) {
        const result = { ...target };
        
        for (const key in source) {
            if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
                result[key] = this.deepMerge(result[key] || {}, source[key]);
            } else {
                result[key] = source[key];
            }
        }
        
        return result;
    }

    async buildContext(userId, branchId, conversation = null) {
        const context = {
            user: null,
            branch: null,
            cart: null,
            recentOrders: [],
            conversationHistory: [],
            conversationContext: {}
        };

        try {
            if (userId) {
                context.user = await knex('users')
                    .select('id', 'name', 'email')
                    .where('id', userId)
                    .first();
            }

            if (branchId) {
                context.branch = await knex('branches')
                    .select('id', 'name', 'address_detail', 'phone', 'opening_hours', 'close_hours')
                    .where('id', branchId)
                    .first();
            }

            if (userId && branchId) {
                context.cart = await knex('carts')
                    .where('user_id', userId)
                    .where('branch_id', branchId)
                    .where('status', 'pending')
                    .where('expires_at', '>', new Date())
                    .first();
            }

            if (userId) {
                context.recentOrders = await knex('orders')
                    .select('id', 'order_type', 'total', 'status', 'created_at')
                    .where('user_id', userId)
                    .orderBy('created_at', 'desc')
                    .limit(3);
            }

            if (conversation) {
                context.conversationHistory = await this.getConversationHistory(conversation.id, 10);

                if (conversation.context_data) {
                    try {
                        if (typeof conversation.context_data === 'string') {
                            context.conversationContext = JSON.parse(conversation.context_data);
                        } else if (typeof conversation.context_data === 'object') {
                            context.conversationContext = conversation.context_data;
                        } else {
                            context.conversationContext = {};
                        }
                    } catch (e) {
                        context.conversationContext = {};
                    }
                }

                let latestEntities = {};
                let latestIntent = null;
                
                for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                    const m = context.conversationHistory[i];
                    if (m.intent && (m.intent.includes('book_table') || m.intent.includes('find_nearest_branch') || m.intent.includes('reservation'))) {
                        try {
                            const ents = m.entities ? JSON.parse(m.entities) : {};
                            const normalizedEnts = this.normalizeEntityFields(ents);
                            latestEntities = { ...latestEntities, ...normalizedEnts };
                            if (!latestIntent) latestIntent = m.intent;
                        } catch (_) {}
                    }
                }
                
                if (Object.keys(context.conversationContext).length === 0 && Object.keys(latestEntities).length > 0) {
                    context.conversationContext.lastEntities = latestEntities;
                    context.conversationContext.lastIntent = latestIntent;
                } else if (Object.keys(latestEntities).length > 0) {
                    context.conversationContext.lastEntities = { 
                        ...context.conversationContext.lastEntities || {}, 
                        ...latestEntities 
                    };
                    if (latestIntent) {
                        context.conversationContext.lastIntent = latestIntent;
                    }
                }
            }

            return context;
        } catch (error) {
            return context;
        }
    }

    async callAI(userMessage, context) {
        if (!this.apiKey) {
            return this.fallbackResponse(userMessage, context);
        }

        try {
            const systemPrompt = this.buildSystemPrompt(context);
            
            const response = await axios.post(
                this.apiUrl,
                {
                    model: this.model,
                    messages: [
                        { role: 'system', content: systemPrompt },
                        { role: 'user', content: userMessage }
                    ],
                    temperature: 0.7,
                    max_tokens: 500,
                },
                {
                    headers: {
                        'Authorization': `Bearer ${this.apiKey}`,
                        'Content-Type': 'application/json',
                    },
                }
            );

            const aiMessage = response.data.choices[0]?.message?.content || 
                'Xin lỗi, tôi không hiểu. Bạn có thể nói rõ hơn được không?';

            const { intent, entities } = this.parseIntentFromAI(aiMessage, userMessage);

            return {
                response: aiMessage,
                intent,
                entities,
            };
        } catch (error) {
            return this.fallbackResponse(userMessage, context);
        }
    }

    buildSystemPrompt(context) {
        let prompt = `Bạn là trợ lý ảo thông minh của Beast Bite Restaurant, một chuỗi nhà hàng cao cấp. 

Nhiệm vụ của bạn:
1. Trả lời câu hỏi về menu, giá cả, chi nhánh
2. Hỗ trợ đặt món ăn với NLP thông minh
3. Hỗ trợ đặt bàn với xử lý ngôn ngữ tự nhiên
4. Giới thiệu món ăn và khuyến mãi
5. Giúp tìm chi nhánh phù hợp

QUAN TRỌNG về xử lý ngôn ngữ tự nhiên:
- Hiểu được tiếng Việt có dấu và không dấu"
- Hiểu được viết tắt và format tự nhiên"
- Hiểu được format thời gian: "17h", "5pm", "17:00", "17 giờ"
- Hiểu được số người: "4 nguoi", "4 người", "4 people", "4 pax"
- Hiểu được ngày: "ngay mai", "tomorrow", "hôm nay", "today"
- Hiểu được chi nhánh: "pearl", "riverside", "diamond", "thao dien", "landmark", "opera"

Khi user cung cấp thông tin không đầy đủ:
1. Xác nhận thông tin đã hiểu được
2. Hỏi thông tin còn thiếu một cách cụ thể
3. Đưa ra suggestions phù hợp với context

Ví dụ xử lý thông minh:
User: "4 nguoi 17h ngay mai"
Bot: "Tôi hiểu bạn muốn đặt bàn cho 4 người vào 17:00 ngày mai. Bạn muốn đặt tại chi nhánh nào? Tôi có thể gợi ý chi nhánh gần bạn nhất."

CÁC YÊU CẦU ĐẶC BIỆT:
- "chi nhánh gần nhất" → Trả lời về chi nhánh Pearl District (gần trung tâm nhất)
- "chi nhánh đầu tiên" → Trả lời về chi nhánh Pearl District (chi nhánh đầu tiên)
- "chi nhánh nào" → Liệt kê tất cả chi nhánh

Thông tin:`;

        if (context.branch) {
            prompt += `\n\nChi nhánh hiện tại: ${context.branch.name}
- Địa chỉ: ${context.branch.address_detail}
- Điện thoại: ${context.branch.phone}
- Giờ mở cửa: ${context.branch.opening_hours}h - ${context.branch.close_hours}h`;
        }

        if (context.user) {
            prompt += `\n\nKhách hàng: ${context.user.name}`;
        }

        if (context.cart) {
            prompt += `\n\nKhách hàng đang có giỏ hàng với order type: ${context.cart.order_type}`;
        }

        if (context.conversationHistory && context.conversationHistory.length > 0) {
            prompt += `\n\nLịch sử cuộc trò chuyện gần đây:`;
            context.conversationHistory.forEach(msg => {
                const role = msg.message_type === 'user' ? 'Khách hàng' : 'Bot';
                prompt += `\n${role}: ${msg.message_content}`;
                if (msg.intent) {
                    prompt += ` (Intent: ${msg.intent})`;
                }
            });
        }

        if (context.conversationContext && Object.keys(context.conversationContext).length > 0) {
            prompt += `\n\nContext từ cuộc trò chuyện:`;
            if (context.conversationContext.lastBranch) {
                prompt += `\n- Chi nhánh đang thảo luận: ${context.conversationContext.lastBranch}`;
            }
            if (context.conversationContext.lastIntent) {
                prompt += `\n- Intent gần nhất: ${context.conversationContext.lastIntent}`;
            }
        }

        prompt += `\n\nKhi trả lời:
- Luôn lịch sự và thân thiện
- Trả lời bằng tiếng Việt
- Ngắn gọn, súc tích nhưng đầy đủ thông tin
- Sử dụng emoji để làm cho tin nhắn thân thiện hơn
- Nếu khách muốn đặt món, hãy hỏi tên món, số lượng, chi nhánh
- Nếu khách muốn đặt bàn, hỏi số người, ngày giờ, chi nhánh
- Đưa ra gợi ý hữu ích và cụ thể
- Luôn kết thúc bằng câu hỏi để tiếp tục cuộc trò chuyện
- Khi được hỏi về chi nhánh gần nhất hoặc đầu tiên, hãy đưa ra thông tin cụ thể về Pearl District

QUAN TRỌNG: Ở cuối tin nhắn, thêm một dòng với format:
[INTENT: view_menu|order_food|book_table|view_orders|ask_info|find_nearest_branch|find_first_branch]
[ENTITIES: {json}]`;

        return prompt;
    }

    parseIntentFromAI(aiMessage, userMessage) {
        const intentMatch = aiMessage.match(/\[INTENT:\s*(\w+)\]/);
        const entitiesMatch = aiMessage.match(/\[ENTITIES:\s*({[^}]*})\]/);

        let intent = intentMatch ? intentMatch[1] : this.detectIntent(userMessage);
        let entities = {};

        if (entitiesMatch) {
            try {
                entities = JSON.parse(entitiesMatch[1]);
            } catch (e) {
            }
        } else {
            entities = this.extractEntities(userMessage);
        }

        return { intent, entities };
    }

    normalizeEntityFields(entities) {
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
     * Enhanced fallback rule-based response
     */
    async fallbackResponse(userMessage, context) {
        const intent = this.detectIntent(userMessage);
        const entities = this.extractEntities(userMessage);
        
        const lastEntities = context.conversationContext?.lastEntities || {};
        
        const normalizedEntities = this.normalizeEntityFields(entities);
        const normalizedLastEntities = this.normalizeEntityFields(lastEntities);
        
        const mergedEntities = {
            ...normalizedLastEntities,
            ...normalizedEntities
        };
        
        
        let response = '';

        const lower = userMessage.toLowerCase();
        const normalized = this.normalizeVietnamese(lower);
        const isAffirmative = /(ok|oke|okay|co|có|dong y|đồng ý|yes|y|chuẩn|chuan|dung roi|đúng rồi|xác nhận|xac nhan|confirm|được|duoc|tốt|tot|hay|ổn|on|chắc chắn|chac chan|tất nhiên|tat nhien)/i;
        const isNegative = /(khong|ko|k|không|no|huy|hủy|hủy|cancel)/i;

        const lastIntent = context.conversationContext?.lastIntent;

        if ((isAffirmative.test(lower) || isAffirmative.test(normalized)) &&
            (lastIntent === 'book_table' || lastIntent === 'book_table_partial' || lastIntent === 'book_table_confirmed' || lastIntent === 'find_nearest_branch' || lastIntent === 'find_first_branch')) {
            
            
            const people = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
            const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
            let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
            const branch = mergedEntities.branch_name || mergedEntities.branch || context.branch?.name || context.conversationContext?.lastBranch || 'chi nhánh đã chọn';
            
            if (date === 'ngày mai' || date === 'tomorrow') {
                const tomorrow = new Date();
                tomorrow.setDate(tomorrow.getDate() + 1);
                date = tomorrow.toISOString().split('T')[0];
            } else if (date === 'hôm nay' || date === 'today') {
                date = new Date().toISOString().split('T')[0];
            }
            

            const confirmedEntities = {
                people: people || null,
                time: time || null,
                date: date || null,
                branch_name: branch || null,
            };
            
            if (!date) {
                response = `Tôi hiểu bạn đồng ý đặt bàn cho ${people} người vào ${time} tại ${branch}, nhưng tôi cần biết ngày đặt bàn.\n\nBạn muốn đặt bàn:\n📅 Hôm nay\n📅 Ngày mai\n\nHoặc bạn có thể cho biết ngày cụ thể?`;
                return { 
                    response, 
                    intent: 'ask_info', 
                    entities: confirmedEntities
                };
            }
            
            try {
                const reservation = await this.createActualReservation(context.user?.id, confirmedEntities);
                
                const menuItems = await this.getMenuForOrdering(reservation.branch_id);
                
                response = `🎉 **ĐẶT BÀN THÀNH CÔNG!**\n\n📋 **Thông tin đặt bàn:**\n👥 Số người: ${people}\n📅 Ngày: ${date}\n🕐 Giờ: ${time}\n📍 Chi nhánh: ${branch}\n🪑 Bàn: ${reservation.table_number} (Tầng ${reservation.floor_id})\n\n🍽️ **Bạn có muốn đặt món ngay không?**\n\n**Menu có sẵn:**\n${menuItems.map(item => `• ${item.name} - ${item.price.toLocaleString()}đ`).join('\n')}\n\nChọn món để thêm vào giỏ hàng!`;
                
                return {
                    response,
                    intent: 'reservation_created',
                    entities: {
                        ...confirmedEntities,
                        reservation_id: reservation.id,
                        table_number: reservation.table_number,
                        floor_id: reservation.floor_id
                    },
                    suggestions: [
                        { text: '🍽️ Đặt món ngay', action: 'order_food', data: { branch_id: reservation.branch_id, reservation_id: reservation.id } },
                        { text: '📋 Xem menu đầy đủ', action: 'view_menu', data: { branch_id: reservation.branch_id } },
                        { text: '📞 Gọi điện xác nhận', action: 'call_confirmation', data: { reservation_id: reservation.id } }
                    ]
                };
            } catch (error) {
                response = `❌ **Không thể đặt bàn:** ${error.message}\n\nVui lòng thử lại với thời gian khác hoặc liên hệ trực tiếp với nhà hàng.`;
                return {
                    response,
                    intent: 'reservation_failed',
                    entities: confirmedEntities
                };
            }
        }

        if ((isNegative.test(lower) || isNegative.test(normalized)) &&
            (lastIntent === 'book_table' || lastIntent === 'book_table_partial' || lastIntent === 'book_table_confirmed')) {
            response = '❎ Đã hủy thao tác đặt bàn hiện tại. Bạn muốn tôi hỗ trợ điều gì tiếp theo?';
            return { response, intent: 'book_table_cancelled', entities: {} };
        }

        switch (intent) {
            case 'confirm_booking':
                
                const hasBookingInfo = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                const hasTimeInfo = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                const hasDateInfo = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                const hasBranchInfo = mergedEntities.branch_name || mergedEntities.branch;
                
                
                
                if ((lastIntent === 'book_table' || lastIntent === 'book_table_partial' || lastIntent === 'book_table_confirmed' || 
                    lastIntent === 'find_nearest_branch' || lastIntent === 'find_first_branch') && 
                    (hasBookingInfo && hasTimeInfo && hasBranchInfo)) {
                    
                    const people = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                    const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                    let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                    const branch = mergedEntities.branch_name || mergedEntities.branch || context.branch?.name || 'chi nhánh đã chọn';
                    
                    if (date === 'ngày mai' || date === 'tomorrow') {
                        const tomorrow = new Date();
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        date = tomorrow.toISOString().split('T')[0];
                    } else if (date === 'hôm nay' || date === 'today') {
                        date = new Date().toISOString().split('T')[0];
                    }
                    
                    
                    if (!date) {
                        response = `Tôi hiểu bạn đồng ý đặt bàn cho ${people} người vào ${time} tại ${branch}, nhưng tôi cần biết ngày đặt bàn.\n\nBạn muốn đặt bàn:\n📅 Hôm nay\n📅 Ngày mai\n\nHoặc bạn có thể cho biết ngày cụ thể?`;
                        return { 
                            response, 
                            intent: 'ask_info', 
                            entities: {
                                people: people,
                                time: time,
                                branch_name: branch,
                                date: null
                            }
                        };
                    }
                    
                    const confirmedEntities = {
                        people: people || null,
                        time: time || null,
                        date: date || null,
                        branch_name: branch || null,
                    };
                    
                    try {
                        const reservation = await this.createActualReservation(context.user?.id, confirmedEntities);
                        
                        const menuItems = await this.getMenuForOrdering(reservation.branch_id);
                        
                        response = `🎉 **ĐẶT BÀN THÀNH CÔNG!**\n\n📋 **Thông tin đặt bàn:**\n👥 Số người: ${people}\n📅 Ngày: ${date}\n🕐 Giờ: ${time}\n📍 Chi nhánh: ${branch}\n🪑 Bàn: ${reservation.table_number} (Tầng ${reservation.floor_id})\n\n🍽️ **Bạn có muốn đặt món ngay không?**\n\n**Menu có sẵn:**\n${menuItems.map(item => `• ${item.name} - ${item.price.toLocaleString()}đ`).join('\n')}\n\nChọn món để thêm vào giỏ hàng!`;
                        
                        return {
                            response,
                            intent: 'reservation_created',
                            entities: {
                                ...confirmedEntities,
                                reservation_id: reservation.id,
                                table_number: reservation.table_number,
                                floor_id: reservation.floor_id
                            },
                            suggestions: [
                                { text: '🍽️ Đặt món ngay', action: 'order_food', data: { branch_id: reservation.branch_id, reservation_id: reservation.id } },
                                { text: '📋 Xem menu đầy đủ', action: 'view_menu', data: { branch_id: reservation.branch_id } },
                                { text: '📞 Gọi điện xác nhận', action: 'call_confirmation', data: { reservation_id: reservation.id } }
                            ]
                        };
                    } catch (error) {
                        response = `❌ **Không thể đặt bàn:** ${error.message}\n\nVui lòng thử lại với thời gian khác hoặc liên hệ trực tiếp với nhà hàng.`;
                        return {
                            response,
                            intent: 'reservation_failed',
                            entities: confirmedEntities
                        };
                    }
                } else {
                    
                    const missingInfo = [];
                    if (!hasBookingInfo) missingInfo.push('👥 Số người');
                    if (!hasTimeInfo) missingInfo.push('🕐 Giờ');
                    if (!hasDateInfo) missingInfo.push('📅 Ngày');
                    if (!hasBranchInfo) missingInfo.push('📍 Chi nhánh');
                    
                    if (hasBookingInfo && hasTimeInfo && hasBranchInfo && !hasDateInfo) {
                        response = `Tôi hiểu bạn đồng ý đặt bàn cho ${mergedEntities.people} người vào ${mergedEntities.time} tại ${mergedEntities.branch_name}, nhưng tôi cần biết ngày đặt bàn.\n\nBạn muốn đặt bàn:\n📅 Hôm nay\n📅 Ngày mai\n\nHoặc bạn có thể cho biết ngày cụ thể?`;
                    } else {
                        response = `Tôi hiểu bạn đồng ý, nhưng tôi không có đủ thông tin đặt bàn để xác nhận. Còn thiếu:\n\n${missingInfo.join('\n')}\n\nBạn có thể cung cấp thông tin còn thiếu không?`;
                    }
                    
                    return { response, intent: 'ask_info', entities: mergedEntities };
                }

            case 'cancel_booking':
                response = '❎ Đã hủy thao tác đặt bàn hiện tại. Bạn muốn tôi hỗ trợ điều gì tiếp theo?';
                return { response, intent: 'book_table_cancelled', entities: {} };

            case 'view_menu_specific_branch':
                if (entities.branch_name) {
                    response = `Tuyệt vời! Đây là menu của chi nhánh **${entities.branch_name}**:\n\n🍽️ **Main Course**\n- Pan-Seared Fillet with Dual Sauces (520,000đ)\n- Thai Basil Minced Pork with Fried Egg (320,000đ)\n- Grilled Skewers with Herb Rice & Tomato Salsa (450,000đ)\n\n🍰 **Dessert**\n- Seasonal Fresh Fruits\n- House-made Pastries\n\n🥤 **Refreshments**\n- Premium Coffee & Tea\n- Fresh Juices & Mocktails\n\nBạn muốn đặt món nào từ menu này?`;
                } else if (context.conversationContext.lastBranch) {
                    response = `Tuyệt vời! Đây là menu của chi nhánh **${context.conversationContext.lastBranch}**:\n\n🍽️ **Main Course**\n- Pan-Seared Fillet with Dual Sauces (520,000đ)\n- Thai Basil Minced Pork with Fried Egg (320,000đ)\n- Grilled Skewers with Herb Rice & Tomato Salsa (450,000đ)\n\n🍰 **Dessert**\n- Seasonal Fresh Fruits\n- House-made Pastries\n\n🥤 **Refreshments**\n- Premium Coffee & Tea\n- Fresh Juices & Mocktails\n\nBạn muốn đặt món nào từ menu này?`;
                } else {
                    response = 'Tôi hiểu bạn muốn xem menu của chi nhánh cụ thể. Bạn có thể cho tôi biết tên chi nhánh không?';
                }
                break;

            case 'order_food_specific_branch':
                if (entities.branch_name) {
                    response = `Tuyệt vời! Bạn muốn đặt món tại chi nhánh **${entities.branch_name}**.\n\nVui lòng cho tôi biết:\n- Tên món ăn cụ thể\n- Số lượng\n- Tùy chọn đặc biệt (nếu có)\n\nTôi sẽ giúp bạn thêm vào giỏ hàng!`;
                } else {
                    response = 'Tôi hiểu bạn muốn đặt món tại chi nhánh cụ thể. Bạn có thể cho tôi biết tên chi nhánh không?';
                }
                break;

            case 'book_table_specific_branch':
                if (entities.branch_name) {
                    response = `Tuyệt vời! Bạn muốn đặt bàn tại chi nhánh **${entities.branch_name}**.\n\nXin cho biết:\n👥 Số người: ?\n📅 Ngày: ?\n🕐 Giờ: ?\n\nTôi sẽ giúp bạn tìm bàn phù hợp tại chi nhánh này!`;
                } else {
                    response = 'Tôi hiểu bạn muốn đặt bàn tại chi nhánh cụ thể. Bạn có thể cho tôi biết tên chi nhánh không?';
                }
                break;

            case 'find_nearest_branch':
                response = '📍 Chi nhánh gần nhất của Beast Bite:\n\n🏢 **Beast Bite - The Pearl District**\n📍 The Pearl District - HCMC\n📞 028-1111-0001\n🕐 7h - 22h\n\nĐây là chi nhánh đầu tiên và gần trung tâm nhất!\n\nBạn muốn đặt bàn tại đây không?';
                break;

            case 'find_first_branch':
                response = '🏢 Chi nhánh đầu tiên của Beast Bite:\n\n**Beast Bite - The Pearl District**\n📍 The Pearl District - HCMC\n📞 028-1111-0001\n🕐 7h - 22h\n\nĐây là chi nhánh flagship đầu tiên của chúng tôi!\n\nBạn muốn xem menu hoặc đặt bàn tại đây không?';
                break;

            case 'view_menu':
                response = context.branch
                    ? `Chúng tôi có menu đa dạng tại ${context.branch.name}. Bạn muốn xem món nào?\n\n🍽️ Main Course\n🍰 Dessert\n🥤 Refreshments\n🥗 Salad\n\nHoặc bạn có thể chọn danh mục cụ thể!`
                    : 'Chúng tôi có menu đa dạng với nhiều món ăn ngon. Bạn muốn xem chi nhánh nào để tôi có thể giới thiệu menu phù hợp?';
                break;

            case 'order_food':
                response = 'Tuyệt vời! Bạn muốn đặt món gì?\n\nVui lòng cho tôi biết:\n- Tên món ăn\n- Số lượng\n- Chi nhánh (nếu chưa chọn)\n\nTôi sẽ giúp bạn thêm vào giỏ hàng!';
                break;

            case 'book_table':
                const smartBookingResult = await this.handleSmartBooking(userMessage, context);
                
                const smartMergedEntities = {
                    ...context.conversationContext?.lastEntities || {},
                    ...smartBookingResult.entities
                };
                
                response = smartBookingResult.message;
                intent = smartBookingResult.intent;
                mergedEntities = smartMergedEntities;
                break;

            case 'view_orders':
                if (context.recentOrders && context.recentOrders.length > 0) {
                    response = `Bạn có ${context.recentOrders.length} đơn hàng gần đây.\n\nĐơn gần nhất:\n💰 Tổng: ${context.recentOrders[0].total}đ\n📊 Trạng thái: ${context.recentOrders[0].status}\n\nBạn muốn xem chi tiết đơn hàng nào?`;
                } else {
                    response = 'Bạn chưa có đơn hàng nào.\n\nHãy đặt món ngay để trải nghiệm những món ăn tuyệt vời của chúng tôi! 🍽️';
                }
                break;

            case 'ask_branch':
                response = 'Beast Bite có 6 chi nhánh tại TP.HCM:\n\n🏢 Pearl District\n🌊 Riverside\n💎 Diamond Plaza\n🌿 Thao Dien\n🏗️ Landmark 81\n🎭 Opera House\n\nBạn muốn xem thông tin chi nhánh nào?';
                break;

            case 'show_booking_info':
                if (mergedEntities.people && mergedEntities.time && mergedEntities.date && mergedEntities.branch_name) {
                    response = `📋 **Thông tin đặt bàn đã xác nhận:**\n\n👥 Số người: ${mergedEntities.people}\n📅 Ngày: ${mergedEntities.date}\n🕐 Giờ: ${mergedEntities.time}\n📍 Chi nhánh: ${mergedEntities.branch_name}\n\nBạn có cần thay đổi thông tin nào không?`;
                } else {
                    response = 'Tôi không tìm thấy thông tin đặt bàn đã xác nhận. Bạn có muốn đặt bàn mới không?';
                }
                break;

            default:
                response = 'Xin chào! Tôi là trợ lý ảo của Beast Bite.\n\nTôi có thể giúp bạn:\n🍽️ Xem menu và đặt món\n🪑 Đặt bàn tại nhà hàng\n📍 Tìm hiểu thông tin chi nhánh\n📦 Kiểm tra đơn hàng của bạn\n\nBạn cần tôi giúp gì?';
        }

        return { response, intent, entities: mergedEntities };
    }

    /**
     * Parse natural language input for booking and ordering
     */
    parseNaturalLanguage(message) {
        const lower = message.toLowerCase();
        const normalized = this.normalizeVietnamese(lower);
        
        const peopleMatch = lower.match(/(\d+)\s*(nguoi|người|people|person|pax)/i) || 
                           lower.match(/(\d+)(nguoi|người|people|person|pax)/i);
        const people = peopleMatch ? parseInt(peopleMatch[1]) : null;
        
        const timeMatch = lower.match(/(\d{1,2})[h:]\s*(\d{0,2})?\s*(am|pm)?/i) || 
                         lower.match(/(\d{1,2})\s*(giờ|gio|hour)/i) ||
                         lower.match(/(\d{1,2})\s*(pm|am)/i) ||
                         lower.match(/(\d{1,2})h(\d{0,2})/i);
        let time = null;
        if (timeMatch) {
            let hour = parseInt(timeMatch[1]);
            const minute = timeMatch[2] && !isNaN(parseInt(timeMatch[2])) ? parseInt(timeMatch[2]) : 0;
            const period = timeMatch[3];
            
            if (period === 'pm' && hour < 12) hour += 12;
            if (period === 'am' && hour === 12) hour = 0;
            
            time = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
        }
        
        const dateMatch = lower.match(/(ngay mai|tomorrow|ngày mai)/i) || 
                         normalized.match(/(ngay mai|tomorrow|ngay mai)/i);
        const todayMatch = lower.match(/(hom nay|hôm nay|today|ngay hom nay)/i) || 
                          normalized.match(/(hom nay|hom nay|today|ngay hom nay)/i);
        
        let date = null;
        if (dateMatch) {
            const tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            date = tomorrow.toISOString().split('T')[0];
        } else if (todayMatch) {
            date = new Date().toISOString().split('T')[0];
        }
        
        const branchPatterns = [
            { pattern: /pearl|pearl district|district/i, name: 'Pearl District' },
            { pattern: /riverside|saigon riverside/i, name: 'Saigon Riverside' },
            { pattern: /diamond|diamond plaza/i, name: 'Diamond Plaza' },
            { pattern: /thao dien|thao dien/i, name: 'Thao Dien' },
            { pattern: /landmark|landmark 81/i, name: 'Landmark 81' },
            { pattern: /opera|opera house/i, name: 'Opera House' },
        ];
        
        let branchName = null;
        for (const pattern of branchPatterns) {
            if (lower.match(pattern.pattern) || normalized.match(pattern.pattern)) {
                branchName = pattern.name;
                break;
            }
        }
        
        return {
            people,
            time,
            date,
            branch_name: branchName
        };
    }

    /**
     * Validate booking request
     */
    validateBookingRequest(entities) {
        const errors = [];
        
        const normalizedEntities = this.normalizeEntityFields(entities);
        
        if (!normalizedEntities.people || normalizedEntities.people < 1) {
            errors.push("Vui lòng cho biết số người (tối thiểu 1 người)");
        }
        
        if (!normalizedEntities.time) {
            errors.push("Vui lòng cho biết giờ đặt bàn");
        }
        
        if (!normalizedEntities.date) {
            errors.push("Vui lòng cho biết ngày đặt bàn");
        }
        
        return errors;
    }

    /**
     * Normalize Vietnamese text (remove accents for better matching)
     */
    normalizeVietnamese(text) {
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

    /**
     * Enhanced intent detection with Vietnamese support and specific requests
     */
    detectIntent(message) {
        const lower = message.toLowerCase();
        const normalized = this.normalizeVietnamese(lower);


        const isAffirmative = /^(ok|oke|okay|co|có|dong y|đồng ý|yes|y|chuẩn|chuan|dung roi|đúng rồi|đúng|dung|xác nhận|xac nhan|confirm|được|duoc|tốt|tot|hay|ổn|on|chắc chắn|chac chan|tất nhiên|tat nhien)$/i;
        const isNegative = /^(khong|ko|k|không|no|huy|hủy|hủy|cancel|thôi|toi|không được|khong duoc|không muốn|khong muon)$/i;


        if (isAffirmative.test(lower) || isAffirmative.test(normalized)) {
            return 'confirm_booking';
        }

        if (isNegative.test(lower) || isNegative.test(normalized)) {
            return 'cancel_booking';
        }

        const bookingPatterns = [
            /(đặt bàn|book|reservation|chỗ ngồi|đặt chỗ|muốn đặt bàn|tôi muốn đặt bàn|dat ban|book|reservation|cho ngoi|dat cho|muon dat ban|toi muon dat ban)/i,
            /(\d+)\s*(nguoi|người|people|person|pax).*(đặt bàn|book|reservation|dat ban|book|reservation)/i,
            /(đặt bàn|book|reservation|dat ban|book|reservation).*(\d+)\s*(nguoi|người|people|person|pax)/i,
            /(\d+)\s*(nguoi|người|people|person|pax).*(\d{1,2})[h:]\s*(\d{0,2})?\s*(am|pm)?/i,
            /(\d{1,2})[h:]\s*(\d{0,2})?\s*(am|pm)?.*(\d+)\s*(nguoi|người|people|person|pax)/i
        ];

        for (const pattern of bookingPatterns) {
            if (lower.match(pattern) || normalized.match(pattern)) {
                return 'book_table';
            }
        }

        if (lower.match(/(chi nhánh gần nhất|gần nhất|gần tôi|nearest|closest)/i) || 
            normalized.match(/(chi nhanh gan nhat|gan nhat|gan toi|nearest|closest)/i)) {
            return 'find_nearest_branch';
        }
        
        if (lower.match(/(chi nhánh đầu tiên|đầu tiên|đầu|first|first branch)/i) || 
            normalized.match(/(chi nhanh dau tien|dau tien|dau|first|first branch)/i)) {
            return 'find_first_branch';
        }
        
        if (lower.match(/(nhi nhanh dau tien|nhi nhanh dau|nhi nhanh)/i) ||
            normalized.match(/(nhi nhanh dau tien|nhi nhanh dau|nhi nhanh)/i)) {
            return 'find_first_branch';
        }
        
        if (lower.match(/(xem menu|menu|thực đơn).*(pearl|district|riverside|diamond|thao dien|landmark|opera)/i) || 
            normalized.match(/(xem menu|menu|thuc don).*(pearl|district|riverside|diamond|thao dien|landmark|opera)/i)) {
            return 'view_menu_specific_branch';
        }
        
        if (lower.match(/(đặt món|order|gọi món|mua|chọn món).*(pearl|district|riverside|diamond|thao dien|landmark|opera)/i) || 
            normalized.match(/(dat mon|order|goi mon|mua|chon mon).*(pearl|district|riverside|diamond|thao dien|landmark|opera)/i)) {
            return 'order_food_specific_branch';
        }
        
        if (lower.match(/(đặt bàn|book|reservation|chỗ ngồi|đặt chỗ).*(pearl|district|riverside|diamond|thao dien|landmark|opera)/i) || 
            normalized.match(/(dat ban|book|reservation|cho ngoi|dat cho).*(pearl|district|riverside|diamond|thao dien|landmark|opera)/i)) {
            return 'book_table_specific_branch';
        }
        
        if (lower.match(/(chi nhánh nào|chi nhánh|branch|nhà hàng)/i) || 
            normalized.match(/(chi nhanh nao|chi nhanh|branch|nha hang)/i)) {
            return 'ask_branch';
        }

        if (lower.match(/(menu|món|danh sách|có gì|xem món|thực đơn)/i) || 
            normalized.match(/(menu|mon|danh sach|co gi|xem mon|thuc don)/i)) {
            return 'view_menu';
        }
        
        if (lower.match(/(đặt món|order|gọi món|mua|chọn món)/i) || 
            normalized.match(/(dat mon|order|goi mon|mua|chon mon)/i)) {
            return 'order_food';
        }
        
        if (lower.match(/(đặt bàn|book|reservation|chỗ ngồi|đặt chỗ|muốn đặt bàn|tôi muốn đặt bàn)/i) || 
            normalized.match(/(dat ban|book|reservation|cho ngoi|dat cho|muon dat ban|toi muon dat ban)/i)) {
            return 'book_table';
        }
        
        const parsedData = this.parseNaturalLanguage(message);
        if (parsedData.people && (parsedData.time || parsedData.date)) {
            return 'book_table';
        }
        
        if (lower.match(/(đơn hàng|order|lịch sử|đơn của tôi)/i) || 
            normalized.match(/(don hang|order|lich su|don cua toi)/i)) {
            return 'view_orders';
        }

        if (lower.match(/(gửi lại|gui lai|gửi lại thông tin|gui lai thong tin|thông tin đặt bàn|thong tin dat ban|thông tin đơn|thong tin don)/i) || 
            normalized.match(/(gui lai|gui lai thong tin|thong tin dat ban|thong tin don)/i)) {
            return 'show_booking_info';
        }

        return 'ask_info';
    }

    /**
     * Normalize Vietnamese text by removing accents
     */
    normalizeVietnamese(text) {
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

    /**
     * Enhanced entity extraction with NLP parsing
     */
    extractEntities(message) {
        const lower = message.toLowerCase();
        const normalized = this.normalizeVietnamese(lower);
        const entities = {};

        const parsedData = this.parseNaturalLanguage(message);
        
        if (parsedData.people) {
            entities.people = parsedData.people;
            entities.number_of_people = parsedData.people;
            entities.guest_count = parsedData.people;
        }
        if (parsedData.time) {
            entities.time = parsedData.time;
            entities.reservation_time = parsedData.time;
            entities.time_slot = parsedData.time;
        }
        if (parsedData.date) {
            entities.date = parsedData.date;
            entities.reservation_date = parsedData.date;
            entities.booking_date = parsedData.date;
        }
        if (parsedData.branch_name) {
            entities.branch_name = parsedData.branch_name;
            entities.branch = parsedData.branch_name;
        }

        const branchPatterns = [
            { pattern: /pearl|pearl district/i, branchId: 5, branchName: 'Pearl District' },
            { pattern: /riverside|saigon riverside/i, branchId: 6, branchName: 'Saigon Riverside' },
            { pattern: /diamond|diamond plaza/i, branchId: 7, branchName: 'Diamond Plaza' },
            { pattern: /thao dien|thao dien/i, branchId: 8, branchName: 'Thao Dien' },
            { pattern: /landmark|landmark 81/i, branchId: 9, branchName: 'Landmark 81' },
            { pattern: /opera|opera house/i, branchId: 10, branchName: 'Opera House' },
        ];

        for (const branchPattern of branchPatterns) {
            if (lower.match(branchPattern.pattern) || normalized.match(branchPattern.pattern)) {
                entities.branch_id = branchPattern.branchId;
                entities.branch_name = branchPattern.branchName;
                entities.branch = branchPattern.branchName;
                break;
            }
        }

        if (!entities.people && !entities.quantity) {
            const numbers = message.match(/\d+/g);
            if (numbers) {
                const firstNumber = parseInt(numbers[0]);
                if (firstNumber >= 1 && firstNumber <= 20) {
                    entities.people = firstNumber;
                    entities.number_of_people = firstNumber;
                    entities.quantity = firstNumber;
                }
            }
        }


        return entities;
    }

    /**
     * Get nearest branch based on user location
     */
    async getNearestBranch(userLocation) {
        if (!userLocation) return null;
        
        try {
            const branches = await knex('branches')
                .where('status', 'active')
                .select('*');
            
            return branches.find(branch => branch.id === 5) || branches[0];
        } catch (error) {
            return null;
        }
    }

    /**
     * Calculate distance between two coordinates (Haversine formula)
     */
    calculateDistance(lat1, lon1, lat2, lon2) {
        const R = 6371;
        const dLat = this.deg2rad(lat2 - lat1);
        const dLon = this.deg2rad(lon2 - lon1);
        const a = 
            Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) * 
            Math.sin(dLon/2) * Math.sin(dLon/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const d = R * c;
        return d;
    }

    deg2rad(deg) {
        return deg * (Math.PI/180);
    }

    /**
     * Handle smart booking processing with enhanced context
     */
    async handleSmartBooking(userMessage, context) {
        const parsedData = this.parseNaturalLanguage(userMessage);
        
        const lastEntities = context.conversationContext?.lastEntities || {};
        const normalizedLastEntities = this.normalizeEntityFields(lastEntities);
        const normalizedParsedData = this.normalizeEntityFields(parsedData);
        
        const mergedData = {
            ...normalizedLastEntities,
            ...normalizedParsedData
        };
        
        
        const validation = this.validateBookingRequest(mergedData);
        
        if (validation.length === 0) {
            return {
                message: `Tuyệt vời! Tôi đã hiểu yêu cầu đặt bàn của bạn:\n\n👥 Số người: ${mergedData.people}\n📅 Ngày: ${mergedData.date}\n🕐 Giờ: ${mergedData.time}\n📍 Chi nhánh: ${mergedData.branch_name || 'Chưa chọn'}\n\nTôi sẽ giúp bạn tìm bàn phù hợp!`,
                intent: 'book_table_confirmed',
                entities: mergedData,
                suggestions: [
                    { text: '✅ Xác nhận đặt bàn', action: 'confirm_booking', data: mergedData },
                    { text: '🔄 Thay đổi thông tin', action: 'modify_booking', data: {} },
                    { text: '📍 Chọn chi nhánh khác', action: 'select_branch', data: {} }
                ]
            };
        } else if (mergedData.people || mergedData.time || mergedData.date) {
            const provided = [];
            if (mergedData.people) provided.push(`👥 Số người: ${mergedData.people}`);
            if (mergedData.time) provided.push(`🕐 Giờ: ${mergedData.time}`);
            if (mergedData.date) provided.push(`📅 Ngày: ${mergedData.date}`);
            if (mergedData.branch_name) provided.push(`📍 Chi nhánh: ${mergedData.branch_name}`);
            
            return {
                message: `Tôi đã hiểu một phần thông tin:\n\n${provided.join('\n')}\n\nCòn thiếu:\n${validation.join('\n')}\n\nBạn có thể cung cấp thông tin còn thiếu không?`,
                intent: 'book_table_partial',
                entities: mergedData,
                suggestions: [
                    { text: '📍 Chi nhánh gần tôi', action: 'find_nearest_branch', data: {} },
                    { text: '🕐 Giờ mở cửa', action: 'check_hours', data: {} },
                    { text: '📞 Gọi đặt bàn', action: 'call_booking', data: {} }
                ]
            };
        } else {
            return {
                message: context.branch
                    ? `Tuyệt vời! Bạn muốn đặt bàn tại ${context.branch.name}?\n\nXin cho biết:\n👥 Số người: ?\n📅 Ngày: ?\n🕐 Giờ: ?\n\nTôi sẽ giúp bạn tìm bàn phù hợp!`
                    : 'Bạn muốn đặt bàn tại chi nhánh nào?\n\nVui lòng cho biết:\n📍 Chi nhánh\n👥 Số người\n📅 Ngày giờ dự kiến\n\nTôi sẽ giúp bạn đặt bàn!',
                intent: 'book_table',
                entities: {},
                suggestions: [
                    { text: '📍 Chi nhánh gần tôi', action: 'find_nearest_branch', data: {} },
                    { text: '🕐 Giờ mở cửa', action: 'check_hours', data: {} },
                    { text: '📞 Gọi đặt bàn', action: 'call_booking', data: {} }
                ]
            };
        }
    }

    /**
     * Get suggestions based on intent
     */
    getSuggestions(intent, branchId) {
        const suggestions = [];

        switch (intent) {
            case 'confirm_booking':
            case 'book_table_confirmed':
                suggestions.push(
                    { text: '✅ Tạo đặt bàn ngay', action: 'confirm_booking', data: { branch_id: branchId } },
                    { text: '📝 Thêm ghi chú', action: 'add_note', data: {} },
                    { text: '🔄 Thay đổi thời gian', action: 'modify_booking', data: {} }
                );
                break;
            case 'cancel_booking':
            case 'book_table_cancelled':
                suggestions.push(
                    { text: '🪑 Đặt bàn mới', action: 'book_table', data: { branch_id: branchId } },
                    { text: '🍽️ Xem menu', action: 'view_menu', data: { branch_id: branchId } }
                );
                break;
            case 'view_menu_specific_branch':
                suggestions.push(
                    { text: '🛒 Đặt món ngay', action: 'order_food', data: { branch_id: branchId } },
                    { text: '🪑 Đặt bàn', action: 'book_table', data: { branch_id: branchId } },
                    { text: '📍 Xem chi nhánh khác', action: 'view_branches', data: {} }
                );
                break;

            case 'order_food_specific_branch':
                suggestions.push(
                    { text: '🛒 Xem giỏ hàng', action: 'view_cart', data: { branch_id: branchId } },
                    { text: '📋 Xem menu đầy đủ', action: 'view_menu', data: { branch_id: branchId } }
                );
                break;

            case 'book_table_specific_branch':
                suggestions.push(
                    { text: '🪑 Chọn bàn', action: 'select_table', data: { branch_id: branchId } },
                    { text: '📅 Chọn ngày giờ', action: 'select_datetime', data: {} }
                );
                break;

            case 'find_nearest_branch':
                suggestions.push(
                    { text: '🪑 Đặt bàn tại Pearl District', action: 'book_table', data: { branch_id: 5 } },
                    { text: '🍽️ Xem menu Pearl District', action: 'view_menu', data: { branch_id: 5 } },
                    { text: '📍 Xem tất cả chi nhánh', action: 'view_branches', data: {} }
                );
                break;

            case 'find_first_branch':
                suggestions.push(
                    { text: '🪑 Đặt bàn tại Pearl District', action: 'book_table', data: { branch_id: 5 } },
                    { text: '🍽️ Xem menu Pearl District', action: 'view_menu', data: { branch_id: 5 } },
                    { text: '📍 Xem tất cả chi nhánh', action: 'view_branches', data: {} }
                );
                break;

            case 'view_menu':
                suggestions.push(
                    { text: '🍽️ Main Course', action: 'view_category', data: { category: 'Main Course' } },
                    { text: '🍰 Dessert', action: 'view_category', data: { category: 'Dessert' } },
                    { text: '🥤 Refreshments', action: 'view_category', data: { category: 'Refreshments' } }
                );
                break;

            case 'order_food':
                suggestions.push(
                    { text: '🛒 Xem giỏ hàng', action: 'view_cart', data: { branch_id: branchId } },
                    { text: '📋 Xem menu', action: 'view_menu', data: { branch_id: branchId } }
                );
                break;

            case 'book_table':
                suggestions.push(
                    { text: '🪑 Chọn bàn', action: 'select_table', data: { branch_id: branchId } },
                    { text: '📅 Chọn ngày giờ', action: 'select_datetime', data: {} }
                );
                break;

            case 'ask_branch':
                suggestions.push(
                    { text: '📍 Chi nhánh gần nhất', action: 'find_nearest_branch', data: {} },
                    { text: '🏢 Chi nhánh đầu tiên', action: 'find_first_branch', data: {} },
                    { text: '🗺️ Xem tất cả chi nhánh', action: 'view_branches', data: {} }
                );
                break;

            case 'show_booking_info':
                suggestions.push(
                    { text: '✅ Xác nhận đặt bàn', action: 'confirm_booking', data: {} },
                    { text: '🔄 Thay đổi thông tin', action: 'modify_booking', data: {} },
                    { text: '❌ Hủy đặt bàn', action: 'cancel_booking', data: {} }
                );
                break;

            case 'reservation_created':
                suggestions.push(
                    { text: '🍽️ Đặt món ngay', action: 'order_food', data: { branch_id: branchId } },
                    { text: '📋 Xem menu đầy đủ', action: 'view_menu', data: { branch_id: branchId } },
                    { text: '📞 Gọi điện xác nhận', action: 'call_confirmation', data: {} }
                );
                break;

            case 'reservation_failed':
                suggestions.push(
                    { text: '🔄 Thử lại', action: 'book_table', data: { branch_id: branchId } },
                    { text: '📞 Gọi đặt bàn', action: 'call_booking', data: {} },
                    { text: '📍 Chọn chi nhánh khác', action: 'select_branch', data: {} }
                );
                break;

            default:
                suggestions.push(
                    { text: '🍽️ Xem menu', action: 'view_menu', data: { branch_id: branchId } },
                    { text: '🪑 Đặt bàn', action: 'book_table', data: { branch_id: branchId } },
                    { text: '📍 Chi nhánh gần tôi', action: 'find_nearest_branch', data: {} }
                );
        }

        return suggestions;
    }

    /**
     * Determine action to execute
     */
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

    /**
     * Get message type for frontend
     */
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

    /**
     * Create actual reservation in database
     */
    async createActualReservation(userId, entities) {
        try {
            const normalizedEntities = this.normalizeEntityFields(entities);
            
            let reservationDate = normalizedEntities.date;
            if (normalizedEntities.date === 'ngày mai' || normalizedEntities.date === 'tomorrow') {
                const tomorrow = new Date();
                tomorrow.setDate(tomorrow.getDate() + 1);
                reservationDate = tomorrow.toISOString().split('T')[0];
            } else if (normalizedEntities.date === 'hôm nay' || normalizedEntities.date === 'today') {
                reservationDate = new Date().toISOString().split('T')[0];
            }

            let branchId = normalizedEntities.branch_id;
            if (!branchId && normalizedEntities.branch_name) {
                const branch = await knex('branches')
                    .where('name', 'like', `%${normalizedEntities.branch_name}%`)
                    .first();
                if (branch) {
                    branchId = branch.id;
                }
            }

            if (!branchId) {
                throw new Error('Branch not found');
            }

            const reservationData = {
                user_id: userId,
                branch_id: branchId,
                reservation_date: reservationDate,
                reservation_time: normalizedEntities.time,
                guest_count: normalizedEntities.people,
                special_requests: null
            };

            const reservation = await ReservationService.createQuickReservation(reservationData);
            return reservation;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Get menu items for ordering after reservation
     */
    async getMenuForOrdering(branchId) {
        try {
            const products = await knex('products')
                .join('branch_products', 'products.id', 'branch_products.product_id')
                .join('categories', 'products.category_id', 'categories.id')
                .where('branch_products.branch_id', branchId)
                .where('branch_products.is_available', 1)
                .where('branch_products.status', 'available')
                .select(
                    'products.id',
                    'products.name',
                    'products.description',
                    'products.image',
                    'branch_products.price',
                    'categories.name as category_name'
                )
                .orderBy('categories.name', 'asc')
                .orderBy('products.name', 'asc');

            return products;
        } catch (error) {
            return [];
        }
    }

    /**
     * Get default suggestions
     */
    getDefaultSuggestions(branchId) {
        return [
            { text: '🍽️ Xem menu', action: 'view_menu', data: { branch_id: branchId } },
            { text: '🪑 Đặt bàn', action: 'book_table', data: { branch_id: branchId } },
            { text: '📍 Chi nhánh gần tôi', action: 'find_branch', data: {} },
            { text: '📦 Đơn hàng của tôi', action: 'view_orders', data: {} },
        ];
    }
}

module.exports = new ChatService();

