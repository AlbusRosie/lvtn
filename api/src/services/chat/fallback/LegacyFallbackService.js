const knex = require('../../database/knex');
const BookingIntentHandler = require('./handlers/BookingIntentHandler');
const MenuIntentHandler = require('./handlers/MenuIntentHandler');
const BranchIntentHandler = require('./handlers/BranchIntentHandler');
const BranchHandler = BranchIntentHandler.instance;
const BookingHandler = BookingIntentHandler.instance;
const MenuHandler = MenuIntentHandler.instance;
const MenuFormatterService = require('./helpers/MenuFormatterService');
const Utils = require('./Utils');
const EntityExtractor = require('./EntityExtractor');
const IntentDetector = require('./IntentDetector');
const { GREETING_MESSAGE } = require('./constants/Messages');
class LegacyFallbackService {
    async fallbackResponse(userMessage, context) {
        try {
            let historyEntities = {};
            if (context.conversationHistory && context.conversationHistory.length > 0) {
                for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                    const msg = context.conversationHistory[i];
                    if (msg.entities) {
                        try {
                            const ents = typeof msg.entities === 'string' ? JSON.parse(msg.entities) : msg.entities;
                            if (ents && Object.keys(ents).length > 0) {
                                historyEntities = { ...historyEntities, ...Utils.normalizeEntityFields(ents) };
                            }
                        } catch (error) {
                            console.error('[LegacyFallbackService] Error normalizing entities:', error);
                        }
                    }
                }
            }
            const intent = IntentDetector.detectIntent(userMessage);
            const entities = await EntityExtractor.extractEntities(userMessage);
            const lastEntities = context.conversationContext?.lastEntities || {};
            const mergedEntities = Utils.mergeAndNormalizeEntities(entities, lastEntities, historyEntities);
            const isTimeAmbiguous = mergedEntities.time_ambiguous || 
                                    (mergedEntities.time && mergedEntities.time_hour && mergedEntities.time_hour >= 1 && mergedEntities.time_hour <= 11);
            const hasDate = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
            const hasPeople = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
            const hasTime = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
            const hasBookingKeywords = /(đặt bàn|dat ban|book|reservation|đặt chỗ|dat cho|muốn đặt|muon dat)/i.test(userMessage) ||
                                      /(đặt bàn|dat ban|book|reservation|đặt chỗ|dat cho|muốn đặt|muon dat)/i.test(Utils.normalizeVietnamese(userMessage.toLowerCase()));
            const lastIntentForBooking = context.conversationContext?.lastIntent;
            if (isTimeAmbiguous && mergedEntities.time_hour) {
                const shouldAskTimePeriod = (
                    intent === 'book_table' || 
                    intent === 'book_table_partial' ||
                    lastIntentForBooking === 'book_table' || 
                    lastIntentForBooking === 'book_table_partial' ||
                    (hasDate && hasBookingKeywords) ||
                    (hasDate && hasPeople)
                );
                if (shouldAskTimePeriod) {
                    const timeHour = mergedEntities.time_hour;
                    return {
                        response: `Tôi hiểu bạn muốn đặt bàn vào lúc ${timeHour} giờ. Bạn muốn đặt vào buổi nào?\n\nBuổi sáng (${timeHour}:00)\nBuổi chiều (${timeHour + 12}:00)\n\nVui lòng cho tôi biết bạn muốn đặt vào buổi sáng hay chiều?`,
                        intent: 'ask_time_period',
                        entities: {
                            ...mergedEntities,
                            time: null,
                            time_hour: timeHour
                        }
                    };
                }
            }
            const hasCompleteBookingInfo = hasPeople && hasDate && hasTime;
            const hasBookingContextForProcessing = intent === 'book_table' || 
                                                   intent === 'book_table_partial' ||
                                                   lastIntentForBooking === 'book_table' || 
                                                   lastIntentForBooking === 'book_table_partial' ||
                                                   hasBookingKeywords;
            if (hasCompleteBookingInfo && hasBookingContextForProcessing) {
                const bookingResult = await BookingHandler.handleSmartBooking(userMessage, {
                    ...context,
                    conversationContext: {
                        ...context.conversationContext,
                        lastEntities: mergedEntities,
                        lastIntent: 'book_table'
                    }
                });
                if (bookingResult && bookingResult.message) {
                    return bookingResult;
                }
            }
            let response = '';
        const lower = userMessage.toLowerCase().trim();
        const normalized = Utils.normalizeVietnamese(lower);
        const isAffirmative = /\b(ok|oke|okay|okie|okey|co|có|dong y|đồng ý|yes|y|chuẩn|chuan|dung roi|đúng rồi|xác nhận|xac nhan|confirm|được|duoc|tốt|tot|hay|ổn|on|chắc chắn|chac chan|tất nhiên|tat nhien)\b/i;
        const isNegative = /\b(khong|ko|k|không|no|huy|hủy|hủy|cancel)\b/i;
        const lastIntent = context.conversationContext?.lastIntent;
        if (isAffirmative.test(userMessage) || isAffirmative.test(lower) || isAffirmative.test(normalized)) {
            let lastBotMessage = null;
            let isMenuContext = false;
            let isBookingContext = false;
            if (context.conversationHistory && context.conversationHistory.length > 0) {
                for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                    const msg = context.conversationHistory[i];
                    if (msg.message_type === 'bot') {
                        lastBotMessage = msg.message_content;
                        break;
                    }
                }
            }
            if (lastBotMessage) {
                const botMsgLower = lastBotMessage.toLowerCase();
                isMenuContext = botMsgLower.includes('menu') || 
                               botMsgLower.includes('xem menu') ||
                               botMsgLower.includes('bạn có muốn xem menu') ||
                               botMsgLower.includes('menu của') ||
                               lastIntent === 'view_menu' || 
                               lastIntent === 'view_menu_specific_branch';
                isBookingContext = botMsgLower.includes('đặt bàn') ||
                                 botMsgLower.includes('dat ban') ||
                                 botMsgLower.includes('số người') ||
                                 botMsgLower.includes('so nguoi') ||
                                 botMsgLower.includes('giờ') ||
                                 botMsgLower.includes('gio') ||
                                 lastIntent === 'book_table' ||
                                 lastIntent === 'book_table_partial' ||
                                 lastIntent === 'book_table_confirmed';
            }
            if (isMenuContext && !isBookingContext) {
                let menuBranchId = mergedEntities.branch_id || context.branch?.id || context.conversationContext?.lastBranchId;
                let menuBranchName = mergedEntities.branch_name || mergedEntities.branch || context.conversationContext?.lastBranch || context.branch?.name;
                if (!menuBranchId && !menuBranchName && context.conversationHistory) {
                    for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                        const msg = context.conversationHistory[i];
                        if (msg.entities) {
                            try {
                                const entities = typeof msg.entities === 'string' ? JSON.parse(msg.entities) : msg.entities;
                                if (entities.branch_id || entities.branch_name) {
                                    menuBranchId = menuBranchId || entities.branch_id;
                                    menuBranchName = menuBranchName || entities.branch_name || entities.branch;
                        break;
                    }
                            } catch (error) {
                                console.error('[LegacyFallbackService] Error extracting branch from message:', error);
                            }
                        }
                    }
                }
                if (menuBranchName && !menuBranchId) {
                    try {
                        const foundBranch = await BranchHandler.getAllActiveBranches(menuBranchName);
                        if (foundBranch) {
                            menuBranchId = foundBranch.id;
                            menuBranchName = foundBranch.name;
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                if (menuBranchId) {
                    try {
                        const menuItems = await MenuHandler.getMenuForOrdering(menuBranchId);
                        const branch = await knex('branches')
                            .where('id', menuBranchId)
                            .first();
                        if (menuItems && menuItems.length > 0) {
                            const groupedMenu = MenuFormatterService.groupByCategory(menuItems);
                            const menuText = MenuFormatterService.formatMenuAsText(groupedMenu, { includeDescription: true });
                            return {
                                response: `Menu của ${branch?.name || menuBranchName || 'chi nhánh'}:\n\n${menuText}\n\nBạn muốn đặt món nào?`,
                                intent: 'view_menu',
                                entities: {
                                    ...mergedEntities,
                                    branch_id: menuBranchId,
                                    branch_name: menuBranchName
                                }
                            };
                        } else {
                            return {
                                response: `Hiện tại ${branch?.name || menuBranchName || 'chi nhánh này'} chưa có món nào trong menu. Vui lòng liên hệ trực tiếp với nhà hàng.`,
                                intent: 'view_menu',
                                entities: mergedEntities
                            };
                        }
                    } catch {
                        return {
                            response: 'Có lỗi khi tải menu. Vui lòng thử lại sau.',
                            intent: 'view_menu',
                            entities: mergedEntities
                        };
                    }
        } else {
                    try {
                        const allBranches = await BranchHandler.getAllActiveBranches();
                        if (allBranches.length > 0) {
                            const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                            return {
                                response: `Bạn muốn xem menu của chi nhánh nào?\n\n${branchList.join('\n\n')}\n\nVui lòng cho tôi biết tên chi nhánh hoặc số thứ tự.`,
                                intent: 'view_menu',
                                entities: mergedEntities
                            };
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
            }
        }
        if ((isAffirmative.test(userMessage) || isAffirmative.test(lower) || isAffirmative.test(normalized)) &&
            (lastIntent === 'book_table' || lastIntent === 'book_table_partial' || lastIntent === 'book_table_confirmed' || lastIntent === 'find_nearest_branch' || lastIntent === 'find_first_branch')) {
            const people = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
            const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
            let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
            const branch = mergedEntities.branch_name || mergedEntities.branch;
            if (date === 'ngày mai' || date === 'tomorrow') {
                const tomorrow = new Date();
                tomorrow.setDate(tomorrow.getDate() + 1);
                date = tomorrow.toISOString().split('T')[0];
            } else if (date === 'hôm nay' || date === 'today') {
                date = new Date().toISOString().split('T')[0];
            }
            const confirmedEntities = {
                people: people || null,
                time: time || null,
                date: date || null,
                branch_name: branch || null,
            };
            const isTimeAmbiguous = mergedEntities.time_ambiguous || 
                                    (time && mergedEntities.time_hour && mergedEntities.time_hour >= 1 && mergedEntities.time_hour <= 11);
            if (isTimeAmbiguous && mergedEntities.time_hour) {
                const timeHour = mergedEntities.time_hour;
                return {
                    response: `Tôi hiểu bạn muốn đặt bàn vào lúc ${timeHour} giờ. Bạn muốn đặt vào buổi nào?\n\nBuổi sáng (${timeHour}:00)\nBuổi chiều (${timeHour + 12}:00)\n\nVui lòng cho tôi biết bạn muốn đặt vào buổi sáng hay chiều?`,
                    intent: 'ask_time_period',
                    entities: {
                        ...confirmedEntities,
                        time: null, 
                        time_hour: timeHour
                    }
                };
            }
            const missingInfo = [];
            if (!confirmedEntities.people) missingInfo.push('số người');
            if (!confirmedEntities.time) missingInfo.push('giờ');
            if (!confirmedEntities.date) missingInfo.push('ngày');
            if (!confirmedEntities.branch_name) missingInfo.push('chi nhánh');
            if (missingInfo.length > 0) {
                const BookingValidator = require('./validators/BookingValidator');
                const missingFields = [];
                if (!confirmedEntities.people) missingFields.push('people');
                if (!confirmedEntities.time) missingFields.push('time');
                if (!confirmedEntities.date) missingFields.push('date');
                if (!confirmedEntities.branch_name) missingFields.push('branch_name');
                response = BookingValidator.buildMissingInfoPrompt(missingFields, confirmedEntities);
                if (missingInfo.includes('chi nhánh')) {
                    try {
                        const allBranches = await BranchHandler.getAllActiveBranches();
                        if (allBranches.length > 0) {
                            const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                            response += `\n\nDanh sách chi nhánh:\n\n${branchList.join('\n\n')}`;
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                return { 
                    response, 
                    intent: 'ask_info', 
                    entities: confirmedEntities
                };
            }
            if (!branch) {
                try {
                    const allBranches = await BranchHandler.getAllActiveBranches();
                    if (allBranches.length > 0) {
                        const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                        response = `Tôi hiểu bạn muốn đặt bàn cho ${people || '?'} người vào ${time || '?'} ngày ${date || '?'}. Bạn muốn đặt bàn tại chi nhánh nào?\n\n${branchList.join('\n\n')}\n\nVui lòng cho tôi biết tên chi nhánh bạn muốn đến.`;
                    } else {
                        response = `Tôi hiểu bạn muốn đặt bàn cho ${people || '?'} người vào ${time || '?'} ngày ${date || '?'}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                    }
                } catch {
                    response = `Tôi hiểu bạn muốn đặt bàn cho ${people || '?'} người vào ${time || '?'} ngày ${date || '?'}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                }
                return { 
                    response, 
                    intent: 'ask_info', 
                    entities: confirmedEntities
                };
            }
            if (!date) {
                response = `Tôi hiểu bạn đồng ý đặt bàn cho ${people} người vào ${time} tại ${branch}, nhưng tôi cần biết ngày đặt bàn.\n\nBạn muốn đặt bàn:\n- Hôm nay\n- Ngày mai\n\nHoặc bạn có thể cho biết ngày cụ thể?`;
                return { 
                    response, 
                    intent: 'ask_info', 
                    entities: confirmedEntities
                };
            }
            if (time && branch) {
                let branchToCheck = null;
                if (confirmedEntities.branch_id) {
                    branchToCheck = await BranchHandler.getBranchById(confirmedEntities.branch_id);
                } else if (branch) {
                    branchToCheck = await BranchHandler.getBranchByName(branch);
                }
                if (branchToCheck) {
                    const isWithinHours = BranchHandler.isTimeWithinOperatingHours(time, branchToCheck);
                    if (!isWithinHours) {
                        const openBranches = await BranchHandler.getBranchesOpenAtTime(time);
                        let errorMessage = `Chi nhánh ${branchToCheck.name} không hoạt động vào lúc ${time}.\n\n`;
                        errorMessage += `Giờ làm việc của chi nhánh này: ${BranchHandler.formatOperatingHours(branchToCheck)}\n\n`;
                        if (openBranches.length > 0) {
                            errorMessage += `Các chi nhánh còn hoạt động vào lúc ${time}:\n\n`;
                            const branchList = await BranchIntentHandler.formatBranchListWithDetails(openBranches);
                            errorMessage += branchList.join('\n\n');
                            errorMessage += `\n\nBạn có muốn đặt bàn tại một trong các chi nhánh này không?`;
                        } else {
                            errorMessage += `Hiện tại không có chi nhánh nào hoạt động vào lúc ${time}.\n\n`;
                            errorMessage += `Vui lòng chọn giờ khác hoặc liên hệ trực tiếp với nhà hàng.`;
                        }
                        return {
                            response: errorMessage,
                            intent: 'book_table_warning',
                            entities: confirmedEntities
                        };
                    }
                    const closeCheck = BranchHandler.checkIfCloseToClosing(time, branchToCheck, 60);
                    if (closeCheck && closeCheck.isClose) {
                        const remainingMinutes = closeCheck.remainingMinutes;
                        const hours = Math.floor(remainingMinutes / 60);
                        const minutes = remainingMinutes % 60;
                        let timeWarning = `Lưu ý: Chi nhánh ${branchToCheck.name} sẽ đóng cửa sau `;
                        if (hours > 0) {
                            timeWarning += `${hours} giờ `;
                        }
                        if (minutes > 0) {
                            timeWarning += `${minutes} phút`;
                        } else if (hours === 0) {
                            timeWarning += `${remainingMinutes} phút`;
                        }
                        timeWarning += ` (lúc ${branchToCheck.close_hours}h).\n\n`;
                        timeWarning += `Bạn vẫn có thể đặt bàn, nhưng vui lòng đến đúng giờ để đảm bảo có đủ thời gian thưởng thức bữa ăn.\n\n`;
                        timeWarning += `Giờ làm việc: ${BranchHandler.formatOperatingHours(branchToCheck)}\n\n`;
                        try {
                            const reservation = await BookingHandler.createActualReservation(context.user?.id, confirmedEntities);
                            response = timeWarning + `ĐẶT BÀN THÀNH CÔNG!\n\nThông tin đặt bàn:\nSố người: ${people}\nNgày: ${date}\nGiờ: ${time}\nChi nhánh: ${branch}\nBàn: #${reservation.table_id || reservation.id} (Tầng ${reservation.floor_id})\n\nBạn có muốn đặt món kèm theo không?\n\nBạn có thể chọn món từ menu của chi nhánh ${branch} để đặt kèm với đặt bàn này.`;
                            return {
                                response,
                                intent: 'reservation_created',
                                entities: {
                                    ...confirmedEntities,
                                    reservation_id: reservation.id,
                                    table_id: reservation.table_id || reservation.id,
                                    floor_id: reservation.floor_id
                                },
                                suggestions: [
                                    { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: reservation.branch_id, reservation_id: reservation.id } },
                                    { text: 'Xem menu đầy đủ', action: 'view_menu', data: { branch_id: reservation.branch_id } },
                                    { text: 'Không, cảm ơn', action: 'skip_order', data: {} }
                                ]
                            };
                        } catch (error) {
                            response = timeWarning + `\n\nKhông thể đặt bàn: ${error.message}\n\nVui lòng thử lại với thời gian khác hoặc liên hệ trực tiếp với nhà hàng.`;
                            return {
                                response,
                                intent: 'reservation_failed',
                                entities: confirmedEntities
                            };
                        }
                    }
                }
            }
            try {
                const reservation = await BookingHandler.createActualReservation(context.user?.id, confirmedEntities);
                response = `ĐẶT BÀN THÀNH CÔNG!\n\nThông tin đặt bàn:\nSố người: ${people}\nNgày: ${date}\nGiờ: ${time}\nChi nhánh: ${branch}\nBàn: #${reservation.table_id || reservation.id} (Tầng ${reservation.floor_id})\n\nBạn có muốn đặt món kèm theo không?\n\nBạn có thể chọn món từ menu của chi nhánh ${branch} để đặt kèm với đặt bàn này.`;
                return {
                    response,
                    intent: 'reservation_created',
                    entities: {
                        ...confirmedEntities,
                        reservation_id: reservation.id,
                        table_id: reservation.table_id || reservation.id,
                        floor_id: reservation.floor_id
                    },
                    suggestions: [
                        { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: reservation.branch_id, reservation_id: reservation.id } },
                        { text: 'Xem menu đầy đủ', action: 'view_menu', data: { branch_id: reservation.branch_id } },
                        { text: 'Không, cảm ơn', action: 'skip_order', data: {} }
                    ]
                };
            } catch (error) {
                response = `Không thể đặt bàn: ${error.message}\n\nVui lòng thử lại với thời gian khác hoặc liên hệ trực tiếp với nhà hàng.`;
                return {
                    response,
                    intent: 'reservation_failed',
                    entities: confirmedEntities
                };
            }
        }
        const isOrderingFood = intent === 'order_food' || intent === 'order_food_specific_branch' || 
                               lower.match(/(đặt món|order|thêm món|add|món|dish)/i) ||
                               normalized.match(/(dat mon|order|them mon|add|mon|dish)/i);
        const isBookingRequest = intent === 'book_table' || 
                                lower.match(/(đặt bàn|book|reservation|chỗ ngồi|đặt chỗ|muốn đặt bàn|tôi muốn đặt bàn|dat ban|book|reservation|cho ngoi|dat cho|muon dat ban|toi muon dat ban)/i) ||
                                normalized.match(/(dat ban|book|reservation|cho ngoi|dat cho|muon dat ban|toi muon dat ban)/i);
        if ((isNegative.test(userMessage) || isNegative.test(lower) || isNegative.test(normalized)) &&
            (lastIntent === 'book_table' || lastIntent === 'book_table_partial' || lastIntent === 'book_table_confirmed') &&
            !isOrderingFood &&
            !isBookingRequest) {
            response = 'Đã hủy thao tác đặt bàn hiện tại. Bạn muốn tôi hỗ trợ điều gì tiếp theo?';
            return { response, intent: 'book_table_cancelled', entities: {} };
        }
        switch (intent) {
            case 'ask_time_period': {
                const lower = userMessage.toLowerCase();
                const normalized = Utils.normalizeVietnamese(lower);
                const isMorning = /(sáng|sang|morning|am)/i.test(lower) || /(sang|morning|am)/i.test(normalized);
                const isAfternoon = /(chiều|tối|chieu|toi|afternoon|pm|evening)/i.test(lower) || /(chieu|toi|afternoon|pm|evening)/i.test(normalized);
                if (isMorning || isAfternoon) {
                    const timeHour = mergedEntities.time_hour || context.conversationContext?.time_hour;
                    if (timeHour && timeHour >= 1 && timeHour <= 11) {
                        let finalTime;
                        if (isMorning) {
                            finalTime = `${timeHour.toString().padStart(2, '0')}:00`;
                        } else {
                            finalTime = `${(timeHour + 12).toString().padStart(2, '0')}:00`;
                        }
                        const updatedEntities = {
                            ...mergedEntities,
                            time: finalTime,
                            reservation_time: finalTime,
                            time_slot: finalTime,
                            time_ambiguous: false,
                            time_hour: null
                        };
                        const bookingResult = await BookingHandler.handleSmartBooking(userMessage, {
                            ...context,
                            conversationContext: {
                                ...context.conversationContext,
                                lastEntities: updatedEntities,
                                lastIntent: 'book_table'
                            }
                        });
                        if (bookingResult && bookingResult.message) {
                            return bookingResult;
                        }
                    }
                }
                response = 'Bạn muốn đặt bàn vào buổi sáng hay chiều? Vui lòng cho tôi biết rõ hơn.';
                return { response, intent: 'ask_time_period', entities: mergedEntities };
            }
            case 'confirm_booking': {
                const hasBookingInfo = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                const hasTimeInfo = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                const hasDateInfo = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                const hasBranchInfo = mergedEntities.branch_name || mergedEntities.branch;
                if ((lastIntent === 'book_table' || lastIntent === 'book_table_partial' || lastIntent === 'book_table_confirmed' || 
                    lastIntent === 'find_nearest_branch' || lastIntent === 'find_first_branch') && 
                    (hasBookingInfo && hasTimeInfo && hasBranchInfo)) {
                    const people = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                    const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                    let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                    const branch = mergedEntities.branch_name || mergedEntities.branch;
                    if (date === 'ngày mai' || date === 'tomorrow') {
                        const tomorrow = new Date();
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        date = tomorrow.toISOString().split('T')[0];
                    } else if (date === 'hôm nay' || date === 'today') {
                        date = new Date().toISOString().split('T')[0];
                    }
                    const confirmedEntities = {
                        people: people || null,
                        time: time || null,
                        date: date || null,
                        branch_name: branch || null,
                        branch_id: mergedEntities.branch_id || null
                    };
                    if (time && branch) {
                        let branchToCheck = null;
                        if (confirmedEntities.branch_id) {
                            branchToCheck = await BranchHandler.getBranchById(confirmedEntities.branch_id);
                        } else if (branch) {
                            branchToCheck = await BranchHandler.getBranchByName(branch);
                        }
                        if (branchToCheck) {
                            const isWithinHours = BranchHandler.isTimeWithinOperatingHours(time, branchToCheck);
                            if (!isWithinHours) {
                                const openBranches = await BranchHandler.getBranchesOpenAtTime(time);
                                let errorMessage = `Chi nhánh ${branchToCheck.name} không hoạt động vào lúc ${time}.\n\n`;
                                errorMessage += `Giờ làm việc của chi nhánh này: ${BranchHandler.formatOperatingHours(branchToCheck)}\n\n`;
                                if (openBranches.length > 0) {
                                    errorMessage += `Các chi nhánh còn hoạt động vào lúc ${time}:\n\n`;
                                    const branchList = await BranchIntentHandler.formatBranchListWithDetails(openBranches);
                                    errorMessage += branchList.join('\n\n');
                                    errorMessage += `\n\nBạn có muốn đặt bàn tại một trong các chi nhánh này không?`;
                                } else {
                                    errorMessage += `Hiện tại không có chi nhánh nào hoạt động vào lúc ${time}.\n\n`;
                                    errorMessage += `Vui lòng chọn giờ khác hoặc liên hệ trực tiếp với nhà hàng.`;
                                }
                                return {
                                    response: errorMessage,
                                    intent: 'book_table_warning',
                                    entities: confirmedEntities
                                };
                            }
                            const closeCheck = BranchHandler.checkIfCloseToClosing(time, branchToCheck, 60);
                            if (closeCheck && closeCheck.isClose) {
                                const remainingMinutes = closeCheck.remainingMinutes;
                                const hours = Math.floor(remainingMinutes / 60);
                                const minutes = remainingMinutes % 60;
                                let timeWarning = `Lưu ý: Chi nhánh ${branchToCheck.name} sẽ đóng cửa sau `;
                                if (hours > 0) {
                                    timeWarning += `${hours} giờ `;
                                }
                                if (minutes > 0) {
                                    timeWarning += `${minutes} phút`;
                                } else if (hours === 0) {
                                    timeWarning += `${remainingMinutes} phút`;
                                }
                                timeWarning += ` (lúc ${branchToCheck.close_hours}h).\n\n`;
                                timeWarning += `Bạn vẫn có thể đặt bàn, nhưng vui lòng đến đúng giờ để đảm bảo có đủ thời gian thưởng thức bữa ăn.\n\n`;
                                timeWarning += `Giờ làm việc: ${BranchHandler.formatOperatingHours(branchToCheck)}\n\n`;
                                try {
                                    const reservation = await BookingHandler.createActualReservation(context.user?.id, confirmedEntities);
                                    response = timeWarning + `ĐẶT BÀN THÀNH CÔNG!\n\nThông tin đặt bàn:\nSố người: ${people}\nNgày: ${date}\nGiờ: ${time}\nChi nhánh: ${branch}\nBàn: ${(reservation.table_id || reservation.id)} (Tầng ${reservation.floor_id})\n\nBạn có muốn đặt món kèm theo không?\n\nBạn có thể chọn món từ menu của chi nhánh ${branch} để đặt kèm với đặt bàn này.`;
                                    return {
                                        response,
                                        intent: 'reservation_created',
                                        entities: {
                                            ...confirmedEntities,
                                            reservation_id: reservation.id,
                                            table_id: (reservation.table_id || reservation.id),
                                            floor_id: reservation.floor_id
                                        },
                                        suggestions: [
                                            { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: reservation.branch_id, reservation_id: reservation.id } },
                                            { text: 'Xem menu đầy đủ', action: 'view_menu', data: { branch_id: reservation.branch_id } },
                                            { text: 'Không, cảm ơn', action: 'skip_order', data: {} }
                                        ]
                                    };
                                } catch (error) {
                                    response = timeWarning + `\n\nKhông thể đặt bàn: ${error.message}\n\nVui lòng thử lại với thời gian khác hoặc liên hệ trực tiếp với nhà hàng.`;
                                    return {
                                        response,
                                        intent: 'reservation_failed',
                                        entities: confirmedEntities
                                    };
                                }
                            }
                        }
                    }
                    const missingInfo = [];
                    if (!confirmedEntities.people) missingInfo.push('số người');
                    if (!confirmedEntities.time) missingInfo.push('giờ');
                    if (!confirmedEntities.date) missingInfo.push('ngày');
                    if (!confirmedEntities.branch_name) missingInfo.push('chi nhánh');
                    if (missingInfo.length > 0) {
                        const BookingValidator = require('./validators/BookingValidator');
                        const missingFields = [];
                        if (!confirmedEntities.people) missingFields.push('people');
                        if (!confirmedEntities.time) missingFields.push('time');
                        if (!confirmedEntities.date) missingFields.push('date');
                        if (!confirmedEntities.branch_name) missingFields.push('branch_name');
                        response = BookingValidator.buildMissingInfoPrompt(missingFields, confirmedEntities);
                        if (missingInfo.includes('chi nhánh')) {
                            try {
                                const allBranches = await BranchHandler.getAllActiveBranches();
                                if (allBranches.length > 0) {
                                    const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                                    response += `\n\nDanh sách chi nhánh:\n\n${branchList.join('\n\n')}`;
                                }
                            } catch (error) {
                                console.error('[LegacyFallbackService] Error getting all active branches:', error);
                            }
                        }
                        return { 
                            response, 
                            intent: 'ask_info', 
                            entities: confirmedEntities
                        };
                    }
                    if (!branch) {
                        try {
                            const allBranches = await BranchHandler.getAllActiveBranches();
                            if (allBranches.length > 0) {
                                const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                                response = `Tôi hiểu bạn muốn đặt bàn cho ${people || '?'} người vào ${time || '?'} ngày ${date || '?'}. Bạn muốn đặt bàn tại chi nhánh nào?\n\n${branchList.join('\n\n')}\n\nVui lòng cho tôi biết tên chi nhánh bạn muốn đến.`;
                            } else {
                                response = `Tôi hiểu bạn muốn đặt bàn cho ${people || '?'} người vào ${time || '?'} ngày ${date || '?'}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                            }
                        } catch {
                            response = `Tôi hiểu bạn muốn đặt bàn cho ${people || '?'} người vào ${time || '?'} ngày ${date || '?'}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                        }
                        return { 
                            response, 
                            intent: 'ask_info', 
                            entities: confirmedEntities
                        };
                    }
                    if (!date) {
                        response = `Tôi hiểu bạn đồng ý đặt bàn cho ${people} người vào ${time} tại ${branch}, nhưng tôi cần biết ngày đặt bàn.\n\nBạn muốn đặt bàn:\n- Hôm nay\n- Ngày mai\n\nHoặc bạn có thể cho biết ngày cụ thể?`;
                        return { 
                            response, 
                            intent: 'ask_info', 
                            entities: {
                                people: people,
                                time: time,
                                branch_name: branch,
                                date: null
                            }
                        };
                    }
                    try {
                        const reservation = await BookingHandler.createActualReservation(context.user?.id, confirmedEntities);
                        response = `ĐẶT BÀN THÀNH CÔNG!\n\nThông tin đặt bàn:\nSố người: ${people}\nNgày: ${date}\nGiờ: ${time}\nChi nhánh: ${branch}\nBàn: ${(reservation.table_id || reservation.id)} (Tầng ${reservation.floor_id})\n\nBạn có muốn đặt món kèm theo không?\n\nBạn có thể chọn món từ menu của chi nhánh ${branch} để đặt kèm với đặt bàn này.`;
                        return {
                            response,
                            intent: 'reservation_created',
                            entities: {
                                ...confirmedEntities,
                                reservation_id: reservation.id,
                                table_id: (reservation.table_id || reservation.id),
                                floor_id: reservation.floor_id
                            },
                            suggestions: [
                                { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: reservation.branch_id, reservation_id: reservation.id } },
                                { text: 'Xem menu đầy đủ', action: 'view_menu', data: { branch_id: reservation.branch_id } },
                                { text: 'Không, cảm ơn', action: 'skip_order', data: {} }
                            ]
                        };
                    } catch (error) {
                        response = `Không thể đặt bàn: ${error.message}\n\nVui lòng thử lại với thời gian khác hoặc liên hệ trực tiếp với nhà hàng.`;
                        return {
                            response,
                            intent: 'reservation_failed',
                            entities: confirmedEntities
                        };
                    }
                } else {
                    const missingInfo = [];
                    if (!hasBookingInfo) missingInfo.push('Số người');
                    if (!hasTimeInfo) missingInfo.push('Giờ');
                    if (!hasDateInfo) missingInfo.push('Ngày');
                    if (!hasBranchInfo) missingInfo.push('Chi nhánh');
                    if (hasBookingInfo && hasTimeInfo && hasBranchInfo && !hasDateInfo) {
                        response = `Tôi hiểu bạn đồng ý đặt bàn cho ${mergedEntities.people} người vào ${mergedEntities.time} tại ${mergedEntities.branch_name}, nhưng tôi cần biết ngày đặt bàn.\n\nBạn muốn đặt bàn:\n- Hôm nay\n- Ngày mai\n\nHoặc bạn có thể cho biết ngày cụ thể?`;
                    } else {
                        response = `Tôi hiểu bạn đồng ý, nhưng tôi không có đủ thông tin đặt bàn để xác nhận. Còn thiếu:\n\n${missingInfo.join('\n')}\n\nBạn có thể cung cấp thông tin còn thiếu không?`;
                    }
                    return { response, intent: 'ask_info', entities: mergedEntities };
                }
            }
            case 'cancel_booking': {
                response = 'Đã hủy thao tác đặt bàn hiện tại. Bạn muốn tôi hỗ trợ điều gì tiếp theo?';
                return { response, intent: 'book_table_cancelled', entities: {} };
            }
            case 'view_menu_specific_branch': {
                let branchNameForMenu = entities.branch_name || mergedEntities.branch_name || mergedEntities.branch || context.conversationContext?.lastBranch || context.branch?.name;
                if (!branchNameForMenu) {
                    const foundBranch = await EntityExtractor.extractBranchFromMessage(userMessage);
                    if (foundBranch) {
                        branchNameForMenu = foundBranch.name;
                        mergedEntities.branch_id = foundBranch.id;
                        mergedEntities.branch_name = foundBranch.name;
                    }
                }
                if (branchNameForMenu) {
                    try {
                        let branch = null;
                        if (mergedEntities.branch_id) {
                            branch = await knex('branches')
                                .where('id', mergedEntities.branch_id)
                                .where('status', 'active')
                                .first();
                        } else {
                            branch = await knex('branches')
                                .where('status', 'active')
                                .where(function() {
                                    this.where('name', 'like', `%${branchNameForMenu}%`)
                                        .orWhere('name', 'like', `%${branchNameForMenu.toLowerCase()}%`)
                                        .orWhere('name', 'like', `%${branchNameForMenu.toUpperCase()}%`);
                                })
                                .first();
                        }
                        if (branch) {
                            const menuItems = await MenuHandler.getMenuForOrdering(branch.id);
                            if (menuItems && menuItems.length > 0) {
                                const groupedMenu = MenuFormatterService.groupByCategory(menuItems);
                                const menuText = MenuFormatterService.formatMenuAsText(groupedMenu, { includeDescription: true });
                                response = `Menu của ${branch.name}:\n\n${menuText}\n\nBạn muốn đặt món nào?`;
                            } else {
                                response = `Hiện tại ${branch.name} chưa có món nào trong menu. Vui lòng liên hệ trực tiếp với nhà hàng.`;
                            }
                        } else {
                            response = `Tôi chưa lấy được dữ liệu chi nhánh "${branchNameForMenu}" từ hệ thống. Bạn có thể cho tôi biết tên chi nhánh chính xác không?`;
                        }
                    } catch {
                        response = 'Có lỗi khi tải menu. Vui lòng thử lại sau.';
                    }
                } else if (context.conversationContext?.lastBranch) {
                    try {
                        const lastBranch = await knex('branches')
                            .where('name', context.conversationContext.lastBranch)
                            .where('status', 'active')
                            .first();
                        if (lastBranch) {
                            const menuItems = await MenuHandler.getMenuForOrdering(lastBranch.id);
                            if (menuItems && menuItems.length > 0) {
                                const groupedMenu = MenuFormatterService.groupByCategory(menuItems);
                                const menuText = MenuFormatterService.formatMenuAsText(groupedMenu, { includeDescription: true });
                                response = `Menu của ${lastBranch.name}:\n\n${menuText}\n\nBạn muốn đặt món nào?`;
                            } else {
                                response = `Hiện tại ${lastBranch.name} chưa có món nào trong menu. Vui lòng liên hệ trực tiếp với nhà hàng.`;
                            }
                        } else {
                            response = 'Tôi hiểu bạn muốn xem menu của chi nhánh cụ thể. Bạn có thể cho tôi biết tên chi nhánh không?';
                        }
                    } catch {
                        response = 'Có lỗi khi tải menu. Vui lòng thử lại sau.';
                    }
                } else {
                    response = 'Tôi hiểu bạn muốn xem menu của chi nhánh cụ thể. Bạn có thể cho tôi biết tên chi nhánh không?';
                }
                break;
            }
            case 'order_food_specific_branch': {
                const reservationId = mergedEntities.reservation_id || context.conversationContext?.lastReservationId;
                const branchId = mergedEntities.branch_id || context.conversationContext?.lastBranchId || context.branch?.id;
                const branchName = mergedEntities.branch_name || mergedEntities.branch || context.conversationContext?.lastBranch || context.branch?.name;
                const lowerForBranch = userMessage.toLowerCase();
                const normalizedForBranch = Utils.normalizeVietnamese(lowerForBranch);
                const isReferringToLastBranch = lowerForBranch.match(/(chi nhánh|chi nhanh|branch).*(vừa|vua|mới|moi|đặt|dat|book|reservation)/i) ||
                                                lowerForBranch.match(/(vừa|vua|mới|moi|đặt|dat|book|reservation).*(chi nhánh|chi nhanh|branch)/i) ||
                                                normalizedForBranch.match(/(chi nhanh|branch).*(vua|moi|dat|book|reservation)/i);
                if (isReferringToLastBranch && (reservationId || branchId)) {
                    if (reservationId) {
                        response = `Tuyệt vời! Bạn muốn đặt món gì cho đặt bàn #${reservationId} tại ${branchName || 'chi nhánh đã chọn'}?\n\nVui lòng cho tôi biết:\n- Tên món ăn cụ thể\n- Số lượng\n- Tùy chọn đặc biệt (nếu có)\n\nTôi sẽ giúp bạn thêm vào giỏ hàng!`;
                    } else {
                        response = `Tuyệt vời! Bạn muốn đặt món tại ${branchName || 'chi nhánh đã chọn'}.\n\nVui lòng cho tôi biết:\n- Tên món ăn cụ thể\n- Số lượng\n- Tùy chọn đặc biệt (nếu có)\n\nTôi sẽ giúp bạn thêm vào giỏ hàng!`;
                    }
                } else if (entities.branch_name || branchName) {
                    response = `Tuyệt vời! Bạn muốn đặt món tại chi nhánh ${entities.branch_name || branchName}.\n\nVui lòng cho tôi biết:\n- Tên món ăn cụ thể\n- Số lượng\n- Tùy chọn đặc biệt (nếu có)\n\nTôi sẽ giúp bạn thêm vào giỏ hàng!`;
                } else {
                    response = 'Tôi hiểu bạn muốn đặt món tại chi nhánh cụ thể. Bạn có thể cho tôi biết tên chi nhánh không?';
                }
                break;
            }
            case 'book_table_specific_branch':
                if (entities.branch_name) {
                    response = `Tuyệt vời! Bạn muốn đặt bàn tại chi nhánh ${entities.branch_name}.\n\nXin cho biết:\nSố người: ?\nNgày: ?\nGiờ: ?\n\nTôi sẽ giúp bạn tìm bàn phù hợp tại chi nhánh này!`;
                } else {
                    response = 'Tôi hiểu bạn muốn đặt bàn tại chi nhánh cụ thể. Bạn có thể cho tôi biết tên chi nhánh không?';
                }
                break;
            case 'find_nearest_branch':
            case 'find_first_branch': {
                const hasBookingInfoForBranch = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                const hasTimeInfoForBranch = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                const hasDateInfoForBranch = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                if ((lastIntent === 'book_table' || lastIntent === 'book_table_partial' || lastIntent === 'reservation_failed' || lastIntent === 'ask_info') &&
                    hasBookingInfoForBranch && hasTimeInfoForBranch && hasDateInfoForBranch) {
                    const people = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                    const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                    let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                    if (date === 'ngày mai' || date === 'tomorrow') {
                        const tomorrow = new Date();
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        date = tomorrow.toISOString().split('T')[0];
                    } else if (date === 'hôm nay' || date === 'today') {
                        date = new Date().toISOString().split('T')[0];
                    }
                    try {
                        const allBranches = await BranchHandler.getAllActiveBranches();
                        if (allBranches.length > 0) {
                            const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                            response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?\n\n${branchList.join('\n\n')}\n\nVui lòng cho tôi biết tên chi nhánh bạn muốn đến.`;
                        } else {
                            response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                        }
                    } catch {
                        response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                    }
                    return { 
                        response, 
                        intent: 'book_table_partial', 
                        entities: {
                            ...mergedEntities,
                            people: people,
                            time: time,
                            date: date,
                            branch_name: null,
                            branch_id: null
                        }
                    };
                }
                if (mergedEntities.district_id || mergedEntities.district_name) {
                    const districtId = mergedEntities.district_id;
                    const districtName = mergedEntities.district_name;
                    let foundBranch = null;
                    let foundDistrict = null;
                    if (districtId) {
                        foundDistrict = await knex('districts')
                            .where('id', districtId)
                            .first();
                    } else if (districtName) {
                        const normalizedDistrictName = districtName.toLowerCase().trim();
                        foundDistrict = await knex('districts')
                            .where('name', 'like', `%${normalizedDistrictName}%`)
                            .orWhere('code', 'like', `%${normalizedDistrictName}%`)
                            .orWhere('name', 'like', `%District ${districtName}%`)
                            .orWhere('name', 'like', `%Quận ${districtName}%`)
                            .orWhere('name', 'like', `%Q${districtName}%`)
                            .first();
                    }
                    if (foundDistrict) {
                        const branches = await knex('branches')
                            .where('district_id', foundDistrict.id)
                            .where('status', 'active')
                            .orderBy('id', 'asc')
                            .limit(1);
                        if (branches.length > 0) {
                            foundBranch = branches[0];
                        }
                    }
                    if (foundBranch && hasBookingInfoForBranch && hasTimeInfoForBranch && hasDateInfoForBranch) {
                        const people = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                        const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                        let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                        if (date === 'ngày mai' || date === 'tomorrow') {
                            const tomorrow = new Date();
                            tomorrow.setDate(tomorrow.getDate() + 1);
                            date = tomorrow.toISOString().split('T')[0];
                        } else if (date === 'hôm nay' || date === 'today') {
                            date = new Date().toISOString().split('T')[0];
                        }
                        const confirmedEntities = {
                            people: people,
                            time: time,
                            date: date,
                            branch_id: foundBranch.id,
                            branch_name: foundBranch.name,
                        };
                        try {
                            const reservation = await BookingHandler.createActualReservation(context.user?.id, confirmedEntities);
                            response = `ĐẶT BÀN THÀNH CÔNG!\n\nThông tin đặt bàn:\nSố người: ${people}\nNgày: ${date}\nGiờ: ${time}\nChi nhánh: ${foundBranch.name}\nBàn: ${(reservation.table_id || reservation.id)} (Tầng ${reservation.floor_id})\n\nBạn có muốn đặt món kèm theo không?\n\nBạn có thể chọn món từ menu của chi nhánh ${foundBranch.name} để đặt kèm với đặt bàn này.`;
                            return {
                                response,
                                intent: 'reservation_created',
                                entities: {
                                    ...confirmedEntities,
                                    reservation_id: reservation.id,
                                    table_id: (reservation.table_id || reservation.id),
                                    floor_id: reservation.floor_id
                                },
                                suggestions: [
                                    { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: reservation.branch_id, reservation_id: reservation.id } },
                                    { text: 'Xem menu đầy đủ', action: 'view_menu', data: { branch_id: reservation.branch_id } },
                                    { text: 'Không, cảm ơn', action: 'skip_order', data: {} }
                                ]
                            };
                        } catch (error) {
                            response = `Không thể đặt bàn: ${error.message}\n\nVui lòng thử lại với thời gian khác hoặc liên hệ trực tiếp với nhà hàng.`;
                            return {
                                response,
                                intent: 'reservation_failed',
                                entities: confirmedEntities
                            };
                        }
                    } else if (foundBranch) {
                        response = `Tôi tìm thấy chi nhánh ${foundBranch.name} ở quận ${districtName || districtId}.\n\nBạn muốn đặt bàn tại đây không? Vui lòng cho tôi biết:\nSố người\nNgày\nGiờ`;
                    } else {
                        try {
                            const allBranches = await knex('branches')
                                .where('status', 'active')
                                .select('id', 'name', 'address_detail', 'phone', 'opening_hours', 'close_hours', 'district_id')
                                .orderBy('id', 'asc');
                            if (allBranches.length > 0) {
                                const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                                response = `Tôi chưa lấy được dữ liệu chi nhánh ở quận ${districtName || districtId} từ hệ thống. Dưới đây là danh sách tất cả các chi nhánh của chúng tôi:\n\n${branchList.join('\n\n')}\n\nBạn có muốn đặt bàn tại chi nhánh nào không?`;
                            } else {
                                response = `Tôi chưa lấy được dữ liệu chi nhánh ở quận ${districtName || districtId} từ hệ thống. Vui lòng liên hệ trực tiếp với nhà hàng để biết thêm thông tin.`;
                            }
                        } catch {
                            response = `Tôi chưa lấy được dữ liệu chi nhánh ở quận ${districtName || districtId} từ hệ thống. Vui lòng liên hệ trực tiếp với nhà hàng để biết thêm thông tin.`;
                        }
                    }
                } else {
                    try {
                        if (intent === 'find_nearest_branch') {
                            const allBranches = await BranchHandler.getAllActiveBranches();
                            const nearestBranch = allBranches.length > 0 ? allBranches[0] : null;
                            if (nearestBranch) {
                                const address = nearestBranch.address_detail || '';
                                const phone = nearestBranch.phone || '';
                                const openingHours = nearestBranch.opening_hours ? `${nearestBranch.opening_hours}h` : '';
                                const closeHours = nearestBranch.close_hours ? `${nearestBranch.close_hours}h` : '';
                                const hours = openingHours && closeHours ? `${openingHours} - ${closeHours}` : (openingHours || closeHours || '');
                                let branchInfo = `Chi nhánh gần nhất của Beast Bite:\n\n${nearestBranch.name}`;
                                if (address) branchInfo += `\n${address}`;
                                if (phone) branchInfo += `\n${phone}`;
                                if (hours) branchInfo += `\n${hours}`;
                                branchInfo += `\n\nBạn muốn đặt bàn tại đây không?`;
                                response = branchInfo;
                            } else {
                                response = 'Tôi chưa lấy được dữ liệu chi nhánh đang hoạt động từ hệ thống. Vui lòng liên hệ trực tiếp với nhà hàng.';
                            }
                        } else {
                            const allBranches = await BranchHandler.getAllActiveBranches();
                            const firstBranch = allBranches.length > 0 ? allBranches[0] : null;
                            if (firstBranch) {
                                const address = firstBranch.address_detail || '';
                                const phone = firstBranch.phone || '';
                                const openingHours = firstBranch.opening_hours ? `${firstBranch.opening_hours}h` : '';
                                const closeHours = firstBranch.close_hours ? `${firstBranch.close_hours}h` : '';
                                const hours = openingHours && closeHours ? `${openingHours} - ${closeHours}` : (openingHours || closeHours || '');
                                let branchInfo = `Chi nhánh đầu tiên của Beast Bite:\n\n${firstBranch.name}`;
                                if (address) branchInfo += `\n${address}`;
                                if (phone) branchInfo += `\n${phone}`;
                                if (hours) branchInfo += `\n${hours}`;
                                branchInfo += `\n\nBạn muốn xem menu hoặc đặt bàn tại đây không?`;
                                response = branchInfo;
                            } else {
                                response = 'Tôi chưa lấy được dữ liệu chi nhánh đang hoạt động từ hệ thống. Vui lòng liên hệ trực tiếp với nhà hàng.';
                            }
                        }
                    } catch {
                        response = 'Có lỗi khi tìm kiếm chi nhánh. Vui lòng thử lại sau.';
                    }
                }
                break;
            }
            case 'view_menu': {
                let menuBranchId = mergedEntities.branch_id || context.branch?.id || context.conversationContext?.lastBranchId;
                let menuBranchName = mergedEntities.branch_name || mergedEntities.branch || context.conversationContext?.lastBranch || context.branch?.name;
                if (!menuBranchId && !menuBranchName) {
                    try {
                        const foundBranch = await EntityExtractor.extractBranchFromMessage(userMessage);
                        if (foundBranch) {
                            menuBranchId = foundBranch.id;
                            menuBranchName = foundBranch.name;
                            mergedEntities.branch_id = foundBranch.id;
                            mergedEntities.branch_name = foundBranch.name;
                            mergedEntities.branch = foundBranch.name;
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                if (menuBranchName && !menuBranchId) {
                    try {
                        const foundBranch = await knex('branches')
                            .where('status', 'active')
                            .where(function() {
                                this.where('name', 'like', `%${menuBranchName}%`)
                                    .orWhereRaw('LOWER(name) LIKE ?', [`%${menuBranchName.toLowerCase()}%`]);
                            })
                            .first();
                        if (foundBranch) {
                            menuBranchId = foundBranch.id;
                            menuBranchName = foundBranch.name;
                            mergedEntities.branch_id = foundBranch.id;
                            mergedEntities.branch_name = foundBranch.name;
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                if (menuBranchId) {
                    try {
                        const menuItems = await MenuHandler.getMenuForOrdering(menuBranchId);
                        const branch = await knex('branches')
                            .where('id', menuBranchId)
                            .first();
                        if (menuItems && menuItems.length > 0) {
                            const groupedMenu = MenuFormatterService.groupByCategory(menuItems);
                            const menuText = MenuFormatterService.formatMenuAsText(groupedMenu, { includeDescription: true });
                            response = `Menu của ${branch?.name || menuBranchName || 'chi nhánh'}:\n\n${menuText}\n\nBạn muốn đặt món nào?`;
                        } else {
                            response = `Hiện tại ${branch?.name || menuBranchName || 'chi nhánh này'} chưa có món nào trong menu. Vui lòng liên hệ trực tiếp với nhà hàng.`;
                        }
                    } catch {
                        response = 'Có lỗi khi tải menu. Vui lòng thử lại sau.';
                    }
                } else {
                    try {
                        const allBranches = await BranchHandler.getAllActiveBranches();
                        if (allBranches.length > 0) {
                            const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                            response = `Chúng tôi có menu đa dạng với nhiều món ăn ngon. Bạn muốn xem menu của chi nhánh nào?\n\n${branchList.join('\n\n')}\n\nVui lòng cho tôi biết tên chi nhánh hoặc quận bạn muốn xem menu.`;
                        } else {
                            response = 'Tôi chưa lấy được dữ liệu chi nhánh đang hoạt động từ hệ thống. Vui lòng liên hệ trực tiếp với nhà hàng.';
                        }
                    } catch {
                        response = 'Có lỗi khi tải danh sách chi nhánh. Vui lòng thử lại sau.';
                    }
                }
                break;
            }
            case 'order_food': {
                let lastReservationId = mergedEntities.reservation_id || context.conversationContext?.lastReservationId;
                let lastBranchId = mergedEntities.branch_id || context.conversationContext?.lastBranchId || context.branch?.id;
                let lastBranchName = mergedEntities.branch_name || context.conversationContext?.lastBranch || context.branch?.name;
                if (lastReservationId && !lastBranchId) {
                    try {
                        const reservation = await knex('reservations')
                            .where('id', lastReservationId)
                            .first();
                        if (reservation) {
                            lastBranchId = reservation.branch_id;
                            const branch = await knex('branches')
                                .where('id', lastBranchId)
                                .first();
                            if (branch) {
                                lastBranchName = branch.name;
                            }
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                const quantityMatch = userMessage.match(/^\d+/);
                const quantity = quantityMatch ? parseInt(quantityMatch[0]) : (entities.quantity || 1);
                let dishKeyword = userMessage.replace(/^\d+\s+/, '').trim(); 
                dishKeyword = dishKeyword.replace(/\b(món|mon|dish|đặt|dat|thêm|them|add|order)\b/gi, '').trim(); 
                if (lastBranchId && dishKeyword && dishKeyword.length >= 2) {
                    try {
                        const dishResults = await MenuHandler.searchFoodItems(dishKeyword, lastBranchId);
                        if (dishResults.length > 0) {
                            const dish = dishResults[0]; 
                            const branchName = lastBranchName || 'chi nhánh đã chọn';
                            if (lastReservationId) {
                                response = `Đã thêm ${dish.name} x${quantity} vào đặt bàn #${lastReservationId} tại ${branchName}!\n\nTổng: ${(dish.price * quantity).toLocaleString()}đ\n\nBạn có muốn thêm món khác không?`;
                            } else {
                                response = `Đã thêm ${dish.name} x${quantity} vào giỏ hàng tại ${branchName}!\n\nTổng: ${(dish.price * quantity).toLocaleString()}đ\n\nBạn có muốn thêm món khác không?`;
                            }
                            mergedEntities.dish = dish.name;
                            mergedEntities.product_id = dish.id;
                            mergedEntities.quantity = quantity;
                            mergedEntities.branch_id = lastBranchId;
                            mergedEntities.branch_name = branchName;
                        } else {
                            if (lastReservationId) {
                                response = `Tôi không tìm thấy món "${dishKeyword}" trong menu tại ${lastBranchName}.\n\nBạn có thể:\n• Kiểm tra lại tên món\n• Xem menu đầy đủ\n• Thử tìm món khác`;
                            } else {
                                response = `Tôi không tìm thấy món "${dishKeyword}" trong menu.\n\nBạn có thể:\n• Kiểm tra lại tên món\n• Xem menu đầy đủ\n• Thử tìm món khác`;
                            }
                        }
                    } catch {
                        response = 'Có lỗi khi tìm kiếm món ăn. Bạn có thể xem toàn bộ menu thay thế.';
                    }
                } else if (lastReservationId || lastBranchId) {
                    if (lastReservationId) {
                        response = `Tuyệt vời! Bạn muốn đặt món gì cho đặt bàn #${lastReservationId} tại ${lastBranchName}?\n\nVui lòng cho tôi biết:\n- Tên món ăn\n- Số lượng\n\nTôi sẽ giúp bạn thêm vào giỏ hàng!`;
                    } else {
                        response = `Tuyệt vời! Bạn muốn đặt món gì tại ${lastBranchName || 'chi nhánh đã chọn'}?\n\nVui lòng cho tôi biết:\n- Tên món ăn\n- Số lượng\n\nTôi sẽ giúp bạn thêm vào giỏ hàng!`;
                    }
                } else {
                response = 'Tuyệt vời! Bạn muốn đặt món gì?\n\nVui lòng cho tôi biết:\n- Tên món ăn\n- Số lượng\n- Chi nhánh (nếu chưa chọn)\n\nTôi sẽ giúp bạn thêm vào giỏ hàng!';
                }
                break;
            }
            case 'view_orders': {
                if (context.recentOrders && context.recentOrders.length > 0) {
                    response = `Bạn có ${context.recentOrders.length} đơn hàng gần đây.\n\nĐơn gần nhất:\nTổng: ${context.recentOrders[0].total}đ\nTrạng thái: ${context.recentOrders[0].status}\n\nBạn muốn xem chi tiết đơn hàng nào?`;
                } else {
                    response = 'Bạn chưa có đơn hàng nào.\n\nHãy đặt món ngay để trải nghiệm những món ăn tuyệt vời của chúng tôi! ';
                }
                break;
            }
            case 'ask_branch':
            case 'view_branches': {
                let finalDistrictId = mergedEntities.district_id;
                let finalProvinceId = null;
                let finalProvinceName = null;
                if (!finalDistrictId) {
                    try {
                        let searchTerm = mergedEntities.district_search_term || mergedEntities.district_name;
                        if (searchTerm) {
                            mergedEntities.district_search_term = searchTerm;
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                if (finalProvinceId && !finalDistrictId) {
                    try {
                        const searchTerm = mergedEntities.district_search_term || mergedEntities.district_name || '';
                        let allBranchesInProvince = [];
                        if (searchTerm) {
                            const BranchService = require('../BranchService');
                            allBranchesInProvince = await BranchService.getAllBranches('active', searchTerm);
                        }
                        if (allBranchesInProvince.length > 0) {
                            const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranchesInProvince);
                            const response = `Danh sách ${allBranchesInProvince.length} chi nhánh tại ${finalProvinceName}:\n\n${branchList.join('\n\n')}\n\nBạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`;
                            return {
                                response,
                                intent: 'view_branches',
                                entities: {
                                    ...mergedEntities,
                                    province_id: finalProvinceId,
                                    province_name: finalProvinceName
                                },
                                suggestions: [] 
                            };
                        } else {
                            const searchTerm = mergedEntities.district_search_term || mergedEntities.district_name || finalProvinceName;
                            let foundBranchesBySearch = [];
                            if (context.branchesCache && context.branchesCache.length > 0) {
                                foundBranchesBySearch = BranchHandler.searchBranchesInCache(context.branchesCache, searchTerm);
                            }
                            if (foundBranchesBySearch.length === 0) {
                                try {
                                    const allBranches = await knex('branches')
                                        .where('status', 'active')
                                        .where(function() {
                                            this.where('name', 'like', `%${searchTerm}%`)
                                                .orWhere('address_detail', 'like', `%${searchTerm}%`)
                                                .orWhereRaw('LOWER(name) LIKE ?', [`%${searchTerm.toLowerCase()}%`])
                                                .orWhereRaw('LOWER(address_detail) LIKE ?', [`%${searchTerm.toLowerCase()}%`]);
                                        })
                                        .limit(10);
                                    if (allBranches.length > 0) {
                                        foundBranchesBySearch = allBranches;
                                    }
                                } catch (error) {
                                    console.error('[LegacyFallbackService] Error getting all branches by search term:', error);
                                }
                            }
                            if (foundBranchesBySearch.length > 0) {
                                const branchList = await BranchIntentHandler.formatBranchListWithDetails(foundBranchesBySearch);
                                const response = `Tìm thấy ${foundBranchesBySearch.length} chi nhánh liên quan đến "${searchTerm}":\n\n${branchList.join('\n\n')}\n\nBạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`;
                                return {
                                    response,
                                    intent: 'view_branches',
                                    entities: {
                                        ...mergedEntities,
                                        province_id: finalProvinceId,
                                        province_name: finalProvinceName
                                    },
                                    suggestions: [] 
                                };
                            }
                            const suggestions = [
                                { text: 'Xem tất cả chi nhánh', action: 'view_branches', data: {} },
                                { text: 'Tìm tỉnh/thành phố khác', action: 'ask_branch', data: {} }
                            ];
                            return {
                                response: `Nhà hàng không có chi nhánh tại ${finalProvinceName}.\n\nBạn có thể:\n• Xem tất cả chi nhánh của chúng tôi\n• Tìm chi nhánh tại tỉnh/thành phố khác`,
                                intent: 'view_branches',
                                entities: {
                                    ...mergedEntities,
                                    province_id: finalProvinceId,
                                    province_name: finalProvinceName
                                },
                                suggestions: suggestions
                            };
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                if (finalDistrictId) {
                    try {
                        const branchesInDistrict = await BranchHandler.getBranchesByDistrict(finalDistrictId);
                        const districtName = mergedEntities.district_name || `Quận ${finalDistrictId}`;
                        if (branchesInDistrict.length > 0) {
                            if (branchesInDistrict.length === 1) {
                                const branch = branchesInDistrict[0];
                                const address = branch.address_detail || 'Địa chỉ chưa cập nhật';
                                const phone = branch.phone || '';
                                const hours = BranchHandler.formatOperatingHours(branch) || 'Giờ làm việc chưa cập nhật';
                                let branchInfo = `${branch.name}\n\n`;
                                branchInfo += `${address} (${districtName})`;
                                branchInfo += `\n${hours}`;
                                if (phone) {
                                    branchInfo += `\n${phone}`;
                                }
                                const suggestions = [
                                    { text: 'Đặt bàn tại đây', action: 'book_table', data: { branch_id: branch.id, branch_name: branch.name } },
                                    { text: ' Xem menu', action: 'view_menu', data: { branch_id: branch.id, branch_name: branch.name } },
                                    { text: 'Xem chi nhánh khác', action: 'view_branches', data: {} }
                                ];
                                return {
                                    response: branchInfo,
                                    intent: 'view_branch_info',
                                    entities: {
                                        ...mergedEntities,
                                        branch_id: branch.id,
                                        branch_name: branch.name,
                                        district_id: finalDistrictId,
                                        district_name: districtName
                                    },
                                    suggestions: suggestions
                                };
                            } else {
                                const branchList = await BranchIntentHandler.formatBranchListWithDetails(branchesInDistrict);
                                const response = `Danh sách ${branchesInDistrict.length} chi nhánh tại ${districtName}:\n\n${branchList.join('\n\n')}\n\nBạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`;
                                return {
                                    response,
                                    intent: 'view_branches',
                                    entities: {
                                        ...mergedEntities,
                                        district_id: finalDistrictId,
                                        district_name: districtName
                                    },
                                    suggestions: [] 
                                };
                            }
                        } else {
                            const searchTerm = mergedEntities.district_search_term || mergedEntities.district_name || districtName;
                            let foundBranchesBySearch = [];
                            if (context.branchesCache && context.branchesCache.length > 0) {
                                foundBranchesBySearch = BranchHandler.searchBranchesInCache(context.branchesCache, searchTerm);
                            }
                            if (foundBranchesBySearch.length === 0) {
                                try {
                                    const allBranches = await knex('branches')
                                        .where('status', 'active')
                                        .where(function() {
                                            this.where('name', 'like', `%${searchTerm}%`)
                                                .orWhere('address_detail', 'like', `%${searchTerm}%`)
                                                .orWhereRaw('LOWER(name) LIKE ?', [`%${searchTerm.toLowerCase()}%`])
                                                .orWhereRaw('LOWER(address_detail) LIKE ?', [`%${searchTerm.toLowerCase()}%`]);
                                        })
                                        .limit(10);
                                    if (allBranches.length > 0) {
                                        foundBranchesBySearch = allBranches;
                                    }
                                } catch (error) {
                                    console.error('[LegacyFallbackService] Error getting all branches by search term:', error);
                                }
                            }
                            if (foundBranchesBySearch.length > 0) {
                                const branchList = await BranchIntentHandler.formatBranchListWithDetails(foundBranchesBySearch);
                                const response = `Tìm thấy ${foundBranchesBySearch.length} chi nhánh liên quan đến "${searchTerm}":\n\n${branchList.join('\n\n')}\n\nBạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`;
                                return {
                                    response,
                                    intent: 'view_branches',
                                    entities: {
                                        ...mergedEntities,
                                        district_id: finalDistrictId,
                                        district_name: districtName
                                    },
                                    suggestions: [] 
                                };
                            }
                            const suggestions = [
                                { text: 'Xem tất cả chi nhánh', action: 'view_branches', data: {} },
                                { text: 'Tìm quận/huyện khác', action: 'ask_branch', data: {} }
                            ];
                            return {
                                response: `Nhà hàng không có chi nhánh tại ${districtName}.\n\nBạn có thể:\n• Xem tất cả chi nhánh của chúng tôi\n• Tìm chi nhánh tại quận/huyện khác`,
                                intent: 'view_branches',
                                entities: {
                                    ...mergedEntities,
                                    district_id: finalDistrictId,
                                    district_name: districtName
                                },
                                suggestions: suggestions
                            };
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                const foundBranch = await EntityExtractor.extractBranchFromMessage(userMessage);
                if (foundBranch) {
                    try {
                        const districtName = '';
                        const address = foundBranch.address_detail || 'Địa chỉ chưa cập nhật';
                        const phone = foundBranch.phone || '';
                        const hours = BranchHandler.formatOperatingHours(foundBranch) || 'Giờ làm việc chưa cập nhật';
                        let branchInfo = `🏢 ${foundBranch.name}\n\n`;
                        branchInfo += `${address}`;
                        if (districtName) {
                            branchInfo += ` (${districtName})`;
                        }
                        branchInfo += `\n${hours}`;
                        if (phone) {
                            branchInfo += `\n${phone}`;
                        }
                        const suggestions = [
                            { text: 'Đặt bàn tại đây', action: 'book_table', data: { branch_id: foundBranch.id, branch_name: foundBranch.name } },
                            { text: ' Xem menu', action: 'view_menu', data: { branch_id: foundBranch.id, branch_name: foundBranch.name } },
                            { text: 'Xem chi nhánh khác', action: 'view_branches', data: {} }
                        ];
                        return {
                            response: branchInfo,
                            intent: 'view_branch_info',
                            entities: {
                                ...mergedEntities,
                                branch_id: foundBranch.id,
                                branch_name: foundBranch.name
                            },
                            suggestions: suggestions
                        };
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error:', error.message);
                    }
                }
                try {
                    const hasBookingInfo = mergedEntities.people || mergedEntities.time || mergedEntities.date ||
                                        mergedEntities.number_of_people || mergedEntities.reservation_time || mergedEntities.reservation_date;
                    const { branches: allBranches, suggestions: branchSuggestions } = await BranchHandler.getBranchesWithSuggestions(
                        hasBookingInfo ? 'book_table' : 'view_branches',
                        hasBookingInfo ? mergedEntities : {}
                    );
                    if (allBranches.length > 0) {
                        if (hasBookingInfo) {
                            const bookingInfo = [];
                            if (mergedEntities.people) bookingInfo.push(`${mergedEntities.people} người`);
                            if (mergedEntities.time) bookingInfo.push(`${mergedEntities.time}`);
                            if (mergedEntities.date) bookingInfo.push(`${mergedEntities.date}`);
                            response = `Dựa trên thông tin đặt bàn của bạn:\n${bookingInfo.join('\n')}\n\nBạn muốn đặt bàn tại chi nhánh nào? Vui lòng chọn chi nhánh từ danh sách bên dưới:`;
                            return {
                                response,
                                intent: 'ask_branch',
                                entities: mergedEntities,
                                suggestions: branchSuggestions
                            };
                        } else {
                            const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                            response = `Danh sách ${allBranches.length} chi nhánh của Beast Bite:\n\n${branchList.join('\n\n')}\n\nBạn muốn xem menu hoặc đặt bàn tại chi nhánh nào?`;
                            return {
                                response,
                                intent: 'ask_branch',
                                entities: mergedEntities,
                                suggestions: [] 
                            };
                        }
                    } else {
                        response = 'Hiện tại không có chi nhánh nào đang hoạt động. Vui lòng liên hệ trực tiếp với nhà hàng.';
                    }
                } catch {
                    response = 'Có lỗi khi tải danh sách chi nhánh. Vui lòng thử lại sau.';
                }
                break;
            }
            case 'search_food': {
                const searchReservationId = mergedEntities.reservation_id || context.conversationContext?.lastReservationId;
                const searchBranchId = mergedEntities.branch_id || context.conversationContext?.lastBranchId || context.branch?.id;
                const searchKeyword = MenuHandler.extractFoodSearchKeyword(userMessage);
                if (searchKeyword && searchKeyword !== 'món ăn') {
                    try {
                        let branchIdForSearch = searchBranchId || context.branch?.id;
                        const searchResults = await MenuHandler.searchFoodItems(searchKeyword, branchIdForSearch);
                        if (searchResults.length > 0) {
                            const isQuestion = /(có|co).*(không|khong)/i.test(userMessage);
                            if (isQuestion) {
                                const branchName = mergedEntities.branch_name || context.conversationContext?.lastBranch || context.branch?.name || 'tất cả chi nhánh';
                                if (searchResults.length === 1) {
                                    const item = searchResults[0];
                                    try {
                                        const ProductService = require('./ProductService');
                                        const options = await ProductService.getProductOptions(item.id);
                                        let optionsText = '';
                                        if (options && options.length > 0) {
                                            const optionsList = options.map(opt => {
                                                const valuesList = opt.values.map(val => {
                                                    const priceModifier = val.price_modifier ? 
                                                        (val.price_modifier > 0 ? ` (+${val.price_modifier.toLocaleString()}đ)` : 
                                                         val.price_modifier < 0 ? ` (${val.price_modifier.toLocaleString()}đ)` : '') : '';
                                                    return `  - ${val.value}${priceModifier}`;
                                                }).join('\n');
                                                return `${opt.name}${opt.required ? ' (Bắt buộc)' : ''}:\n${valuesList}`;
                                            }).join('\n\n');
                                            optionsText = `\n\nTùy chọn:\n${optionsList}`;
                                        }
                                        response = `Có! Chúng tôi có món ${item.name} tại ${branchName}.\n\nGiá: ${item.price.toLocaleString()}đ\n${item.description || 'Món ăn ngon miệng'}${optionsText}\n\nBạn có muốn đặt món này không?`;
                                    } catch {
                                        response = `Có! Chúng tôi có món ${item.name} tại ${branchName}.\n\nGiá: ${item.price.toLocaleString()}đ\n${item.description || 'Món ăn ngon miệng'}\n\nBạn có muốn đặt món này không?`;
                                    }
                                } else {
                                    const itemsList = searchResults.map(item => 
                                        `• ${item.name} - ${item.price.toLocaleString()}đ`
                                    ).join('\n');
                                    response = `Có! Chúng tôi có ${searchResults.length} món liên quan đến "${searchKeyword}" tại ${branchName}:\n\n${itemsList}\n\nBạn muốn đặt món nào?`;
                                }
                            } else {
                                const quantityMatch = userMessage.match(/(\d+)\s+/);
                                const quantity = quantityMatch ? parseInt(quantityMatch[1]) : null;
                                if (quantity && searchResults.length === 1) {
                                    const item = searchResults[0];
                                    const branchName = mergedEntities.branch_name || context.conversationContext?.lastBranch || context.branch?.name || 'chi nhánh đã chọn';
                                    try {
                                        const ProductService = require('./ProductService');
                                        const options = await ProductService.getProductOptions(item.id);
                                        let optionsText = '';
                                        if (options && options.length > 0) {
                                            const optionsList = options.map(opt => {
                                                const valuesList = opt.values.map(val => {
                                                    const priceModifier = val.price_modifier ? 
                                                        (val.price_modifier > 0 ? ` (+${val.price_modifier.toLocaleString()}đ)` : 
                                                         val.price_modifier < 0 ? ` (${val.price_modifier.toLocaleString()}đ)` : '') : '';
                                                    return `  - ${val.value}${priceModifier}`;
                                                }).join('\n');
                                                return `${opt.name}${opt.required ? ' (Bắt buộc)' : ''}:\n${valuesList}`;
                                            }).join('\n\n');
                                            optionsText = `\n\nTùy chọn:\n${optionsList}`;
                                        }
                                        if (searchReservationId) {
                                            response = `Đã thêm ${item.name} x${quantity} vào đặt bàn #${searchReservationId} tại ${branchName}!\n\nGiá: ${item.price.toLocaleString()}đ${optionsText}\n\nBạn có muốn thêm món khác không?`;
                                        } else if (searchBranchId) {
                                            response = `Đã thêm ${item.name} x${quantity} vào giỏ hàng tại ${branchName}!\n\nGiá: ${item.price.toLocaleString()}đ${optionsText}\n\nBạn có muốn thêm món khác không?`;
                                        } else {
                                            response = `Kết quả tìm kiếm cho "${searchKeyword}":\n\n• ${item.name} x${quantity} - ${(item.price * quantity).toLocaleString()}đ\n  ${item.description || ''}${optionsText}\n\nBạn muốn đặt món này tại chi nhánh nào?`;
                                        }
                                    } catch {
                                        if (searchReservationId) {
                                            response = `Đã thêm ${item.name} x${quantity} vào đặt bàn #${searchReservationId} tại ${branchName}!\n\nBạn có muốn thêm món khác không?`;
                                        } else if (searchBranchId) {
                                            response = `Đã thêm ${item.name} x${quantity} vào giỏ hàng tại ${branchName}!\n\nBạn có muốn thêm món khác không?`;
                                        } else {
                                            response = `Kết quả tìm kiếm cho "${searchKeyword}":\n\n• ${item.name} x${quantity} - ${(item.price * quantity).toLocaleString()}đ\n  ${item.description || ''}\n\nBạn muốn đặt món này tại chi nhánh nào?`;
                                        }
                                    }
                                } else {
                                    const resultsWithOptions = await Promise.all(searchResults.map(async (item) => {
                                        try {
                                            const ProductService = require('./ProductService');
                                            const options = await ProductService.getProductOptions(item.id);
                                            let optionsText = '';
                                            if (options && options.length > 0) {
                                                const optionsList = options.map(opt => {
                                                    const valuesList = opt.values.map(val => {
                                                        const priceModifier = val.price_modifier ? 
                                                            (val.price_modifier > 0 ? ` (+${val.price_modifier.toLocaleString()}đ)` : 
                                                             val.price_modifier < 0 ? ` (${val.price_modifier.toLocaleString()}đ)` : '') : '';
                                                        return `    - ${val.value}${priceModifier}`;
                                                    }).join('\n');
                                                    return `  ${opt.name}${opt.required ? ' (Bắt buộc)' : ''}:\n${valuesList}`;
                                                }).join('\n\n');
                                                optionsText = `\n  Tùy chọn:\n${optionsList}`;
                                            }
                                            return `• ${item.name} - ${item.price.toLocaleString()}đ\n  ${item.description || ''}${optionsText}`;
                                        } catch {
                                            return `• ${item.name} - ${item.price.toLocaleString()}đ\n  ${item.description || ''}`;
                                        }
                                    }));
                                    response = `Kết quả tìm kiếm cho "${searchKeyword}":\n\n${resultsWithOptions.join('\n\n')}\n\nBạn muốn đặt món nào?`;
                                }
                            }
                        } else {
                            try {
                                const OrderService = require('./OrderService');
                                const bestSellers = await OrderService.getTopProducts({ branch_id: branchIdForSearch }, 3);
                                const bestSellerDetails = await Promise.all(bestSellers.map(async (item) => {
                                    const branchProduct = await knex('branch_products')
                                        .where('product_id', item.id)
                                        .where('branch_id', branchIdForSearch || knex.raw('(SELECT id FROM branches WHERE status = "active" LIMIT 1)'))
                                        .where('is_available', 1)
                                        .where('status', 'available')
                                        .first();
                                    const product = await knex('products')
                                        .where('id', item.id)
                                        .first();
                                    return {
                                        id: item.id,
                                        name: item.name || product?.name,
                                        price: branchProduct?.price || product?.base_price || 0,
                                        total_quantity: item.total_quantity || 0
                                    };
                                }));
                                const isQuestion = /(có|co).*(không|khong)/i.test(userMessage);
                                if (bestSellerDetails.length > 0) {
                                    const bestSellerList = bestSellerDetails.map((item, idx) => 
                                        `${idx + 1}. ${item.name} - ${item.price.toLocaleString()}đ (Đã bán: ${item.total_quantity} phần)`
                                    ).join('\n');
                                    if (isQuestion) {
                                        response = `Không, chúng tôi không có món "${searchKeyword}" trong menu hiện tại.\n\nNhưng đây là 3 món bán chạy nhất của chúng tôi:\n\n${bestSellerList}\n\nBạn có muốn đặt một trong những món này không?`;
                                    } else {
                                        response = `Không tìm thấy món nào với từ khóa "${searchKeyword}".\n\nNhưng đây là 3 món bán chạy nhất của chúng tôi:\n\n${bestSellerList}\n\nBạn có muốn đặt một trong những món này không?`;
                                    }
                                } else {
                                    if (isQuestion) {
                                        response = `Không, chúng tôi không có món "${searchKeyword}" trong menu hiện tại.\n\nBạn có thể:\n• Thử tìm món khác\n• Xem toàn bộ menu\n• Liên hệ trực tiếp với nhà hàng để biết thêm thông tin`;
                        } else {
                                        response = `Không tìm thấy món nào với từ khóa "${searchKeyword}".\n\nBạn có thể:\n• Thử từ khóa khác\n• Xem toàn bộ menu\n• Mô tả món ăn bạn muốn tìm`;
                                    }
                        }
                    } catch {
                        const isQuestion = /(có|co).*(không|khong)/i.test(userMessage);
                                if (isQuestion) {
                                    response = `Không, chúng tôi không có món "${searchKeyword}" trong menu hiện tại.\n\nBạn có thể:\n• Thử tìm món khác\n• Xem toàn bộ menu\n• Liên hệ trực tiếp với nhà hàng để biết thêm thông tin`;
                                } else {
                                    response = `Không tìm thấy món nào với từ khóa "${searchKeyword}".\n\nBạn có thể:\n• Thử từ khóa khác\n• Xem toàn bộ menu\n• Mô tả món ăn bạn muốn tìm`;
                                }
                            }
                        }
                    } catch {
                        response = 'Có lỗi khi tìm kiếm món ăn. Bạn có thể xem toàn bộ menu thay thế.';
                    }
                } else {
                    try {
                        const ToolHandlers = require('../ToolHandlers');
                        const searchResult = await ToolHandlers.searchProducts({
                            keyword: null,
                            branch_id: searchBranchId || null,
                            limit: 10,
                            sort_by: 'popularity'
                        });
                        if (searchResult && searchResult.products && searchResult.products.length > 0) {
                            const products = searchResult.products;
                            let responseText = ` Danh sách ${products.length} món phổ biến:\n\n`;
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
                            responseText += 'Bạn muốn tìm món gì cụ thể? Hãy cho tôi biết tên món hoặc từ khóa.\n\nVí dụ: "có burger không", "tìm pizza", "món chay"';
                            response = responseText;
                        } else {
                            response = 'Bạn muốn tìm món gì? Hãy cho tôi biết tên món hoặc từ khóa tìm kiếm.\n\nVí dụ: "có burger không", "tìm pizza", "có món gì ngon"';
                        }
                    } catch (error) {
                        console.error('[LegacyFallbackService] Error searching products:', error);
                        response = 'Bạn muốn tìm món gì? Hãy cho tôi biết tên món hoặc từ khóa tìm kiếm.\n\nVí dụ: "có burger không", "tìm pizza", "có món gì ngon"';
                    }
                }
                break;
            }
            case 'book_table': {
                const hasTimeInfoForTable = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                const hasDateInfoForTable = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                const normalizedCurrentEntities = Utils.normalizeEntityFields(entities);
                const hasBranchInfoForTable = normalizedCurrentEntities.branch_name || normalizedCurrentEntities.branch || normalizedCurrentEntities.branch_id || normalizedCurrentEntities.district_id;
                const peopleValue = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                const isValidPeople = peopleValue && peopleValue >= 1 && peopleValue <= 20;
                const normalizedCurrentEntitiesCheck = Utils.normalizeEntityFields(entities);
                const hasBranchInCurrentMessage = normalizedCurrentEntitiesCheck.branch_name || normalizedCurrentEntitiesCheck.branch || normalizedCurrentEntitiesCheck.branch_id || normalizedCurrentEntitiesCheck.district_id;
                if ((lastIntent === 'book_table' || lastIntent === 'book_table_partial' || lastIntent === 'reservation_failed' || lastIntent === 'ask_info' || lastIntent === 'find_nearest_branch' || lastIntent === 'find_first_branch') &&
                    isValidPeople && hasTimeInfoForTable && hasDateInfoForTable && hasBranchInfoForTable && hasBranchInCurrentMessage) {
                    const people = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                    const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                    let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                    if (people && time && parseInt(people) === parseInt(time.split(':')[0])) {
                        const normalizedCurrentEntities = Utils.normalizeEntityFields(entities);
                        response = `Tôi hiểu bạn muốn đặt bàn vào ${time} ngày ${date}. Bạn muốn đặt bàn cho bao nhiêu người?`;
                        return {
                            response,
                            intent: 'book_table_partial',
                            entities: {
                                ...mergedEntities,
                                people: null, 
                                time: time,
                                date: date,
                                branch_name: normalizedCurrentEntities.branch_name || normalizedCurrentEntities.branch || null
                            }
                        };
                    }
                    if (date === 'ngày mai' || date === 'tomorrow') {
                        const tomorrow = new Date();
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        date = tomorrow.toISOString().split('T')[0];
                    } else if (date === 'hôm nay' || date === 'today') {
                        date = new Date().toISOString().split('T')[0];
                    }
                    const normalizedCurrentEntities = Utils.normalizeEntityFields(entities);
                    const confirmedEntities = {
                        people: people,
                        time: time,
                        date: date,
                        branch_name: normalizedCurrentEntities.branch_name || normalizedCurrentEntities.branch || null,
                        branch_id: normalizedCurrentEntities.branch_id || null,
                        district_id: normalizedCurrentEntities.district_id || null,
                    };
                    const missingInfo = [];
                    if (!confirmedEntities.people) missingInfo.push('số người');
                    if (!confirmedEntities.time) missingInfo.push('giờ');
                    if (!confirmedEntities.date) missingInfo.push('ngày');
                    if (!confirmedEntities.branch_name && !confirmedEntities.branch_id && !confirmedEntities.district_id) missingInfo.push('chi nhánh');
                    if (missingInfo.length > 0) {
                        const BookingValidator = require('./validators/BookingValidator');
                        const missingFields = [];
                        if (!confirmedEntities.people) missingFields.push('people');
                        if (!confirmedEntities.time) missingFields.push('time');
                        if (!confirmedEntities.date) missingFields.push('date');
                        if (!confirmedEntities.branch_name) missingFields.push('branch_name');
                        response = BookingValidator.buildMissingInfoPrompt(missingFields, confirmedEntities);
                        if (missingInfo.includes('chi nhánh')) {
                            try {
                                const allBranches = await knex('branches')
                                    .where('status', 'active')
                                    .select('id', 'name')
                                    .orderBy('id', 'asc');
                                if (allBranches.length > 0) {
                                    const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                                    response += `\n\nDanh sách chi nhánh:\n\n${branchList.join('\n\n')}`;
                                }
                            } catch (error) {
                                console.error('[LegacyFallbackService] Error getting all active branches:', error);
                            }
                        }
                        return { 
                            response, 
                            intent: 'ask_info', 
                            entities: confirmedEntities
                        };
                    }
                    if (!confirmedEntities.branch_name && !confirmedEntities.branch_id && !confirmedEntities.district_id) {
                        try {
                            const allBranches = await BranchHandler.getAllActiveBranches();
                            if (allBranches.length > 0) {
                                const branchList = await BranchIntentHandler.formatBranchListWithDetails(allBranches);
                                response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?\n\n${branchList.join('\n\n')}\n\nVui lòng cho tôi biết tên chi nhánh bạn muốn đến.`;
                            } else {
                                response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                            }
                        } catch {
                            response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                        }
                        return { 
                            response, 
                            intent: 'ask_info', 
                            entities: confirmedEntities
                        };
                    }
                    try {
                        const reservation = await BookingHandler.createActualReservation(context.user?.id, confirmedEntities);
                        const branch = await knex('branches').where('id', reservation.branch_id).first();
                        const branchName = branch ? branch.name : 'chi nhánh đã chọn';
                        response = `ĐẶT BÀN THÀNH CÔNG!\n\nThông tin đặt bàn:\nSố người: ${people}\nNgày: ${date}\nGiờ: ${time}\nChi nhánh: ${branchName}\nBàn: ${(reservation.table_id || reservation.id)} (Tầng ${reservation.floor_id})\n\nBạn có muốn đặt món kèm theo không?\n\nBạn có thể chọn món từ menu của chi nhánh ${branchName} để đặt kèm với đặt bàn này.`;
                        return {
                            response,
                            intent: 'reservation_created',
                            entities: {
                                ...confirmedEntities,
                                reservation_id: reservation.id,
                                table_id: (reservation.table_id || reservation.id),
                                floor_id: reservation.floor_id
                            },
                            suggestions: [
                                { text: 'Đặt món ngay', action: 'order_food', data: { branch_id: reservation.branch_id, reservation_id: reservation.id } },
                                { text: 'Xem menu đầy đủ', action: 'view_menu', data: { branch_id: reservation.branch_id } },
                                { text: 'Không, cảm ơn', action: 'skip_order', data: {} }
                            ]
                        };
                    } catch (error) {
                        response = `Không thể đặt bàn: ${error.message}\n\nVui lòng thử lại với thời gian khác hoặc liên hệ trực tiếp với nhà hàng.`;
                        return {
                            response,
                            intent: 'reservation_failed',
                            entities: confirmedEntities
                        };
                    }
                }
                if (hasTimeInfoForTable && hasDateInfoForTable && !isValidPeople) {
                    const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                    let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                    if (date === 'ngày mai' || date === 'tomorrow') {
                        const tomorrow = new Date();
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        date = tomorrow.toISOString().split('T')[0];
                    } else if (date === 'hôm nay' || date === 'today') {
                        date = new Date().toISOString().split('T')[0];
                    }
                    const normalizedCurrentEntities = Utils.normalizeEntityFields(entities);
                    const currentBranchName = normalizedCurrentEntities.branch_name || normalizedCurrentEntities.branch;
                    response = `Tôi hiểu bạn muốn đặt bàn vào ${time} ngày ${date}${currentBranchName ? ` tại ${currentBranchName}` : ''}. Bạn muốn đặt bàn cho bao nhiêu người?`;
                    return {
                        response,
                        intent: 'book_table_partial',
                        entities: {
                            ...mergedEntities,
                            time: time,
                            date: date,
                            branch_name: currentBranchName || null,
                            people: null 
                        }
                    };
                }
                if (isValidPeople && hasTimeInfoForTable && hasDateInfoForTable && !hasBranchInfoForTable) {
                    const people = mergedEntities.people || mergedEntities.number_of_people || mergedEntities.guest_count;
                    const time = mergedEntities.time || mergedEntities.reservation_time || mergedEntities.time_slot;
                    let date = mergedEntities.date || mergedEntities.reservation_date || mergedEntities.booking_date;
                    if (date === 'ngày mai' || date === 'tomorrow') {
                        const tomorrow = new Date();
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        date = tomorrow.toISOString().split('T')[0];
                    } else if (date === 'hôm nay' || date === 'today') {
                        date = new Date().toISOString().split('T')[0];
                    }
                    try {
                        const allBranches = await BranchHandler.getAllActiveBranches();
                        if (allBranches.length > 0) {
                            const branchSuggestions = await BranchHandler.createBranchSuggestions(allBranches, {
                                intent: 'book_table',
                                people: people,
                                time: time,
                                date: date
                            });
                            response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?\n\nBạn có thể chọn chi nhánh bằng cách click vào nút bên dưới hoặc cho tôi biết tên chi nhánh.`;
                            return {
                                response,
                                intent: 'book_table_partial',
                                entities: {
                                    ...mergedEntities,
                                    people: people,
                                    time: time,
                                    date: date,
                                    branch_name: null,
                                    branch_id: null
                                },
                                suggestions: branchSuggestions
                            };
                        } else {
                            response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                        }
                    } catch {
                        response = `Tôi hiểu bạn muốn đặt bàn cho ${people} người vào ${time} ngày ${date}. Bạn muốn đặt bàn tại chi nhánh nào?`;
                    }
                    return {
                        response,
                        intent: 'book_table_partial',
                        entities: {
                            ...mergedEntities,
                            people: people,
                            time: time,
                            date: date,
                            branch_name: null,
                            branch_id: null
                        }
                    };
                }
                response = 'Tuyệt vời! Bạn muốn đặt bàn cho bao nhiêu người? Vui lòng cho tôi biết ngày và giờ bạn muốn đặt bàn, cùng với chi nhánh nào bạn muốn đến nhé!';
                break;
            }
            case 'show_booking_info': {
                if (mergedEntities.people && mergedEntities.time && mergedEntities.date && mergedEntities.branch_name) {
                    response = `Thông tin đặt bàn đã xác nhận:\n\nSố người: ${mergedEntities.people}\nNgày: ${mergedEntities.date}\nGiờ: ${mergedEntities.time}\nChi nhánh: ${mergedEntities.branch_name}\n\nBạn có cần thay đổi thông tin nào không?`;
                } else {
                    response = 'Tôi không tìm thấy thông tin đặt bàn đã xác nhận. Bạn có muốn đặt bàn mới không?';
                }
                break;
            }
            default:
                response = GREETING_MESSAGE;
        }
        return { response, intent, entities: mergedEntities };
        } catch {
            return { 
                response: 'Xin lỗi, đã có lỗi xảy ra. Bạn có thể thử lại hoặc liên hệ trực tiếp với nhà hàng.', 
                intent: 'error', 
                entities: {} 
            };
        }
    }
}
module.exports = new LegacyFallbackService();
