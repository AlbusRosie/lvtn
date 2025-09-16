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

    async function generateNextTableNumber(branchId, floorId) {
        const tables = await getTablesByBranchAndFloor(branchId, floorId);

        let maxNumber = 0;
        tables.forEach(table => {
            const tableNumber = table.table_number;
            if (tableNumber.startsWith('T')) {
                const numberPart = parseInt(tableNumber.substring(1));
                if (!isNaN(numberPart) && numberPart > maxNumber) {
                    maxNumber = numberPart;
                }
            }
        });

        const nextNumber = maxNumber + 1;
        return {
            nextTableNumber: `T${String(nextNumber).padStart(2, '0')}`,
            currentTableCount: tables.length,
            maxNumber: maxNumber
        };
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
        generateNextTableNumber,
        createTable,
        updateTable,
        updateTableStatus,
        deleteTable,
        getStatusOptions,
        getStatusLabel,
        getStatusColor
    };
}

export default makeTableService();