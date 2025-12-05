import { efetch, buildQueryString } from './BaseService';
function makeTableService() {
    const baseUrl = '/api/tables';
    async function getAllTables(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}?${queryString}` : baseUrl;
        return efetch(url);
    }
    async function getAvailableTables(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/available?${queryString}` : `${baseUrl}/available`;
        return efetch(url);
    }
    async function getTablesByStatus(status, params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/status/${status}?${queryString}` : `${baseUrl}/status/${status}`;
        return efetch(url);
    }
    async function getTableById(id) {
        const { table } = await efetch(`${baseUrl}/${id}`);
        return table;
    }
    async function getTablesByBranchAndFloor(branchId, floorId) {
        return efetch(`${baseUrl}/branches/${branchId}/floors/${floorId}/tables`);
    }
    async function createTable(tableData) {
        return efetch(baseUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(tableData)
        });
    }
    async function updateTable(id, tableData) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(tableData)
        });
    }
    async function updateTableStatus(id, status) {
        return efetch(`${baseUrl}/${id}/status`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ status })
        });
    }
    async function deleteTable(id) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'DELETE'
        });
    }
    async function checkTableAvailability(tableId, date, time, durationMinutes = 120) {
        let normalizedTime = time;
        if (normalizedTime.length === 5) {
            normalizedTime = normalizedTime + ':00';
        }
        const queryString = buildQueryString({
            date,
            time: normalizedTime,
            duration_minutes: durationMinutes
        });
        const data = await efetch(`${baseUrl}/${tableId}/check-availability?${queryString}`);
        return data;
    }
    function getStatusOptions() {
        return [
            { value: 'available', label: 'Có sẵn', color: 'green' },
            { value: 'occupied', label: 'Đang sử dụng', color: 'red' },
            { value: 'reserved', label: 'Đã đặt trước', color: 'orange' },
            { value: 'maintenance', label: 'Bảo trì', color: 'gray' }
        ];
    }
    function getStatusLabel(status) {
        const options = getStatusOptions();
        const option = options.find(opt => opt.value === status);
        return option ? option.label : status;
    }
    function getStatusColor(status) {
        const options = getStatusOptions();
        const option = options.find(opt => opt.value === status);
        return option ? option.color : 'gray';
    }
    return {
        getAllTables,
        getAvailableTables,
        getTablesByStatus,
        getTableById,
        getTablesByBranchAndFloor,
        createTable,
        updateTable,
        updateTableStatus,
        deleteTable,
        checkTableAvailability,
        getStatusOptions,
        getStatusLabel,
        getStatusColor
    };
}
export default makeTableService();