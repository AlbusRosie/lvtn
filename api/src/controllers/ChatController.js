const ChatService = require('../services/ChatService');
const ApiError = require('../api-error');
const { success } = require('../jsend');
const { v4: uuidv4 } = require('uuid');
const knex = require('../database/knex');
const Utils = require('../services/chat/Utils');
const AnalyticsService = require('../services/chat/AnalyticsService');
async function sendMessage(req, res, next) {
    try {
        const { message, branch_id, conversation_id } = req.body;
        const user_id = req.user?.id;
        if (!message || typeof message !== 'string') {
            throw new ApiError(400, 'Message is required and must be a string');
        }
        const sanitizedMessage = Utils.validateChatInput(message);
        if (conversation_id && (typeof conversation_id !== 'string' || conversation_id.length > 100)) {
            throw new ApiError(400, 'Invalid conversation_id format');
        }
        if (branch_id && (!Number.isInteger(Number(branch_id)) || Number(branch_id) <= 0)) {
            throw new ApiError(400, 'Invalid branch_id format');
        }
        const result = await ChatService.processMessage({
            message: sanitizedMessage,
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
            conversation_id: result.conversation_id, 
            timestamp: new Date().toISOString(),
        };
        res.json(success(response, 'Message processed successfully'));
    } catch (error) {
        try {
            await AnalyticsService.trackEvent(
                req.user?.id || null,
                'message_error',
                {
                    error: error.message,
                    message: req.body.message?.substring(0, 100) || 'unknown',
                    conversationId: req.body.conversation_id || null
                }
            );
        } catch (analyticsError) {
            }
        const errorMessage = error.message || 'Failed to process message';
        next(new ApiError(error.statusCode || 500, errorMessage));
    }
}
async function getChatHistory(req, res, next) {
    try {
        const { conversation_id } = req.query;
        const user_id = req.user?.id;
        if (!conversation_id || typeof conversation_id !== 'string' || conversation_id.length > 100) {
            throw new ApiError(400, 'Valid conversation_id is required');
        }
        if (!user_id) {
            throw new ApiError(401, 'User authentication required');
        }
        const history = await ChatService.getConversationHistory(conversation_id, 50, user_id);
        res.json(success(history, 'Chat history retrieved successfully'));
    } catch {
        next(new ApiError(500, 'Failed to get chat history'));
    }
}
async function getAllConversations(req, res, next) {
    try {
        const user_id = req.user?.id;
        if (!user_id) {
            return res.json(success([], 'No conversations found - user not authenticated'));
        }
        const conversations = await ChatService.getAllUserConversations(user_id);
        res.json(success(conversations, 'All conversations retrieved successfully'));
    } catch {
        next(new ApiError(500, 'Failed to get conversations'));
    }
}
async function getSuggestions(req, res, next) {
    try {
        const { branch_id } = req.query;
        const suggestions = ChatService.getDefaultSuggestions(branch_id);
        res.json(success(suggestions, 'Suggestions retrieved successfully'));
    } catch {
        next(new ApiError(500, 'Failed to get suggestions'));
    }
}
async function getWelcomeMessage(req, res, next) {
    try {
        const { branch_id, conversation_id } = req.query;
        const user_id = req.user?.id;
        if (!user_id) {
            throw new ApiError(401, 'User authentication required');
        }
        const branchId = branch_id ? (Number.isInteger(Number(branch_id)) && Number(branch_id) > 0 ? Number(branch_id) : null) : null;
        if (conversation_id && (typeof conversation_id !== 'string' || conversation_id.length > 100)) {
            throw new ApiError(400, 'Invalid conversation_id format');
        }
        const welcomeMessage = await ChatService.getWelcomeMessage(user_id, branchId, conversation_id);
        const response = {
            id: require('uuid').v4(),
            message: welcomeMessage.message,
            intent: welcomeMessage.intent,
            entities: welcomeMessage.entities,
            suggestions: welcomeMessage.suggestions,
            action: welcomeMessage.action,
            action_data: welcomeMessage.action_data,
            type: welcomeMessage.type,
            conversation_id: welcomeMessage.conversation_id,
            timestamp: new Date().toISOString(),
        };
        res.json(success(response, 'Welcome message retrieved successfully'));
    } catch (error) {
        next(new ApiError(500, error.message || 'Failed to get welcome message'));
    }
}
async function executeAction(req, res, next) {
    try {
        const { action, data } = req.body;
        const user_id = req.user?.id;
        if (!action || typeof action !== 'string' || action.length > 50) {
            throw new ApiError(400, 'Valid action is required');
        }
        const allowedActions = [
            'confirm_booking', 'order_food', 'view_menu', 'call_confirmation',
            'add_to_cart', 'navigate_menu', 'navigate_orders', 'show_reservation_details',
            'search_food', 'modify_booking', 'select_branch', 'book_table', 'find_branch', 'view_orders', 'select_time',
            'confirm_reservation_only', 'check_order_status', 'use_existing_cart',
            'select_branch_for_takeaway', 'select_branch_for_booking', 'select_branch_for_delivery',
            'confirm_delivery_address', 'change_delivery_address', 'use_saved_address', 'enter_delivery_address',
            'checkout_cart'
        ];
        if (!allowedActions.includes(action)) {
            throw new ApiError(400, 'Invalid action');
        }
        if (data && typeof data !== 'object') {
            throw new ApiError(400, 'Data must be an object');
        }
        let result = {
            action,
            success: true,
            message: `Action ${action} executed successfully`,
        };
        switch (action) {
            case 'confirm_booking':
                try {
                    if (!user_id) {
                        throw new Error('Bạn cần đăng nhập để đặt bàn. Vui lòng đăng nhập và thử lại.');
                    }
                    console.log('[ChatController] confirm_booking - user_id:', user_id);
                    console.log('[ChatController] confirm_booking - data:', JSON.stringify(data, null, 2));
                    const BookingHandler = require('../services/chat/BookingHandler');
                    const reservation = await BookingHandler.createActualReservation(user_id, data);
                    console.log('[ChatController] confirm_booking - reservation created:', reservation?.id);
                    const CartService = require('../services/CartService');
                    let existingCart = null;
                    try {
                        existingCart = await CartService.getUserCart(user_id, reservation.branch_id, null);
                    } catch (cartError) {
                        }
                    const formattedDate = reservation.reservation_date ? 
                        new Date(reservation.reservation_date).toLocaleDateString('vi-VN', {
                            day: '2-digit',
                            month: '2-digit',
                            year: 'numeric'
                        }) : reservation.reservation_date;
                    if (existingCart && existingCart.items && existingCart.items.length > 0) {
                        const itemsCount = existingCart.items.reduce((sum, item) => sum + (item.quantity || 0), 0);
                        result.message = `**Đặt bàn thành công!**\n\nMã đặt bàn của bạn: **#${reservation.id}**\n\n**Ngày:** ${formattedDate}\n**Giờ:** ${reservation.reservation_time}\n**Số người:** ${reservation.guest_count}\n**Chi nhánh:** ${reservation.branch_name}\n\n**Bạn đang có ${itemsCount} món trong giỏ hàng của chi nhánh này.**\n\nBạn có muốn đặt kèm các món này với đặt bàn không?`;
                        result.success = true;
                        result.data = {
                            reservation_id: reservation.id,
                            reservation: reservation,
                            has_existing_cart: true,
                            cart_items_count: itemsCount,
                            suggestions: [
                                { 
                                    text: 'Đặt kèm giỏ hàng hiện tại', 
                                    action: 'use_existing_cart', 
                                    data: { 
                                        branch_id: reservation.branch_id, 
                                        reservation_id: reservation.id,
                                        cart_id: existingCart.id
                                    } 
                                },
                                { 
                                    text: 'Đặt món mới', 
                                    action: 'order_food', 
                                    data: { 
                                        branch_id: reservation.branch_id, 
                                        reservation_id: reservation.id 
                                    } 
                                },
                                { 
                                    text: 'Xác nhận (không đặt món)', 
                                    action: 'confirm_reservation_only', 
                                    data: { 
                                        reservation_id: reservation.id 
                                    } 
                                }
                            ]
                        };
                    } else {
                        result.message = `**Đặt bàn thành công!**\n\nMã đặt bàn của bạn: **#${reservation.id}**\n\n**Ngày:** ${formattedDate}\n**Giờ:** ${reservation.reservation_time}\n**Số người:** ${reservation.guest_count}\n**Chi nhánh:** ${reservation.branch_name}\n\n**Bạn có muốn đặt món trước không?**\n\nBạn có thể chọn món từ menu và đặt trước để tiết kiệm thời gian khi đến nhà hàng.`;
                        result.success = true;
                        result.data = {
                            reservation_id: reservation.id,
                            reservation: reservation,
                            has_existing_cart: false,
                            suggestions: [
                                { 
                                    text: 'Đặt món trước', 
                                    action: 'order_food', 
                                    data: { 
                                        branch_id: reservation.branch_id, 
                                        reservation_id: reservation.id 
                                    } 
                                },
                                { 
                                    text: 'Xác nhận (không đặt món)', 
                                    action: 'confirm_reservation_only', 
                                    data: { 
                                        reservation_id: reservation.id 
                                    } 
                                },
                                { 
                                    text: 'Xem menu', 
                                    action: 'view_menu', 
                                    data: { 
                                        branch_id: reservation.branch_id,
                                        reservation_id: reservation.id 
                                    } 
                                }
                            ]
                        };
                    }
                    try {
                        await AnalyticsService.trackBooking(
                            'created',
                            user_id,
                            reservation.branch_id,
                            reservation.id,
                            {
                                guest_count: reservation.guest_count,
                                reservation_date: reservation.reservation_date,
                                reservation_time: reservation.reservation_time
                            }
                        );
                    } catch (analyticsError) {
                        }
                } catch (error) {
                    console.error('[ChatController] confirm_booking - Error:', error);
                    console.error('[ChatController] confirm_booking - Error stack:', error.stack);
                    result.message = `Không thể đặt bàn: ${error.message}`;
                    result.success = false;
                    result.data = { error: error.message };
                    try {
                        await AnalyticsService.trackBooking(
                            'failed',
                            user_id,
                            data?.branch_id || null,
                            null,
                            {
                                error: error.message,
                                guest_count: data?.people || data?.guest_count || null
                            }
                        );
                    } catch (analyticsError) {
                        }
                }
                break;
            case 'modify_booking':
                result.message = 'Bạn muốn thay đổi thông tin nào?\n\nVui lòng cho tôi biết thông tin mới bạn muốn cập nhật.';
                result.data = { reset: true };
                break;
            case 'select_time':
                try {
                    const BookingHandler = require('../services/chat/BookingHandler');
                    const bookingResult = await BookingHandler.handleSmartBooking('', {
                        conversationContext: {
                            lastEntities: data,
                            lastIntent: 'book_table'
                        }
                    });
                    result.message = bookingResult.message || bookingResult.response;
                    result.data = {
                        entities: bookingResult.entities,
                        suggestions: bookingResult.suggestions
                    };
                } catch (error) {
                    result.message = `Không thể cập nhật giờ đặt bàn: ${error.message}`;
                    result.success = false;
                    result.data = { error: error.message };
                }
                break;
            case 'select_branch': {
                const BranchHandler = require('../services/chat/BranchHandler');
                const allBranches = await BranchHandler.getAllActiveBranches();
                const branchSuggestions = await BranchHandler.createBranchSuggestions(allBranches, {
                    intent: 'book_table',
                    ...data
                });
                result.message = 'Bạn muốn đặt bàn tại chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:';
                result.data = {
                    branches: allBranches,
                    suggestions: branchSuggestions
                };
                break;
            }
            case 'order_food':
                result.message = '';
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
            case 'order_takeaway':
                result.message = '';
                result.data = {
                    order_type: 'takeaway'
                };
                break;
            case 'select_branch_for_takeaway':
                if (data && data.branch_id) {
                    try {
                        const ConversationService = require('../services/chat/ConversationService');
                        const conversationId = req.body.conversation_id || req.query.conversation_id;
                        if (conversationId) {
                            await ConversationService.updateConversationContext(conversationId, {
                                lastBranchId: data.branch_id,
                                lastBranch: data.branch_name || data.branch,
                                lastIntent: 'order_takeaway'
                            }, user_id);
                        }
                        result.message = '';
                        result.data = {
                            branch_id: data.branch_id,
                            branch_name: data.branch_name || data.branch,
                            order_type: 'takeaway',
                            action: 'navigate_to_takeaway_menu'
                        };
                    } catch (error) {
                        result.message = '';
                        result.data = {
                            branch_id: data.branch_id,
                            branch_name: data.branch_name || data.branch,
                            order_type: 'takeaway',
                            action: 'navigate_to_takeaway_menu'
                        };
                    }
                } else {
                    result.message = 'Không tìm thấy thông tin chi nhánh. Vui lòng thử lại.';
                    result.success = false;
                }
                break;
            case 'select_branch_for_booking':
                if (data && data.branch_id) {
                    try {
                        const ConversationService = require('../services/chat/ConversationService');
                        const conversationId = req.body.conversation_id || req.query.conversation_id;
                        if (conversationId) {
                            await ConversationService.updateConversationContext(conversationId, {
                                lastBranchId: data.branch_id,
                                lastBranch: data.branch_name || data.branch,
                                lastIntent: 'book_table'
                            }, user_id);
                        }
                        const BookingHandler = require('../services/chat/BookingHandler');
                        const bookingResult = await BookingHandler.handleSmartBooking('', {
                            conversationContext: {
                                lastBranchId: data.branch_id,
                                lastBranch: data.branch_name || data.branch,
                                lastIntent: 'book_table',
                                lastEntities: data
                            }
                        });
                        result.message = bookingResult.message || bookingResult.response;
                        result.data = {
                            branch_id: data.branch_id,
                            branch_name: data.branch_name || data.branch,
                            entities: bookingResult.entities,
                            suggestions: bookingResult.suggestions
                        };
                    } catch (error) {
                        result.message = `Không thể xử lý: ${error.message}`;
                        result.success = false;
                        result.data = { error: error.message };
                    }
                } else {
                    result.message = 'Không tìm thấy thông tin chi nhánh. Vui lòng thử lại.';
                    result.success = false;
                }
                break;
            case 'select_branch_for_delivery':
                if (data && data.branch_id) {
                    try {
                        const ConversationService = require('../services/chat/ConversationService');
                        const conversationId = req.body.conversation_id || req.query.conversation_id;
                        const deliveryAddress = data.delivery_address || null;
                        if (conversationId) {
                            await ConversationService.updateConversationContext(conversationId, {
                                lastBranchId: data.branch_id,
                                lastBranch: data.branch_name || data.branch,
                                lastIntent: 'order_delivery',
                                lastDeliveryAddress: deliveryAddress
                            }, user_id);
                        }
                        const branchName = data.branch_name || data.branch || 'Chi nhánh';
                        result.message = `Đã chọn chi nhánh: **${branchName}**\n\n**Địa chỉ giao hàng:** ${deliveryAddress || 'Chưa có'}\n\n**Bạn muốn làm gì tiếp theo?**\n\nBạn có thể xem menu và chọn món để đặt giao hàng.`;
                        result.success = true;
                        result.data = {
                            branch_id: data.branch_id,
                            branch_name: branchName,
                            order_type: 'delivery',
                            delivery_address: deliveryAddress,
                            action: 'navigate_to_delivery_menu',
                            suggestions: [
                                {
                                    text: 'Xem menu',
                                    action: 'view_menu',
                                    data: {
                                        branch_id: data.branch_id,
                                        branch_name: branchName,
                                        order_type: 'delivery',
                                        delivery_address: deliveryAddress
                                    }
                                },
                                {
                                    text: 'Đặt món ngay',
                                    action: 'order_food',
                                    data: {
                                        branch_id: data.branch_id,
                                        branch_name: branchName,
                                        order_type: 'delivery',
                                        delivery_address: deliveryAddress
                                    }
                                }
                            ]
                        };
                    } catch (error) {
                        console.error('[ChatController] select_branch_for_delivery error:', error);
                        result.message = `Không thể xử lý: ${error.message}`;
                        result.success = false;
                        result.data = { error: error.message };
                    }
                } else {
                    result.message = 'Không tìm thấy thông tin chi nhánh. Vui lòng thử lại.';
                    result.success = false;
                }
                break;
            case 'confirm_delivery_address':
                if (data && data.delivery_address) {
                    try {
                        const ConversationService = require('../services/chat/ConversationService');
                        const conversationId = req.body.conversation_id || req.query.conversation_id;
                        let userLat = data.latitude || null;
                        let userLng = data.longitude || null;
                        if (!userLat || !userLng) {
                            try {
                                const axios = require('axios');
                                const mapboxKey = process.env.MAPBOX_KEY_PUBLIC || process.env.MAPBOX_KEY;
                                if (mapboxKey) {
                                    const encodedQuery = encodeURIComponent(data.delivery_address.trim());
                                    const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedQuery}.json?access_token=${mapboxKey}`;
                                    const geocodeResponse = await axios.get(url);
                                    if (geocodeResponse.data && geocodeResponse.data.features && geocodeResponse.data.features.length > 0) {
                                        const coordinates = geocodeResponse.data.features[0].geometry.coordinates; 
                                        userLng = coordinates[0];
                                        userLat = coordinates[1];
                                        }
                                }
                            } catch (geocodeError) {
                            }
                        }
                        if (conversationId) {
                            await ConversationService.updateConversationContext(conversationId, {
                                lastDeliveryAddress: data.delivery_address,
                                deliveryAddress: data.delivery_address,
                                lastIntent: 'order_delivery',
                                userLatitude: userLat,
                                userLongitude: userLng
                            }, user_id);
                        }
                        const BranchHandler = require('../services/chat/BranchHandler');
                        let allBranches = await BranchHandler.getAllActiveBranches();
                        if (userLat && userLng) {
                            const BranchService = require('../services/BranchService');
                            allBranches = await BranchService.getNearbyBranches(userLat, userLng);
                        }
                        const branchSuggestions = await BranchHandler.createBranchSuggestions(allBranches, {
                            intent: 'order_delivery', 
                            delivery_address: data.delivery_address
                        });
                        let message = `Đã xác nhận địa chỉ giao hàng:\n\n**${data.delivery_address}**\n\n`;
                        if (userLat && userLng && allBranches.length > 0 && allBranches[0].distance_km) {
                            const nearestBranch = allBranches[0];
                            const distance = nearestBranch.distance_km.toFixed(1);
                            message += `Chi nhánh gần bạn nhất: **${nearestBranch.name}** (cách ${distance} km)\n\n`;
                        }
                        message += `Bạn muốn đặt món giao hàng từ chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:`;
                        result.message = message;
                        result.intent = 'order_delivery'; 
                        result.data = {
                            delivery_address: data.delivery_address,
                            suggestions: branchSuggestions,
                            userLatitude: userLat, 
                            userLongitude: userLng
                        };
                    } catch (error) {
                        result.message = `Không thể xử lý: ${error.message}`;
                        result.success = false;
                    }
                } else {
                    result.message = 'Không tìm thấy địa chỉ giao hàng. Vui lòng thử lại.';
                    result.success = false;
                }
                break;
            case 'change_delivery_address':
            case 'enter_delivery_address':
                try {
                    const ConversationService = require('../services/chat/ConversationService');
                    const conversationId = req.body.conversation_id || req.query.conversation_id;
                    if (conversationId) {
                        await ConversationService.updateConversationContext(conversationId, {
                            waitingForAddress: true,
                            lastIntent: 'order_delivery'
                        }, user_id);
                    }
                    result.message = 'Vui lòng cho tôi biết địa chỉ giao hàng mới của bạn.\n\nBạn có thể nhập địa chỉ chi tiết (số nhà, tên đường, phường/xã, quận/huyện, thành phố).';
                    result.data = { action: 'enter_address' };
                } catch (error) {
                    result.message = 'Vui lòng cho tôi biết địa chỉ giao hàng mới của bạn.\n\nBạn có thể nhập địa chỉ chi tiết (số nhà, tên đường, phường/xã, quận/huyện, thành phố).';
                    result.data = { action: 'enter_address' };
                }
                break;
            case 'use_saved_address':
                try {
                    const UserService = require('../services/UserService');
                    const user = await UserService.getUserById(user_id);
                    if (user && user.address) {
                        const ConversationService = require('../services/chat/ConversationService');
                        const conversationId = req.body.conversation_id || req.query.conversation_id;
                        if (conversationId) {
                            await ConversationService.updateConversationContext(conversationId, {
                                lastDeliveryAddress: user.address,
                                deliveryAddress: user.address,
                                lastIntent: 'order_delivery'
                            }, user_id);
                        }
                        const BranchHandler = require('../services/chat/BranchHandler');
                        const allBranches = await BranchHandler.getAllActiveBranches();
                        const branchSuggestions = await BranchHandler.createBranchSuggestions(allBranches, {
                            intent: 'order_delivery',
                            delivery_address: user.address
                        });
                        result.message = `Đã sử dụng địa chỉ đã lưu:\n\n**${user.address}**\n\nBạn muốn đặt món giao hàng từ chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:`;
                        result.data = {
                            delivery_address: user.address,
                            suggestions: branchSuggestions
                        };
                    } else {
                        result.message = 'Bạn chưa có địa chỉ đã lưu. Vui lòng nhập địa chỉ mới.';
                        result.data = { action: 'enter_address' };
                    }
                } catch (error) {
                    result.message = `Không thể lấy địa chỉ đã lưu: ${error.message}`;
                    result.success = false;
                }
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
            case 'search_food':
                result.message = 'Searching for food items';
                result.data = data;
                break;
            case 'book_table': {
                const BranchHandlerForBook = require('../services/chat/BranchHandler');
                const branchesForBook = await BranchHandlerForBook.getAllActiveBranches();
                const bookBranchSuggestions = await BranchHandlerForBook.createBranchSuggestions(branchesForBook, {
                    intent: 'book_table',
                    ...data
                });
                result.message = 'Bạn muốn đặt bàn tại chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:';
                result.data = {
                    branches: branchesForBook,
                    suggestions: bookBranchSuggestions
                };
                break;
            }
            case 'find_branch': {
                const BranchHandlerForFind = require('../services/chat/BranchHandler');
                const allBranchesFind = await BranchHandlerForFind.getAllActiveBranches();
                let branchListMessage = 'Danh sách chi nhánh của Beast Bite:\n\n';
                allBranchesFind.forEach((branch, index) => {
                    branchListMessage += `${index + 1}. ${branch.name}\n`;
                    branchListMessage += `   ${branch.address}\n`;
                    if (branch.phone) {
                        branchListMessage += `   ${branch.phone}\n`;
                    }
                    branchListMessage += `\n`;
                });
                result.message = branchListMessage;
                result.data = {
                    branches: allBranchesFind
                };
                break;
            }
            case 'view_orders':
                result.message = 'Đang chuyển đến trang đơn hàng của bạn...';
                result.data = {
                    navigate_to: 'orders'
                };
                break;
            case 'confirm_reservation_only':
                result.message = 'Đã xác nhận đặt bàn!\n\nChúng tôi sẽ chuẩn bị bàn cho bạn. Bạn có thể đặt món khi đến nhà hàng hoặc đặt sau qua ứng dụng.\n\nCảm ơn bạn đã đặt bàn tại Beast Bite!';
                result.data = {
                    reservation_id: data.reservation_id
                };
                break;
            case 'use_existing_cart':
                try {
                    const CartService = require('../services/CartService');
                    const cart = await CartService.getCartById(data.cart_id);
                    if (!cart || cart.items.length === 0) {
                        result.message = 'Giỏ hàng hiện tại đang trống. Vui lòng chọn món mới.';
                        result.success = false;
                        result.data = {
                            reservation_id: data.reservation_id,
                            suggestions: [
                                {
                                    text: 'Đặt món mới',
                                    action: 'order_food',
                                    data: {
                                        branch_id: data.branch_id,
                                        reservation_id: data.reservation_id
                                    }
                                }
                            ]
                        };
                    } else {
                        const checkoutResult = await CartService.checkout(cart.id, data.reservation_id);
                        const itemsList = cart.items.map(item => {
                            const itemTotal = (item.price || 0) * (item.quantity || 0);
                            return `• ${item.quantity || 0}x ${item.product_name || 'Món'} - ${new Intl.NumberFormat('vi-VN').format(itemTotal)}đ`;
                        }).join('\n');
                        const ReservationService = require('../services/ReservationService');
                        const reservation = await ReservationService.getReservationById(data.reservation_id);
                        const formattedDate = reservation.reservation_date ? 
                            new Date(reservation.reservation_date).toLocaleDateString('vi-VN', {
                                day: '2-digit',
                                month: '2-digit',
                                year: 'numeric'
                            }) : reservation.reservation_date;
                        result.message = `**Đã đặt kèm giỏ hàng thành công!**\n\n**Mã đơn hàng:** #${checkoutResult.order_id}\n**Ngày đặt bàn:** ${formattedDate}\n**Giờ:** ${reservation.reservation_time}\n**Chi nhánh:** ${cart.branch_name || reservation.branch_name || 'Chi nhánh'}\n\n**Danh sách món:**\n${itemsList}\n\n**Tổng tiền:** ${new Intl.NumberFormat('vi-VN').format(checkoutResult.total)}đ\n\nĐơn hàng sẽ được chuẩn bị và phục vụ khi bạn đến nhà hàng.`;
                        result.success = true;
                        result.data = {
                            order_id: checkoutResult.order_id,
                            reservation_id: data.reservation_id,
                            total: checkoutResult.total,
                            suggestions: [] 
                        };
                    }
                } catch (error) {
                    result.message = `Không thể đặt kèm giỏ hàng: ${error.message}`;
                    result.success = false;
                    result.data = { error: error.message };
                }
                break;
            case 'check_order_status':
                try {
                    const OrderService = require('../services/OrderService');
                    const ReservationService = require('../services/ReservationService');
                    const reservation = await ReservationService.getReservationById(data.reservation_id);
                    const order = await OrderService.getLatestOrderForReservation(data.reservation_id);
                    if (order && order.total > 0 && order.items && order.items.length > 0) {
                        const itemsList = order.items.map(item => {
                            const itemTotal = (item.price || 0) * (item.quantity || 0);
                            return `• ${item.quantity || 0}x ${item.product_name || 'Món'} - ${new Intl.NumberFormat('vi-VN').format(itemTotal)}đ`;
                        }).join('\n');
                        const formattedDate = reservation.reservation_date ? 
                            new Date(reservation.reservation_date).toLocaleDateString('vi-VN', {
                                day: '2-digit',
                                month: '2-digit',
                                year: 'numeric'
                            }) : reservation.reservation_date;
                        result.message = `**Đơn hàng của bạn đã được tạo!**\n\n**Mã đơn hàng:** #${order.id}\n**Ngày đặt bàn:** ${formattedDate}\n**Giờ:** ${reservation.reservation_time}\n**Chi nhánh:** ${reservation.branch_name}\n\n**Danh sách món:**\n${itemsList}\n\n**Tổng tiền:** ${new Intl.NumberFormat('vi-VN').format(order.total || 0)}đ\n\nĐơn hàng sẽ được chuẩn bị và phục vụ khi bạn đến nhà hàng.`;
                        result.data = {
                            order_id: order.id,
                            reservation_id: reservation.id,
                            order: order,
                            suggestions: [] 
                        };
                    } else {
                        result.message = 'Chưa có món nào trong đơn hàng. Bạn có muốn đặt món ngay không?';
                        result.data = {
                            reservation_id: reservation.id,
                            suggestions: [
                                {
                                    text: 'Đặt món ngay',
                                    action: 'order_food',
                                    data: {
                                        branch_id: reservation.branch_id,
                                        reservation_id: reservation.id
                                    }
                                }
                            ]
                        };
                    }
                } catch (error) {
                    result.message = `Không thể kiểm tra đơn hàng: ${error.message}`;
                    result.success = false;
                    result.data = { error: error.message };
                }
                break;
            case 'checkout_cart':
                if (!user_id) {
                    result.message = 'Bạn cần đăng nhập để đặt hàng. Vui lòng đăng nhập và thử lại.';
                    result.success = false;
                    result.data = { error: 'User not authenticated' };
                    break;
                }
                try {
                    const CartService = require('../services/CartService');
                    const ConversationService = require('../services/chat/ConversationService');
                    const conversationId = req.body.conversation_id || req.query.conversation_id;
                    
                    // Get delivery address from context or data
                    let deliveryAddress = data.delivery_address || null;
                    let deliveryPhone = data.delivery_phone || null;
                    let customerName = data.customer_name || null;
                    let customerPhone = data.customer_phone || null;
                    
                    if (!deliveryAddress && conversationId) {
                        try {
                            const conversation = await knex('chat_conversations')
                                .where('session_id', conversationId)
                                .where('user_id', user_id)
                                .first();
                            if (conversation && conversation.context_data) {
                                const context = typeof conversation.context_data === 'string' 
                                    ? JSON.parse(conversation.context_data) 
                                    : conversation.context_data;
                                deliveryAddress = context?.lastDeliveryAddress || context?.deliveryAddress || null;
                            }
                        } catch (error) {
                            console.error('[ChatController] Error getting conversation context:', error);
                        }
                    }
                    
                    if (!data.cart_id) {
                        // Try to find user's cart for the branch
                        const branchId = data.branch_id;
                        if (!branchId) {
                            throw new Error('Branch ID is required');
                        }
                        const cart = await CartService.getUserCart(user_id, branchId, null);
                        if (!cart || cart.items.length === 0) {
                            result.message = 'Giỏ hàng của bạn đang trống. Vui lòng thêm món vào giỏ hàng trước khi đặt hàng.';
                            result.success = false;
                            result.data = {
                                suggestions: [
                                    {
                                        text: 'Xem menu',
                                        action: 'view_menu',
                                        data: { branch_id: branchId, order_type: data.order_type || 'delivery' }
                                    }
                                ]
                            };
                            break;
                        }
                        data.cart_id = cart.id;
                    }
                    
                    // Validate delivery address for delivery orders
                    const cart = await CartService.getCartById(data.cart_id);
                    if (cart.order_type === 'delivery' && !deliveryAddress) {
                        result.message = 'Địa chỉ giao hàng là bắt buộc cho đơn hàng giao hàng. Vui lòng cung cấp địa chỉ giao hàng.';
                        result.success = false;
                        result.data = {
                            suggestions: [
                                {
                                    text: 'Nhập địa chỉ giao hàng',
                                    action: 'enter_delivery_address',
                                    data: {}
                                }
                            ]
                        };
                        break;
                    }
                    
                    // Get user info for customer name and phone
                    if (!customerName || !customerPhone) {
                        const UserService = require('../services/UserService');
                        const user = await UserService.getUserById(user_id);
                        if (user) {
                            customerName = customerName || user.name || null;
                            customerPhone = customerPhone || user.phone || null;
                        }
                    }
                    
                    const checkoutResult = await CartService.checkout(
                        data.cart_id,
                        data.reservation_id || null,
                        deliveryAddress,
                        deliveryPhone,
                        customerName,
                        customerPhone
                    );
                    
                    const itemsList = cart.items.map(item => {
                        const itemTotal = (item.price || 0) * (item.quantity || 0);
                        return `• ${item.quantity || 0}x ${item.product_name || 'Món'} - ${new Intl.NumberFormat('vi-VN').format(itemTotal)}đ`;
                    }).join('\n');
                    
                    const BranchService = require('../services/BranchService');
                    const branch = await BranchService.getBranchById(cart.branch_id);
                    const branchName = branch?.name || 'Chi nhánh';
                    
                    let successMessage = `**Đặt hàng thành công!**\n\n**Mã đơn hàng:** #${checkoutResult.order_id}\n**Chi nhánh:** ${branchName}\n\n**Danh sách món:**\n${itemsList}\n\n**Tổng tiền:** ${new Intl.NumberFormat('vi-VN').format(checkoutResult.total)}đ\n\n`;
                    
                    if (cart.order_type === 'delivery') {
                        successMessage += `**Địa chỉ giao hàng:** ${deliveryAddress}\n\nĐơn hàng sẽ được giao đến địa chỉ của bạn trong thời gian sớm nhất.`;
                    } else if (cart.order_type === 'takeaway') {
                        successMessage += `Bạn có thể đến chi nhánh để lấy đơn hàng.`;
                    } else {
                        successMessage += `Đơn hàng sẽ được chuẩn bị và phục vụ tại nhà hàng.`;
                    }
                    
                    result.message = successMessage;
                    result.success = true;
                    result.data = {
                        order_id: checkoutResult.order_id,
                        total: checkoutResult.total,
                        order_type: cart.order_type,
                        suggestions: []
                    };
                } catch (error) {
                    console.error('[ChatController] checkout_cart error:', error);
                    result.message = `Không thể đặt hàng: ${error.message}`;
                    result.success = false;
                    result.data = { error: error.message };
                }
                break;
            default:
                result.message = `Action ${action} executed successfully`;
                result.data = data;
        }
        // If action failed, return error response instead of success
        if (result.success === false) {
            return res.status(400).json({
                status: 'fail',
                message: result.message || 'Action execution failed',
                data: result.data || {}
            });
        }
        res.json(success(result, 'Action executed successfully'));
    } catch (error) {
        next(new ApiError(500, error.message || 'Failed to execute action'));
    }
}
async function resetChat(req, res, next) {
    try {
        const { conversation_id } = req.body;
        const user_id = req.user?.id;
        const delete_messages = req.body.delete_messages !== undefined ? req.body.delete_messages : true;
        if (!conversation_id || typeof conversation_id !== 'string' || conversation_id.length > 100) {
            throw new ApiError(400, 'Valid conversation_id is required');
        }
        if (!user_id) {
            throw new ApiError(401, 'User authentication required');
        }
        const deleteMessages = delete_messages !== undefined ? delete_messages : true;
        if (delete_messages !== undefined && typeof delete_messages !== 'boolean') {
            throw new ApiError(400, 'delete_messages must be a boolean');
        }
        const result = await ChatService.resetConversation(conversation_id, user_id, deleteMessages);
        res.json(success(result, 'Chat reset successfully'));
    } catch (error) {
        next(new ApiError(500, error.message || 'Failed to reset chat'));
    }
}
module.exports = {
    sendMessage,
    getChatHistory,
    getAllConversations,
    getSuggestions,
    getWelcomeMessage,
    executeAction,
    resetChat,
};
