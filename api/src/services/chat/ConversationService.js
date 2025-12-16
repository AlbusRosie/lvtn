const knex = require('../../database/knex');
const Utils = require('./Utils');
class ConversationService {
    async getOrCreateConversation(userId, conversationId, branchId) {
            let conversation = null;
            if (conversationId) {
                conversation = await knex('chat_conversations')
                    .where({ 
                        user_id: userId,
                        session_id: conversationId 
                    })
                    .first();
            }
            if (!conversation) {
                const [id] = await knex('chat_conversations').insert({
                    user_id: userId,
                    session_id: conversationId || `user_${userId}_${Date.now()}`,
                    branch_id: branchId,
                    context_data: JSON.stringify({}), 
                    status: 'active',
                    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000),
                    created_at: new Date()
                });
                conversation = await knex('chat_conversations')
                    .where({ id })
                    .first();
            } else {
                if (conversation.user_id !== userId) {
                    throw new Error('Unauthorized: Conversation does not belong to user');
                }
                const updates = {};
                if (conversation.branch_id !== branchId) {
                    updates.branch_id = branchId;
                }
                updates.expires_at = new Date(Date.now() + 24 * 60 * 60 * 1000);
                if (Object.keys(updates).length > 0) {
                    await knex('chat_conversations')
                        .where({ id: conversation.id, user_id: userId })
                        .update(updates);
                    conversation = await knex('chat_conversations')
                        .where({ id: conversation.id, user_id: userId })
                        .first();
                }
            }
            return conversation;
    }
    async getAllUserConversations(userId) {
            const conversations = await knex('chat_conversations')
                .where('user_id', userId)
                .orderBy('created_at', 'desc')
                .limit(50)
                .select(
                    'id',
                    'session_id',
                    'branch_id',
                    'created_at',
                    'context_data'
                );
            const conversationsWithLastMessage = await Promise.all(
                conversations.map(async (conv) => {
                    const lastMessage = await knex('chat_messages')
                        .join('chat_conversations', 'chat_messages.conversation_id', 'chat_conversations.id')
                        .where('chat_messages.conversation_id', conv.id)
                        .where('chat_conversations.user_id', userId)
                        .orderBy('chat_messages.created_at', 'desc')
                        .first()
                        .select('chat_messages.message_content', 'chat_messages.message_type', 'chat_messages.created_at');
                    return {
                        id: conv.id,
                        session_id: conv.session_id,
                        branch_id: conv.branch_id,
                        created_at: conv.created_at,
                        last_message: lastMessage ? {
                            content: lastMessage.message_type === 'bot' 
                                ? this.cleanMessage(lastMessage.message_content) 
                                : lastMessage.message_content,
                            is_user: lastMessage.message_type === 'user',
                            created_at: lastMessage.created_at
                        } : null
                    };
                })
            );
            return conversationsWithLastMessage;
    }
    async getConversationHistory(conversationId, limit = 10, userId = null) {
        try {
            if (!userId) {
                return [];
            }
            const conversation = await knex('chat_conversations')
                .where({ id: conversationId, user_id: userId })
                .first();
            if (!conversation) {
                return [];
            }
            const messages = await knex('chat_messages')
                .join('chat_conversations', 'chat_messages.conversation_id', 'chat_conversations.id')
                .where('chat_messages.conversation_id', conversationId)
                .where('chat_conversations.user_id', userId)
                .select('chat_messages.*')
                .orderBy('chat_messages.created_at', 'asc')
                .limit(limit);
            return messages;
        } catch {
            return [];
        }
    }
    async resetConversation(conversationId, userId, deleteMessages = true) {
            const conversation = await knex('chat_conversations')
                .where({ id: conversationId, user_id: userId })
                .first();
            if (!conversation) {
                throw new Error('Conversation not found or unauthorized');
            }
            await knex('chat_conversations')
                .where({ id: conversationId, user_id: userId })
                .update({
                    context_data: JSON.stringify({})
                });
            if (deleteMessages) {
                await knex('chat_messages')
                    .where('conversation_id', conversationId)
                    .delete();
            }
            return {
                success: true,
                conversationId: conversationId,
                messagesDeleted: deleteMessages
            };
    }
    async updateConversationContext(conversationId, contextData, userId = null) {
        try {
            const whereClause = { id: conversationId };
            if (userId) {
                whereClause.user_id = userId;
            }
            const existing = await knex('chat_conversations')
                .where(whereClause)
                .first();
            if (!existing) {
                return; 
            }
            let currentContext = {};
            if (existing.context_data) {
                try { 
                    if (typeof existing.context_data === 'string') {
                        currentContext = Utils.safeJsonParse(existing.context_data, 'context') || {};
                    } else if (typeof existing.context_data === 'object') {
                        currentContext = existing.context_data || {};
                    } else {
                        currentContext = {};
                    }
                } catch {
                    currentContext = {}; 
                }
            }
            const merged = this.deepMerge(currentContext, contextData);
            const contextString = typeof merged === 'string' ? merged : JSON.stringify(merged);
            await knex('chat_conversations')
                .where(whereClause)
                .update({ 
                    context_data: contextString
                });
        } catch {
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
    cleanMessage(message) {
        if (!message) return message;
        let cleaned = message.replace(/\[INTENT:\s*[^\]]+\]/gi, '');
        cleaned = cleaned.replace(/\[ENTITIES:\s*[^\]]+\]/gi, '');
        cleaned = cleaned.split('\n')
            .filter(line => line.trim() !== '')
            .join('\n')
            .trim();
        return cleaned;
    }
}
module.exports = new ConversationService();
