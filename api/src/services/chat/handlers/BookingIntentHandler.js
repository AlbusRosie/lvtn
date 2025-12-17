const BaseIntentHandler = require('./BaseIntentHandler');
const ReservationService = require('../ReservationService');
const EntityExtractor = require('../fallback/EntityExtractor');
const BranchIntentHandler = require('./BranchIntentHandler');
const BranchHandler = BranchIntentHandler.instance;
const BookingValidator = require('../validators/BookingValidator');
const Utils = require('../Utils');

class BookingIntentHandler extends BaseIntentHandler {
    constructor() {
        super();
        this.intentSet = new Set([
            'book_table',
            'book_table_partial',
            'book_table_specific_branch',
            'confirm_booking',
            'modify_booking',
            'show_booking_info',
        ]);
    }

    canHandle(intent, context = {}) {
        if (this.intentSet.has(intent)) {
            return true;
        }
        const lastIntent = context.conversationContext?.lastIntent;
        return lastIntent && this.intentSet.has(lastIntent);
    }

    async handle({ intent, message, context, entities, userId }) {
        const normalized = Utils.normalizeEntityFields(entities || {});
        const validation = BookingValidator.validate(normalized);
        
        if (intent === 'modify_booking') {
            return this.buildResponse({
                intent: 'modify_booking',
                response: 'Bạn muốn thay đổi thông tin nào? Vui lòng cho tôi biết thông tin mới bạn cần cập nhật.',
                entities: normalized,
                suggestions: [
                    { text: 'Đổi số người', action: 'modify_booking', data: { field: 'people' } },
                    { text: 'Đổi ngày', action: 'modify_booking', data: { field: 'date' } },
                    { text: 'Đổi giờ', action: 'modify_booking', data: { field: 'time' } },
                ],
            });
        }
        
        if (validation.status === 'ask_missing') {
            const response = BookingValidator.buildMissingInfoPrompt(validation.missing);
            const suggestions = await this._buildBranchSuggestionsIfNeeded(validation);
            return this.buildResponse({
                intent: 'ask_info',
                response,
                entities: validation.entities,
                suggestions,
            });
        }
        
        const handlerContext = {
            ...context,
            conversationContext: {
                ...context.conversationContext,
                lastEntities: validation.entities,
                lastIntent: 'book_table',
            },
        };
        
        const result = await this.handleSmartBooking(message, handlerContext);
        if (result?.intent === 'reservation_created' || result?.message || result?.response) {
            return result;
        }
        
        if (intent === 'confirm_booking') {
            return this.buildResponse({
                intent: 'book_table',
                response: 'Vui lòng sử dụng nút "Xác nhận đặt bàn" để hoàn tất đặt bàn.',
                entities: validation.entities,
            });
        }
        
        if (userId) {
            try {
                const reservation = await this.createActualReservation(userId, validation.entities);
                const branchName = validation.entities.branch_name || 'chi nhánh đã chọn';
                return this.buildResponse({
                    intent: 'reservation_created',
                    response: `ĐẶT BÀN THÀNH CÔNG!\n\n ${validation.entities.people} người\n ${validation.entities.date}\n ${validation.entities.time}\n ${branchName}\n\nMã đặt bàn: #${reservation.id}`,
                    entities: {
                        ...validation.entities,
                        reservation_id: reservation.id,
                        table_id: reservation.table_id,
                        floor_id: reservation.floor_id,
                    },
                });
            } catch (error) {
                return this.buildResponse({
                    intent: 'reservation_failed',
                    response: `Không thể tạo đặt bàn: ${error.message}`,
                    entities: validation.entities,
                });
            }
        }
        
        return null;
    }

    // Methods từ BookingHandler (gộp vào đây)
    validateBookingRequest(entities) {
        const errors = [];
        const normalizedEntities = Utils.normalizeEntityFields(entities);
        if (!normalizedEntities.people || normalizedEntities.people < 1) {
            errors.push("Vui lòng cho biết số người (tối thiểu 1 người)");
        }
        if (!normalizedEntities.time) {
            errors.push("Vui lòng cho biết giờ đặt bàn");
        }
        if (!normalizedEntities.date) {
            errors.push("Vui lòng cho biết ngày đặt bàn");
        }
        return errors;
    }

    async checkTableAvailability(branchId, date, time, guestCount) {
        return await ReservationService.checkTableAvailability(branchId, date, time, guestCount);
    }

    async findAvailableTimeSlots(branchId, date, guestCount, branch) {
        return await ReservationService.findAvailableTimeSlots(branchId, date, guestCount, branch);
    }

    async handleSmartBooking(userMessage, context) {
        let historyEntities = {};
        if (context.conversationHistory && context.conversationHistory.length > 0) {
            for (let i = context.conversationHistory.length - 1; i >= 0; i--) {
                const msg = context.conversationHistory[i];
                if (msg.entities) {
                    try {
                        const ents = typeof msg.entities === 'string' ? Utils.safeJsonParse(msg.entities, 'entities') || {} : msg.entities;
                        if (ents && Object.keys(ents).length > 0) {
                            historyEntities = { ...historyEntities, ...Utils.normalizeEntityFields(ents) };
                        }
                    } catch (error) {
                        console.error('[BookingIntentHandler] Error parsing entities:', error.message);
                    }
                }
            }
        }
        
        const parsedData = EntityExtractor.parseNaturalLanguage(userMessage);
        const lastEntities = context.conversationContext?.lastEntities || {};
        const lastBranchId = context.conversationContext?.lastBranchId;
        const lastBranch = context.conversationContext?.lastBranch;
        const mergedData = Utils.mergeAndNormalizeEntities(parsedData, lastEntities, historyEntities);
        
        // Merge thêm branch info từ context
        if (lastBranchId && !mergedData.branch_id) {
            mergedData.branch_id = lastBranchId;
        }
        if (lastBranch && !mergedData.branch_name) {
            mergedData.branch_name = lastBranch;
            mergedData.branch = lastBranch;
        }
        
        if (mergedData.time && (mergedData.branch_id || mergedData.branch_name)) {
            let branch = null;
            if (mergedData.branch_id) {
                branch = await BranchHandler.getBranchById(mergedData.branch_id);
            } else if (mergedData.branch_name) {
                branch = await BranchHandler.getBranchByName(mergedData.branch_name);
            }
            if (branch && branch.opening_hours && branch.close_hours) {
                const isWithinHours = BranchHandler.isTimeWithinOperatingHours(mergedData.time, branch);
                if (!isWithinHours) {
                    const openBranches = await BranchHandler.getBranchesOpenAtTime(mergedData.time);
                    let warningMessage = `Lưu ý: Chi nhánh ${branch.name} không hoạt động vào lúc ${mergedData.time}.\n\n`;
                    warningMessage += `Giờ làm việc của chi nhánh này: ${BranchHandler.formatOperatingHours(branch)}\n\n`;
                    if (openBranches.length > 0) {
                        warningMessage += `Các chi nhánh còn hoạt động vào lúc ${mergedData.time}:\n\n`;
                        openBranches.forEach((b, idx) => {
                            warningMessage += `${idx + 1}. ${b.name} - ${BranchHandler.formatOperatingHours(b)}\n`;
                        });
                        warningMessage += `\nBạn có muốn đổi sang một trong các chi nhánh này không?`;
                    } else {
                        warningMessage += `Hiện tại không có chi nhánh nào hoạt động vào lúc ${mergedData.time}.\n\n`;
                        warningMessage += `Vui lòng chọn giờ khác.`;
                    }
                    const validation = this.validateBookingRequest(mergedData);
                    if (validation.length === 0) {
                        return {
                            message: warningMessage,
                            intent: 'book_table_warning',
                            entities: mergedData,
                            suggestions: [
                                { text: 'Vẫn đặt tại chi nhánh này', action: 'confirm_booking', data: mergedData },
                                { text: 'Chọn chi nhánh khác', action: 'select_branch', data: { time: mergedData.time } },
                                { text: 'Chọn giờ khác', action: 'modify_booking', data: { time: null } }
                            ]
                        };
                    }
                }
            }
        }
        
        const isTimeAmbiguous = mergedData.time_ambiguous || 
                                (mergedData.time && mergedData.time_hour && mergedData.time_hour >= 1 && mergedData.time_hour <= 11);
        if (isTimeAmbiguous && mergedData.time_hour) {
            const timeHour = mergedData.time_hour;
            return {
                message: `Tôi hiểu bạn muốn đặt bàn vào lúc ${timeHour} giờ. Bạn muốn đặt vào buổi nào?\n\nBuổi sáng (${timeHour}:00)\nBuổi chiều (${timeHour + 12}:00)\n\nVui lòng cho tôi biết bạn muốn đặt vào buổi sáng hay chiều?`,
                intent: 'ask_time_period',
                entities: {
                    ...mergedData,
                    time: null, 
                    time_hour: timeHour
                },
                suggestions: [
                    { text: `${timeHour} giờ sáng`, action: 'select_time', data: { time: `${timeHour.toString().padStart(2, '0')}:00`, period: 'am' } },
                    { text: `${timeHour} giờ chiều`, action: 'select_time', data: { time: `${(timeHour + 12).toString().padStart(2, '0')}:00`, period: 'pm' } }
                ]
            };
        }
        
        if (mergedData.time && (mergedData.branch_id || mergedData.branch_name)) {
            let branch = null;
            if (mergedData.branch_id) {
                branch = await BranchHandler.getBranchById(mergedData.branch_id);
            } else if (mergedData.branch_name) {
                branch = await BranchHandler.getBranchByName(mergedData.branch_name);
            }
            if (branch) {
                const isWithinHours = BranchHandler.isTimeWithinOperatingHours(mergedData.time, branch);
                if (!isWithinHours) {
                    const openBranches = await BranchHandler.getBranchesOpenAtTime(mergedData.time);
                    let errorMessage = `Chi nhánh ${branch.name} không hoạt động vào lúc ${mergedData.time}.\n\n`;
                    errorMessage += `Giờ làm việc của chi nhánh này: ${BranchHandler.formatOperatingHours(branch)}\n\n`;
                    if (openBranches.length > 0) {
                        errorMessage += `Các chi nhánh còn hoạt động vào lúc ${mergedData.time}:\n\n`;
                        openBranches.forEach((b, idx) => {
                            errorMessage += `${idx + 1}. ${b.name} - ${BranchHandler.formatOperatingHours(b)}\n`;
                        });
                        errorMessage += `\nBạn có muốn đặt bàn tại một trong các chi nhánh này không?`;
                    } else {
                        errorMessage += `Hiện tại không có chi nhánh nào hoạt động vào lúc ${mergedData.time}.\n\n`;
                        errorMessage += `Vui lòng chọn giờ khác hoặc liên hệ trực tiếp với nhà hàng.`;
                    }
                    return {
                        message: errorMessage,
                        intent: 'book_table_warning',
                        entities: mergedData,
                        suggestions: [
                            { text: 'Chọn giờ khác', action: 'modify_booking', data: { time: null } },
                            { text: 'Chọn chi nhánh khác', action: 'select_branch', data: { time: mergedData.time } }
                        ]
                    };
                }
                
                const closeCheck = BranchHandler.checkIfCloseToClosing(mergedData.time, branch, 60);
                if (closeCheck && closeCheck.isClose) {
                    const remainingMinutes = closeCheck.remainingMinutes;
                    const hours = Math.floor(remainingMinutes / 60);
                    const minutes = remainingMinutes % 60;
                    let timeWarning = `Lưu ý: Chi nhánh ${branch.name} sẽ đóng cửa sau `;
                    if (hours > 0) {
                        timeWarning += `${hours} giờ `;
                    }
                    if (minutes > 0) {
                        timeWarning += `${minutes} phút`;
                    } else if (hours === 0) {
                        timeWarning += `${remainingMinutes} phút`;
                    }
                    timeWarning += ` (lúc ${branch.close_hours}h).\n\n`;
                    timeWarning += `Bạn vẫn có thể đặt bàn, nhưng vui lòng đến đúng giờ để đảm bảo có đủ thời gian thưởng thức bữa ăn.\n\n`;
                    timeWarning += `Giờ làm việc: ${BranchHandler.formatOperatingHours(branch)}`;
                    const validation = this.validateBookingRequest(mergedData);
                    if (validation.length === 0) {
                        return {
                            message: timeWarning + `\n\nTuyệt vời! Tôi đã hiểu yêu cầu đặt bàn của bạn:\n\nSố người: ${mergedData.people}\nNgày: ${mergedData.date}\nGiờ: ${mergedData.time}\nChi nhánh: ${mergedData.branch_name || 'Chưa chọn'}\n\nTôi sẽ giúp bạn tìm bàn phù hợp!`,
                            intent: 'book_table_confirmed',
                            entities: mergedData,
                            suggestions: [
                                { text: 'Xác nhận đặt bàn', action: 'confirm_booking', data: mergedData },
                                { text: 'Thay đổi thông tin', action: 'modify_booking', data: {} },
                                { text: 'Chọn chi nhánh khác', action: 'select_branch', data: {} }
                            ]
                        };
                    }
                }
            }
        }
        
        const validation = this.validateBookingRequest(mergedData);
        if (validation.length === 0) {
            const branchId = mergedData.branch_id;
            const date = mergedData.date;
            const time = mergedData.time;
            const guestCount = mergedData.people || mergedData.number_of_people || mergedData.guest_count;
            if (branchId && date && time && guestCount) {
                try {
                    let reservationDate = date;
                    if (date === 'ngày mai' || date === 'tomorrow') {
                        const tomorrow = new Date();
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        reservationDate = tomorrow.toISOString().split('T')[0];
                    } else if (date === 'hôm nay' || date === 'today') {
                        reservationDate = new Date().toISOString().split('T')[0];
                    }
                    const branch = await BranchHandler.getBranchById(branchId);
                    if (branch) {
                        const availabilityCheck = await this.checkTableAvailability(branchId, reservationDate, time, guestCount);
                        if (!availabilityCheck.available) {
                            let availableSlots = [];
                            try {
                                availableSlots = await this.findAvailableTimeSlots(branchId, reservationDate, guestCount, branch);
                            } catch {
                                // Ignore error, continue with empty slots
                            }
                            let errorMessage = `Rất tiếc! Không còn bàn trống tại ${branch.name} vào lúc ${time} ngày ${reservationDate} cho ${guestCount} người.\n\n`;
                            if (availabilityCheck.reason === 'capacity') {
                                errorMessage += `Chi nhánh này không có bàn đủ lớn cho ${guestCount} người.\n\n`;
                                errorMessage += `Gợi ý:\n`;
                                errorMessage += `• Đặt nhiều bàn nhỏ hơn\n`;
                                errorMessage += `• Chọn chi nhánh khác có bàn lớn hơn\n`;
                                errorMessage += `• Liên hệ trực tiếp với nhà hàng: ${branch.phone || 'hotline'}`;
                            } else {
                                errorMessage += `Các giờ khác còn bàn trống trong ngày:\n\n`;
                                if (availableSlots.length > 0) {
                                    availableSlots.forEach((slot, idx) => {
                                        errorMessage += `${idx + 1}. ${slot}\n`;
                                    });
                                    const timeSuggestions = availableSlots.slice(0, 3).map(slot => ({
                                        text: `${slot}`,
                                        action: 'select_time',
                                        data: {
                                            ...mergedData,
                                            time: slot,
                                            reservation_time: slot
                                        }
                                    }));
                                    return {
                                        message: errorMessage,
                                        intent: 'book_table_no_availability',
                                        entities: mergedData,
                                        suggestions: [
                                            ...timeSuggestions,
                                            { text: 'Thay đổi ngày', action: 'modify_booking', data: {} },
                                            { text: 'Chọn chi nhánh khác', action: 'select_branch', data: {} }
                                        ]
                                    };
                                } else {
                                    errorMessage += `Không còn giờ nào trống trong ngày này.\n\n`;
                                    errorMessage += `Gợi ý:\n`;
                                    errorMessage += `• Chọn ngày khác\n`;
                                    errorMessage += `• Chọn chi nhánh khác\n`;
                                    errorMessage += `• Liên hệ trực tiếp: ${branch.phone || 'hotline'}`;
                                    return {
                                        message: errorMessage,
                                        intent: 'book_table_no_availability',
                                        entities: mergedData,
                                        suggestions: [
                                            { text: 'Thay đổi ngày', action: 'modify_booking', data: {} },
                                            { text: 'Chọn chi nhánh khác', action: 'select_branch', data: {} }
                                        ]
                                    };
                                }
                            }
                        }
                    }
                } catch {
                    // Ignore error, continue with booking flow
                }
            }
            return {
                message: `Tuyệt vời! Tôi đã hiểu yêu cầu đặt bàn của bạn:\n\nSố người: ${mergedData.people}\nNgày: ${mergedData.date}\nGiờ: ${mergedData.time}\nChi nhánh: ${mergedData.branch_name || 'Chưa chọn'}\n\nTôi sẽ giúp bạn tìm bàn phù hợp!`,
                intent: 'book_table_confirmed',
                entities: mergedData,
                suggestions: [
                    { text: 'Xác nhận đặt bàn', action: 'confirm_booking', data: mergedData },
                    { text: 'Thay đổi thông tin', action: 'modify_booking', data: {} },
                    { text: 'Chọn chi nhánh khác', action: 'select_branch', data: {} }
                ]
            };
        } else if (mergedData.branch_id || mergedData.branch_name) {
            const missingFields = [];
            if (!mergedData.people) missingFields.push('people');
            if (!mergedData.time) missingFields.push('time');
            if (!mergedData.date) missingFields.push('date');
            const message = BookingValidator.buildMissingInfoPrompt(missingFields, mergedData);
            const suggestions = [];
            if (!mergedData.people) {
                suggestions.push(
                    { text: '2 người', action: 'select_people', data: { people: 2, ...mergedData } },
                    { text: '4 người', action: 'select_people', data: { people: 4, ...mergedData } },
                    { text: '6 người', action: 'select_people', data: { people: 6, ...mergedData } }
                );
            }
            return {
                message,
                intent: 'book_table_partial',
                entities: mergedData,
                suggestions: suggestions
            };
        } else if (mergedData.people || mergedData.time || mergedData.date) {
            const missingFields = [];
            if (!mergedData.people) missingFields.push('people');
            if (!mergedData.time) missingFields.push('time');
            if (!mergedData.date) missingFields.push('date');
            if (!mergedData.branch_id && !mergedData.branch_name) missingFields.push('branch_name');
            const message = BookingValidator.buildMissingInfoPrompt(missingFields, mergedData);
            return {
                message,
                intent: 'book_table_partial',
                entities: mergedData,
                suggestions: [] 
            };
        } else {
            const { suggestions: branchSuggestions } = await BranchHandler.getBranchesWithSuggestions('book_table');
            let message = 'Bạn muốn đặt bàn tại chi nhánh nào?\n\nVui lòng chọn chi nhánh từ danh sách bên dưới:';
            return {
                message,
                intent: 'book_table',
                entities: {},
                suggestions: branchSuggestions.length > 0 ? branchSuggestions : [
                    { text: 'Chi nhánh gần tôi', action: 'find_nearest_branch', data: {} }
                ]
            };
        }
    }

    async createActualReservation(userId, entities) {
        console.log('[BookingIntentHandler] createActualReservation - userId:', userId);
        console.log('[BookingIntentHandler] createActualReservation - entities:', JSON.stringify(entities, null, 2));
        const normalizedEntities = Utils.normalizeEntityFields(entities);
        console.log('[BookingIntentHandler] createActualReservation - normalizedEntities:', JSON.stringify(normalizedEntities, null, 2));
        
        let reservationDate = normalizedEntities.date;
        if (normalizedEntities.date === 'ngày mai' || normalizedEntities.date === 'tomorrow') {
            const tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            reservationDate = tomorrow.toISOString().split('T')[0];
        } else if (normalizedEntities.date === 'hôm nay' || normalizedEntities.date === 'today') {
            reservationDate = new Date().toISOString().split('T')[0];
        }
        
        let branchId = normalizedEntities.branch_id;
        const BranchService = require('../BranchService');
        if (!branchId && normalizedEntities.branch_name) {
            const branches = await BranchService.getAllBranches('active', normalizedEntities.branch_name);
            if (branches.length > 0) {
                branchId = branches[0].id;
            }
        }
        if (!branchId && normalizedEntities.district_name) {
            const branches = await BranchService.getAllBranches('active', normalizedEntities.district_name);
            if (branches.length > 0) {
                branchId = branches[0].id;
            }
        }
        if (!branchId) {
            console.error('[BookingIntentHandler] createActualReservation - Missing branch_id');
            throw new Error('Vui lòng chọn chi nhánh bạn muốn đặt bàn. Bạn có thể cho tôi biết tên chi nhánh hoặc quận bạn muốn đến.');
        }
        
        console.log('[BookingIntentHandler] createActualReservation - branchId:', branchId);
        const branch = await BranchHandler.getBranchById(branchId);
        if (!branch) {
            console.error('[BookingIntentHandler] createActualReservation - Branch not found:', branchId);
            throw new Error('Không tìm thấy chi nhánh. Vui lòng thử lại.');
        }
        
        console.log('[BookingIntentHandler] createActualReservation - branch found:', branch.name);
        if (normalizedEntities.time && branch.opening_hours && branch.close_hours) {
            const isWithinHours = BranchHandler.isTimeWithinOperatingHours(normalizedEntities.time, branch);
            if (!isWithinHours) {
                const openBranches = await BranchHandler.getBranchesOpenAtTime(normalizedEntities.time);
                let errorMessage = `Chi nhánh ${branch.name} không hoạt động vào lúc ${normalizedEntities.time}.\n\n`;
                errorMessage += `Giờ làm việc của chi nhánh này: ${BranchHandler.formatOperatingHours(branch)}\n\n`;
                if (openBranches.length > 0) {
                    errorMessage += `Các chi nhánh còn hoạt động vào lúc ${normalizedEntities.time}:\n\n`;
                    openBranches.forEach((b, idx) => {
                        errorMessage += `${idx + 1}. ${b.name} - ${BranchHandler.formatOperatingHours(b)}\n`;
                    });
                    errorMessage += `\nBạn có muốn đặt bàn tại một trong các chi nhánh này không?`;
                } else {
                    errorMessage += `Hiện tại không có chi nhánh nào hoạt động vào lúc ${normalizedEntities.time}.\n\n`;
                    errorMessage += `Vui lòng chọn giờ khác hoặc liên hệ trực tiếp với nhà hàng.`;
                }
                throw new Error(errorMessage);
            }
        }
        
        const knex = require('../../../database/knex');
        const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
        const existingReservation = await knex('reservations')
            .where('user_id', userId)
            .where('branch_id', branchId)
            .where('reservation_date', reservationDate)
            .where('reservation_time', normalizedEntities.time)
            .where('guest_count', normalizedEntities.people || normalizedEntities.guest_count || normalizedEntities.number_of_people)
            .where('status', '!=', 'cancelled')
            .where('created_at', '>=', fiveMinutesAgo)
            .orderBy('created_at', 'desc')
            .first();
            
        if (existingReservation) {
            const existingOrder = await knex('orders')
                .where('reservation_id', existingReservation.id)
                .where('total', '>', 0)
                .orderBy('created_at', 'desc')
                .first();
            
            return {
                ...existingReservation,
                branch_name: branch.name,
                branch_address: branch.address_detail,
                branch_phone: branch.phone,
                order_id: existingOrder ? existingOrder.id : null
            };
        }
        
        const guestCount = normalizedEntities.people || normalizedEntities.guest_count || normalizedEntities.number_of_people;
        console.log('[BookingIntentHandler] createActualReservation - guestCount:', guestCount);
        console.log('[BookingIntentHandler] createActualReservation - time:', normalizedEntities.time);
        console.log('[BookingIntentHandler] createActualReservation - reservationDate:', reservationDate);
        
        if (!guestCount || guestCount < 1) {
            console.error('[BookingIntentHandler] createActualReservation - Invalid guestCount:', guestCount);
            throw new Error('Vui lòng cho biết số người (tối thiểu 1 người)');
        }
        if (!normalizedEntities.time) {
            console.error('[BookingIntentHandler] createActualReservation - Missing time');
            throw new Error('Vui lòng cho biết giờ đặt bàn');
        }
        if (!reservationDate) {
            console.error('[BookingIntentHandler] createActualReservation - Missing reservationDate');
            throw new Error('Vui lòng cho biết ngày đặt bàn');
        }
        
        const availabilityCheck = await this.checkTableAvailability(
            branchId,
            reservationDate,
            normalizedEntities.time,
            guestCount
        );
        
        if (!availabilityCheck.available) {
            let availableSlots = [];
            try {
                availableSlots = await this.findAvailableTimeSlots(branchId, reservationDate, guestCount, branch);
            } catch (error) {
                console.error('[BookingIntentHandler] Error finding available time slots:', error.message);
            }
            let errorMessage = '';
            if (availabilityCheck.reason === 'capacity') {
                errorMessage = `Rất tiếc! Chi nhánh ${branch.name} không có bàn đủ lớn cho ${guestCount} người.\n\n`;
                errorMessage += `Gợi ý:\n`;
                errorMessage += `• Đặt nhiều bàn nhỏ hơn\n`;
                errorMessage += `• Chọn chi nhánh khác có bàn lớn hơn\n`;
                errorMessage += `• Liên hệ trực tiếp với nhà hàng: ${branch.phone || 'hotline'}`;
            } else if (availabilityCheck.reason === 'time') {
                errorMessage = `Rất tiếc! Không còn bàn trống tại ${branch.name} vào lúc ${normalizedEntities.time} ngày ${reservationDate} cho ${guestCount} người.\n\n`;
                if (availableSlots.length > 0) {
                    errorMessage += `Các giờ khác còn bàn trống trong ngày:\n\n`;
                    availableSlots.slice(0, 6).forEach((slot, idx) => {
                        errorMessage += `${idx + 1}. ${slot}\n`;
                    });
                    errorMessage += `\nBạn có muốn chọn một trong các giờ này không?`;
                } else {
                    errorMessage += `Không còn giờ nào trống trong ngày này.\n\n`;
                    errorMessage += `Gợi ý:\n`;
                    errorMessage += `• Chọn ngày khác\n`;
                    errorMessage += `• Chọn chi nhánh khác\n`;
                    errorMessage += `• Liên hệ trực tiếp: ${branch.phone || 'hotline'}`;
                }
            } else {
                errorMessage = `Rất tiếc! Không thể đặt bàn tại ${branch.name} vào lúc ${normalizedEntities.time} ngày ${reservationDate}.\n\n`;
                errorMessage += `Vui lòng thử thời gian khác hoặc liên hệ trực tiếp với nhà hàng: ${branch.phone || 'hotline'}`;
            }
            throw new Error(errorMessage);
        }
        
        const reservationData = {
            user_id: userId,
            branch_id: branchId,
            reservation_date: reservationDate,
            reservation_time: normalizedEntities.time,
            guest_count: guestCount,
            special_requests: null
        };
        
        console.log('[BookingIntentHandler] createActualReservation - reservationData:', JSON.stringify(reservationData, null, 2));
        const reservation = await ReservationService.createQuickReservation(reservationData);
        console.log('[BookingIntentHandler] createActualReservation - reservation created successfully:', reservation?.id);
        
        return {
            ...reservation,
            branch_name: branch.name,
            branch_address: branch.address_detail,
            branch_phone: branch.phone
        };
    }

    async _buildBranchSuggestionsIfNeeded(validation) {
        if (validation.missing && validation.missing.includes('branch_name')) {
            const { suggestions } = await BranchHandler.getBranchesWithSuggestions('book_table', validation.entities);
            return suggestions.length > 0 ? suggestions : null;
        }
        return null;
    }
}

// Export instance để LegacyFallbackService có thể dùng
module.exports = BookingIntentHandler;
module.exports.instance = new BookingIntentHandler();