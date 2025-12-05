const BaseIntentHandler = require('./BaseIntentHandler');
const MenuHandler = require('../MenuHandler');
const BranchHandler = require('../BranchHandler');
const Utils = require('../Utils');
class MenuIntentHandler extends BaseIntentHandler {
    constructor() {
        super();
        this.intentSet = new Set(['view_menu', 'view_menu_specific_branch', 'order_food', 'order_food_specific_branch']);
    }
    canHandle(intent) {
        return this.intentSet.has(intent);
    }
    async handle({ intent, message, context, entities, aiResponse }) {
        if (aiResponse && aiResponse.tool_results && aiResponse.tool_results.length > 0) {
            const normalized = Utils.normalizeEntityFields(entities || {});
            let suggestions = aiResponse.suggestions || [];
            const hasGetAllBranches = aiResponse.tool_results.some(r => r.tool === 'get_all_branches' && r.success);
            const hasGetBranchMenu = aiResponse.tool_results.some(r => r.tool === 'get_branch_menu' && r.success);
            if (hasGetAllBranches && !hasGetBranchMenu) {
                const messageLower = (message || '').toLowerCase();
                const hasBranchName = /(chi\s+nhánh|chi\s+nhanh|branch)\s+([^?.,!]+)/i.test(message) ||
                                     /menu\s+(của|cua|chi\s+nhánh|chi\s+nhanh)\s+([^?.,!]+)/i.test(message) ||
                                     /(xem|view)\s+menu\s+(của|cua|chi\s+nhánh|chi\s+nhanh)\s+([^?.,!]+)/i.test(message);
                if (hasBranchName) {
                    try {
                        const branchMatch = message.match(/(?:chi\s+nhánh|chi\s+nhanh|branch)\s+([^?.,!]+)/i) ||
                                          message.match(/menu\s+(?:của|cua|chi\s+nhánh|chi\s+nhanh)\s+([^?.,!]+)/i) ||
                                          message.match(/(?:xem|view)\s+menu\s+(?:của|cua|chi\s+nhánh|chi\s+nhanh)\s+([^?.,!]+)/i);
                        if (branchMatch && branchMatch[1]) {
                            const searchTerm = branchMatch[1].trim();
                            const branchesResult = aiResponse.tool_results.find(r => r.tool === 'get_all_branches' && r.success);
                            if (branchesResult && branchesResult.result && branchesResult.result.branches) {
                                const allBranches = branchesResult.result.branches;
                                const normalizedSearch = searchTerm.toLowerCase().trim();
                                let foundBranch = allBranches.find(b => {
                                    const branchName = (b.name || '').toLowerCase().replace(/^beast\s+bite\s*-\s*/i, '').trim();
                                    const address = (b.address_detail || '').toLowerCase();
                                    const district = (b.district || '').toLowerCase();
                                    return branchName.includes(normalizedSearch) ||
                                           normalizedSearch.includes(branchName) ||
                                           address.includes(normalizedSearch) ||
                                           normalizedSearch.includes(address) ||
                                           district.includes(normalizedSearch) ||
                                           normalizedSearch.includes(district);
                                });
                                if (!foundBranch && normalizedSearch.split(/\s+/).length > 1) {
                                    const words = normalizedSearch.split(/\s+/).filter(w => w.length > 2);
                                    for (const word of words) {
                                        foundBranch = allBranches.find(b => {
                                            const branchName = (b.name || '').toLowerCase().replace(/^beast\s+bite\s*-\s*/i, '').trim();
                                            const address = (b.address_detail || '').toLowerCase();
                                            const district = (b.district || '').toLowerCase();
                                            return branchName.includes(word) || address.includes(word) || district.includes(word);
                                        });
                                        if (foundBranch) break;
                                    }
                                }
                                if (foundBranch) {
                                    const ToolOrchestrator = require('../ToolOrchestrator');
                                    const menuResult = await ToolOrchestrator.executeToolCall(
                                        'get_branch_menu',
                                        { branch_id: foundBranch.id },
                                        { userId: context.user?.id || null, role: context.user?.role_id || null }
                                    );
                                    if (menuResult.success && menuResult.data) {
                                        const menu = menuResult.data.menu || {};
                                        const categories = Object.keys(menu);
                                        let response = `📋 Menu của ${foundBranch.name}:\n\n`;
                                        categories.forEach(category => {
                                            const items = menu[category] || [];
                                            if (items.length > 0) {
                                                response += `🍽️ ${category}\n`;
                                                items.forEach(item => {
                                                    response += `• ${item.name} - ${item.price?.toLocaleString() || 'N/A'}đ\n`;
                                                    if (item.description) {
                                                        response += `  ${item.description}\n`;
                                                    }
                                                });
                                                response += `\n`;
                                            }
                                        });
                                        response += `Bạn muốn đặt món nào?`;
                                        suggestions = [{
                                            text: `🍽️ Xem menu ${foundBranch.name}`,
                                            action: 'navigate_menu',
                                            data: {
                                                branch_id: foundBranch.id,
                                                branch_name: foundBranch.name
                                            }
                                        }];
                                        aiResponse.tool_results.push({
                                            tool: 'get_branch_menu',
                                            success: true,
                                            result: menuResult.data
                                        });
                                        aiResponse.response = response;
                                        aiResponse.intent = 'view_menu';
                                        }
                                } else {
                                    }
                            }
                        }
                    } catch (error) {
                        }
                }
            }
            if (hasGetAllBranches && !hasGetBranchMenu && (aiResponse.intent === 'view_menu' || intent === 'view_menu')) {
                try {
                    const allBranches = await BranchHandler.getAllActiveBranches();
                    if (allBranches.length > 0) {
                        const branchSuggestions = await BranchHandler.createBranchSuggestions(allBranches, {
                            intent: 'view_menu'
                        });
                        suggestions = branchSuggestions;
                        }
                } catch (error) { }
            }
            return this.buildResponse({
                intent: aiResponse.intent || intent || 'view_menu',
                response: aiResponse.response,
                entities: normalized,
                suggestions: suggestions,
            });
        }
        const result = await MenuHandler.handleMenuQuery(message, context);
        if (result) {
            return result;
        }
        const normalized = Utils.normalizeEntityFields(entities || {});
        return this.buildResponse({
            intent: intent || 'view_menu',
            response: 'Tôi chưa xác định được chi nhánh để hiển thị menu. Bạn có thể cho tôi biết chi nhánh cụ thể không?',
            entities: normalized,
        });
    }
}
module.exports = MenuIntentHandler;
