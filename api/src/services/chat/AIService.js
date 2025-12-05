const IntentDetector = require('./IntentDetector');
const EntityExtractor = require('./EntityExtractor');
const Utils = require('./Utils');
const ToolOrchestrator = require('./ToolOrchestrator');
const { USER_ROLES } = require('./ToolRegistry');
class AIService {
    constructor() {
        this.geminiEnabled = !!process.env.GEMINI_API_KEY;
        this.genAI = null;
        this.geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
        if (this.geminiEnabled) {
            try {
                const { GoogleGenerativeAI } = require('@google/generative-ai');
                this.genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
            } catch (err) {
                this.geminiEnabled = false;
            }
        }
    }
    async callAI(message, context, fallback) {
        try {
            const userRole = this._getUserRole(context);
            if (!this.geminiEnabled || !this.genAI) {
                return await this._ruleBasedToolCalling(message, context, userRole, fallback);
            }
            const availableTools = ToolOrchestrator.getAvailableToolsForLLM(userRole);
            const response = await this._callGeminiWithRetry(message, context, availableTools);
            if (response.functionCalls && response.functionCalls.length > 0) {
                return await this._handleGeminiFunctionCalls(response.functionCalls, message, context);
            }
            const intent = this._extractIntentFromMessage(response.text, message);
            const entities = await EntityExtractor.extractEntities(message);
            return {
                intent,
                entities: Utils.normalizeEntityFields(entities),
                response: response.text,
                source: 'gemini_direct'
            };
        } catch (error) {
            return await fallback(message, context);
        }
    }
    async _ruleBasedToolCalling(message, context, userRole, fallback) {
        try {
            if (/(có món|co mon|tìm món|tim mon|món nào|mon nao|có gì|co gi|có nước|co nuoc|nước gì|nuoc gi|đồ uống|do uong|để uống|de uong)/i.test(message)) {
                const keyword = this._extractSearchKeyword(message);
                if (keyword) {
                    const result = await ToolOrchestrator.executeToolCall(
                        'search_products',
                        { keyword, limit: 10 },
                        { userId: context.user?.id || null, role: userRole }
                    );
                    if (result.success && result.data) {
                        const products = result.data.products || [];
                        let response = '';
                        const isDrinksSearch = /(nước|nuoc|uống|uong|drink|nước|cafe|coffee|tea|trà|tra)/i.test(keyword);
                        const emoji = isDrinksSearch ? '🥤' : '🔍';
                        if (products.length > 0) {
                            response = `${emoji} Tôi tìm thấy ${products.length} món có "${keyword}":\n\n`;
                            products.forEach((p, idx) => {
                                response += `${idx + 1}. ${p.name}\n`;
                                response += `   💰 ${this._formatPrice(p.price)}\n`;
                                if (p.description) {
                                    response += `   📝 ${p.description}\n`;
                                }
                                response += `\n`;
                            });
                            response += `Bạn muốn xem chi tiết món nào?`;
                        } else {
                            response = `Xin lỗi, tôi không tìm thấy món nào có "${keyword}" 😔\n\nBạn có thể thử tìm món khác hoặc xem menu đầy đủ.`;
                        }
                        return {
                            intent: 'search_product',
                            entities: { keyword },
                            response,
                            tool_results: [{ tool: 'search_products', success: true, result: result.data }]
                        };
                    }
                }
            }
            if (/(giao hàng|giao hang|delivery|đặt đơn giao|dat don giao)/i.test(message)) {
                const result = await ToolOrchestrator.executeToolCall(
                    'get_all_branches',
                    {},
                    { userId: context.user?.id || null, role: userRole }
                );
                if (result.success && result.data) {
                    let response = 'Bạn muốn đặt món giao hàng từ chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:';
                    return {
                        intent: 'order_delivery', 
                        entities: {},
                        response,
                        tool_results: [{ tool: 'get_all_branches', success: true, result: result.data }]
                    };
                }
            }
            if (/(đặt đơn|dat don|đặt món mang về|dat mon mang ve|takeaway|mang về|mang ve)/i.test(message)) {
                const result = await ToolOrchestrator.executeToolCall(
                    'get_all_branches',
                    {},
                    { userId: context.user?.id || null, role: userRole }
                );
                if (result.success && result.data) {
                    let response = 'Bạn muốn đặt món mang về từ chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:';
                    return {
                        intent: 'order_takeaway', 
                        entities: {},
                        response,
                        tool_results: [{ tool: 'get_all_branches', success: true, result: result.data }]
                    };
                }
            }
            if (/(chi nhánh gần nhất|gần nhất|gần tôi|nearest|closest|chi nhanh gan nhat|gan nhat|gan toi)/i.test(message)) {
                return {
                    intent: 'find_nearest_branch',
                    entities: {},
                    response: null, 
                    tool_results: []
                };
            }
            if (/(chi nhánh ở|chi nhanh o|chi nhánh tại|chi nhanh tai|nhánh ở|nhanh o|nap o|nằm ở|nam o)/i.test(message)) {
                const locationKeyword = this._extractLocationKeyword(message);
                if (locationKeyword) {
                    const result = await ToolOrchestrator.executeToolCall(
                        'get_all_branches',
                        {},
                        { userId: context.user?.id || null, role: userRole }
                    );
                    if (result.success && result.data) {
                        const allBranches = result.data.branches || [];
                        const filteredBranches = allBranches.filter(b => {
                            const searchText = `${b.name} ${b.address} ${b.district}`.toLowerCase();
                            return searchText.includes(locationKeyword.toLowerCase());
                        });
                        let response = '';
                        if (filteredBranches.length > 0) {
                            response = `🏢 Tìm thấy ${filteredBranches.length} chi nhánh tại "${locationKeyword}":\n\n`;
                            filteredBranches.forEach((b, idx) => {
                                response += `${idx + 1}. ${b.name}\n`;
                                response += `   📍 ${b.address}, ${b.district}\n`;
                                response += `   📞 ${b.phone}\n`;
                                response += `   🕐 ${b.operating_hours.open} - ${b.operating_hours.close}\n\n`;
                            });
                            response += `Bạn muốn xem chi tiết chi nhánh nào?`;
                        } else {
                            response = `😔 Nhà hàng không có chi nhánh tại "${locationKeyword}".\n\nBạn có thể:\n• Xem tất cả ${allBranches.length} chi nhánh của chúng tôi\n• Tìm chi nhánh tại quận/huyện khác`;
                        }
                        return {
                            intent: 'search_branches_by_location',
                            entities: { location: locationKeyword },
                            response,
                            tool_results: [{ tool: 'get_all_branches', success: true, result: result.data }]
                        };
                    }
                }
            }
            if (/(xem menu|menu|thực đơn|thuc don)\s+(của|cua|cu|tại|tai|ở|o)\s*(?:CHI\s+NHANH|chi\s+nhánh|chi\s+nhanh|branch)?\s*(.+)/i.test(message) ||
                /(?:CHI\s+NHANH|chi\s+nhánh|chi\s+nhanh|branch)\s+(.+)\s+(?:menu|thực đơn|thuc don)/i.test(message)) {
                let branchName = null;
                const menuBranchPattern1 = /(?:xem\s+menu|menu|thực đơn|thuc don)\s+(?:của|cua|cu|tại|tai|ở|o)\s*(?:CHI\s+NHANH|chi\s+nhánh|chi\s+nhanh|branch)?\s*(.+)/i;
                const menuBranchPattern2 = /(?:CHI\s+NHANH|chi\s+nhánh|chi\s+nhanh|branch)\s+(.+)\s+(?:menu|thực đơn|thuc don)/i;
                const match1 = message.match(menuBranchPattern1);
                const match2 = message.match(menuBranchPattern2);
                if (match1 && match1[1]) {
                    branchName = match1[1].trim();
                } else if (match2 && match2[1]) {
                    branchName = match2[1].trim();
                }
                if (branchName) {
                    branchName = branchName.replace(/^Beast\s+Bite\s*-\s*/i, '').trim();
                }
                const genericKeywords = ['quan an', 'nha hang', 'restaurant', 'nhà hàng', 'quán ăn', 'cua quan', 'cua nha hang'];
                const isGenericRequest = genericKeywords.some(keyword => 
                    branchName && branchName.toLowerCase().includes(keyword)
                );
                if (branchName && branchName.length > 2 && !isGenericRequest) {
                    const EntityExtractor = require('./EntityExtractor');
                    const entities = await EntityExtractor.extractEntities(message);
                    const branchesParams = {};
                    if (entities.district_id) {
                        branchesParams.district_id = entities.district_id;
                        }
                    if (entities.province_id) {
                        branchesParams.province_id = entities.province_id;
                        }
                    const branchesResult = await ToolOrchestrator.executeToolCall(
                        'get_all_branches',
                        branchesParams,
                        { userId: context.user?.id || null, role: userRole }
                    );
                    if (branchesResult.success && branchesResult.data) {
                        const allBranches = branchesResult.data.branches || [];
                        let foundBranch = null;
                        if (allBranches.length === 1 && (entities.district_id || entities.province_id)) {
                            foundBranch = allBranches[0];
                        } else {
                            const normalizedBranchName = branchName.toLowerCase().trim();
                            foundBranch = allBranches.find(b => {
                                const normalizedBranch = b.name.toLowerCase().replace(/^beast\s+bite\s*-\s*/i, '').trim();
                                return normalizedBranch.includes(normalizedBranchName) || 
                                       normalizedBranchName.includes(normalizedBranch) ||
                                       b.name.toLowerCase().includes(normalizedBranchName);
                            });
                            if (!foundBranch) {
                                foundBranch = allBranches.find(b => {
                                    const address = (b.address_detail || '').toLowerCase();
                                    return address.includes(normalizedBranchName) ||
                                           normalizedBranchName.includes(address) ||
                                           normalizedBranchName.split(/\s+/).some(word => 
                                               word.length > 2 && address.includes(word)
                                           );
                                });
                            }
                            if (!foundBranch && normalizedBranchName.split(/\s+/).length > 1) {
                                const words = normalizedBranchName.split(/\s+/).filter(w => w.length > 2);
                                for (const word of words) {
                                    foundBranch = allBranches.find(b => {
                                        const normalizedBranch = b.name.toLowerCase().replace(/^beast\s+bite\s*-\s*/i, '').trim();
                                        const address = (b.address_detail || '').toLowerCase();
                                        return normalizedBranch.includes(word) || 
                                               address.includes(word);
                                    });
                                    if (foundBranch) break;
                                }
                            }
                            if (!foundBranch && allBranches.length > 0 && (entities.district_id || entities.province_id)) {
                                foundBranch = allBranches[0];
                            }
                        }
                        if (foundBranch) {
                            const menuResult = await ToolOrchestrator.executeToolCall(
                                'get_branch_menu',
                                { branch_id: foundBranch.id },
                                { userId: context.user?.id || null, role: userRole }
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
                                return {
                                    intent: 'view_menu',
                                    entities: { 
                                        branch_id: foundBranch.id, 
                                        branch_name: foundBranch.name 
                                    },
                                    response,
                                    tool_results: [
                                        { tool: 'get_all_branches', success: true, result: branchesResult.data },
                                        { tool: 'get_branch_menu', success: true, result: menuResult.data }
                                    ]
                                };
                            }
                        } else {
                        }
                    }
                } else if (isGenericRequest) {
                }
            }
            if (/(có những loại|co nhung loai|loại món|loai mon|danh mục|danh muc|category)/i.test(message)) {
                const result = await ToolOrchestrator.executeToolCall(
                    'get_categories',
                    {},
                    { userId: context.user?.id || null, role: userRole }
                );
                if (result.success && result.data) {
                    const categories = result.data.categories || [];
                    let response = `📂 Beast Bite có ${result.data.total} loại món:\n\n`;
                    categories.forEach((c, idx) => {
                        response += `${idx + 1}. ${c.name}\n`;
                        if (c.description) {
                            response += `   ${c.description}\n`;
                        }
                        response += `\n`;
                    });
                    response += `Bạn muốn xem món nào?`;
                    return {
                        intent: 'view_categories',
                        entities: {},
                        response,
                        tool_results: [{ tool: 'get_categories', success: true, result: result.data }]
                    };
                }
            }
            return await fallback(message, context);
        } catch (error) {
            return await fallback(message, context);
        }
    }
    _extractSearchKeyword(message) {
        const patterns = [
            /(?:có|co)?\s*([a-zàáảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ]+)\s+(?:gì|gi|nào|nao)/i,
            /(?:có món|co mon|tìm món|tim mon|món nào|mon nao)\s+([a-zàáảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ\s]+)/i,
            /(?:tìm|tim|có|co)\s+([a-zàáảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ]+)(?:\s+(?:không|khong|nào|nao))?/i
        ];
        for (const pattern of patterns) {
            const match = message.match(pattern);
            if (match && match[1]) {
                const keyword = match[1].trim();
                const excludeWords = ['gì', 'gi', 'nào', 'nao', 'không', 'khong', 'món', 'mon'];
                if (!excludeWords.includes(keyword.toLowerCase())) {
                    return keyword;
                }
            }
        }
        if (/(?:có gì|co gi)/i.test(message)) {
            return ''; 
        }
        return null;
    }
    _extractLocationKeyword(message) {
        const patterns = [
            /(?:chi nhánh|chi nhanh|nhánh|nhanh|nap)\s+(?:ở|o|tại|tai)\s+([a-zàáảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ\s]+?)(?:\s+(?:không|khong|nào|nao|gì|gi))?$/i,
            /(?:nằm|nam)\s+(?:ở|o)\s+([a-zàáảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ\s]+?)(?:\s+(?:không|khong|nào|nao))?$/i
        ];
        for (const pattern of patterns) {
            const match = message.match(pattern);
            if (match && match[1]) {
                let location = match[1].trim();
                location = location.replace(/\s+(không|khong|nào|nao|gì|gi)$/i, '').trim();
                return location;
            }
        }
        return null;
    }
    _formatPrice(price) {
        if (!price) return 'Liên hệ';
        const numPrice = typeof price === 'string' ? parseFloat(price) : price;
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(numPrice);
    }
    _getUserRole(context) {
        if (context.user && context.user.role) {
            return context.user.role;
        }
        if (context.user && context.user.id) {
            return USER_ROLES.CUSTOMER;
        }
        return USER_ROLES.GUEST;
    }
    _buildSystemPrompt(context, availableTools) {
        const userName = context.user?.full_name || 'Khách';
        const branchName = context.branch?.name || 'chưa chọn chi nhánh';
        const currentTime = new Date().toLocaleString('vi-VN');
        const lastBranchId = context.conversationContext?.lastBranchId;
        const lastBranch = context.conversationContext?.lastBranch;
        const lastIntent = context.conversationContext?.lastIntent;
        const lastReservationId = context.conversationContext?.lastReservationId;
        const isBookingFlow = lastIntent === 'book_table' && lastBranchId;
        const hasRecentBooking = (lastIntent === 'book_table_confirmed' || lastIntent === 'reservation_confirmed') && lastBranchId;
        if (isBookingFlow) {
            } else if (hasRecentBooking) {
            } else {
            }
        return `Bạn là trợ lý ảo thông minh của nhà hàng Beast Bite tại Việt Nam.
🎯 NHIỆM VỤ:
- Giúp khách hàng đặt bàn, xem menu, tìm món ăn/đồ uống, tra cứu đơn hàng
- Trả lời bằng tiếng Việt TỰ NHIÊN, THÂN THIỆN, NHIỆT TÌNH
- ⚠️ BẮT BUỘC SỬ DỤNG TOOLS để lấy dữ liệu THỰC từ database
- KHÔNG BAO GIỜ bịa đặt thông tin hoặc trả lời mà không gọi tool
📊 CONTEXT HIỆN TẠI:
- Thời gian: ${currentTime}
- Khách hàng: ${userName}
- Chi nhánh: ${branchName}
- User ID: ${context.user?.id || 'Guest'}
${isBookingFlow ? `\n🪑 BOOKING CONTEXT:\n- ✅ User ĐÃ CHỌN chi nhánh: ${lastBranch} (ID: ${lastBranchId})\n- ⚠️ QUAN TRỌNG: Không hỏi lại chi nhánh! Dùng branch_id=${lastBranchId} cho check_table_availability` : ''}
${hasRecentBooking ? `\n📋 RECENT BOOKING CONTEXT:\n- ✅ User VỪA ĐẶT BÀN tại: ${lastBranch} (ID: ${lastBranchId})${lastReservationId ? `, Mã đặt bàn: #${lastReservationId}` : ''}\n- ⚠️ QUAN TRỌNG: Khi user hỏi "chi nhánh tôi vừa đặt bàn", "trong chi nhánh tôi vừa đặt bàn", "chi nhánh này", v.v. → LUÔN dùng branch_id=${lastBranchId} cho get_branch_menu, search_products, v.v.\n- KHÔNG BAO GIỜ hỏi lại "Bạn muốn xem chi nhánh nào?"` : ''}
🛠️ TOOLS KHẢ DỤNG (${availableTools.length} tools):
${availableTools.slice(0, 10).map(t => `• ${t.function.name}: ${t.function.description}`).join('\n')}
${availableTools.length > 10 ? `... và ${availableTools.length - 10} tools khác` : ''}
⚠️ QUY TẮC BẮT BUỘC - PHẢI TUÂN THỦ:
1. 🔍 KHI KHÁCH HỎI VỀ MÓN ĂN/ĐỒ UỐNG:
   ✅ LUÔN GỌI search_products TRƯỚC, KHÔNG suggest chi nhánh
   ${hasRecentBooking ? `\n   ⚠️ QUAN TRỌNG: Nếu user hỏi "trong chi nhánh tôi vừa đặt bàn", "chi nhánh này", "chi nhánh tôi vừa book", v.v.\n   → LUÔN dùng branch_id=${lastBranchId} cho search_products hoặc get_branch_menu\n   → KHÔNG BAO GIỜ hỏi lại "Bạn muốn xem chi nhánh nào?"` : ''}
   Ví dụ:
   • "có nước gì" → search_products({ keyword: "nước"${hasRecentBooking ? `, branch_id: ${lastBranchId}` : ''} })
   • "có món chay không" → search_products({ dietary: "vegetarian"${hasRecentBooking ? `, branch_id: ${lastBranchId}` : ''} })
   • "món dưới 100k" → search_products({ max_price: 100000${hasRecentBooking ? `, branch_id: ${lastBranchId}` : ''} })
   • "có burger không" → search_products({ keyword: "burger"${hasRecentBooking ? `, branch_id: ${lastBranchId}` : ''} })
   • "có gì ngon" → search_products({ limit: 10${hasRecentBooking ? `, branch_id: ${lastBranchId}` : ''} })
   ${hasRecentBooking ? `• "trong chi nhánh tôi vừa đặt bàn có món gì" → get_branch_menu({ branch_id: ${lastBranchId} })` : ''}
   ❌ KHÔNG BAO GIỜ:
   • Suggest "Bạn muốn xem chi nhánh nào"
   • Trả lời mà không gọi search_products
   • Bịa danh sách món
2. 📋 KHI KHÁCH HỎI XEM MENU CỦA CHI NHÁNH (CỤ THỂ):
   ⚠️⚠️⚠️ QUAN TRỌNG CỰC KỲ - PHẢI ĐỌC KỸ ⚠️⚠️⚠️
   ✅ NẾU user hỏi "xem menu của chi nhánh X", "menu chi nhánh Y", "thực đơn chi nhánh Z", 
      "toi muon xem menu cua CHI NHANH [tên]", "menu cua quan an", "menu cua nha hang",
      "menu chi nhánh ở [địa chỉ]", "menu chi nhánh tại [địa chỉ]", "menu chi nhánh [tên hoặc địa chỉ]"
   → BƯỚC 1: Extract tên chi nhánh HOẶC địa chỉ từ message 
      (có thể là "Beast Bite - The Pearl District", "The Pearl District", "Diamond Plaza", 
       "34 Le Duan Street", "Pearl District", "ở 34 Le Duan", "tại Diamond Plaza", etc.)
   → BƯỚC 2: GỌI get_all_branches() để lấy danh sách tất cả chi nhánh
   → BƯỚC 3: Tìm branch_id từ tên chi nhánh HOẶC địa chỉ (fuzzy match):
      - Tìm branch có tên chứa search term hoặc ngược lại
      - Tìm branch có địa chỉ chứa search term hoặc ngược lại
      - Tìm theo từng từ trong search term nếu không tìm thấy
   → BƯỚC 4: GỌI get_branch_menu({ branch_id: <id_tìm_được> })
   → BƯỚC 5: Sau khi có kết quả, tạo response với suggestions để navigate vào menu chi nhánh đó
   → TUYỆT ĐỐI KHÔNG chỉ gọi get_all_branches() và trả về danh sách chi nhánh!
   📋 VÍ DỤ CỤ THỂ:
   • "toi muon xem menu cua CHI NHANH Beast Bite - The Pearl District"
     → Step 1: Extract "Beast Bite - The Pearl District" hoặc "The Pearl District"
     → Step 2: get_all_branches() → Tìm branch có tên chứa "The Pearl District" → branch_id = 5
     → Step 3: get_branch_menu({ branch_id: 5 })
     → Step 4: Response: Hiển thị menu + suggestions với action: "navigate_menu", data: { branch_id: 5 }
   • "menu chi nhánh Diamond Plaza"
     → Step 1: Extract "Diamond Plaza"
     → Step 2: get_all_branches() → Tìm branch có tên chứa "Diamond Plaza" → branch_id = 7
     → Step 3: get_branch_menu({ branch_id: 7 })
     → Step 4: Response: Hiển thị menu + suggestions với action: "navigate_menu", data: { branch_id: 7 }
   • "xem menu chi nhánh ở 34 Le Duan Street" hoặc "menu chi nhánh tại 34 Le Duan"
     → Step 1: Extract "34 Le Duan Street" hoặc "34 Le Duan"
     → Step 2: get_all_branches() → Tìm branch có địa chỉ chứa "34 Le Duan" → branch_id = X
     → Step 3: get_branch_menu({ branch_id: X })
     → Step 4: Response: Hiển thị menu + suggestions với action: "navigate_menu", data: { branch_id: X }
   • "menu chi nhánh Pearl District" (chỉ có tên địa điểm, không có "Beast Bite")
     → Step 1: Extract "Pearl District"
     → Step 2: get_all_branches() → Tìm branch có tên chứa "Pearl District" HOẶC địa chỉ chứa "Pearl District" → branch_id = 5
     → Step 3: get_branch_menu({ branch_id: 5 })
     → Step 4: Response: Hiển thị menu + suggestions với action: "navigate_menu", data: { branch_id: 5 }
   • "xem menu của chi nhánh này" (nếu có lastBranchId trong context)
     → get_branch_menu({ branch_id: lastBranchId })
     → Response: Hiển thị menu + suggestions với action: "navigate_menu", data: { branch_id: lastBranchId }
   • "menu cua quan an" hoặc "menu cua nha hang"
     → Step 1: Extract "quan an" hoặc "nha hang" (có thể là generic, nhưng vẫn thử tìm)
     → Step 2: get_all_branches() → Nếu không tìm thấy branch cụ thể, hiển thị danh sách branches với suggestions
     → Step 3: Nếu tìm thấy branch, get_branch_menu({ branch_id: <id> })
   ❌ SAI - TUYỆT ĐỐI KHÔNG LÀM:
   • "xem menu chi nhánh X" → CHỈ gọi get_all_branches() ← SAI! Phải gọi get_branch_menu!
   • "menu chi nhánh Y" → Trả về danh sách chi nhánh ← SAI! Phải hiển thị menu!
   • "toi muon xem menu cua CHI NHANH X" → get_all_branches() rồi dừng ← SAI! Phải tìm branch_id và gọi get_branch_menu!
   • "menu chi nhánh ở [địa chỉ]" → Chỉ hỏi lại "Bạn muốn xem chi nhánh nào?" ← SAI! Phải tìm theo địa chỉ và gọi get_branch_menu!
   • Hiển thị menu mà không có suggestions để navigate ← SAI! Phải có bubble để user click vào!
3. 📍 KHI KHÁCH HỎI VỀ CHI NHÁNH (KHÔNG PHẢI MENU):
   ✅ GỌI get_all_branches hoặc search_branches_by_location
   Ví dụ:
   • "có chi nhánh nào" → get_all_branches()
   • "chi nhánh ở Tân Phú" → search_branches_by_location({ location: "Tân Phú" })
   • "thông tin chi nhánh X" → get_branch_details({ branch_id: <id> })
4. 📋 KHI KHÁCH CHỈ HỎI "XEM MENU" (KHÔNG CHỈ ĐỊNH CHI NHÁNH):
   ✅ NẾU user chỉ hỏi "xem menu", "menu", "thực đơn" (không có tên chi nhánh)
   → BƯỚC 1: GỌI get_all_branches() để lấy danh sách chi nhánh
   → BƯỚC 2: Tạo response với suggestions/bubbles cho MỖI chi nhánh
   → Mỗi suggestion có: text (tên chi nhánh + địa chỉ + giờ làm việc), action: "view_menu", data: { branch_id: <id> }
   → KHÔNG BAO GIỜ chỉ trả về text danh sách chi nhánh mà không có suggestions!
   Ví dụ:
   • "xem menu" → get_all_branches() → Response với suggestions cho mỗi chi nhánh
   • "menu" → get_all_branches() → Response với suggestions cho mỗi chi nhánh
   • "thực đơn" → get_all_branches() → Response với suggestions cho mỗi chi nhánh
   ❌ SAI:
   • "xem menu" → Chỉ trả về text danh sách chi nhánh ← SAI! Phải có suggestions/bubbles!
   • "menu" → Trả về danh sách chi nhánh dạng text ← SAI! Phải có bubbles để user click!
4. 🚚 KHI KHÁCH MUỐN ĐẶT ĐƠN GIAO HÀNG (DELIVERY):
   ⚠️⚠️⚠️ QUAN TRỌNG CỰC KỲ - PHẢI ĐỌC KỸ ⚠️⚠️⚠️
   ✅ NẾU user hỏi "giao hàng", "giao hang", "delivery", "đặt đơn giao", "dat don giao", "toi muon dat don giao"
   → BƯỚC 1: GỌI get_all_branches() để lấy danh sách tất cả chi nhánh
   → BƯỚC 2: Tạo response với suggestions/bubbles cho MỖI chi nhánh
   → Mỗi suggestion có: 
     - text: Tên chi nhánh + địa chỉ + giờ làm việc + số điện thoại (format đẹp)
     - action: "select_branch_for_delivery"
     - data: { branch_id: <id>, branch_name: <tên>, intent: "order_delivery" }
   → Response message: "Bạn muốn đặt món giao hàng từ chi nhánh nào?\\n\\nVui lòng chọn chi nhánh từ danh sách bên dưới:"
   → Intent: "order_delivery" (QUAN TRỌNG: Phải là order_delivery, không phải order_takeaway!)
   → LƯU Ý: TakeawayIntentHandler sẽ tự động hỏi địa chỉ giao hàng trước khi hiển thị danh sách chi nhánh
5. 🛒 KHI KHÁCH MUỐN ĐẶT ĐƠN TAKEAWAY/MANG VỀ:
   ⚠️⚠️⚠️ QUAN TRỌNG CỰC KỲ - PHẢI ĐỌC KỸ ⚠️⚠️⚠️
   ✅ NẾU user hỏi "đặt đơn", "đặt món mang về", "takeaway", "mang về", "mang ve",
      "toi muon dat don", "toi muon dat don takeaway", "dat mon mang ve", "toi muon dat mon mang ve"
   → BƯỚC 1: GỌI get_all_branches() để lấy danh sách tất cả chi nhánh
   → BƯỚC 2: Tạo response với suggestions/bubbles cho MỖI chi nhánh
   → Mỗi suggestion có: 
     - text: Tên chi nhánh + địa chỉ + giờ làm việc + số điện thoại (format đẹp)
     - action: "select_branch_for_takeaway"
     - data: { branch_id: <id>, branch_name: <tên>, intent: "order_takeaway" }
   → Response message: "Bạn muốn đặt món mang về từ chi nhánh nào?\\n\\nVui lòng chọn chi nhánh từ danh sách bên dưới:"
   → Intent: "order_takeaway"
   → TUYỆT ĐỐI KHÔNG chỉ trả về text danh sách chi nhánh mà không có suggestions!
   → TUYỆT ĐỐI KHÔNG hiểu nhầm là tìm kiếm món ăn hoặc xem menu!
   📋 VÍ DỤ CỤ THỂ:
   • "toi muon dat don takeaway"
     → Step 1: get_all_branches()
     → Step 2: Response: "Bạn muốn đặt món mang về từ chi nhánh nào?\\n\\nVui lòng chọn chi nhánh từ danh sách bên dưới:"
     → Step 3: Suggestions với action "select_branch_for_takeaway" cho mỗi chi nhánh
     → Intent: "order_takeaway"
   • "dat mon mang ve"
     → Step 1: get_all_branches()
     → Step 2: Response với suggestions cho mỗi chi nhánh
     → Intent: "order_takeaway"
   • "toi muon dat don"
     → Step 1: get_all_branches()
     → Step 2: Response với suggestions cho mỗi chi nhánh
     → Intent: "order_takeaway"
   ❌ SAI - TUYỆT ĐỐI KHÔNG LÀM:
   • "toi muon dat don takeaway" → search_products({ keyword: "toi muon dat takeaway" }) ← SAI! Phải gọi get_all_branches!
   • "dat mon mang ve" → Trả về text danh sách chi nhánh không có suggestions ← SAI! Phải có bubbles!
   • "toi muon dat don" → Hiểu nhầm là xem menu ← SAI! Phải là order_takeaway!
   • "takeaway" → Chỉ hỏi lại "Bạn muốn đặt món gì?" ← SAI! Phải hiển thị danh sách chi nhánh với bubbles!
3. 🪑 KHI KHÁCH ĐĂT ĐƠN BÀN:
   ${isBookingFlow ? `
   ⚠️⚠️⚠️ QUAN TRỌNG CỰC KỲ - ĐỌC KỸ ⚠️⚠️⚠️
   User ĐÃ CHỌN chi nhánh: ${lastBranch} (ID: ${lastBranchId})
   → Khi user cung cấp thông tin đặt bàn (ví dụ: "2 người ngày mai 9h", "4 người chiều nay 5h")
   → BẮT BUỘC gọi check_table_availability với branch_id=${lastBranchId}
   → TUYỆT ĐỐI KHÔNG gọi get_all_branches() (user đã chọn rồi!)
   📋 VÍ DỤ CỤ THỂ:
   Context: User đã chọn branch_id=${lastBranchId}
   User message: "2 người chiều nay 5h"
   → ✅ ĐÚNG: check_table_availability({
       branch_id: ${lastBranchId},  ← PHẢI dùng branch_id này!
       reservation_date: "2025-11-20",
       reservation_time: "17:00",
       guest_count: 2
     })
   → ❌ SAI: get_all_branches() ← KHÔNG BAO GIỜ!
   → ❌ SAI: Hỏi "Bạn muốn đặt tại chi nhánh nào?" ← Đã chọn rồi!
   🔒 RULE: Nếu có lastBranchId trong context → LUÔN dùng nó cho check_table_availability!
   ` : `✅ Flow chuẩn:
   Step 1: check_table_availability (kiểm tra bàn trống)
   Step 2: Nếu có bàn → Hỏi xác nhận
   Step 3: create_reservation`}
4. ❌ KHÔNG BAO GIỜ:
   • Bịa tên món, giá, địa chỉ, số điện thoại
   • Trả lời về doanh thu, dữ liệu nội bộ
   • Suggest chi nhánh khi khách hỏi về món ăn
   • Trả lời trực tiếp mà không gọi tool
6. ✅ CÁCH TRẢ LỜI SAU KHI CÓ KẾT QUẢ TOOL:
   • Ngắn gọn (3-5 câu), dễ hiểu
   • Dùng emoji phù hợp (🍽️ 🥤 📍 🪑 ✅ ❌ 🎉)
   • Gợi ý hành động tiếp theo rõ ràng
   • Hiển thị giá cả chính xác từ tool
📝 VÍ DỤ CHUẨN:
Query: "có nước gì không"
✅ ĐÚNG:
- Gọi: search_products({ keyword: "nước" })
- Trả lời: "🥤 Chúng tôi có 8 loại nước:
  • Nước cam - 35,000đ
  • Coca Cola - 25,000đ
  • Nước suối - 15,000đ
  ..."
❌ SAI:
- "Bạn muốn xem menu chi nhánh nào?"
- "Chúng tôi có nhiều loại nước" (không cụ thể)
Query: "món chay dưới 100k"
✅ ĐÚNG:
- Gọi: search_products({ dietary: "vegetarian", max_price: 100000 })
- Trả lời: "🌱 Tìm thấy 5 món chay dưới 100k:
  • Salad rau củ - 68,000đ
  ..."
Query: "có chi nhánh nào"
✅ ĐÚNG:
- Gọi: get_all_branches()
- Trả lời: "📍 Beast Bite có 6 chi nhánh:
  1. Diamond Plaza Corner (Q1)
  ..."
📝 VÍ DỤ CÁCH XỬ LÝ:
User: "Chi nhánh 3 còn bàn lúc 7h tối mai không?"
→ Tool: check_table_availability(branch_id=3, date="2024-01-20", time="19:00", guest_count=2)
→ Response: "✅ Chi nhánh 3 còn X bàn trống vào 7h tối mai. Bạn có muốn đặt không?"
User: "Có món bò nào không?"
→ Tool: search_products(keyword="bò")
→ Response: "🍽️ Chúng tôi có X món bò: [list]. Bạn thích món nào?"
User: "Xem menu chi nhánh 5"
→ Tool: get_branch_menu(branch_id=5)
→ Response: "📋 Menu chi nhánh 5: [categories với giá]. Bạn muốn đặt món nào?"
HÃY BẮT ĐẦU! Trả lời ngắn gọn, tự nhiên, hữu ích.`;
    }
    _buildConversationHistory(context) {
        const messages = [];
        if (context.conversationHistory && context.conversationHistory.length > 0) {
            const recentHistory = context.conversationHistory.slice(-6);
            for (const msg of recentHistory) {
                messages.push({
                    role: msg.message_type === 'user' ? 'user' : 'assistant',
                    content: msg.message_content
                });
            }
        }
        return messages;
    }
    async _callGeminiWithRetry(message, context, tools, maxRetries = 2) {
        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            try {
                return await this._callGemini(message, context, tools);
            } catch (error) {
                const is503 = error.message?.includes('503') || 
                             error.message?.includes('overloaded') ||
                             error.message?.includes('Service Unavailable');
                if (is503 && attempt < maxRetries) {
                    const delay = 1000 * (attempt + 1);
                    console.log(`Gemini API overloaded, retry ${attempt + 1}/${maxRetries} in ${delay}ms...`);
                    await new Promise(resolve => setTimeout(resolve, delay));
                    continue;
                }
                throw error;
            }
        }
    }
    async _callGemini(message, context, tools) {
        const history = this._buildConversationHistory(context);
        const geminiHistory = [];
        history.forEach(msg => {
            geminiHistory.push({
                role: msg.role === 'assistant' ? 'model' : 'user',
                parts: [{ text: msg.content }]
            });
        });
        if (geminiHistory.length > 0 && geminiHistory[0].role === 'model') {
            geminiHistory.shift(); 
        }
        const functions = tools.map(tool => ({
            name: tool.function.name,
            description: tool.function.description,
            parameters: tool.function.parameters
        }));
        const systemInstruction = this._buildSystemPrompt(context, tools);
        try {
            const model = this.genAI.getGenerativeModel({
                model: this.geminiModel,
                tools: [{ functionDeclarations: functions }],
                systemInstruction: systemInstruction,
            });
            const chat = model.startChat({
                history: geminiHistory,
                generationConfig: {
                    temperature: 0.7,
                    maxOutputTokens: 800,
                },
            });
            const result = await chat.sendMessage(message);
            const response = result.response;
            const functionCalls = [];
            const candidates = response.candidates;
            if (candidates && candidates[0] && candidates[0].content && candidates[0].content.parts) {
                candidates[0].content.parts.forEach(part => {
                    if (part.functionCall) {
                        functionCalls.push({
                            name: part.functionCall.name,
                            args: part.functionCall.args
                        });
                    }
                });
            }
            return {
                text: response.text(),
                functionCalls: functionCalls
            };
        } catch (error) {
            throw error;
        }
    }
    async _handleGeminiFunctionCalls(functionCalls, originalMessage, context) {
        const toolResults = [];
        for (const fc of functionCalls) {
            const toolName = fc.name;
            const args = fc.args || {};
            try {
                const result = await ToolOrchestrator.executeToolCall(
                    toolName,
                    args,
                    {
                        userId: context.user?.id || null,
                        role: this._getUserRole(context),
                        ip: context.ip,
                        userAgent: context.userAgent
                    }
                );
                toolResults.push({
                    tool: toolName,
                    result: result.data,
                    success: true
                });
                } catch (error) {
                toolResults.push({
                    tool: toolName,
                    error: error.message,
                    success: false
                });
            }
        }
        return await this._generateResponseFromToolResults(
            toolResults,
            originalMessage
        );
    }
    async _handleToolCalls(toolCalls, originalMessage, context) {
        const toolResults = [];
        for (const toolCall of toolCalls) {
            const toolName = toolCall.function.name;
            let args = {};
            try {
                args = JSON.parse(toolCall.function.arguments);
            } catch {
                toolResults.push({
                    tool_call_id: toolCall.id,
                    tool: toolName,
                    error: 'Invalid arguments format'
                });
                continue;
            }
            try {
                const result = await ToolOrchestrator.executeToolCall(
                    toolName,
                    args,
                    {
                        userId: context.user?.id,
                        role: this._getUserRole(context),
                        ip: context.ip,
                        userAgent: context.userAgent
                    }
                );
                toolResults.push({
                    tool_call_id: toolCall.id,
                    tool: toolName,
                    result: result.data,
                    success: true
                });
                } catch (error) {
                toolResults.push({
                    tool_call_id: toolCall.id,
                    tool: toolName,
                    error: error.message,
                    success: false
                });
            }
        }
        return await this._generateResponseFromToolResults(
            toolResults,
            originalMessage
        );
    }
    async _generateResponseFromToolResults(toolResults, originalMessage) {
        try {
            if (this.geminiEnabled && this.genAI) {
                const toolResultsText = toolResults.map(r => {
                    if (r.success) {
                        return `Tool: ${r.tool}\nResult: ${JSON.stringify(r.result, null, 2)}`;
                    } else {
                        return `Tool: ${r.tool}\nError: ${r.error}`;
                    }
                }).join('\n\n');
                const prompt = `Khách hàng hỏi: "${originalMessage}"
Kết quả từ hệ thống:
${toolResultsText}
Dựa vào kết quả trên, hãy trả lời khách hàng một cách TỰ NHIÊN, NGẮN GỌN (3-5 câu) bằng tiếng Việt. Dùng emoji phù hợp. GỢI Ý hành động tiếp theo rõ ràng.`;
                const model = this.genAI.getGenerativeModel({ model: this.geminiModel });
                const result = await model.generateContent(prompt);
                const response = result.response;
                const entities = this._extractEntitiesFromToolResults(toolResults);
                const intent = this._inferIntentFromToolCalls(toolResults, originalMessage);
                return {
                    intent,
                    entities,
                    response: response.text(),
                    tool_results: toolResults,
                    source: 'gemini_with_tools'
                };
            }
            return this._buildFallbackResponseFromTools(toolResults, originalMessage);
        } catch (err) {
            return this._buildFallbackResponseFromTools(toolResults, originalMessage);
        }
    }
    _buildFallbackResponseFromTools(toolResults, originalMessage = '') {
        let response = '';
        let intent = 'tool_response';
        const lowerMessage = (originalMessage || '').toLowerCase();
        const isMenuRequest = /(xem\s+menu|menu|thực\s+đơn|thuc\s+don)/i.test(lowerMessage) && 
                             !/(chi\s+nhánh|chi\s+nhanh|branch)\s+(.+)/i.test(lowerMessage);
        for (const result of toolResults) {
            if (result.success && result.result) {
                if (result.tool === 'get_branch_menu') {
                    response += this._formatMenuResult(result.result);
                    intent = 'view_menu';
                } else if (result.tool === 'search_products') {
                    response += this._formatSearchResult(result.result);
                    intent = 'search_food';
                } else if (result.tool === 'check_table_availability') {
                    response += this._formatAvailabilityResult(result.result);
                    intent = 'check_availability';
                } else if (result.tool === 'create_reservation') {
                    response += this._formatReservationResult(result.result);
                    intent = 'reservation_created';
                } else if (result.tool === 'get_all_branches') {
                    const isDeliveryRequest = /(giao hàng|giao hang|delivery|đặt đơn giao|dat don giao)/i.test(lowerMessage);
                    const isTakeawayRequest = /(đặt đơn|dat don|đặt món mang về|dat mon mang ve|takeaway|mang về|mang ve)/i.test(lowerMessage);
                    if (isDeliveryRequest) {
                        response += this._formatBranchesResult(result.result);
                        intent = 'order_delivery'; 
                    } else if (isTakeawayRequest) {
                        response += this._formatBranchesResult(result.result);
                        intent = 'order_takeaway'; 
                    } else if (isMenuRequest) {
                        response += this._formatBranchesResultForMenu(result.result);
                        intent = 'view_menu';
                    } else {
                        response += this._formatBranchesResult(result.result);
                        intent = 'view_branches';
                    }
                } else {
                    response += `✅ Đã thực hiện: ${result.tool}\n\n`;
                }
            } else {
                response += `❌ ${result.error || 'Có lỗi xảy ra'}\n\n`;
            }
        }
        return {
            intent,
            entities: this._extractEntitiesFromToolResults(toolResults),
            response: response.trim() || 'Đã xử lý yêu cầu của bạn.',
            tool_results: toolResults,
            source: 'fallback_formatting'
        };
    }
    _formatMenuResult(result) {
        if (!result.menu) return '📋 Menu không có sẵn.\n\n';
        let text = `📋 Menu (${result.total_products} món):\n\n`;
        let count = 0;
        for (const [category, items] of Object.entries(result.menu)) {
            if (count >= 3) break; 
            text += `${category}\n`;
            items.slice(0, 5).forEach(item => {
                text += `• ${item.name} - ${item.price.toLocaleString()}đ\n`;
            });
            text += '\n';
            count++;
        }
        if (Object.keys(result.menu).length > 3) {
            text += '... và nhiều món khác\n\n';
        }
        return text;
    }
    _formatSearchResult(result) {
        if (!result.products || result.products.length === 0) {
            return `🔍 Không tìm thấy món nào với từ khóa "${result.keyword}".\n\n`;
        }
        let text = `🔍 Tìm thấy ${result.total_found} món:\n\n`;
        result.products.slice(0, 5).forEach(p => {
            text += `• ${p.name} - ${p.price.toLocaleString()}đ\n`;
        });
        if (result.products.length > 5) {
            text += `... và ${result.products.length - 5} món khác\n`;
        }
        return text + '\n';
    }
    _formatAvailabilityResult(result) {
        if (result.available) {
            return `✅ ${result.message}\n\n📅 ${result.reservation_date}\n🕐 ${result.reservation_time}\n👥 ${result.guest_count} người\n\nBạn có muốn đặt bàn không?\n\n`;
        } else {
            return `❌ ${result.message}\n\n${result.suggestion || ''}\n\n`;
        }
    }
    _formatReservationResult(result) {
        if (result.success) {
            const d = result.details;
            return `🎉 Đặt bàn thành công!\n\n📍 ${d.branch}\n🪑 Bàn ${d.table} (Tầng ${d.floor})\n📅 ${d.date}\n🕐 ${d.time}\n👥 ${d.guests} người\n\n✅ Mã: #${d.id}\n\n`;
        } else {
            return `❌ ${result.message}\n\n`;
        }
    }
    _formatBranchesResult(result) {
        if (!result.branches || result.branches.length === 0) {
            return '📍 Không tìm thấy chi nhánh nào.\n\n';
        }
        let text = `📍 ${result.total} chi nhánh của Beast Bite:\n\n`;
        result.branches.slice(0, 5).forEach((b, idx) => {
            text += `${idx + 1}. ${b.name}\n`;
            text += `   📍 ${b.address}\n`;
            if (b.phone) text += `   📞 ${b.phone}\n`;
            text += '\n';
        });
        if (result.branches.length > 5) {
            text += `... và ${result.branches.length - 5} chi nhánh khác\n\n`;
        }
        return text;
    }
    _formatBranchesResultForMenu(result) {
        if (!result.branches || result.branches.length === 0) {
            return '📍 Không tìm thấy chi nhánh nào.\n\n';
        }
        return `📍 Chọn chi nhánh để xem menu:\n\nBạn muốn xem menu của chi nhánh nào? Vui lòng chọn một chi nhánh từ danh sách bên dưới:`;
    }
    _extractEntitiesFromToolResults(toolResults) {
        const entities = {};
        for (const result of toolResults) {
            if (result.success && result.result) {
                if (result.result.branch_id) entities.branch_id = result.result.branch_id;
                if (result.result.reservation_id) entities.reservation_id = result.result.reservation_id;
                if (result.result.reservation_date) entities.date = result.result.reservation_date;
                if (result.result.reservation_time) entities.time = result.result.reservation_time;
                if (result.result.details && result.result.details.id) {
                    entities.reservation_id = result.result.details.id;
                }
            }
        }
        return entities;
    }
    _inferIntentFromToolCalls(toolResults, originalMessage = '') {
        if (toolResults.length === 0) return 'unknown';
        const firstTool = toolResults.find(r => r.success);
        if (!firstTool) return 'tool_error';
        const lowerMessage = (originalMessage || '').toLowerCase();
        const isDeliveryRequest = /(giao hàng|giao hang|delivery|đặt đơn giao|dat don giao)/i.test(lowerMessage);
        const isTakeawayRequest = /(đặt đơn|dat don|đặt món mang về|dat mon mang ve|takeaway|mang về|mang ve)/i.test(lowerMessage);
        const hasMenuKeyword = /(xem\s+menu|menu|thực\s+đơn|thuc\s+don|menu\s+của|menu\s+cua)/i.test(lowerMessage);
        const isMenuRequest = hasMenuKeyword && 
                             !/(có những|co nhung|danh sách|danh sach|list|chi nhánh nào|chi nhanh nao)\s*(chi nhánh|chi nhanh|branch)/i.test(lowerMessage);
        const toolToIntentMap = {
            'get_branch_menu': 'view_menu',
            'search_products': 'search_food',
            'check_table_availability': 'check_availability',
            'create_reservation': 'book_table',
            'get_all_branches': isDeliveryRequest ? 'order_delivery' : (isTakeawayRequest ? 'order_takeaway' : (isMenuRequest || hasMenuKeyword ? 'view_menu' : 'view_branches')), 
            'get_branch_details': 'view_branch_info',
            'get_my_orders': 'view_orders',
            'get_my_reservations': 'view_reservations',
            'get_product_details': 'view_product'
        };
        return toolToIntentMap[firstTool.tool] || 'tool_response';
    }
    _extractIntentFromMessage(aiResponse, userMessage) {
        const lower = aiResponse.toLowerCase();
        const userLower = userMessage.toLowerCase();
        if (/(chi nhánh gần nhất|gần nhất|gần tôi|nearest|closest|chi nhanh gan nhat|gan nhat|gan toi)/i.test(userLower)) {
            return 'find_nearest_branch';
        }
        if (/(giao hàng|giao hang|delivery|đặt đơn giao|dat don giao)/i.test(userLower)) {
            return 'order_delivery';
        }
        if (/(đặt đơn|dat don|đặt món mang về|dat mon mang ve|takeaway|mang về|mang ve)/i.test(userLower)) {
            return 'order_takeaway';
        }
        if (lower.includes('menu')) return 'view_menu';
        if (lower.includes('đặt bàn') || lower.includes('reservation')) return 'book_table';
        if (lower.includes('chi nhánh') || lower.includes('branch')) return 'ask_branch';
        if (lower.includes('đơn hàng')) return 'view_orders';
        if (lower.includes('tìm') || lower.includes('search')) return 'search_food';
        return IntentDetector.detectIntent(userMessage);
    }
}
module.exports = new AIService();
