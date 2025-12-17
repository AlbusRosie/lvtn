const BaseIntentHandler = require('./BaseIntentHandler');
const MenuIntentHandler = require('./MenuIntentHandler');
const ToolHandlers = require('../ToolHandlers');
const Utils = require('../Utils');
const MenuHandler = MenuIntentHandler.instance;
class SearchIntentHandler extends BaseIntentHandler {
    constructor() {
        super();
        this.intentSet = new Set(['search_food', 'search_product', 'search_branches_by_location']);
    }
    canHandle(intent, _context, metadata = {}) {
        return this.intentSet.has(intent) || metadata?.isSearchQuery;
    }
    async handle({ intent, message, context, entities, aiResponse }) {
        if (aiResponse && aiResponse.tool_results && aiResponse.tool_results.length > 0) {
            const normalized = Utils.normalizeEntityFields(entities || {});
            return this.buildResponse({
                intent: aiResponse.intent || intent || 'search_product',
                response: aiResponse.response,
                entities: normalized,
                suggestions: aiResponse.suggestions || [],
            });
        }
        const keyword = MenuHandler.extractFoodSearchKeyword(message);
        if (!keyword || keyword === 'món ăn') {
            const result = await MenuHandler.handleMenuQuery(message, context);
            if (result) {
                return result;
            }
        } else {
            try {
                const normalizedEntities = Utils.normalizeEntityFields(entities || {});
                const branchId = normalizedEntities.branch_id || context.branch?.id || context.conversationContext?.lastBranchId;
                const searchParams = {
                    keyword: keyword,
                    branch_id: branchId || null, 
                    limit: 10
                };
                const searchResult = await ToolHandlers.searchProducts(searchParams);
                if (searchResult && searchResult.products && searchResult.products.length > 0) {
                    const products = searchResult.products;
                    let responseText = `Tìm thấy ${products.length} món:\n\n`;
                    products.forEach((product, idx) => {
                        responseText += `${idx + 1}. ${product.name}`;
                        if (product.price) {
                            responseText += ` - ${product.price.toLocaleString()}đ`;
                        }
                        if (product.description) {
                            responseText += `\n   ${product.description}`;
                        }
                        if (product.category_name) {
                            responseText += `\n   ${product.category_name}`;
                        }
                        responseText += '\n\n';
                    });
                    responseText += 'Bạn muốn xem chi tiết món nào hoặc đặt món?';
                    return this.buildResponse({
                        intent: intent || 'search_food',
                        response: responseText,
                        entities: normalizedEntities,
                        suggestions: []
                    });
                } else {
                    return this.buildResponse({
                        intent: intent || 'search_food',
                        response: `Tôi không tìm thấy món nào với từ khóa "${keyword}". Bạn có thể thử tìm kiếm với từ khóa khác hoặc cho tôi biết chi nhánh cụ thể không?`,
                        entities: normalizedEntities,
                    });
                }
            } catch {
                const result = await MenuHandler.handleMenuQuery(message, context);
                if (result) {
                    return result;
                }
            }
        }
        const normalized = Utils.normalizeEntityFields(entities || {});
        return this.buildResponse({
            intent: intent || 'search_food',
            response: 'Tôi chưa tìm thấy kết quả phù hợp. Bạn có thể mô tả chi tiết hơn về món ăn hoặc chi nhánh bạn cần không?',
            entities: normalized,
        });
    }
}
module.exports = SearchIntentHandler;
