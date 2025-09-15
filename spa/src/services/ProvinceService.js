import { efetch, buildQueryString } from './BaseService';

function makeProvinceService() {
    const baseUrl = '/api/provinces';

    async function getAllProvinces(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}?${queryString}` : baseUrl;
        return efetch(url);
    }

    async function getProvinceById(id) {
        const { province } = await efetch(`${baseUrl}/${id}`);
        return province;
    }

    async function getDistrictsByProvinceId(provinceId) {
        return efetch(`${baseUrl}/${provinceId}/districts`);
    }

    async function getDistrictById(id) {
        const { district } = await efetch(`${baseUrl}/districts/${id}`);
        return district;
    }

    async function searchProvinces(searchTerm) {
        const params = { q: searchTerm };
        const queryString = buildQueryString(params);
        const url = `${baseUrl}/search?${queryString}`;
        return efetch(url);
    }

    async function searchDistricts(searchTerm, provinceId = null) {
        const params = { q: searchTerm };
        if (provinceId) {
            params.province_id = provinceId;
        }
        const queryString = buildQueryString(params);
        const url = `${baseUrl}/districts/search?${queryString}`;
        return efetch(url);
    }

    return {
        getAllProvinces,
        getProvinceById,
        getDistrictsByProvinceId,
        getDistrictById,
        searchProvinces,
        searchDistricts
    };
}

export default makeProvinceService();
