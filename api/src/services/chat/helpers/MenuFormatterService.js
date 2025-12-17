/**
 * MenuFormatterService - Service để format menu theo category
 * Loại bỏ duplicate code trong AIService, MenuIntentHandler, LegacyFallbackService, ToolHandlers
 */
class MenuFormatterService {
    /**
     * Group products theo category
     * @param {Array} products - Danh sách products
     * @returns {object} Object với key là category name, value là array of products
     */
    groupByCategory(products) {
        if (!products || !Array.isArray(products)) {
            return {};
        }

        const groupedMenu = {};
        
        products.forEach(product => {
            const category = product.category_name || product.category || 'Khác';
            if (!groupedMenu[category]) {
                groupedMenu[category] = [];
            }
            
            groupedMenu[category].push({
                id: product.id,
                name: product.name,
                description: product.description,
                price: product.display_price || product.price || product.branch_price,
                image: product.image,
                is_available: product.is_available === 1 || product.is_available === true,
                category_id: product.category_id,
                category_name: category
            });
        });
        
        return groupedMenu;
    }

    /**
     * Format menu thành text string
     * @param {object} groupedMenu - Menu đã được group by category
     * @param {object} options - Options: { maxCategories, maxItemsPerCategory, includeDescription }
     * @returns {string} Formatted menu text
     */
    formatMenuAsText(groupedMenu, options = {}) {
        const maxCategories = options.maxCategories || 10;
        const maxItemsPerCategory = options.maxItemsPerCategory || 20;
        const includeDescription = options.includeDescription !== false;
        
        if (!groupedMenu || Object.keys(groupedMenu).length === 0) {
            return 'Menu không có sẵn.';
        }

        let text = '';
        let count = 0;
        
        for (const [category, items] of Object.entries(groupedMenu)) {
            if (count >= maxCategories) break;
            
            if (items.length > 0) {
                text += `${category}\n`;
                items.slice(0, maxItemsPerCategory).forEach(item => {
                    const price = item.price ? new Intl.NumberFormat('vi-VN').format(item.price) : 'N/A';
                    text += `• ${item.name} - ${price}đ\n`;
                    if (includeDescription && item.description) {
                        text += `  ${item.description}\n`;
                    }
                });
                text += `\n`;
                count++;
            }
        }
        
        const totalCategories = Object.keys(groupedMenu).length;
        if (totalCategories > maxCategories) {
            text += `... và ${totalCategories - maxCategories} danh mục khác\n\n`;
        }
        
        return text.trim();
    }
}

module.exports = new MenuFormatterService();

