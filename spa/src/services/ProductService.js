import { efetch, buildQueryString, transformData, transformDataArray } from './BaseService';
import { DEFAULT_PRODUCT_IMAGE } from '@/constants';

function makeProductService() {
    const baseUrl = '/api/products';

    async function getProducts(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}?${queryString}` : baseUrl;
        
        const data = await efetch(url);
        if (data.products) {
            data.products = transformDataArray(data.products, DEFAULT_PRODUCT_IMAGE);
        }
        return data;
    }

    async function getAvailableProducts(params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/available?${queryString}` : `${baseUrl}/available`;
        
        const data = await efetch(url);
        if (data.products) {
            data.products = transformDataArray(data.products, DEFAULT_PRODUCT_IMAGE);
        }
        return data;
    }

    async function getProduct(id) {
        const data = await efetch(`${baseUrl}/${id}`);
        return transformData(data, DEFAULT_PRODUCT_IMAGE);
    }

    async function createProduct(productData) {
        const body = (productData instanceof FormData)
            ? productData
            : (() => {
                const fd = new FormData();
                Object.entries(productData).forEach(([key, value]) => {
                    fd.append(key, value);
                });
                return fd;
            })();

        return efetch(baseUrl, {
            method: 'POST',
            body
        });
    }

    async function updateProduct(id, productData) {
        const body = (productData instanceof FormData)
            ? productData
            : (() => {
                const fd = new FormData();
                Object.entries(productData).forEach(([key, value]) => {
                    fd.append(key, value);
                });
                return fd;
            })();

        return efetch(`${baseUrl}/${id}`, {
            method: 'PUT',
            body
        });
    }

    async function deleteProduct(id) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'DELETE'
        });
    }

    async function deleteAllProducts() {
        return efetch(baseUrl, {
            method: 'DELETE'
        });
    }

    async function getProductsByCategory(categoryId) {
        const data = await efetch(`${baseUrl}/category/${categoryId}`);
        if (data.products) {
            data.products = transformDataArray(data.products, DEFAULT_PRODUCT_IMAGE);
        }
        return data;
    }

    async function searchProducts(name, params = {}) {
        const searchParams = { ...params, name };
        return getProducts(searchParams);
    }

    async function filterProductsByPrice(minPrice, maxPrice, params = {}) {
        const filterParams = { ...params, min_price: minPrice, max_price: maxPrice };
        return getProducts(filterParams);
    }

    async function filterProductsByAvailability(isAvailable, params = {}) {
        const filterParams = { ...params, is_available: isAvailable };
        return getProducts(filterParams);
    }

    async function addProductToBranch(branchId, productId, branchProductData) {
        return efetch(`${baseUrl}/branches/${branchId}/products/${productId}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(branchProductData)
        });
    }

    async function updateBranchProduct(branchProductId, updateData) {
        return efetch(`${baseUrl}/branch-products/${branchProductId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(updateData)
        });
    }

    async function removeProductFromBranch(branchId, productId) {
        return efetch(`${baseUrl}/branches/${branchId}/products/${productId}`, {
            method: 'DELETE'
        });
    }

    async function getProductsByBranch(branchId, params = {}) {
        const queryString = buildQueryString(params);
        const url = queryString ? `${baseUrl}/branches/${branchId}/products?${queryString}` : `${baseUrl}/branches/${branchId}/products`;
        
        const data = await efetch(url);
        if (data.products) {
            data.products = transformDataArray(data.products, DEFAULT_PRODUCT_IMAGE);
        }
        return data;
    }

    async function getBranchProduct(branchProductId) {
        const { branchProduct } = await efetch(`${baseUrl}/branch-products/${branchProductId}`);
        return transformData(branchProduct, DEFAULT_PRODUCT_IMAGE);
    }

    async function getActiveBranches() {
        return efetch(`${baseUrl}/branches/active`);
    }

    return {
        getProducts,
        getAvailableProducts,
        getProduct,
        createProduct,
        updateProduct,
        deleteProduct,
        deleteAllProducts,
        getProductsByCategory,
        searchProducts,
        filterProductsByPrice,
        filterProductsByAvailability,
        addProductToBranch,
        updateBranchProduct,
        removeProductFromBranch,
        getProductsByBranch,
        getBranchProduct,
        getActiveBranches
    };
}

export default makeProductService();