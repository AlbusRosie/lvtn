import { DEFAULT_AVATAR, DEFAULT_PRODUCT_IMAGE } from '@/constants';

/**
 * Enhanced fetch utility with authentication and error handling
 * @param {string} url
 * @param {RequestInit} options
 * @returns Promise<any>
 */
async function efetch(url, options = {}) {
    const token = localStorage.getItem('auth_token');
    
    const headers = {
        'Content-Type': 'application/json',
        ...(options.headers || {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
    };

    if (options.body instanceof FormData) {
        delete headers['Content-Type'];
    }

    let result = {};
    let json = {};
    
    try {
        result = await fetch(url, { ...options, headers });
        json = await result.json();
    } catch (error) {
        throw new Error(error.message);
    }
    
    if (!result.ok || json.status !== 'success') {
        if (result.status === 401) {
            localStorage.removeItem('auth_token');
            localStorage.removeItem('auth_user');
            window.location.href = '/admin/login';
            return;
        }
        throw new Error(json.message || 'Bạn cần đăng nhập');
    }
    
    return json.data;
}

/**
 * Create query string from parameters
 * @param {Object} params
 * @returns {string}
 */
function buildQueryString(params) {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
        if (value !== null && value !== undefined && value !== '') {
            searchParams.append(key, value);
        }
    });
    return searchParams.toString();
}

/**
 * Transform data with default values
 * @param {Object} data
 * @param {string} defaultImage
 * @returns {Object}
 */
function transformData(data, defaultImage = DEFAULT_AVATAR) {
    return {
        ...data,
        avatar: data.avatar ?? defaultImage,
        image: data.image ?? defaultImage
    };
}

/**
 * Transform array of data with default values
 * @param {Array} items
 * @param {string} defaultImage
 * @returns {Array}
 */
function transformDataArray(items, defaultImage = DEFAULT_AVATAR) {
    return items.map(item => transformData(item, defaultImage));
}

export { efetch, buildQueryString, transformData, transformDataArray };
