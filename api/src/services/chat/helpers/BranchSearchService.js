/**
 * BranchSearchService - Service để tìm kiếm branch theo tên hoặc địa chỉ
 * Loại bỏ duplicate code trong AIService, MenuIntentHandler, LegacyFallbackService
 */
const Utils = require('../Utils');

class BranchSearchService {
    /**
     * Tìm branch theo tên hoặc địa chỉ (fuzzy match)
     * @param {string} searchTerm - Tên branch hoặc địa chỉ cần tìm
     * @param {Array} branches - Danh sách branches để search
     * @returns {object|null} Branch object hoặc null nếu không tìm thấy
     */
    findBranchByNameOrAddress(searchTerm, branches) {
        if (!searchTerm || !branches || branches.length === 0) {
            return null;
        }

        const normalizedSearch = Utils.normalizeVietnamese(searchTerm.toLowerCase().trim());
        
        // Remove "Beast Bite -" prefix từ search term
        const cleanSearchTerm = normalizedSearch.replace(/^beast\s+bite\s*-\s*/i, '').trim();
        
        // Bước 1: Tìm exact match hoặc partial match theo tên
        let foundBranch = branches.find(b => {
            const branchName = (b.name || '').toLowerCase().replace(/^beast\s+bite\s*-\s*/i, '').trim();
            return branchName === cleanSearchTerm || 
                   branchName.includes(cleanSearchTerm) ||
                   cleanSearchTerm.includes(branchName);
        });
        
        if (foundBranch) {
            return foundBranch;
        }
        
        // Bước 2: Tìm theo địa chỉ
        foundBranch = branches.find(b => {
            const address = (b.address_detail || b.address || '').toLowerCase();
            const district = (b.district || '').toLowerCase();
            return address.includes(cleanSearchTerm) ||
                   cleanSearchTerm.includes(address) ||
                   district.includes(cleanSearchTerm) ||
                   cleanSearchTerm.includes(district);
        });
        
        if (foundBranch) {
            return foundBranch;
        }
        
        // Bước 3: Tìm theo từng từ trong search term (nếu có nhiều từ)
        if (cleanSearchTerm.split(/\s+/).length > 1) {
            const words = cleanSearchTerm.split(/\s+/).filter(w => w.length > 2);
            for (const word of words) {
                foundBranch = branches.find(b => {
                    const branchName = (b.name || '').toLowerCase().replace(/^beast\s+bite\s*-\s*/i, '').trim();
                    const address = (b.address_detail || b.address || '').toLowerCase();
                    const district = (b.district || '').toLowerCase();
                    return branchName.includes(word) || 
                           address.includes(word) ||
                           district.includes(word);
                });
                if (foundBranch) {
                    return foundBranch;
                }
            }
        }
        
        return null;
    }

}

module.exports = new BranchSearchService();

