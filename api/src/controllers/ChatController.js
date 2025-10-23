const ChatService = require('../services/ChatService');
const ApiError = require('../api-error');
const { success } = require('../jsend');
const { v4: uuidv4 } = require('uuid');
const knex = require('../database/knex');

async function sendMessage(req, res, next) {
    try {
        const { message, branch_id, conversation_id } = req.body;
        const user_id = req.user?.id;

        if (!message || message.trim() === '') {
            throw new ApiError(400, 'Message is required');
        }

        const result = await ChatService.processMessage({
            message: message.trim(),
            userId: user_id,
            branchId: branch_id,
            conversationId: conversation_id,
        });

        const response = {
            id: uuidv4(),
            message: result.message,
            intent: result.intent,
            entities: result.entities,
            suggestions: result.suggestions,
            action: result.action,
            action_data: result.action_data,
            type: result.type,
            timestamp: new Date().toISOString(),
        };

        res.json(success(response, 'Message processed successfully'));
    } catch (error) {
        next(new ApiError(500, error.message || 'Failed to process message'));
    }
}

async function getChatHistory(req, res, next) {
    try {
        const { conversation_id } = req.query;
        const user_id = req.user?.id;

        if (!conversation_id) {
            throw new ApiError(400, 'conversation_id is required');
        }

        const history = await ChatService.getConversationHistory(conversation_id, 20);

        res.json(success(history, 'Chat history retrieved successfully'));
    } catch (error) {
        next(new ApiError(500, 'Failed to get chat history'));
    }
}

async function getSuggestions(req, res, next) {
    try {
        const { branch_id } = req.query;

        const suggestions = ChatService.getDefaultSuggestions(branch_id);

        res.json(success(suggestions, 'Suggestions retrieved successfully'));
    } catch (error) {
        next(new ApiError(500, 'Failed to get suggestions'));
    }
}

async function executeAction(req, res, next) {
    try {
        const { action, data } = req.body;
        const user_id = req.user?.id;

        if (!action) {
            throw new ApiError(400, 'Action is required');
        }

        let result = {
            action,
            success: true,
            message: `Action ${action} executed successfully`,
        };

        switch (action) {
            case 'confirm_booking':
                result.message = 'Booking confirmation processed';
                result.data = data;
                break;

            case 'order_food':
                result.message = 'Redirecting to menu';
                result.data = {
                    branch_id: data.branch_id,
                    reservation_id: data.reservation_id
                };
                break;

            case 'view_menu':
                result.message = 'Showing menu';
                result.data = {
                    branch_id: data.branch_id
                };
                break;

            case 'call_confirmation':
                try {
                    const branch = await knex('branches')
                        .where('id', data.reservation_id ? 
                            await knex('reservations').where('id', data.reservation_id).first().then(r => r?.branch_id) : 
                            data.branch_id)
                        .first();
                    
                    result.message = `Calling ${branch?.name || 'restaurant'} at ${branch?.phone || 'hotline'}`;
                    result.data = {
                        phone: branch?.phone,
                        branch_name: branch?.name
                    };
                } catch (error) {
                    result.message = 'Unable to get branch information';
                    result.data = { error: error.message };
                }
                break;

            case 'add_to_cart':
                if (data.product_id && data.branch_id) {
                    try {
                        const CartService = require('../services/CartService');
                        const cartItem = await CartService.addToCart(
                            user_id,
                            data.branch_id,
                            data.product_id,
                            data.quantity || 1,
                            'dine_in',
                            null,
                            data.selected_options || [],
                            data.special_instructions
                        );
                        
                        result.message = 'Product added to cart successfully';
                        result.data = cartItem;
                    } catch (error) {
                        result.message = `Failed to add product to cart: ${error.message}`;
                        result.success = false;
                        result.data = { error: error.message };
                    }
                } else {
                    result.message = 'Product ID and Branch ID are required';
                    result.success = false;
                    result.data = { error: 'Missing required parameters' };
                }
                break;

            case 'navigate_menu':
                result.message = 'Navigating to menu';
                result.data = data;
                break;

            case 'navigate_orders':
                result.message = 'Navigating to orders';
                result.data = data;
                break;

            case 'show_reservation_details':
                result.message = 'Showing reservation details';
                result.data = data;
                break;

            default:
                result.message = `Action ${action} executed successfully`;
                result.data = data;
        }

        res.json(success(result, 'Action executed successfully'));
    } catch (error) {
        next(new ApiError(500, error.message || 'Failed to execute action'));
    }
}

module.exports = {
    sendMessage,
    getChatHistory,
    getSuggestions,
    executeAction,
};

