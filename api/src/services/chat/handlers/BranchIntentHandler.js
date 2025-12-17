const BaseIntentHandler = require('./BaseIntentHandler');
const BranchService = require('../../BranchService');
const Utils = require('../Utils');
const GeocodingService = require('../helpers/GeocodingService');

class BranchIntentHandler extends BaseIntentHandler {
    static async formatBranchListWithDetails(branches) {
        if (!branches || branches.length === 0) {
            return [];
        }
        return await Promise.all(branches.map(async (branch) => {
            const address = branch.address_detail || '';
            const phone = branch.phone || '';
            const openingHours = branch.opening_hours ? `${branch.opening_hours}h` : '';
            const closeHours = branch.close_hours ? `${branch.close_hours}h` : '';
            const hours = openingHours && closeHours ? `${openingHours} - ${closeHours}` : (openingHours || closeHours || '');
            let branchInfo = `${branch.name}`;
            if (address) branchInfo += `\n${address}`;
            if (phone) branchInfo += `\n${phone}`;
            if (hours) branchInfo += `\n${hours}`;
            return branchInfo;
        }));
    }
    constructor() {
        super();
        this.intentSet = new Set(['view_branches', 'ask_branch', 'find_nearest_branch', 'find_first_branch', 'search_branches_by_location']);
    }

    canHandle(intent) {
        return this.intentSet.has(intent);
    }

    async handle({ intent, entities, context, userId, aiResponse, message }) {
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
                const coordinates = await GeocodingService.geocodeAndUpdateContext(
                    userAddress,
                    context.conversationId,
                    userId
                );
                if (coordinates) {
                    userLat = coordinates.lat;
                    userLng = coordinates.lng;
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
                    const suggestions = await this.createBranchSuggestions([nearestBranch], {
                        intent: context.conversationContext?.lastIntent === 'order_delivery' ? 'order_delivery' : 
                                context.conversationContext?.lastIntent === 'order_takeaway' ? 'order_takeaway' : 
                                'view_menu'
                    });
                    if (nearbyBranches.length > 1) {
                        const otherBranches = nearbyBranches.slice(1, 4); 
                        const otherSuggestions = await this.createBranchSuggestions(otherBranches, {
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
                    const hoursText = openingHours && closeHours ? `${openingHours} - ${closeHours}` : '';
                    const responseText = `**Chi nhánh gần bạn nhất${distanceText}:**\n\n` +
                        `**${nearestBranch.name}**\n` +
                        `${address ? `${address}\n` : ''}` +
                        `${hoursText ? `${hoursText}\n` : ''}` +
                        `${phone ? `${phone}\n` : ''}` +
                        `\n${nearbyBranches.length > 1 ? `Còn ${nearbyBranches.length - 1} chi nhánh khác gần bạn. ` : ''}Bạn muốn xem menu hoặc đặt bàn tại chi nhánh này không?`;
                    return this.buildResponse({
                        intent: 'find_nearest_branch',
                        response: responseText,
                        entities: Utils.normalizeEntityFields({ ...entities, branch_id: nearestBranch.id, branch_name: nearestBranch.name }),
                        suggestions: suggestions,
                    });
                } catch (error) {
                    console.error('[BranchIntentHandler] Error finding nearest branches:', error.message);
                }
            } else {
                const branches = await this.getAllActiveBranches();
                if (!branches.length) {
                    return this.buildResponse({
                        intent: 'find_nearest_branch',
                        response: 'Hiện tại không có chi nhánh nào đang mở. Vui lòng quay lại sau nhé.',
                        entities: Utils.normalizeEntityFields(entities || {}),
                        suggestions: [],
                    });
                }
                const branchList = await BranchIntentHandler.formatBranchListWithDetails(branches);
                const responseText = userAddress 
                    ? `Để tìm chi nhánh gần bạn nhất, tôi cần tọa độ chính xác của bạn.\n\n` +
                      `Địa chỉ của bạn: **${userAddress}**\n\n` +
                      `Hiện tại tôi có thể hiển thị tất cả ${branches.length} chi nhánh:\n\n${branchList.join('\n\n')}\n\n` +
                      `Bạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`
                    : `Để tìm chi nhánh gần bạn nhất, vui lòng cung cấp địa chỉ của bạn.\n\n` +
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
        
        // Check if user has delivery address and wants to find nearest branch
        const deliveryAddress = context.conversationContext?.lastDeliveryAddress || context.conversationContext?.deliveryAddress;
        const userLatFromContext = context.conversationContext?.userLatitude;
        const userLngFromContext = context.conversationContext?.userLongitude;
        
        // Get user message from payload or conversation history
        let userMessage = message || '';
        if (!userMessage && context.conversationHistory && context.conversationHistory.length > 0) {
            for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                const msg = context.conversationHistory[i];
                if (msg.message_type === 'user' || msg.is_user) {
                    userMessage = msg.message_content || msg.content || '';
                    break;
                }
            }
        }
        const isAskingForNearest = /(gan|gần|nearest|closest|gần nhất|gan nhat|gan dia chi|gần địa chỉ)/i.test(userMessage);
        
        // If user has delivery address and asking about nearest branch, try to find nearest
        if ((isAskingForNearest || intent === 'view_branches') && (deliveryAddress || userLatFromContext)) {
            let userLat = userLatFromContext;
            let userLng = userLngFromContext;
            
            // Geocode delivery address if we don't have coordinates yet
            if (!userLat && !userLng && deliveryAddress) {
                const coordinates = await GeocodingService.geocodeAndUpdateContext(
                    deliveryAddress,
                    context.conversationId,
                    userId
                );
                if (coordinates) {
                    userLat = coordinates.lat;
                    userLng = coordinates.lng;
                }
            }
            
            // If we have coordinates, find nearest branches
            if (userLat && userLng) {
                try {
                    const nearbyBranches = await BranchService.getNearbyBranches(userLat, userLng);
                    if (nearbyBranches.length > 0) {
                        const nearestBranch = nearbyBranches[0]; 
                        const distance = nearestBranch.distance_km;
                        const distanceText = distance ? ` (cách bạn ${distance.toFixed(1)} km)` : '';
                        const suggestions = await this.createBranchSuggestions([nearestBranch], {
                            intent: context.conversationContext?.lastIntent === 'order_delivery' ? 'order_delivery' : 
                                    context.conversationContext?.lastIntent === 'order_takeaway' ? 'order_takeaway' : 
                                    'view_menu'
                        });
                        if (nearbyBranches.length > 1) {
                            const otherBranches = nearbyBranches.slice(1, 4); 
                            const otherSuggestions = await this.createBranchSuggestions(otherBranches, {
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
                        const hoursText = openingHours && closeHours ? `${openingHours} - ${closeHours}` : '';
                        const responseText = `**Chi nhánh gần bạn nhất${distanceText}:**\n\n` +
                            `**${nearestBranch.name}**\n` +
                            `${address ? `${address}\n` : ''}` +
                            `${hoursText ? `${hoursText}\n` : ''}` +
                            `${phone ? `${phone}\n` : ''}` +
                            `\n${nearbyBranches.length > 1 ? `Còn ${nearbyBranches.length - 1} chi nhánh khác gần bạn. ` : ''}Bạn muốn xem menu hoặc đặt bàn tại chi nhánh này không?`;
                        return this.buildResponse({
                            intent: 'find_nearest_branch',
                            response: responseText,
                            entities: Utils.normalizeEntityFields({ ...entities, branch_id: nearestBranch.id, branch_name: nearestBranch.name }),
                            suggestions: suggestions,
                        });
                    }
                } catch (error) {
                    console.error('[BranchIntentHandler] Error finding nearest branches:', error);
                }
            }
        }
        
        const branches = await this.getAllActiveBranches();
        if (!branches.length) {
            return this.buildResponse({
                intent,
                response: 'Hiện tại không có chi nhánh nào đang mở. Vui lòng quay lại sau nhé.',
                entities: Utils.normalizeEntityFields(entities || {}),
            });
        }
        const branchList = await BranchIntentHandler.formatBranchListWithDetails(branches);
        const responseText = `Danh sách ${branches.length} chi nhánh của Beast Bite:\n\n${branchList.join('\n\n')}\n\nBạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`;
        return this.buildResponse({
            intent: intent || 'view_branches',
            response: responseText,
            entities: Utils.normalizeEntityFields(entities || {}),
            suggestions: [], 
        });
    }

    // Methods từ BranchHandler (gộp vào đây)
    searchBranchesInCache(branchesCache, searchTerm) {
        if (!branchesCache || branchesCache.length === 0 || !searchTerm) {
            return [];
        }
        const normalizedSearchTerm = Utils.normalizeVietnamese(searchTerm.toLowerCase().trim());
        const matches = branchesCache.filter(branch => {
            if (branch.name_normalized && branch.name_normalized.includes(normalizedSearchTerm)) {
                return true;
            }
            if (branch.address_normalized && branch.address_normalized.includes(normalizedSearchTerm)) {
                return true;
            }
            if (branch.name && branch.name.toLowerCase().includes(searchTerm.toLowerCase())) {
                return true;
            }
            if (branch.address_detail && branch.address_detail.toLowerCase().includes(searchTerm.toLowerCase())) {
                return true;
            }
            return false;
        });
        return matches;
    }

    async getAllActiveBranches() {
        try {
            const branches = await BranchService.getActiveBranches();
            return branches.map(b => ({
                id: b.id,
                name: b.name,
                address_detail: b.address_detail,
                phone: b.phone,
                opening_hours: b.opening_hours,
                close_hours: b.close_hours,
            }));
        } catch {
            return [];
        }
    }

    async getBranchById(branchId) {
        try {
            const branch = await BranchService.getBranchById(branchId);
            return branch && branch.status === 'active' ? branch : null;
        } catch (error) {
            console.error('[BranchIntentHandler] Error getting branch:', error.message);
            return null;
        }
    }

    async getBranchByName(branchName) {
        try {
            const branches = await BranchService.getAllBranches('active', branchName);
            return branches.length > 0 ? branches[0] : null;
        } catch (error) {
            console.error('[BranchIntentHandler] Error getting branch:', error.message);
            return null;
        }
    }

    async createBranchSuggestions(branches, bookingContext = null) {
        if (!branches || branches.length === 0) {
            return [];
        }
        const suggestions = await Promise.all(branches.map(async (branch) => {
            const address = branch.address_detail ? branch.address_detail.trim() : 'Địa chỉ chưa cập nhật';
            const phone = branch.phone ? branch.phone.trim() : '';
            const hours = this.formatOperatingHours(branch) || 'Giờ làm việc chưa cập nhật';
            let buttonText = `${branch.name}`;
            buttonText += `\n${address}`;
            buttonText += `\n${hours}`;
            if (phone) {
                buttonText += `\n${phone}`;
            }
            if (bookingContext) {
                const intent = bookingContext.intent;
                if (intent === 'view_menu') {
                    return {
                        text: buttonText,
                        action: 'view_menu',
                        data: {
                            ...bookingContext,
                            branch_id: branch.id,  
                            branch_name: branch.name  
                        }
                    };
                } else if (intent === 'ask_branch' || intent === 'view_branches') {
                    return {
                        text: buttonText,
                        action: 'view_branch_info',
                        data: {
                            ...bookingContext,
                            branch_id: branch.id,  
                            branch_name: branch.name  
                        }
                    };
                } else if (intent === 'book_table' || intent === 'book_table_partial') {
                    return {
                        text: buttonText,
                        action: 'select_branch_for_booking',
                        data: {
                            ...bookingContext,
                            branch_id: branch.id,  
                            branch_name: branch.name  
                        }
                    };
                } else if (intent === 'order_takeaway') {
                    return {
                        text: buttonText,
                        action: 'select_branch_for_takeaway',
                        data: {
                            ...bookingContext,
                            branch_id: branch.id,  
                            branch_name: branch.name  
                        }
                    };
                } else if (intent === 'order_delivery') {
                    return {
                        text: buttonText,
                        action: 'select_branch_for_delivery',
                        data: {
                            ...bookingContext,
                            branch_id: branch.id,  
                            branch_name: branch.name,  
                            delivery_address: bookingContext?.delivery_address || null
                        }
                    };
                }
            }
            return {
                text: buttonText,
                action: 'view_branch_info',
                data: {
                    branch_id: branch.id,
                    branch_name: branch.name
                }
            };
        }));
        return suggestions;
    }

    async getBranchesByDistrict(districtId) {
        try {
            const branches = await BranchService.getAllBranches('active', null, null, districtId);
            return branches;
        } catch {
            return [];
        }
    }

    isTimeWithinOperatingHours(time, branch) {
        if (!time || !branch || !branch.opening_hours || !branch.close_hours) {
            return false;
        }
        try {
            const [hour, minute] = time.split(':').map(Number);
            const timeInMinutes = hour * 60 + minute;
            const openingInMinutes = branch.opening_hours * 60;
            const closingInMinutes = branch.close_hours * 60;
            if (closingInMinutes < openingInMinutes) {
                return timeInMinutes >= openingInMinutes || timeInMinutes <= closingInMinutes;
            } else {
                return timeInMinutes >= openingInMinutes && timeInMinutes <= closingInMinutes;
            }
        } catch (error) {
            console.error('[BranchIntentHandler] Error checking operating hours:', error.message);
            return false;
        }
    }

    async getBranchesOpenAtTime(time) {
        try {
            const allBranches = await this.getAllActiveBranches();
            return allBranches.filter(branch => this.isTimeWithinOperatingHours(time, branch));
        } catch {
            return [];
        }
    }

    formatOperatingHours(branch) {
        if (!branch) {
            return '';
        }
        const openingHours = branch.opening_hours ? `${branch.opening_hours}h` : '';
        const closeHours = branch.close_hours ? `${branch.close_hours}h` : '';
        if (openingHours && closeHours) {
            return `${openingHours} - ${closeHours}`;
        }
        return openingHours || closeHours || '';
    }

    /**
     * Helper method để lấy branches với suggestions - loại bỏ duplicate code
     * Thay thế pattern: getAllActiveBranches() + createBranchSuggestions()
     * @param {string} intent - Intent (view_menu, book_table, order_delivery, etc.)
     * @param {object} context - Context object với các thông tin bổ sung
     * @returns {Promise<{branches: Array, suggestions: Array}>}
     */
    async getBranchesWithSuggestions(intent, context = {}) {
        try {
            const allBranches = await this.getAllActiveBranches();
            if (allBranches.length === 0) {
                return { branches: [], suggestions: [] };
            }
            const branchSuggestions = await this.createBranchSuggestions(allBranches, {
                intent: intent,
                ...context
            });
            return {
                branches: allBranches,
                suggestions: branchSuggestions
            };
        } catch (error) {
            console.error('[BranchIntentHandler] Error getting branches with suggestions:', error.message);
            return { branches: [], suggestions: [] };
        }
    }

    calculateRemainingMinutes(time, branch) {
        if (!time || !branch || !branch.close_hours) {
            return null;
        }
        try {
            const [hour, minute] = time.split(':').map(Number);
            const timeInMinutes = hour * 60 + minute;
            const closingInMinutes = branch.close_hours * 60;
            if (closingInMinutes < branch.opening_hours * 60) {
                if (timeInMinutes >= branch.opening_hours * 60) {
                    const minutesUntilMidnight = (24 * 60) - timeInMinutes;
                    return minutesUntilMidnight + closingInMinutes;
                } else {
                    return closingInMinutes - timeInMinutes;
                }
            } else {
                if (timeInMinutes <= closingInMinutes) {
                    return closingInMinutes - timeInMinutes;
                } else {
                    return null;
                }
            }
        } catch (error) {
            console.error('[BranchIntentHandler] Error getting branch:', error.message);
            return null;
        }
    }

    checkIfCloseToClosing(time, branch, thresholdMinutes = 60) {
        if (!time || !branch || !branch.close_hours) {
            return null;
        }
        const remainingMinutes = this.calculateRemainingMinutes(time, branch);
        if (remainingMinutes === null) {
            return null;
        }
        if (remainingMinutes <= thresholdMinutes && remainingMinutes > 0) {
            return {
                isClose: true,
                remainingMinutes: remainingMinutes
            };
        }
        return {
            isClose: false,
            remainingMinutes: remainingMinutes
        };
    }
}

// Export instance để các file khác có thể dùng (backward compatibility)
module.exports = BranchIntentHandler;
module.exports.instance = new BranchIntentHandler();
