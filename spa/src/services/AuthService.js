import { DEFAULT_AVATAR, USER_ROLES } from '@/constants';
import { efetch } from './BaseService';

function makeAuthService() {
    const TOKEN_KEY = 'auth_token';
    const USER_KEY = 'auth_user';
    const baseUrl = '/api/users';

    async function login(username, password) {
        const data = await efetch(`${baseUrl}/login/admin`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ username, password }),
        });
        localStorage.setItem(TOKEN_KEY, data.token);
        localStorage.setItem(USER_KEY, JSON.stringify(data.user));
        return data;
    }

    function logout() {
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(USER_KEY);
    }

    function getToken() {
        return localStorage.getItem(TOKEN_KEY);
    }

    function getUser() {
        const userStr = localStorage.getItem(USER_KEY);
        if (!userStr) return null;
        const user = JSON.parse(userStr);
        return {
            ...user,
            avatar: user.avatar ?? DEFAULT_AVATAR
        };
    }

    function isAuthenticated() {
        return !!getToken();
    }

    function hasRole(roleId) {
        const user = getUser();
        return user && user.role_id === roleId;
    }

    function isAdmin() {
        return hasRole(USER_ROLES.ADMIN);
    }

    function isCustomer() {
        return hasRole(USER_ROLES.CUSTOMER);
    }

    function isStaff() {
        return hasRole(USER_ROLES.STAFF);
    }

    function canAccessAdmin() {
        return isAdmin() || isStaff();
    }

    return {
        login,
        logout,
        getToken,
        getUser,
        isAuthenticated,
        hasRole,
        isAdmin,
        isCustomer,
        isStaff,
        canAccessAdmin
    };
}

export default makeAuthService();