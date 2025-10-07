import { efetch, buildQueryString, transformData, transformDataArray } from './BaseService';

function makeUserService() {
    const baseUrl = '/api/users';

    async function fetchUsers(page, limit = 10, filters = {}) {
        const params = { page, limit, ...filters };
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}?${queryString}` : baseUrl;
        
        const data = await efetch(url);
        data.users = transformDataArray(data.users);
        return data;
    }

    async function fetchUser(id) {
        const { user } = await efetch(`${baseUrl}/${id}`);
        return transformData(user);
    }

    async function createUser(userData) {
        const formData = new FormData();
        Object.entries(userData).forEach(([key, value]) => {
            formData.append(key, value);
        });

        // Use admin endpoint for creating users with any role
        return efetch(`${baseUrl}/admin/create`, {
            method: 'POST',
            body: formData
        });
    }

    async function createCustomer(userData) {
        const formData = new FormData();
        Object.entries(userData).forEach(([key, value]) => {
            formData.append(key, value);
        });

        // Use public endpoint for creating customers only
        return efetch(`${baseUrl}/register`, {
            method: 'POST',
            body: formData
        });
    }

    async function updateUser(id, userData) {
        const formData = new FormData();
        Object.entries(userData).forEach(([key, value]) => {
            formData.append(key, value);
        });

        return efetch(`${baseUrl}/${id}`, {
            method: 'PUT',
            body: formData
        });
    }

    async function deleteUser(id) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'DELETE'
        });
    }

    async function deleteAllUsers() {
        return efetch(baseUrl, {
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
        createCustomer,
        updateUser,
        deleteUser,
        deleteAllUsers,
        getUsers,
        login
    };
}

export default makeUserService();