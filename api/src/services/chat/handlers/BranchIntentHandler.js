const BaseIntentHandler = require('./BaseIntentHandler');
const BranchHandler = require('../BranchHandler');
const BranchFormatter = require('../helpers/BranchFormatter');
const BranchService = require('../../BranchService');
const Utils = require('../Utils');
class BranchIntentHandler extends BaseIntentHandler {
    constructor() {
        super();
        this.intentSet = new Set(['view_branches', 'ask_branch', 'find_nearest_branch', 'find_first_branch', 'search_branches_by_location']);
    }
    canHandle(intent) {
        return this.intentSet.has(intent);
    }
    async handle({ intent, entities, context, userId, aiResponse }) {
        if (aiResponse && aiResponse.tool_results && aiResponse.tool_results.length > 0) {
            const normalized = Utils.normalizeEntityFields(entities || {});
            return this.buildResponse({
                intent: aiResponse.intent || intent || 'view_branches',
                response: aiResponse.response,
                entities: normalized,
                suggestions: aiResponse.suggestions || [],
            });
        }
        if (intent === 'find_nearest_branch') {
            let userLat = null;
            let userLng = null;
            let userAddress = null;
            const deliveryAddress = context.conversationContext?.lastDeliveryAddress || context.conversationContext?.deliveryAddress;
            const userLatFromContext = context.conversationContext?.userLatitude;
            const userLngFromContext = context.conversationContext?.userLongitude;
            if (userLatFromContext && userLngFromContext) {
                userLat = userLatFromContext;
                userLng = userLngFromContext;
                userAddress = deliveryAddress;
                } else if (deliveryAddress || context.user?.address) {
                userAddress = deliveryAddress || context.user.address;
                try {
                    const axios = require('axios');
                    const mapboxKey = process.env.MAPBOX_KEY_PUBLIC || process.env.MAPBOX_KEY;
                    if (mapboxKey && userAddress) {
                        const encodedQuery = encodeURIComponent(userAddress.trim());
                        const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedQuery}.json?access_token=${mapboxKey}&country=VN&limit=1`;
                        const geocodeResponse = await axios.get(url, { timeout: 5000 });
                        if (geocodeResponse.data && geocodeResponse.data.features && geocodeResponse.data.features.length > 0) {
                            const coordinates = geocodeResponse.data.features[0].geometry.coordinates; 
                            userLng = coordinates[0];
                            userLat = coordinates[1];
                            const ConversationService = require('../ConversationService');
                            const conversationId = context.conversationId;
                            if (conversationId) {
                                await ConversationService.updateConversationContext(conversationId, {
                                    userLatitude: userLat,
                                    userLongitude: userLng
                                }, userId);
                            }
                        }
                    }
                } catch (geocodeError) {
                }
            }
            if (userLat && userLng) {
                try {
                    const nearbyBranches = await BranchService.getNearbyBranches(userLat, userLng);
                    if (nearbyBranches.length === 0) {
                        return this.buildResponse({
                            intent: 'find_nearest_branch',
                            response: 'Hiện tại không có chi nhánh nào đang mở. Vui lòng quay lại sau nhé.',
                            entities: Utils.normalizeEntityFields(entities || {}),
                            suggestions: [],
                        });
                    }
                    const nearestBranch = nearbyBranches[0]; 
                    const distance = nearestBranch.distance_km;
                    const distanceText = distance ? ` (cách bạn ${distance.toFixed(1)} km)` : '';
                    const suggestions = await BranchHandler.createBranchSuggestions([nearestBranch], {
                        intent: context.conversationContext?.lastIntent === 'order_delivery' ? 'order_delivery' : 
                                context.conversationContext?.lastIntent === 'order_takeaway' ? 'order_takeaway' : 
                                'view_menu'
                    });
                    if (nearbyBranches.length > 1) {
                        const otherBranches = nearbyBranches.slice(1, 4); 
                        const otherSuggestions = await BranchHandler.createBranchSuggestions(otherBranches, {
                            intent: context.conversationContext?.lastIntent === 'order_delivery' ? 'order_delivery' : 
                                    context.conversationContext?.lastIntent === 'order_takeaway' ? 'order_takeaway' : 
                                    'view_menu'
                        });
                        suggestions.push(...otherSuggestions);
                    }
                    const address = nearestBranch.address_detail || '';
                    const phone = nearestBranch.phone || '';
                    const openingHours = nearestBranch.opening_hours ? `${nearestBranch.opening_hours}h` : '';
                    const closeHours = nearestBranch.close_hours ? `${nearestBranch.close_hours}h` : '';
                    const hoursText = openingHours && closeHours ? `🕐 ${openingHours} - ${closeHours}` : '';
                    const responseText = `📍 **Chi nhánh gần bạn nhất${distanceText}:**\n\n` +
                        `🏢 **${nearestBranch.name}**\n` +
                        `${address ? `📍 ${address}\n` : ''}` +
                        `${hoursText ? `${hoursText}\n` : ''}` +
                        `${phone ? `📞 ${phone}\n` : ''}` +
                        `\n${nearbyBranches.length > 1 ? `Còn ${nearbyBranches.length - 1} chi nhánh khác gần bạn. ` : ''}Bạn muốn xem menu hoặc đặt bàn tại chi nhánh này không?`;
                    return this.buildResponse({
                        intent: 'find_nearest_branch',
                        response: responseText,
                        entities: Utils.normalizeEntityFields({ ...entities, branch_id: nearestBranch.id, branch_name: nearestBranch.name }),
                        suggestions: suggestions,
                    });
                } catch (error) {
                }
            } else {
                const branches = await BranchHandler.getAllActiveBranches();
                if (!branches.length) {
                    return this.buildResponse({
                        intent: 'find_nearest_branch',
                        response: 'Hiện tại không có chi nhánh nào đang mở. Vui lòng quay lại sau nhé.',
                        entities: Utils.normalizeEntityFields(entities || {}),
                        suggestions: [],
                    });
                }
                const branchList = await BranchFormatter.formatBranchListWithDetails(branches);
                const responseText = userAddress 
                    ? `📍 Để tìm chi nhánh gần bạn nhất, tôi cần tọa độ chính xác của bạn.\n\n` +
                      `Địa chỉ của bạn: **${userAddress}**\n\n` +
                      `Hiện tại tôi có thể hiển thị tất cả ${branches.length} chi nhánh:\n\n${branchList.join('\n\n')}\n\n` +
                      `Bạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`
                    : `📍 Để tìm chi nhánh gần bạn nhất, vui lòng cung cấp địa chỉ của bạn.\n\n` +
                      `Hiện tại tôi có ${branches.length} chi nhánh:\n\n${branchList.join('\n\n')}\n\n` +
                      `Bạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`;
                return this.buildResponse({
                    intent: 'find_nearest_branch',
                    response: responseText,
                    entities: Utils.normalizeEntityFields(entities || {}),
                    suggestions: [],
                });
            }
        }
        const branches = await BranchHandler.getAllActiveBranches();
        if (!branches.length) {
            return this.buildResponse({
                intent,
                response: 'Hiện tại không có chi nhánh nào đang mở. Vui lòng quay lại sau nhé.',
                entities: Utils.normalizeEntityFields(entities || {}),
            });
        }
        const branchList = await BranchFormatter.formatBranchListWithDetails(branches);
        const responseText = `📍 Danh sách ${branches.length} chi nhánh của Beast Bite:\n\n${branchList.join('\n\n')}\n\nBạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`;
        return this.buildResponse({
            intent: intent || 'view_branches',
            response: responseText,
            entities: Utils.normalizeEntityFields(entities || {}),
            suggestions: [], 
        });
    }
}
module.exports = BranchIntentHandler;
