const BranchService = require('../BranchService');
const Utils = require('./Utils');
class BranchHandler {
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
    getBranchesByDistrictFromCache(branchesCache, districtId) {
        return [];
    }
    getBranchesByProvinceFromCache(branchesCache, provinceId) {
        return [];
    }
    async getNearestBranch(userLocation) {
        if (!userLocation) {
            try {
                const branches = await BranchService.getActiveBranches();
                return branches.length > 0 ? branches[0] : null;
            } catch {
                return null;
            }
        }
        try {
            const branches = await BranchService.getActiveBranches();
            if (branches.length === 0) {
                return null;
            }
            let nearestBranch = branches[0];
            let minDistance = this.calculateDistance(
                userLocation.latitude,
                userLocation.longitude,
                branches[0].latitude || 0,
                branches[0].longitude || 0
            );
            for (let i = 1; i < branches.length; i++) {
                const distance = this.calculateDistance(
                    userLocation.latitude,
                    userLocation.longitude,
                    branches[i].latitude || 0,
                    branches[i].longitude || 0
                );
                if (distance < minDistance) {
                    minDistance = distance;
                    nearestBranch = branches[i];
                }
            }
            return nearestBranch;
        } catch {
            return null;
        }
    }
    calculateDistance(lat1, lon1, lat2, lon2) {
        const R = 6371; 
        const dLat = this.deg2rad(lat2 - lat1);
        const dLon = this.deg2rad(lon2 - lon1);
        const a = 
            Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) * 
            Math.sin(dLon/2) * Math.sin(dLon/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const d = R * c;
        return d;
    }
    deg2rad(deg) {
        return deg * (Math.PI/180);
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
        } catch {
            return null;
        }
    }
    async getBranchByName(branchName) {
        try {
            const branches = await BranchService.getAllBranches('active', branchName);
            return branches.length > 0 ? branches[0] : null;
        } catch {
            return null;
        }
    }
    formatBranchList(branches, includeDetails = false) {
        if (!branches || branches.length === 0) {
            return '';
        }
        if (includeDetails) {
            return branches.map((b, idx) => {
                const address = b.address_detail || '';
                const phone = b.phone || '';
                const openingHours = b.opening_hours ? `${b.opening_hours}h` : '';
                const closeHours = b.close_hours ? `${b.close_hours}h` : '';
                const hours = openingHours && closeHours ? `${openingHours} - ${closeHours}` : (openingHours || closeHours || '');
                let branchInfo = `${idx + 1}. ${b.name}`;
                if (address) branchInfo += `\n   📍 ${address}`;
                if (phone) branchInfo += `\n   📞 ${phone}`;
                if (hours) branchInfo += `\n   🕐 ${hours}`;
                return branchInfo;
            }).join('\n\n');
        } else {
            return branches.map((b, idx) => 
                `${idx + 1}. ${b.name}`
            ).join('\n');
        }
    }
    async createBranchSuggestions(branches, bookingContext = null) {
        if (!branches || branches.length === 0) {
            return [];
        }
        const suggestions = await Promise.all(branches.map(async (branch) => {
            const districtName = '';
            const address = branch.address_detail ? branch.address_detail.trim() : 'Địa chỉ chưa cập nhật';
            const phone = branch.phone ? branch.phone.trim() : '';
            const hours = this.formatOperatingHours(branch) || 'Giờ làm việc chưa cập nhật';
            let buttonText = `📍 ${branch.name}`;
            buttonText += `\n${address}`;
            buttonText += `\n🕐 ${hours}`;
            if (phone) {
                buttonText += `\n📞 ${phone}`;
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
    async getDistrict(districtId, districtName = null) {
        return null;
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
        } catch {
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
        } catch {
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
module.exports = new BranchHandler();
