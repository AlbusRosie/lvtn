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

    async function createCategory(categoryData, imageFile = null) {
        if (imageFile && imageFile instanceof File) {
            const formData = new FormData();
            
            Object.keys(categoryData).forEach(key => {
                if (key !== 'imageFile') {
                    formData.append(key, categoryData[key]);
                }
            });
            
            formData.append('categoryImage', imageFile);
            
            return efetch(baseUrl, {
                method: 'POST',
                body: formData
            });
        } else {
            const { imageFile: _, ...cleanData } = categoryData;
            return efetch(baseUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(cleanData)
            });
        }
    }

    async function updateCategory(id, categoryData, imageFile = null) {
        if (imageFile && imageFile instanceof File) {
            const formData = new FormData();
            
            Object.keys(categoryData).forEach(key => {
                if (key !== 'imageFile') {
                    formData.append(key, categoryData[key]);
                }
            });
            
            formData.append('categoryImage', imageFile);
            
            return efetch(`${baseUrl}/${id}`, {
                method: 'PUT',
                body: formData
            });
        } else {
            const { imageFile: _, ...cleanData } = categoryData;
            return efetch(`${baseUrl}/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(cleanData)
            });
        }
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