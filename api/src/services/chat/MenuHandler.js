const knex = require('../../database/knex');
const EntityExtractor = require('./EntityExtractor');
const BranchHandler = require('./BranchHandler');
const Utils = require('./Utils');
const ProductService = require('../ProductService');
const BranchService = require('../BranchService');
const BranchFormatter = require('./helpers/BranchFormatter');
class MenuHandler {
    async handleMenuQuery(userMessage, context) {
        try {
            const entities = await EntityExtractor.extractEntities(userMessage);
            const lastEntities = context.conversationContext?.lastEntities || {};
            const mergedEntities = {
                ...Utils.normalizeEntityFields(lastEntities),
                ...Utils.normalizeEntityFields(entities)
            };
            const lowerMessage = userMessage.toLowerCase().trim();
            const normalized = Utils.normalizeVietnamese(lowerMessage);
            let branchId = mergedEntities.branch_id || context.branch?.id || context.conversationContext?.lastBranchId;
            let branchName = mergedEntities.branch_name || mergedEntities.branch || context.conversationContext?.lastBranch || context.branch?.name;
            if (!branchId && !branchName) {
                const menuBranchPatterns = [
                    /menu\s+(chi\s+nhánh|chi\s+nhanh|branch)\s+(.+)/i,
                    /(?:xem|view|show)\s+menu\s+(?:của|cua|cu|tại|tai|ở|o)\s*(?:CHI\s+NHANH|chi\s+nhánh|chi\s+nhanh|branch)?\s+(.+)/i,
                    /menu\s+(?:của|cua|cu|tại|tai|ở|o)\s*(?:CHI\s+NHANH|chi\s+nhánh|chi\s+nhanh|branch)?\s+(.+)/i,
                ];
                let locationKeyword = null;
                for (const pattern of menuBranchPatterns) {
                    const match = userMessage.match(pattern);
                    if (match && match[1]) {
                        locationKeyword = match[1].trim();
                        locationKeyword = locationKeyword.replace(/^(?:CHI\s+NHANH|chi\s+nhánh|chi\s+nhanh|branch)\s+/i, '').trim();
                        if (locationKeyword && locationKeyword.length > 1) {
                            break;
                        }
                    }
                }
                if (locationKeyword) {
                    try {
                        const foundBranch = await EntityExtractor.extractBranchFromMessage(locationKeyword, mergedEntities);
                        if (foundBranch) {
                            branchId = foundBranch.id;
                            branchName = foundBranch.name;
                            mergedEntities.branch_id = foundBranch.id;
                            mergedEntities.branch_name = foundBranch.name;
                            mergedEntities.branch = foundBranch.name;
                        } else {
                            const allBranches = await BranchHandler.getAllActiveBranches();
                            const normalizedKeyword = Utils.normalizeVietnamese(locationKeyword.toLowerCase());
                            const lowerKeyword = locationKeyword.toLowerCase();
                            let foundBranch = allBranches.find(b => {
                                const normalizedName = Utils.normalizeVietnamese(b.name.toLowerCase());
                                return normalizedName.includes(normalizedKeyword) || 
                                       normalizedKeyword.includes(normalizedName) ||
                                       b.name.toLowerCase().includes(lowerKeyword) || 
                                       lowerKeyword.includes(b.name.toLowerCase());
                            });
                            if (!foundBranch) {
                                foundBranch = allBranches.find(b => {
                                    const address = (b.address_detail || '').toLowerCase();
                                    const normalizedAddress = Utils.normalizeVietnamese(address);
                                    return address.includes(lowerKeyword) ||
                                           lowerKeyword.includes(address) ||
                                           normalizedAddress.includes(normalizedKeyword) ||
                                           normalizedKeyword.includes(normalizedAddress) ||
                                           lowerKeyword.split(/\s+/).some(word => 
                                               word.length > 2 && address.includes(word)
                                           );
                            });
                            }
                            if (foundBranch) {
                                branchId = foundBranch.id;
                                branchName = foundBranch.name;
                                mergedEntities.branch_id = foundBranch.id;
                                mergedEntities.branch_name = foundBranch.name;
                                mergedEntities.branch = foundBranch.name;
                            }
                        }
                    } catch (error) {
                    }
                }
            }
            if (!branchId && !branchName && (lowerMessage.includes('gan nhat') || lowerMessage.includes('gần nhất') || normalized.includes('gan nhat'))) {
                const allBranches = await BranchHandler.getAllActiveBranches();
                if (allBranches.length > 0) {
                    branchId = allBranches[0].id;
                    branchName = allBranches[0].name;
                    mergedEntities.branch_id = branchId;
                    mergedEntities.branch_name = branchName;
                    mergedEntities.branch = branchName;
                }
            }
            if (!branchId && !branchName && (lowerMessage.includes('chi nhanh nay') || lowerMessage.includes('chi nhánh này') || normalized.includes('chi nhanh nay'))) {
                branchId = context.conversationContext?.lastBranchId;
                branchName = context.conversationContext?.lastBranch;
                if (branchId || branchName) {
                    mergedEntities.branch_id = branchId;
                    mergedEntities.branch_name = branchName;
                    mergedEntities.branch = branchName;
                }
            }
            if (!branchId && !branchName) {
                const numberMatch = userMessage.match(/^(\d+)$/);
                if (numberMatch) {
                    const selectedNumber = parseInt(numberMatch[1]);
                    if (context.conversationHistory && context.conversationHistory.length > 0) {
                        for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                            const msg = context.conversationHistory[i];
                            if (msg.message_type === 'bot' && msg.message_content) {
                                const botMessage = msg.message_content;
                                const listMatch = botMessage.match(/(\d+)\.\s+([^\n]+)/g);
                                if (listMatch && listMatch.length > 0) {
                                    const selectedItem = listMatch.find(item => {
                                        const numMatch = item.match(/^(\d+)/);
                                        return numMatch && parseInt(numMatch[1]) === selectedNumber;
                                    });
                                    if (selectedItem) {
                                        const branchNameMatch = selectedItem.match(/\d+\.\s+(.+)/);
                                        if (branchNameMatch && branchNameMatch[1]) {
                                            let extractedBranchName = branchNameMatch[1].trim();
                                            extractedBranchName = extractedBranchName.replace(/^Beast Bite\s*-\s*/i, '').trim();
                                            const foundBranch = await BranchHandler.getBranchByName(extractedBranchName);
                                            if (foundBranch) {
                                                branchId = foundBranch.id;
                                                branchName = foundBranch.name;
                                                mergedEntities.branch_id = branchId;
                                                mergedEntities.branch_name = branchName;
                                                mergedEntities.branch = branchName;
                                                break;
                                            } else {
                                                const keywords = extractedBranchName.split(/\s+/).filter(w => w.length > 2);
                                                for (const keyword of keywords) {
                                                    const foundByKeyword = await BranchHandler.getBranchByName(keyword);
                                                    if (foundByKeyword) {
                                                        branchId = foundByKeyword.id;
                                                        branchName = foundByKeyword.name;
                                                        mergedEntities.branch_id = branchId;
                                                        mergedEntities.branch_name = branchName;
                                                        mergedEntities.branch = branchName;
                                                        break;
                                                    }
                                                }
                                                if (branchId) break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if (!branchId && !branchName) {
                const foundBranch = await EntityExtractor.extractBranchFromMessage(userMessage);
                if (foundBranch) {
                    branchId = foundBranch.id;
                    branchName = foundBranch.name;
                    mergedEntities.branch_id = foundBranch.id;
                    mergedEntities.branch_name = foundBranch.name;
                    mergedEntities.branch = foundBranch.name;
                }
            }
            if (branchName && !branchId) {
                try {
                    const branches = await BranchService.getAllBranches('active', branchName);
                    if (branches.length > 0) {
                        const foundBranch = branches[0];
                        branchId = foundBranch.id;
                        branchName = foundBranch.name;
                        mergedEntities.branch_id = foundBranch.id;
                        mergedEntities.branch_name = foundBranch.name;
                    }
                } catch (error) {
                }
            }
            if (branchId) {
                try {
                    const menuItems = await this.getMenuForOrdering(branchId);
                    const branch = await BranchService.getBranchById(branchId);
                    if (menuItems && menuItems.length > 0) {
                        const menuText = this.formatMenuByCategory(menuItems);
                        const response = `Menu của ${branch?.name || branchName || 'chi nhánh'}:\n\n${menuText}\n\nBạn muốn đặt món nào?`;
                        const suggestions = [
                            {
                                text: `Xem menu ${branch?.name || branchName || 'chi nhánh này'}`,
                                action: 'navigate_menu',
                                data: {
                                    branch_id: branchId,
                                    branch_name: branch?.name || branchName
                                }
                            },
                            {
                                text: 'Đặt bàn tại đây',
                                action: 'book_table',
                                data: {
                                    branch_id: branchId,
                                    branch_name: branch?.name || branchName
                                }
                            }
                        ];
                        return {
                            response,
                            intent: 'view_menu',
                            entities: mergedEntities,
                            suggestions: suggestions 
                        };
                    } else {
                        return {
                            response: `Hiện tại ${branch?.name || branchName || 'chi nhánh này'} chưa có món nào trong menu. Vui lòng liên hệ trực tiếp với nhà hàng.`,
                            intent: 'view_menu',
                            entities: mergedEntities
                        };
                    }
                } catch (error) {
                    return {
                        response: 'Có lỗi khi tải menu từ cơ sở dữ liệu. Vui lòng thử lại sau.',
                        intent: 'view_menu',
                        entities: mergedEntities
                    };
                }
            } else {
                const isMenuRequest = this.isMenuViewRequest(userMessage);
                if (isMenuRequest) {
                } else {
                    const searchKeyword = this.extractFoodSearchKeyword(userMessage);
                    if (searchKeyword && searchKeyword !== 'món ăn' && searchKeyword.length >= 2) {
                        try {
                            const ToolHandlers = require('./ToolHandlers');
                            const searchParams = {
                                keyword: searchKeyword,
                                branch_id: null, 
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
                                    if (product.category) {
                                        responseText += `\n   ${product.category}`;
                                    }
                                    responseText += '\n\n';
                                });
                                responseText += 'Bạn muốn xem chi tiết món nào hoặc đặt món?';
                                return {
                                    response: responseText,
                                    intent: 'view_menu',
                                    entities: mergedEntities
                                };
                            } else {
                                const allBranches = await BranchHandler.getAllActiveBranches();
                                if (allBranches.length > 0) {
                                    const branchList = await BranchFormatter.formatBranchListWithDetails(allBranches);
                                    return {
                                        response: `Tôi không tìm thấy món "${searchKeyword}" trong menu.\n\nBạn có thể:\n• Xem menu theo chi nhánh:\n\n${branchList.join('\n\n')}\n\n• Hoặc thử tìm kiếm với từ khóa khác`,
                                        intent: 'view_menu',
                                        entities: mergedEntities,
                                        suggestions: []
                                    };
                                }
                            }
                        } catch (error) {
                        }
                    }
                }
                try {
                    const allBranches = await BranchHandler.getAllActiveBranches();
                    if (allBranches.length > 0) {
                        const branchSuggestions = await BranchHandler.createBranchSuggestions(allBranches, {
                            intent: 'view_menu'
                        });
                        return {
                            response: `Chọn chi nhánh để xem menu:\n\nBạn muốn xem menu của chi nhánh nào? Vui lòng chọn một chi nhánh từ danh sách bên dưới:`,
                            intent: 'view_menu',
                            entities: mergedEntities,
                            suggestions: branchSuggestions 
                        };
                    } else {
                        return {
                            response: 'Tôi chưa lấy được dữ liệu chi nhánh đang hoạt động từ hệ thống. Vui lòng liên hệ trực tiếp với nhà hàng.',
                            intent: 'view_menu',
                            entities: mergedEntities
                        };
                    }
                } catch (error) {
                    return {
                        response: 'Có lỗi khi tải danh sách chi nhánh từ cơ sở dữ liệu. Vui lòng thử lại sau.',
                        intent: 'view_menu',
                        entities: mergedEntities
                    };
                }
            }
        } catch (error) {
            return null; 
        }
    }
    async getMenuForOrdering(branchId) {
        try {
            const result = await ProductService.getAvailableProducts({
                branch_id: branchId,
                page: 1,
                limit: 1000 
            });
            return result.products.map(p => ({
                id: p.id,
                name: p.name,
                description: p.description,
                image: p.image,
                price: p.display_price || p.price || p.branch_price,
                category_name: p.category_name
            }));
        } catch (error) {
            return [];
        }
    }
    async getMenuItemsByCategory(branchId, categoryKeyword) {
        try {
            const result = await ProductService.getAvailableProducts({
                branch_id: branchId,
                page: 1,
                limit: 1000
            });
            const normalizedKeyword = categoryKeyword.toLowerCase().trim();
            const filteredProducts = result.products.filter(p => {
                const catName = (p.category_name || '').toLowerCase();
                return catName.includes(normalizedKeyword) || normalizedKeyword.includes(catName);
            });
            return filteredProducts.map(p => ({
                id: p.id,
                name: p.name,
                description: p.description,
                image: p.image,
                price: p.display_price || p.price || p.branch_price,
                category_name: p.category_name
            }));
        } catch (error) {
            return [];
        }
    }
    isMenuViewRequest(message) {
        const lower = message.toLowerCase();
        const normalized = Utils.normalizeVietnamese(lower);
        const menuViewPatterns = [
            /(xem|view|show|hiển thị|hien thi)\s+(menu|thực đơn|thuc don)/i,
            /menu\s+(chi nhánh|chi nhanh|branch|của|cu)/i,
            /(thực đơn|thuc don|menu)\s+(của|cu|tại|tai|ở|o)/i,
            /(xem|view|show)\s+(menu|thực đơn|thuc don)/i,
            /menu$/i, 
            /^menu\s/i, 
        ];
        for (const pattern of menuViewPatterns) {
            if (pattern.test(message) || pattern.test(normalized)) {
                return true;
            }
        }
        const isJustMenu = /^(xem|view|show)?\s*menu\s*$/i.test(message) || 
                          /^(xem|view|show)?\s*thực đơn\s*$/i.test(message) ||
                          /^(xem|view|show)?\s*thuc don\s*$/i.test(normalized);
        if (isJustMenu) {
            return true;
        }
        return false;
    }
    extractFoodSearchKeyword(message) {
        if (this.isMenuViewRequest(message)) {
            return null;
        }
        const lower = message.toLowerCase();
        const normalized = Utils.normalizeVietnamese(lower);
        const hasPattern = lower.match(/(có|co)\s+(\w+)\s+(không|khong)/i);
        if (hasPattern && hasPattern[2].length >= 2) {
            return hasPattern[2]; 
        }
        const hasWhatPattern = lower.match(/(có|co)\s+(món|mon)\s+(gì|gi)/i);
        if (hasWhatPattern) {
            return 'món ăn'; 
        }
        const menuWords = ['menu', 'thực đơn', 'thuc don', 'xem', 'view', 'show', 'hiển thị', 'hien thi'];
        let keyword = lower;
        for (const word of menuWords) {
            keyword = keyword.replace(new RegExp(word, 'gi'), '').trim();
        }
        const searchWords = ['tìm', 'tim', 'search', 'tìm kiếm', 'tim kiem', 'có', 'co', 'món', 'mon', 'gì', 'gi', 'nào', 'nao', 'không', 'khong', 'chi nhánh', 'chi nhanh', 'branch'];
        for (const word of searchWords) {
            keyword = keyword.replace(new RegExp(word, 'gi'), '').trim();
        }
        keyword = keyword.replace(/\s+/g, ' ').trim();
        if (keyword.length < 2) {
            return null;
        }
        if (menuWords.some(word => keyword.includes(word))) {
            return null;
        }
        return keyword;
    }
    async searchFoodItems(keyword, branchId = null) {
        try {
            if (!branchId) {
                return [];
            }
            const result = await ProductService.getAvailableProducts({
                branch_id: branchId,
                page: 1,
                limit: 1000
            });
            const searchPattern = keyword.toLowerCase();
            const filteredProducts = result.products.filter(p => {
                const name = (p.name || '').toLowerCase();
                const description = (p.description || '').toLowerCase();
                const categoryName = (p.category_name || '').toLowerCase();
                return name.includes(searchPattern) || 
                       description.includes(searchPattern) || 
                       categoryName.includes(searchPattern);
            });
            return filteredProducts.slice(0, 10).map(p => ({
                id: p.id,
                name: p.name,
                description: p.description,
                image: p.image,
                price: p.display_price || p.price || p.branch_price,
                category_name: p.category_name,
                branch_id: branchId
            }));
        } catch (error) {
            throw error; 
        }
    }
    formatMenuByCategory(menuItems) {
        if (!menuItems || menuItems.length === 0) {
            return '';
        }
        const menuByCategory = {};
        menuItems.forEach(item => {
            const category = item.category_name || 'Khác';
            if (!menuByCategory[category]) {
                menuByCategory[category] = [];
            }
            menuByCategory[category].push(item);
        });
        const menuText = Object.keys(menuByCategory).map(category => {
            const items = menuByCategory[category];
            const itemsText = items.map(item => 
                `• ${item.name} - ${item.price.toLocaleString()}đ\n  ${item.description || ''}`
            ).join('\n\n');
            return `${category}\n${itemsText}`;
        }).join('\n\n');
        return menuText;
    }
    async _formatBranchListWithDetails(branches) {
        return await BranchFormatter.formatBranchListWithDetails(branches);
    }
}
module.exports = new MenuHandler();
