const knex = require('../../database/knex');
const BookingHandler = require('./BookingHandler');
const BranchHandler = require('./BranchHandler');
const MenuHandler = require('./MenuHandler');
const ProductService = require('../ProductService');
const ApiError = require('../../api-error');
class ToolHandlers {
    static async getBranchMenu(params) {
        const { branch_id, category_id } = params;
        if (!branch_id) {
            throw new Error('Branch ID is required');
        }
        try {
            const result = await ProductService.getAvailableProducts({
                branch_id: branch_id,
                page: 1,
                limit: 1000 
            });
            let products = result.products;
            if (category_id) {
                products = products.filter(p => p.category_id === category_id);
            }
            const groupedMenu = {};
            products.forEach(product => {
                const category = product.category_name || 'Khác';
                if (!groupedMenu[category]) {
                    groupedMenu[category] = [];
                }
                groupedMenu[category].push({
                    id: product.id,
                    name: product.name,
                    description: product.description,
                    price: product.display_price || product.price || product.branch_price,
                    image: product.image,
                    is_available: product.is_available === 1 || product.is_available === true
                });
            });
            return {
                branch_id,
                total_products: products.length,
                categories: Object.keys(groupedMenu).length,
                menu: groupedMenu
            };
        } catch (error) {
            throw new Error(`Không thể lấy menu: ${error.message}`);
        }
    }
    static async searchProducts(params) {
        const { 
            keyword, 
            branch_id, 
            category_id,
            min_price,
            max_price,
            sort_by = 'name',
            dietary,
            limit = 10 
        } = params;
        try {
            let query;
            if (branch_id) {
                query = knex('products as p')
                    .join('branch_products as bp', 'p.id', 'bp.product_id')
                    .select(
                        'p.id',
                        'p.name',
                        'p.description',
                        'p.image',
                        'bp.price',
                        'bp.is_available',
                        'c.id as category_id',
                        'c.name as category_name'
                    )
                    .leftJoin('categories as c', 'p.category_id', 'c.id')
                    .where('bp.branch_id', branch_id)
                    .where('bp.status', 'available')
                    .where('p.status', 'active');
            } else {
                query = knex('products as p')
                    .select(
                        'p.id',
                        'p.name',
                        'p.description',
                        'p.image',
                        'p.base_price as price',
                        'c.id as category_id',
                        'c.name as category_name'
                    )
                    .leftJoin('categories as c', 'p.category_id', 'c.id')
                    .where('p.status', 'active');
            }
            if (keyword) {
                query.where(function() {
                    this.where('p.name', 'like', `%${keyword}%`)
                        .orWhere('p.description', 'like', `%${keyword}%`);
                });
            }
            if (category_id) {
                query.where('p.category_id', category_id);
            }
            if (min_price !== undefined && min_price !== null) {
                if (branch_id) {
                    query.where('bp.price', '>=', min_price);
                } else {
                    query.where('p.base_price', '>=', min_price);
                }
            }
            if (max_price !== undefined && max_price !== null) {
                if (branch_id) {
                    query.where('bp.price', '<=', max_price);
                } else {
                    query.where('p.base_price', '<=', max_price);
                }
            }
            if (dietary) {
                const dietaryKeywords = {
                    'vegetarian': ['chay', 'vegetarian', 'rau'],
                    'vegan': ['thuần chay', 'vegan'],
                    'halal': ['halal'],
                    'seafood': ['hải sản', 'seafood', 'tôm', 'cua', 'cá', 'mực'],
                    'meat': ['thịt', 'meat'],
                    'chicken': ['gà', 'chicken'],
                    'beef': ['bò', 'beef'],
                    'pork': ['heo', 'lợn', 'pork']
                };
                const keywords = dietaryKeywords[dietary] || [];
                if (keywords.length > 0) {
                    query.where(function() {
                        keywords.forEach((kw, index) => {
                            if (index === 0) {
                                this.where('p.name', 'like', `%${kw}%`)
                                    .orWhere('p.description', 'like', `%${kw}%`);
                            } else {
                                this.orWhere('p.name', 'like', `%${kw}%`)
                                    .orWhere('p.description', 'like', `%${kw}%`);
                            }
                        });
                    });
                }
            }
            switch (sort_by) {
                case 'price_asc':
                    query.orderBy(branch_id ? 'bp.price' : 'p.base_price', 'asc');
                    break;
                case 'price_desc':
                    query.orderBy(branch_id ? 'bp.price' : 'p.base_price', 'desc');
                    break;
                case 'popularity':
                    query.orderBy('p.name', 'asc');
                    break;
                case 'name':
                default:
                    query.orderBy('p.name', 'asc');
                    break;
            }
            query.limit(limit);
            const products = await query;
            return {
                keyword: keyword || null,
                filters: {
                    category_id,
                    min_price,
                    max_price,
                    dietary,
                    sort_by
                },
                total_found: products.length,
                products: products.map(p => ({
                    id: p.id,
                    name: p.name,
                    description: p.description,
                    price: p.price,
                    image: p.image,
                    category_id: p.category_id,
                    category: p.category_name,
                    is_available: branch_id ? p.is_available === 1 : null
                }))
            };
        } catch (error) {
            throw new Error(`Không thể tìm kiếm món: ${error.message}`);
        }
    }
    static async checkTableAvailability(params) {
        const { branch_id, reservation_date, reservation_time, guest_count } = params;
        try {
            const ReservationService = require('../ReservationService');
            const availabilityCheck = await ReservationService.checkTableAvailability(
                branch_id,
                reservation_date,
                reservation_time,
                guest_count
            );
            if (!availabilityCheck.available) {
                const branch = await knex('branches')
                    .where('id', branch_id)
                    .where('status', 'active')
                    .first();
                if (branch) {
                    const [hours] = reservation_time.split(':');
                    const requestHour = parseInt(hours);
                    if (requestHour < branch.opening_hours || requestHour >= branch.close_hours) {
                        return {
                            available: false,
                            message: `Chi nhánh ${branch.name} chỉ mở cửa từ ${branch.opening_hours}h đến ${branch.close_hours}h`,
                            operating_hours: {
                                open: `${branch.opening_hours}:00`,
                                close: `${branch.close_hours}:00`
                            }
                        };
                    }
                }
                let message = `Không có bàn trống cho ${guest_count} người vào lúc ${reservation_time} ngày ${reservation_date}`;
                let suggestion = 'Vui lòng thử thời gian khác hoặc liên hệ trực tiếp với nhà hàng';
                if (availabilityCheck.reason === 'capacity') {
                    message = `Chi nhánh không có bàn đủ lớn cho ${guest_count} người`;
                    suggestion = 'Vui lòng chọn số người ít hơn hoặc chọn chi nhánh khác';
                } else if (availabilityCheck.reason === 'time') {
                    message = `Không có bàn trống cho ${guest_count} người vào lúc ${reservation_time} ngày ${reservation_date}. Có thể bàn đã được đặt trong khoảng thời gian 2 giờ từ ${reservation_time}`;
                    suggestion = 'Vui lòng thử thời gian khác (cách ít nhất 2 giờ từ các đặt bàn khác) hoặc liên hệ trực tiếp với nhà hàng';
                }
                return {
                    available: false,
                    message,
                    suggestion,
                    reason: availabilityCheck.reason
                };
            }
            const branch = await knex('branches')
                .where('id', branch_id)
                .where('status', 'active')
                .first();
            return {
                available: true,
                message: `Có bàn trống phù hợp cho ${guest_count} người`,
                branch_name: branch?.name || 'Chi nhánh',
                reservation_date,
                reservation_time,
                guest_count,
                table: availabilityCheck.table ? {
                    table_id: availabilityCheck.table.id,
                    capacity: availabilityCheck.table.capacity,
                    floor: availabilityCheck.table.floor_id
                } : null
            };
        } catch (error) {
            throw new Error(`Không thể kiểm tra bàn trống: ${error.message}`);
        }
    }
    static async createReservation(params, userContext) {
        const {
            branch_id,
            reservation_date,
            reservation_time,
            guest_count,
            special_requests,
            customer_name,
            customer_phone,
            _user_id
        } = params;
        try {
            const availability = await this.checkTableAvailability({
                branch_id,
                reservation_date,
                reservation_time,
                guest_count
            });
            if (!availability.available) {
                throw new Error(availability.message);
            }
            let selectedTable = availability.available_tables[0];
            const tableRecord = await knex('tables')
                .where('branch_id', branch_id)
                .where('id', selectedTable.table_id)
                .first();
            const TableService = require('../TableService');
            const reservationId = await knex.transaction(async (trx) => {
                const recheckAvailable = await TableService.isTableAvailable(
                    tableRecord.id,
                    reservation_date,
                    reservation_time,
                    120
                );
                if (!recheckAvailable) {
                    const allTables = await trx('tables')
                        .where('branch_id', branch_id)
                        .where('capacity', '>=', guest_count)
                        .where('id', '!=', tableRecord.id)
                        .where(function() {
                            this.where('status', '!=', 'disabled')
                                .where('status', '!=', 'inactive')
                                .orWhereNull('status');
                        })
                        .orderBy('capacity', 'asc')
                        .select('*');
                    let alternativeTable = null;
                    for (const table of allTables) {
                        const isAvailable = await TableService.isTableAvailable(
                            table.id,
                            reservation_date,
                            reservation_time,
                            120
                        );
                        if (isAvailable) {
                            alternativeTable = table;
                            break;
                        }
                    }
                    if (!alternativeTable) {
                        throw new Error('Không còn bàn trống vào thời gian này. Bàn vừa được đặt bởi khách hàng khác.');
                    }
                    selectedTable = { table_id: alternativeTable.id };
                    tableRecord.id = alternativeTable.id;
                    tableRecord.capacity = alternativeTable.capacity;
                    tableRecord.floor_id = alternativeTable.floor_id;
                }
                const [id] = await trx('reservations').insert({
                    user_id: _user_id || null,
                    branch_id,
                    table_id: tableRecord.id,
                    reservation_date,
                    reservation_time,
                    guest_count,
                    customer_name: customer_name || null,
                    customer_phone: customer_phone || null,
                    special_requests: special_requests || null,
                    status: 'confirmed',
                    created_at: new Date(),
                    updated_at: new Date()
                });
                await TableService.createTableSchedule({
                    table_id: tableRecord.id,
                    reservation_id: id,
                    schedule_date: reservation_date,
                    start_time: reservation_time,
                    duration_minutes: 120,
                    status: 'reserved'
                });
                return id;
            });
            const reservation = await knex('reservations as r')
                .join('branches as b', 'r.branch_id', 'b.id')
                .join('tables as t', 'r.table_id', 't.id')
                .select(
                    'r.id',
                    'r.reservation_date',
                    'r.reservation_time',
                    'r.guest_count',
                    'r.status',
                    'r.special_requests',
                    'b.name as branch_name',
                    'b.address_detail',
                    'b.phone as branch_phone',
                    't.id',
                    't.floor_id'
                )
                .where('r.id', reservationId)
                .first();
            return {
                success: true,
                reservation_id: reservationId,
                message: `Đặt bàn thành công tại ${reservation.branch_name}`,
                details: {
                    id: reservation.id,
                    branch: reservation.branch_name,
                    table_id: reservation.table_id,
                    floor: reservation.floor_id,
                    date: reservation.reservation_date,
                    time: reservation.reservation_time,
                    guests: reservation.guest_count,
                    status: reservation.status,
                    special_requests: reservation.special_requests
                }
            };
        } catch (error) {
            throw new Error(`Không thể tạo đặt bàn: ${error.message}`);
        }
    }
    static async getMyReservations(params) {
        const { status, limit = 10, _user_id } = params;
        if (!_user_id) {
            throw new Error('Vui lòng đăng nhập để xem đặt bàn của bạn');
        }
        try {
            let query = knex('reservations as r')
                .join('branches as b', 'r.branch_id', 'b.id')
                .join('tables as t', 'r.table_id', 't.id')
                .select(
                    'r.id',
                    'r.reservation_date',
                    'r.reservation_time',
                    'r.guest_count',
                    'r.status',
                    'r.special_requests',
                    'r.created_at',
                    'b.name as branch_name',
                    'b.address_detail',
                    't.id',
                    't.floor_id'
                )
                .where('r.user_id', _user_id)
                .orderBy('r.reservation_date', 'desc')
                .orderBy('r.reservation_time', 'desc')
                .limit(limit);
            if (status) {
                query = query.where('r.status', status);
            }
            const reservations = await query;
            return {
                total: reservations.length,
                reservations: reservations.map(r => ({
                    id: r.id,
                    branch: r.branch_name,
                    table_id: r.table_id,
                    floor: r.floor_id,
                    date: r.reservation_date,
                    time: r.reservation_time,
                    guests: r.guest_count,
                    status: r.status,
                    special_requests: r.special_requests,
                    created_at: r.created_at
                }))
            };
        } catch (error) {
            throw new Error(`Không thể lấy danh sách đặt bàn: ${error.message}`);
        }
    }
    static async getMyOrders(params) {
        const { status, limit = 10, _user_id } = params;
        if (!_user_id) {
            throw new Error('Vui lòng đăng nhập để xem đơn hàng');
        }
        try {
            let query = knex('orders as o')
                .join('branches as b', 'o.branch_id', 'b.id')
                .select(
                    'o.id',
                    'o.order_number',
                    'o.order_type',
                    'o.status',
                    'o.total_amount',
                    'o.created_at',
                    'b.name as branch_name'
                )
                .where('o.user_id', _user_id)
                .orderBy('o.created_at', 'desc')
                .limit(limit);
            if (status) {
                query = query.where('o.status', status);
            }
            const orders = await query;
            return {
                total: orders.length,
                orders: orders.map(o => ({
                    id: o.id,
                    order_number: o.order_number,
                    branch: o.branch_name,
                    type: o.order_type,
                    status: o.status,
                    total: o.total_amount,
                    created_at: o.created_at
                }))
            };
        } catch (error) {
            throw new Error(`Không thể lấy danh sách đơn hàng: ${error.message}`);
        }
    }
    static async getAllBranches(params) {
        const { district_id, province_id } = params;
        try {
            let query = knex('branches as b')
                .select(
                    'b.id',
                    'b.name',
                    'b.address_detail',
                    'b.phone',
                    'b.email',
                    'b.opening_hours',
                    'b.close_hours',
                    'b.description'
                )
                .where('b.status', 'active');
            const branches = await query.orderBy('b.name', 'asc');
            return {
                total: branches.length,
                branches: branches.map(b => ({
                    id: b.id,
                    name: b.name,
                    address: b.address_detail,
                    phone: b.phone,
                    email: b.email,
                    operating_hours: {
                        open: `${b.opening_hours}:00`,
                        close: `${b.close_hours}:00`
                    },
                    description: b.description || null
                }))
            };
        } catch (error) {
            throw new Error(`Không thể lấy danh sách chi nhánh: ${error.message}`);
        }
    }
    static async getBranchDetails(params) {
        const { branch_id } = params;
        try {
            const branch = await knex('branches as b')
                .select(
                    'b.id',
                    'b.name',
                    'b.address_detail',
                    'b.phone',
                    'b.email',
                    'b.opening_hours',
                    'b.close_hours',
                    'b.description',
                )
                .where('b.id', branch_id)
                .where('b.status', 'active')
                .first();
            if (!branch) {
                throw new Error('Chi nhánh không tồn tại hoặc không hoạt động');
            }
            const tableStats = await knex('tables')
                .where('branch_id', branch_id)
                .select(
                    knex.raw('COUNT(*) as total_tables'),
                    knex.raw('SUM(capacity) as total_capacity')
                )
                .first();
            return {
                id: branch.id,
                name: branch.name,
                address: branch.address_detail,
                phone: branch.phone,
                email: branch.email,
                operating_hours: {
                    open: `${branch.opening_hours}:00`,
                    close: `${branch.close_hours}:00`,
                    description: `Mở cửa từ ${branch.opening_hours}h đến ${branch.close_hours}h`
                },
                description: branch.description || null,
                capacity: {
                    total_tables: tableStats.total_tables || 0,
                    total_seats: tableStats.total_capacity || 0
                }
            };
        } catch (error) {
            throw new Error(`Không thể lấy thông tin chi nhánh: ${error.message}`);
        }
    }
    static async getProductDetails(params) {
        const { product_id, branch_id } = params;
        try {
            let query = knex('products as p')
                .leftJoin('categories as c', 'p.category_id', 'c.id')
                .select(
                    'p.id',
                    'p.name',
                    'p.description',
                    'p.image',
                    'p.base_price',
                    'c.name as category_name'
                )
                .where('p.id', product_id)
                .where('p.status', 'active')
                .first();
            const product = await query;
            if (!product) {
                throw new Error('Món ăn không tồn tại');
            }
            let branchPrice = null;
            if (branch_id) {
                const branchProduct = await knex('branch_products')
                    .where('product_id', product_id)
                    .where('branch_id', branch_id)
                    .where('status', 'available')
                    .first();
                if (branchProduct) {
                    branchPrice = {
                        price: branchProduct.price,
                        is_available: branchProduct.is_available === 1
                    };
                }
            }
            const options = await knex('product_options as po')
                .join('product_option_values as pov', 'po.id', 'pov.option_id')
                .where('po.product_id', product_id)
                .where('po.status', 'active')
                .select(
                    'po.id as option_id',
                    'po.name as option_name',
                    'po.required',
                    'pov.id as value_id',
                    'pov.value',
                    'pov.price_modifier'
                )
                .orderBy('po.display_order', 'asc')
                .orderBy('pov.display_order', 'asc');
            const groupedOptions = {};
            options.forEach(opt => {
                if (!groupedOptions[opt.option_id]) {
                    groupedOptions[opt.option_id] = {
                        name: opt.option_name,
                        required: opt.required === 1,
                        values: []
                    };
                }
                groupedOptions[opt.option_id].values.push({
                    id: opt.value_id,
                    value: opt.value,
                    price_modifier: opt.price_modifier
                });
            });
            return {
                id: product.id,
                name: product.name,
                description: product.description,
                image: product.image,
                category: product.category_name,
                base_price: product.base_price,
                branch_price: branchPrice,
                options: Object.values(groupedOptions)
            };
        } catch (error) {
            throw new Error(`Không thể lấy thông tin món ăn: ${error.message}`);
        }
    }
    static async getCategories() {
        try {
            const categories = await knex('categories')
                .select('id', 'name', 'description', 'image')
                .orderBy('name', 'asc');
            return {
                total: categories.length,
                categories: categories.map(c => ({
                    id: c.id,
                    name: c.name,
                    description: c.description,
                    icon: c.icon
                }))
            };
        } catch (error) {
            throw new Error(`Không thể lấy danh mục: ${error.message}`);
        }
    }
    static async checkBranchOperatingHours(params) {
        const { branch_id, check_time } = params;
        try {
            const branch = await knex('branches')
                .where('id', branch_id)
                .where('status', 'active')
                .first();
            if (!branch) {
                throw new Error('Chi nhánh không tồn tại');
            }
            const now = new Date();
            const currentHour = now.getHours();
            const currentMinute = now.getMinutes();
            let checkHour = currentHour;
            let checkMinute = currentMinute;
            if (check_time) {
                const [h, m] = check_time.split(':');
                checkHour = parseInt(h);
                checkMinute = parseInt(m);
            }
            const isOpen = checkHour >= branch.opening_hours && checkHour < branch.close_hours;
            return {
                branch_name: branch.name,
                operating_hours: {
                    open: `${branch.opening_hours}:00`,
                    close: `${branch.close_hours}:00`
                },
                check_time: `${checkHour}:${checkMinute.toString().padStart(2, '0')}`,
                is_open: isOpen,
                message: isOpen
                    ? `Chi nhánh đang mở cửa`
                    : `Chi nhánh đóng cửa. Giờ làm việc: ${branch.opening_hours}h - ${branch.close_hours}h`
            };
        } catch (error) {
            throw new Error(`Không thể kiểm tra giờ làm việc: ${error.message}`);
        }
    }
}
module.exports = ToolHandlers;
