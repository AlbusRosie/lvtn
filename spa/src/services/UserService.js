import { DEFAULT_AVATAR } from '@/constants';

async function efetch(url, options = {}) {
    let result = {};
    let json = {};
    const token = localStorage.getItem('auth_token');
    const headers = {
        ...(options.headers || {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
    };
    try {
        result = await fetch(url, { ...options, headers });
        json = await result.json();

    } catch (error) {

        throw new Error(error.message);
    }
    if (!result.ok || json.status !== 'success') {
        throw new Error(json.message);
    }
    return json.data;
}

function makeUsersService() {
    const baseUrl = '/api/users';

    async function fetchUsers(page, limit = 10, filters = {}) {
        let url = `${baseUrl}?page=${page}&limit=${limit}`;

        if (filters.name) {
            url += `&name=${encodeURIComponent(filters.name)}`;
        }
        if (filters.phone) {
            url += `&phone=${encodeURIComponent(filters.phone)}`;
        }
        if (filters.role_id) {
            url += `&role_id=${filters.role_id}`;
        }
        if (filters.favorite !== undefined) {
            url += `&favorite=${filters.favorite}`;
        }

        const data = await efetch(url);
        data.users = data.users.map((user) => {
        return {
            ...user,
            avatar: user.avatar ?? DEFAULT_AVATAR
        };
        });
        return data;
    }

    async function fetchUser(id) {
        const { user } = await efetch(`${baseUrl}/${id}`);
        return {
        ...user,
        avatar: user.avatar ?? DEFAULT_AVATAR
        };
    }

    async function createUser(user) {

        return efetch(`${baseUrl}/register`, {
            method: 'POST',
            body: user // FormData doesn't need Content-Type header or JSON.stringify
        });
    }

    async function deleteAllUsers() {
        return efetch(baseUrl, {
        method: 'DELETE'
        });
    }

    async function updateUser(id, user) {

        return efetch(`${baseUrl}/${id}`, {
        method: 'PUT',
        body: user
        });
    }

    async function deleteUser(id) {
        return efetch(`${baseUrl}/${id}`, {
        method: 'DELETE'
        });
    }

    async function getUsers(page, limit = 10, filters = {}) {
        return fetchUsers(page, limit, filters);
    }

    async function login(credentials) {
        return efetch(`${baseUrl}/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(credentials)
        });
    }

    return {
        fetchUsers,
        fetchUser,
        createUser,
        updateUser,
        deleteUser,
        deleteAllUsers,
        getUsers,
        login
    };
}

export default makeUsersService();