export const DEFAULT_AVATAR = '/public/images/blank-profile-picture.png';
export const DEFAULT_PRODUCT_IMAGE = '/public/images/blank-profile-picture.png';
export const API_BASE_URL = 'http://localhost:3000/api';

export const USER_ROLES = {
    ADMIN: 1,
    CUSTOMER: 2,
    STAFF: 3
};

export const ROLE_NAMES = {
    [USER_ROLES.ADMIN]: 'Admin',
    [USER_ROLES.CUSTOMER]: 'Customer',
    [USER_ROLES.STAFF]: 'Staff'
};

export const ORDER_TYPES = {
    DINE_IN: 'dine_in',
    TAKEAWAY: 'takeaway',
    DELIVERY: 'delivery'
};

export const ORDER_STATUS = {
    PENDING: 'pending',
    PREPARING: 'preparing',
    READY: 'ready',
    SERVED: 'served',
    CANCELLED: 'cancelled',
    COMPLETED: 'completed'
};

export const PAYMENT_STATUS = {
    PENDING: 'pending',
    PAID: 'paid',
    FAILED: 'failed'
};

export const TABLE_STATUS = {
    AVAILABLE: 'available',
    OCCUPIED: 'occupied',
    RESERVED: 'reserved',
    MAINTENANCE: 'maintenance'
};

export const BRANCH_STATUS = {
    ACTIVE: 'active',
    INACTIVE: 'inactive',
    MAINTENANCE: 'maintenance'
};

export const FLOOR_STATUS = {
    ACTIVE: 'active',
    INACTIVE: 'inactive',
    MAINTENANCE: 'maintenance'
};

export const RESERVATION_STATUS = {
    PENDING: 'pending',
    CONFIRMED: 'confirmed',
    CANCELLED: 'cancelled',
    COMPLETED: 'completed'
};