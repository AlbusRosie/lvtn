const Utils = require('./Utils');
class EntityExtractor {
    parseNaturalLanguage(message) {
        const lower = message.toLowerCase();
        const normalized = Utils.normalizeVietnamese(lower);
        const peopleMatch = lower.match(/(\d+)\s*(nguoi|người|people|person|pax)/i) || 
                           lower.match(/(\d+)(nguoi|người|people|person|pax)/i) ||
                           lower.match(/(nguoi|người|people|person|pax)\s*(\d+)/i);
        const people = peopleMatch ? parseInt(peopleMatch[1] || peopleMatch[2]) : null;
        const isBranchButtonText = message.includes('📍') && 
                                   (message.includes('🕐') || message.includes('📞')) &&
                                   message.split('\n').length >= 2;
        let time = null;
        let hour = null;
        let minute = 0;
        let period = null;
        let shouldSkipTimeParsing = false;
        if (isBranchButtonText) {
            const hasBookingKeyword = /(đặt bàn|dat ban|book|reservation|đặt|dat|giờ|gio|time)/i.test(message);
            const timeInHoursLine = /🕐.*\d+[hH]/.test(message);
            if (timeInHoursLine && !hasBookingKeyword) {
                shouldSkipTimeParsing = true;
            }
        }
        if (!shouldSkipTimeParsing) {
            const standaloneAmPm = lower.match(/(\d{1,2})\s*(pm|am)\b/i);
            if (standaloneAmPm) {
                hour = parseInt(standaloneAmPm[1]);
                period = standaloneAmPm[2].toLowerCase();
            } else {
                const standaloneVietnamese = lower.match(/(\d{1,2})\s*(sáng|chiều|tối|trưa|toi|trua|chieu|sang)\b/i);
                if (standaloneVietnamese) {
                    hour = parseInt(standaloneVietnamese[1]);
                    const periodWord = standaloneVietnamese[2].toLowerCase();
                    if (periodWord === 'sáng' || periodWord === 'sang') {
                        period = 'am';
                    } else if (periodWord === 'chiều' || periodWord === 'chieu' || periodWord === 'tối' || periodWord === 'toi') {
                        period = 'pm';
                    } else if (periodWord === 'trưa' || periodWord === 'trua') {
                        if (hour === 12) {
                            period = 'pm';
                        } else {
                            period = 'pm'; 
                        }
                    }
                } else {
                    const timeWithH = lower.match(/(\d{1,2})[hH:]\s*(\d{0,2})?\s*(am|pm|sáng|chiều|tối|trưa|sang|chieu|toi|trua)?/i);
                    if (timeWithH) {
                        hour = parseInt(timeWithH[1]);
                        minute = timeWithH[2] && !isNaN(parseInt(timeWithH[2])) ? parseInt(timeWithH[2]) : 0;
                        const periodWord = timeWithH[3] ? timeWithH[3].toLowerCase() : null;
                        if (periodWord) {
                            if (periodWord === 'pm' || periodWord === 'am') {
                                period = periodWord;
                            } else if (periodWord === 'sáng' || periodWord === 'sang') {
                                period = 'am';
                            } else if (periodWord === 'chiều' || periodWord === 'chieu' || periodWord === 'tối' || periodWord === 'toi') {
                                period = 'pm';
                            } else if (periodWord === 'trưa' || periodWord === 'trua') {
                                period = 'pm';
                            }
                        }
                    } else {
                        const timeWithGio = lower.match(/(\d{1,2})\s*(giờ|gio|hour)\s*(am|pm|sáng|chiều|tối|trưa|sang|chieu|toi|trua)?/i);
                        if (timeWithGio) {
                            hour = parseInt(timeWithGio[1]);
                            const periodWord = timeWithGio[3] ? timeWithGio[3].toLowerCase() : null;
                            if (periodWord) {
                                if (periodWord === 'pm' || periodWord === 'am') {
                                    period = periodWord;
                                } else if (periodWord === 'sáng' || periodWord === 'sang') {
                                    period = 'am';
                                } else if (periodWord === 'chiều' || periodWord === 'chieu' || periodWord === 'tối' || periodWord === 'toi') {
                                    period = 'pm';
                                } else if (periodWord === 'trưa' || periodWord === 'trua') {
                                    period = 'pm';
                                }
                            }
                        } else {
                            const timeCompact = lower.match(/(\d{1,2})[hH](\d{0,2})/i);
                            if (timeCompact) {
                                hour = parseInt(timeCompact[1]);
                                minute = timeCompact[2] && !isNaN(parseInt(timeCompact[2])) ? parseInt(timeCompact[2]) : 0;
                            }
                        }
                    }
                }
            }
        }
        if (hour !== null) {
            if (period === 'pm') {
                if (hour < 12) {
                    hour += 12; 
                }
            } else if (period === 'am') {
                if (hour === 12) {
                    hour = 0; 
                }
            }
            if (hour >= 0 && hour <= 23) {
                time = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
            }
        }
        const dateMatch = lower.match(/(ngay+y?\s+mai|tomorrow|ngày\s+mai)/i) || 
                         normalized.match(/(ngay+y?\s+mai|tomorrow|ngày\s+mai)/i) ||
                         message.match(/(ngay+y?\s*ma+i|tomorrow|ngày\s*ma+i)/i) ||
                         message.match(/(ngay{2,}\s*ma+i)/i);
        const todayMatch = lower.match(/(hom\s+nay|hôm\s+nay|today|ngay\s+hom\s+nay)/i) || 
                          normalized.match(/(hom\s+nay|hôm\s+nay|today|ngay\s+hom\s+nay)/i) ||
                          message.match(/(hom\s+nay|hôm\s+nay|today|ngay\s+hom\s+nay)/i);
        let date = null;
        if (dateMatch) {
            const tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            date = tomorrow.toISOString().split('T')[0];
        } else if (todayMatch) {
            date = new Date().toISOString().split('T')[0];
        }
        let districtSearchTerm = null;
        const districtMatch = lower.match(/(?:ở|tại|o|tai|quận|quan|q|district|huyện|huyen|chi nhánh|chi nhanh)\s*(?:ở|tại|o|tai)?\s*(?:quận|quan|q|district|huyện|huyen)?\s*([a-záàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ0-9\s]+?)(?:\s|$|\.|,|nào|nao|gì|gi)/i) || 
                              lower.match(/(?:ở|tại|o|tai|quận|quan|q|district|huyện|huyen|chi nhánh|chi nhanh)([a-záàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ0-9]+)/i) ||
                              normalized.match(/(?:o|tai|quan|q|district|huyen|chi nhanh)\s*(?:o|tai)?\s*(?:quan|q|district|huyen)?\s*([a-z0-9\s]+?)(?:\s|$|\.|,|nao|gi)/i) ||
                              normalized.match(/(?:o|tai|quan|q|district|huyen|chi nhanh)([a-z0-9]+)/i) ||
                              message.match(/(?:CHI\s*NHANH|CHI\s*NHÁNH)\s*(?:O|Ở|TẠI)\s*(?:QUAN|QUẬN|Q|DISTRICT|HUYEN|HUYỆN)\s*([A-ZÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ0-9\s]+?)(?:\s|$|\.|,)/i) ||
                              message.match(/(?:CHI\s*NHANH|CHI\s*NHÁNH)\s*(?:O|Ở|TẠI)\s*(?:QUAN|QUẬN|Q|DISTRICT|HUYEN|HUYỆN)([A-ZÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ0-9]+)/i);
        if (districtMatch && districtMatch[1]) {
            let extractedTerm = districtMatch[1].trim();
            extractedTerm = extractedTerm.replace(/\b(của|tại|ở|tôi|muốn|muon|xem|đặt|dat|menu|thực đơn|thuc don|beast bite|chi nhánh|chi nhanh|branch|nhà hàng|nha hang)\b/gi, '').trim();
            if (extractedTerm && extractedTerm.length > 0) {
                districtSearchTerm = extractedTerm;
            }
        }
        if (!districtSearchTerm) {
            const districtNamePatterns = [
                /(?:ở|tại|o|tai|quận|quan|q|district|huyện|huyen|chi nhánh|chi nhanh)\s+(?:quận|quan|q|district|huyện|huyen)?\s*([a-záàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ\s]+?)(?:\s|$|\.|,|nào|nao|gì|gi)/i,
                /(?:ở|tại|o|tai)\s+(?:quận|quan|q|district|huyện|huyen)\s+([a-záàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ\s]+?)(?:\s|$|\.|,|nào|nao|gì|gi)/i
            ];
            for (const pattern of districtNamePatterns) {
                const match = lower.match(pattern) || normalized.match(pattern);
                if (match && match[1]) {
                    let extractedName = match[1].trim();
                    extractedName = extractedName.replace(/\b(của|tại|ở|tôi|muốn|muon|xem|đặt|dat|menu|thực đơn|thuc don|beast bite|chi nhánh|chi nhanh|branch|nhà hàng|nha hang)\b/gi, '').trim();
                    if (extractedName && extractedName.length > 1) {
                        districtSearchTerm = extractedName;
                        break;
                    }
                }
            }
        }
        if (!districtSearchTerm) {
            let cleanedMessage = message.trim();
            cleanedMessage = cleanedMessage.replace(/\b(xin chào|hello|hi|chào|chao|bạn|ban|tôi|toi|muốn|muon|xem|đặt|dat|menu|thực đơn|thuc don|beast bite|chi nhánh|chi nhanh|branch|nhà hàng|nha hang|của|tại|ở|o|tai|có|co|nào|nao|gì|gi|vậy|vay|ở đâu|o dau|tại đâu|tai dau)\b/gi, '').trim();
            if (cleanedMessage && cleanedMessage.length >= 2 && /^[a-záàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ0-9\s]+$/i.test(cleanedMessage)) {
                districtSearchTerm = cleanedMessage;
            }
        }
        let branchName = null;
        let branchId = null;
        return {
            people,
            time,
            date,
            branch_name: branchName,
            branch_id: branchId,
            district_search_term: districtSearchTerm  
        };
    }
    async extractBranchFromMessage(userMessage, entities = {}) {
        if (!userMessage || typeof userMessage !== 'string') {
            return null;
        }
        const branchNamePatterns = [
            /^[\u{1F300}-\u{1F9FF}]?\s*(?:Beast Bite\s*-\s*)?(.+?)(?:\n|$)/u,
            /(?:xem menu|menu|thực đơn|menu của|menu cua|chi nhánh|chi nhanh|branch|nhà hàng|nha hang|đặt bàn|dat ban|đặt món|dat mon)\s+(?:chi nhánh|chi nhanh|branch|nhà hàng|nha hang)?\s*(.+?)(?:\s|$|\.|,|\n)/i,
            /(?:xem menu|menu)\s+([A-Z][A-Z\s]+)/,
            /(?:xem menu|menu)\s+([a-z]+)/i,
            /(?:chi nhánh|chi nhanh|branch|nhà hàng|nha hang)\s+(.+?)(?:\s|$|\.|,|\n)/i,
        ];
        let extractedBranchName = null;
        for (const pattern of branchNamePatterns) {
            const match = userMessage.match(pattern);
            if (match && match[1]) {
                extractedBranchName = match[1].trim();
                extractedBranchName = extractedBranchName.replace(/\b(của|tại|ở|tôi|muốn|muon|xem|đặt|dat|menu|thực đơn|thuc don|beast bite)\b/gi, '').trim();
                extractedBranchName = extractedBranchName.replace(/^beast bite\s*-\s*/i, '').trim();
                extractedBranchName = extractedBranchName.replace(/[\u{1F300}-\u{1F9FF}]/gu, '').trim();
                if (extractedBranchName && extractedBranchName.length > 1) {
                    break;
                }
            }
        }
        if (!extractedBranchName) {
            const firstLine = userMessage.split('\n')[0].trim();
            const cleanedFirstLine = firstLine.replace(/[\u{1F300}-\u{1F9FF}]/gu, '').replace(/^📍\s*/i, '').trim();
            const withoutPrefix = cleanedFirstLine.replace(/^beast bite\s*-\s*/i, '').trim();
            if (withoutPrefix && withoutPrefix.length > 2 && !withoutPrefix.match(/^\d/)) {
                extractedBranchName = withoutPrefix;
            }
        }
        if (!extractedBranchName) {
            return null;
        }
        try {
            const BranchService = require('../BranchService');
            if (entities.district_id || entities.province_id) {
                const branchesByLocation = await BranchService.getAllBranches(
                    'active', 
                    null, 
                    entities.province_id || null,
                    entities.district_id || null
                );
                if (branchesByLocation.length > 0) {
                    if (extractedBranchName) {
                        const normalizedSearch = extractedBranchName.toLowerCase().trim();
                        const exactMatch = branchesByLocation.find(b => {
                            const name = (b.name || '').toLowerCase();
                            const address = (b.address_detail || '').toLowerCase();
                            return name.includes(normalizedSearch) || 
                                   address.includes(normalizedSearch) ||
                                   normalizedSearch.includes(name) ||
                                   normalizedSearch.includes(address);
                        });
                        if (exactMatch) return exactMatch;
                    }
                    return branchesByLocation[0];
                }
            }
            let branches = await BranchService.getAllBranches('active', extractedBranchName);
            if (branches.length > 0) {
                return branches[0];
            }
                const knex = require('../../database/knex');
            const normalizedSearch = extractedBranchName.toLowerCase().trim();
                const branchesByAddress = await knex('branches')
                    .where('status', 'active')
                    .where(function() {
                        this.where('address_detail', 'like', `%${extractedBranchName}%`)
                        .orWhere('name', 'like', `%${extractedBranchName}%`)
                        .orWhereRaw('LOWER(name) LIKE ?', [`%${normalizedSearch}%`])
                        .orWhereRaw('LOWER(address_detail) LIKE ?', [`%${normalizedSearch}%`]);
                })
                .limit(10);
            if (branchesByAddress.length > 0) {
                const exactMatch = branchesByAddress.find(b => 
                    b.name.toLowerCase().includes(normalizedSearch) ||
                    b.address_detail?.toLowerCase().includes(normalizedSearch)
                );
                return exactMatch || branchesByAddress[0];
            }
            const words = extractedBranchName.split(/\s+/).filter(w => w.length > 2);
            if (words.length > 1) {
                for (const word of words) {
                    const branchesByWord = await knex('branches')
                        .where('status', 'active')
                        .where(function() {
                            this.where('name', 'like', `%${word}%`)
                                .orWhere('address_detail', 'like', `%${word}%`);
                    })
                    .limit(5);
                    if (branchesByWord.length > 0) {
                        return branchesByWord[0];
                    }
                }
            }
        } catch (error) {
        }
        return null;
    }
    async extractEntities(message) {
        const entities = {};
        const parsedData = this.parseNaturalLanguage(message);
        const hasExplicitPeopleKeyword = /((\d+)\s*(nguoi|người|people|person|pax)|(nguoi|người|people|person|pax)\s*(\d+))/i.test(message);
        if (parsedData.people && hasExplicitPeopleKeyword) {
            entities.people = parsedData.people;
            entities.number_of_people = parsedData.people;
            entities.guest_count = parsedData.people;
        }
        if (parsedData.time) {
            const timeHour = parseInt(parsedData.time.split(':')[0]);
            const hasPeriod = /(sáng|chiều|tối|trưa|am|pm|sang|chieu|toi|trua)/i.test(message);
            if (timeHour >= 1 && timeHour <= 11 && !hasPeriod) {
                entities.time_ambiguous = true;
                entities.time_hour = timeHour; 
            }
            entities.time = parsedData.time;
            entities.reservation_time = parsedData.time;
            entities.time_slot = parsedData.time;
        }
        if (!entities.people && parsedData.people) {
            if (parsedData.time) {
                const timeHour = parseInt(parsedData.time.split(':')[0]);
                const peopleNumber = parsedData.people;
                if (peopleNumber !== timeHour) {
                    entities.people = parsedData.people;
                    entities.number_of_people = parsedData.people;
                    entities.guest_count = parsedData.people;
                }
            } else {
                entities.people = parsedData.people;
                entities.number_of_people = parsedData.people;
                entities.guest_count = parsedData.people;
            }
        }
        if (parsedData.date) {
            entities.date = parsedData.date;
            entities.reservation_date = parsedData.date;
            entities.booking_date = parsedData.date;
        }
        if (parsedData.branch_name) {
            entities.branch_name = parsedData.branch_name;
            entities.branch = parsedData.branch_name;
        }
        if (parsedData.branch_id) {
            entities.branch_id = parsedData.branch_id;
        }
        if (parsedData.district_search_term) {
            try {
                const searchTerm = parsedData.district_search_term.trim();
                entities.district_search_term = searchTerm;
            } catch (error) {
                entities.district_search_term = parsedData.district_search_term;
            }
        }
        if (!parsedData.branchName && !parsedData.branchId) {
            const foundBranch = await this.extractBranchFromMessage(message);
            if (foundBranch) {
                entities.branch_id = foundBranch.id;
                entities.branch_name = foundBranch.name;
                entities.branch = foundBranch.name;
            }
        }
        if (entities.district_id && !entities.branch_id) {
        }
        if (!entities.people && !entities.quantity) {
            const numbers = message.match(/\d+/g);
            if (numbers) {
                for (const numStr of numbers) {
                    const num = parseInt(numStr);
                    const peoplePattern1 = new RegExp(`${num}\\s*(nguoi|người|people|person|pax)`, 'i');
                    const peoplePattern2 = new RegExp(`(nguoi|người|people|person|pax)\\s*${num}`, 'i');
                    if (peoplePattern1.test(message) || peoplePattern2.test(message)) {
                        entities.people = num;
                        entities.number_of_people = num;
                        entities.quantity = num;
                        break; 
                    }
                }
                if (!entities.people) {
                    const firstNumber = parseInt(numbers[0]);
                    if (entities.time) {
                        const timeHour = parseInt(entities.time.split(':')[0]);
                        if (firstNumber === timeHour) {
                            return entities;
                        }
                    }
                    const isTimeExpression = 
                        /(\d{1,2})\s*(giờ|gio|hour|h)/i.test(message) ||  
                        /(\d{1,2})[hH:]\s*(\d{0,2})?\s*(am|pm)?/i.test(message) ||  
                        /(\d{1,2})[hH](\d{0,2})/i.test(message) ||  
                        /(\d{1,2})\s*(pm|am)/i.test(message) ||  
                        /(\d{1,2})[hH]\b/i.test(message);  
                    if (isTimeExpression) {
                        return entities;
                    }
                    const isDateExpression = 
                        /(ngày|ngay|day)\s*\d+/i.test(message) ||
                        /\d+\/\d+/i.test(message) ||
                        /\d+-\d+/i.test(message);
                    if (firstNumber >= 1 && firstNumber <= 20 && !isTimeExpression && !isDateExpression) {
                        if (firstNumber <= 10) {
                            const bookingKeywords = /(đặt bàn|dat ban|book|reservation|người|nguoi|people|pax)/i;
                            if (bookingKeywords.test(message)) {
                                entities.people = firstNumber;
                                entities.number_of_people = firstNumber;
                                entities.quantity = firstNumber;
                            }
                        }
                    }
                }
            }
        }
        return entities;
    }
}
module.exports = new EntityExtractor();
