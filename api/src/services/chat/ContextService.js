const ConversationService = require('./ConversationService');
const Utils = require('./Utils');
const UserService = require('../UserService');
const BranchService = require('../BranchService');
const CartService = require('../CartService');
const OrderService = require('../OrderService');
class ContextService {
    async buildContext(userId, branchId, conversation = null) {
        const context = {
            user: null,
            branch: null,
            cart: null,
            recentOrders: [],
            conversationHistory: [],
            conversationContext: {},
            branchesCache: [], 
            conversationId: conversation?.session_id || null 
        };
        try {
            try {
                const allBranches = await BranchService.getActiveBranches();
                context.branchesCache = allBranches.map(b => ({
                    id: b.id,
                    name: b.name,
                    address_detail: b.address_detail,
                    phone: b.phone,
                    email: b.email,
                    district_id: b.district_id,
                    province_id: b.province_id,
                    opening_hours: b.opening_hours,
                    close_hours: b.close_hours,
                    status: b.status,
                    name_normalized: Utils.normalizeVietnamese(b.name?.toLowerCase() || ''),
                    address_normalized: Utils.normalizeVietnamese(b.address_detail?.toLowerCase() || '')
                }));
            } catch (error) {
                console.error('[ContextService] Error building branches cache:', error.message);
                context.branchesCache = [];
            }
            if (userId) {
                const user = await UserService.getUserById(userId);
                if (user) {
                    context.user = {
                        id: user.id,
                        name: user.name,
                        email: user.email,
                        address: user.address || null, 
                        phone: user.phone || null
                    };
                }
            }
            if (branchId) {
                const branch = await BranchService.getBranchById(branchId);
                if (branch) {
                    context.branch = {
                        id: branch.id,
                        name: branch.name,
                        address_detail: branch.address_detail,
                        phone: branch.phone,
                        opening_hours: branch.opening_hours,
                        close_hours: branch.close_hours
                    };
                }
            }
            if (userId && branchId) {
                context.cart = await CartService.findPendingCart(userId, branchId);
            }
            if (userId) {
                const orders = await OrderService.getUserOrders(userId);
                context.recentOrders = orders.slice(0, 3).map(order => ({
                    id: order.id,
                    order_type: order.order_type,
                    total: order.total,
                    status: order.status,
                    created_at: order.created_at
                }));
            }
            if (conversation) {
                context.conversationHistory = await ConversationService.getConversationHistory(conversation.id, 50, userId);
                if (conversation.context_data) {
                    try {
                        if (typeof conversation.context_data === 'string') {
                            const parsedContext = Utils.safeJsonParse(conversation.context_data, 'context') || {};
                            context.conversationContext = parsedContext && Object.keys(parsedContext).length > 0 ? parsedContext : {};
                        } else if (typeof conversation.context_data === 'object') {
                            context.conversationContext = conversation.context_data && Object.keys(conversation.context_data).length > 0 ? conversation.context_data : {};
                        } else {
                            context.conversationContext = {};
                        }
                    } catch {
                        context.conversationContext = {};
                    }
                } else {
                    context.conversationContext = {};
                }
                let latestEntities = {};
                let latestIntent = null;
                for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                    const m = context.conversationHistory[i];
                    if (m.intent && (m.intent.includes('book_table') || m.intent.includes('find_nearest_branch') || m.intent.includes('reservation'))) {
                        try {
                            const ents = m.entities ? Utils.safeJsonParse(m.entities, 'entities') || {} : {};
                            const normalizedEnts = Utils.normalizeEntityFields(ents);
                            latestEntities = { ...latestEntities, ...normalizedEnts };
                            if (!latestIntent) latestIntent = m.intent;
                        } catch (error) {
                            console.error('[ContextService] Error parsing entities:', error.message);
                        }
                    }
                }
                if (Object.keys(context.conversationContext).length === 0 && Object.keys(latestEntities).length > 0) {
                    context.conversationContext.lastEntities = latestEntities;
                    context.conversationContext.lastIntent = latestIntent;
                } else if (Object.keys(latestEntities).length > 0 && context.conversationContext.lastEntities) {
                    context.conversationContext.lastEntities = { 
                        ...context.conversationContext.lastEntities, 
                        ...latestEntities 
                    };
                    if (latestIntent) {
                        context.conversationContext.lastIntent = latestIntent;
                    }
                }
            }
            return context;
        } catch (error) {
            console.error('[ContextService] Error building context:', error.message);
            return context;
        }
    }
}
module.exports = new ContextService();
