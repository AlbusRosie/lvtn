import { efetch, buildQueryString } from './BaseService';

function makeBranchService() {
    const baseUrl = '/api/branches';

    async function getAllBranches(searchTerm = null, provinceId = null, districtId = null, status = null) {
        const params = {};
        if (searchTerm) params.search = searchTerm;
        if (provinceId) params.province_id = provinceId;
        if (districtId) params.district_id = districtId;
        if (status) params.status = status;

        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}?${queryString}` : baseUrl;
        
        return efetch(url);
    }

    async function getBranchById(id) {
        const { branch } = await efetch(`${baseUrl}/${id}`);
        return branch;
    }

    async function createBranch(branchData, imageFile = null) {
        if (imageFile) {
            const formData = new FormData();
            
            Object.keys(branchData).forEach(key => {
                formData.append(key, branchData[key]);
            });
            
            formData.append('branchImage', imageFile);
            
            return efetch(baseUrl, {
                method: 'POST',
                body: formData
            });
        } else {
            return efetch(baseUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(branchData)
            });
        }
    }

    async function updateBranch(id, branchData, imageFile = null) {
        if (imageFile === 'KEEP_EXISTING') {
            return efetch(`${baseUrl}/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(branchData)
            });
        } else if (imageFile && imageFile !== 'KEEP_EXISTING') {
            const formData = new FormData();
            
            Object.keys(branchData).forEach(key => {
                formData.append(key, branchData[key]);
            });
            
            formData.append('branchImage', imageFile);
            
            return efetch(`${baseUrl}/${id}`, {
                method: 'PUT',
                body: formData
            });
        } else {
            return efetch(`${baseUrl}/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(branchData)
            });
        }
    }

    async function deleteBranch(id) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'DELETE'
        });
    }

    async function getBranchStatistics() {
        return efetch(`${baseUrl}/statistics`);
    }

    async function getActiveBranches() {
        return efetch(`${baseUrl}/active`);
    }

    async function getActiveBranchesForProduct() {
        return efetch(`${baseUrl}/active`);
    }

    return {
        getAllBranches,
        getBranchById,
        createBranch,
        updateBranch,
        deleteBranch,
        getBranchStatistics,
        getActiveBranches,
        getActiveBranchesForProduct
    };
}

export default makeBranchService();