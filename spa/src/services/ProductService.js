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
        return { data };
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

        const created = await efetch(baseUrl, {
            method: 'POST',
            body
        });
        try {
            if (body instanceof FormData) {
                const optionsStr = body.get('options');
                if (optionsStr) {
                    const options = JSON.parse(optionsStr);
                    await syncProductOptions(created.id, [], options);
                }
            }
        } catch (e) {
            // Swallow option sync errors to not block product creation
            console.error('Option sync failed:', e);
        }
        return created;
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
        const updated = await efetch(`${baseUrl}/${id}`, {
            method: 'PUT',
            body
        });
        try {
            if (body instanceof FormData) {
                const optionsStr = body.get('options');
                if (optionsStr) {
                    // Load existing ids to detect deletions
                    const existing = await getProductOptions(id);
                    const originalIds = (existing || []).map(o => o.id);
                    const options = JSON.parse(optionsStr);
                    await syncProductOptions(id, originalIds, options);
                }
            }
        } catch (e) {
            console.error('Option sync failed:', e);
        }
        return updated;
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
        const queryString = buildQueryString({ ...params, branch_id: branchId });
        const url = queryString ? `${baseUrl}?${queryString}` : `${baseUrl}?branch_id=${branchId}`;
        
        const data = await efetch(url);
        if (data.products) {
            data.products = transformDataArray(data.products, DEFAULT_PRODUCT_IMAGE);
        }
        return data;
    }

    async function getNotAddedProductsByBranch(branchId, params = {}) {
        const queryString = buildQueryString({ ...params, branch_id: branchId });
        const url = queryString ? `${baseUrl}/not-added?${queryString}` : `${baseUrl}/not-added?branch_id=${branchId}`;
        
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

    async function createProductOption(productId, optionData) {
        const response = await efetch(`/api/products/${productId}/options`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(optionData)
        });
        return response.data;
    }

    async function updateProductOption(productId, optionTypeId, optionData) {
        const response = await efetch(`/api/products/${productId}/options/${optionTypeId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(optionData)
        });
        return response.data;
    }

    async function deleteProductOption(productId, optionTypeId) {
        const response = await efetch(`/api/products/${productId}/options/${optionTypeId}`, {
            method: 'DELETE'
        });
        return response;
    }

    async function getProductOptions(productId) {
        return efetch(`/api/products/${productId}/options`);
    }

    async function syncProductOptions(productId, originalOptionIds = [], options = []) {
        const currentIds = options.filter(o => o.id).map(o => o.id);
        const toDelete = originalOptionIds.filter(id => !currentIds.includes(id));

        // Delete removed options
        for (const id of toDelete) {
            await deleteProductOption(productId, id);
        }

        // Upsert options
        for (const opt of options) {
            const payload = {
                name: opt.name,
                type: opt.type || 'select',
                required: !!opt.required,
                display_order: opt.display_order ?? 0,
                values: (opt.values || []).map((v, idx) => ({
                    value: v.value,
                    price_modifier: v.price_modifier ?? 0,
                    display_order: v.display_order ?? idx,
                }))
            };
            if (opt.id) {
                // If no values remain, delete the option type
                if (!payload.values || payload.values.length === 0) {
                    await deleteProductOption(productId, opt.id);
                    continue;
                }
                await updateProductOption(productId, opt.id, payload);
            } else {
                await createProductOption(productId, payload);
            }
        }
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
        getNotAddedProductsByBranch,
        getBranchProduct,
        getActiveBranches,
        createProductOption,
        updateProductOption,
        deleteProductOption,
        getProductOptions,
        syncProductOptions
    };
}

export default makeProductService();