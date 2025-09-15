import { efetch, buildQueryString } from './BaseService';

function makeFloorService() {
    const baseUrl = '/api/floors';

    async function getAllFloors(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}?${queryString}` : baseUrl;
        return efetch(url);
    }

    async function getFloorById(id) {
        const { floor } = await efetch(`${baseUrl}/${id}`);
        return floor;
    }

    async function getFloorsByBranch(branchId) {
        return efetch(`${baseUrl}/branch/${branchId}`);
    }

    async function createFloor(floorData) {
        return efetch(baseUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(floorData)
        });
    }

    async function updateFloor(id, floorData) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(floorData)
        });
    }

    async function deleteFloor(id) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'DELETE'
        });
    }

    async function getFloorStatistics(branchId = null) {
        const params = branchId ? { branch_id: branchId } : {};
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/statistics?${queryString}` : `${baseUrl}/statistics`;
        return efetch(url);
    }

    async function getActiveFloors(branchId = null) {
        const params = branchId ? { branch_id: branchId } : {};
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/active?${queryString}` : `${baseUrl}/active`;
        return efetch(url);
    }

    async function generateNextFloorNumber(branchId) {
        const floors = await getFloorsByBranch(branchId);

        let maxNumber = 0;
        floors.forEach(floor => {
            const floorNumber = floor.floor_number;
            if (floorNumber && floorNumber > maxNumber) {
                maxNumber = floorNumber;
            }
        });

        const nextNumber = maxNumber + 1;
        return {
            nextFloorNumber: nextNumber,
            currentFloorCount: floors.length,
            maxNumber: maxNumber
        };
    }

    return {
        getAllFloors,
        getFloorById,
        getFloorsByBranch,
        createFloor,
        updateFloor,
        deleteFloor,
        getFloorStatistics,
        getActiveFloors,
        generateNextFloorNumber
    };
}

export default makeFloorService();