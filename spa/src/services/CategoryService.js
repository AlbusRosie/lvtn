import { efetch } from './BaseService';

function makeCategoryService() {
    const baseUrl = '/api/categories';

    async function getAllCategories() {
        return efetch(baseUrl);
    }

    async function getCategoriesWithProductCount() {
        return efetch(`${baseUrl}/with-count`);
    }

    async function getCategoryById(id) {
        const { category } = await efetch(`${baseUrl}/${id}`);
        return category;
    }

    async function createCategory(categoryData) {
        return efetch(baseUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(categoryData)
        });
    }

    async function updateCategory(id, categoryData) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(categoryData)
        });
    }

    async function deleteCategory(id) {
        return efetch(`${baseUrl}/${id}`, {
            method: 'DELETE'
        });
    }

    return {
        getAllCategories,
        getCategoriesWithProductCount,
        getCategoryById,
        createCategory,
        updateCategory,
        deleteCategory
    };
}

export default makeCategoryService();