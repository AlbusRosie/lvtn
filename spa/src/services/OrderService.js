import { efetch, buildQueryString } from './BaseService';
function makeOrderService() {
    const baseUrl = '/api';
    async function getAllOrders(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/admin/orders?${queryString}` : `${baseUrl}/admin/orders`;
        const data = await efetch(url);
        return data;
    }
    async function getOrderById(id) {
        const data = await efetch(`${baseUrl}/orders/${id}/details`);
        return data;
    }
    async function updateOrderStatus(id, status) {
        try {
            const data = await efetch(`${baseUrl}/employee/orders/${id}/status`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ status }),
            });
            return data;
        } catch (error) {
            const data = await efetch(`${baseUrl}/admin/orders/${id}/status`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ status }),
            });
            return data;
        }
    }
    async function getOrderStatistics(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/admin/orders/statistics?${queryString}` : `${baseUrl}/admin/orders/statistics`;
        const data = await efetch(url);
        return data;
    }
    async function getTopProducts(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/admin/orders/top-products?${queryString}` : `${baseUrl}/admin/orders/top-products`;
        try {
            const data = await efetch(url);
            return data;
        } catch (error) {
            console.error('Error fetching top products:', error);
            throw error;
        }
    }
    async function cancelOrder(id) {
        const data = await efetch(`${baseUrl}/orders/${id}/cancel`, {
            method: 'PUT',
        });
        return data;
    }
    async function getOrdersByBranch(branchId, params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/orders/branch/${branchId}?${queryString}` : `${baseUrl}/orders/branch/${branchId}`;
        const data = await efetch(url);
        return data;
    }
    async function getKitchenOrders(branchId) {
        const data = await efetch(`${baseUrl}/kitchen/orders?branch_id=${branchId}`);
        return data;
    }
    async function markOrderReady(orderId) {
        try {
            const data = await efetch(`${baseUrl}/kitchen/orders/${orderId}/ready`, {
                method: 'PUT',
            });
            return data;
        } catch (error) {
            throw error;
        }
    }
    async function assignDeliveryStaff(orderId, deliveryStaffId) {
        const data = await efetch(`${baseUrl}/admin/orders/${orderId}/assign-delivery`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ delivery_staff_id: deliveryStaffId }),
        });
        return data;
    }
    async function updatePaymentStatus(orderId, paymentStatus, paymentMethod = null) {
        try {
            const data = await efetch(`${baseUrl}/employee/orders/${orderId}/payment-status`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ payment_status: paymentStatus, payment_method: paymentMethod }),
            });
            return data;
        } catch (error) {
            const data = await efetch(`${baseUrl}/admin/orders/${orderId}/payment-status`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ payment_status: paymentStatus, payment_method: paymentMethod }),
            });
            return data;
        }
    }
    async function updateInternalNotes(orderId, notes) {
        const data = await efetch(`${baseUrl}/admin/orders/${orderId}/internal-notes`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ internal_notes: notes }),
        });
        return data;
    }
    async function deleteOrder(orderId) {
        const data = await efetch(`${baseUrl}/admin/orders/${orderId}`, {
            method: 'DELETE',
        });
        return data;
    }
    async function createOrder(orderData) {
        const data = await efetch(`${baseUrl}/orders`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(orderData),
        });
        return data;
    }
    return {
        createOrder,
        getAllOrders,
        getOrderById,
        updateOrderStatus,
        getOrderStatistics,
        getTopProducts,
        cancelOrder,
        getOrdersByBranch,
        getKitchenOrders,
        markOrderReady,
        assignDeliveryStaff,
        updatePaymentStatus,
        updateInternalNotes,
        deleteOrder,
    };
}
export default makeOrderService();
