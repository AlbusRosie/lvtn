const knex = require('../database/knex');
const Paginator = require('./Paginator');

function provinceRepository() {
    return knex('provinces');
}

function districtRepository() {
    return knex('districts');
}

function readProvince(payload) {
    return {
        name: payload.name,
        code: payload.code
    };
}

function readDistrict(payload) {
    return {
        name: payload.name,
        code: payload.code,
        province_id: payload.province_id
    };
}

async function createProvince(payload) {
    if (!payload.name || !payload.code) {
        throw new Error('Province name and code are required');
    }

    const existingProvince = await provinceRepository()
        .where('name', payload.name)
        .orWhere('code', payload.code)
        .first();

    if (existingProvince) {
        throw new Error('Province name or code already exists');
    }

    const province = readProvince(payload);
    const [id] = await provinceRepository().insert(province);
    return { id, ...province };
}

async function getManyProvinces(query) {
    const { name, page = 1, limit = 10 } = query;
    const paginator = new Paginator(page, limit);

    let results = await provinceRepository()
        .where((builder) => {
            if (name) {
                builder.where('name', 'like', `%${name}%`);
            }
        })
        .select(
            knex.raw('count(id) OVER() AS recordCount'),
            'id',
            'name',
            'code',
            'created_at'
        )
        .orderBy('name', 'asc')
        .limit(paginator.limit)
        .offset(paginator.offset);

    let totalRecords = 0;
    results = results.map((result) => {
        totalRecords = result.recordCount;
        delete result.recordCount;
        return result;
    });

    return {
        metadata: paginator.getMetadata(totalRecords),
        provinces: results,
    };
}

async function getProvinceById(id) {
    return provinceRepository().where('id', id).select('*').first();
}

async function updateProvince(id, payload) {
    const updatedProvince = await provinceRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!updatedProvince) {
        return null;
    }

    if (payload.name && payload.name !== updatedProvince.name) {
        const nameConflict = await provinceRepository()
            .where('name', payload.name)
            .whereNot('id', id)
            .first();

        if (nameConflict) {
            throw new Error('Province name already exists');
        }
    }

    if (payload.code && payload.code !== updatedProvince.code) {
        const codeConflict = await provinceRepository()
            .where('code', payload.code)
            .whereNot('id', id)
            .first();

        if (codeConflict) {
            throw new Error('Province code already exists');
        }
    }

    const update = readProvince(payload);
    await provinceRepository().where('id', id).update(update);
    return { ...updatedProvince, ...update };
}

async function deleteProvince(id) {
    const deletedProvince = await provinceRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!deletedProvince) {
        return null;
    }

    const districts = await districtRepository()
        .where('province_id', id)
        .select('id');

    if (districts.length > 0) {
        throw new Error('Cannot delete province that has districts');
    }

    await provinceRepository().where('id', id).del();
    return { ...deletedProvince, message: 'Province deleted successfully' };
}

async function deleteAllProvinces() {
    const provinces = await provinceRepository().select('*');
    await provinceRepository().del();
    return { 
        message: 'All provinces deleted successfully',
        deletedProvincesCount: provinces.length
    };
}

async function createDistrict(payload) {
    if (!payload.name || !payload.code || !payload.province_id) {
        throw new Error('District name, code and province ID are required');
    }

    const existingDistrict = await districtRepository()
        .where('name', payload.name)
        .orWhere('code', payload.code)
        .first();

    if (existingDistrict) {
        throw new Error('District name or code already exists');
    }

    const province = await provinceRepository().where('id', payload.province_id).first();
    if (!province) {
        throw new Error('Province not found');
    }

    const district = readDistrict(payload);
    const [id] = await districtRepository().insert(district);
    return { id, ...district };
}

async function getManyDistricts(query) {
    const { name, province_id, page = 1, limit = 10 } = query;
    const paginator = new Paginator(page, limit);

    let results = await districtRepository()
        .select(
            knex.raw('count(districts.id) OVER() AS recordCount'),
            'districts.*',
            'provinces.name as province_name'
        )
        .leftJoin('provinces', 'districts.province_id', 'provinces.id')
        .where((builder) => {
            if (name) {
                builder.where('districts.name', 'like', `%${name}%`);
            }
            if (province_id) {
                builder.where('districts.province_id', province_id);
            }
        })
        .orderBy('districts.name', 'asc')
        .limit(paginator.limit)
        .offset(paginator.offset);

    let totalRecords = 0;
    results = results.map((result) => {
        totalRecords = result.recordCount;
        delete result.recordCount;
        return result;
    });

    return {
        metadata: paginator.getMetadata(totalRecords),
        districts: results,
    };
}

async function getDistrictById(id) {
    return districtRepository()
        .select('districts.*', 'provinces.name as province_name')
        .leftJoin('provinces', 'districts.province_id', 'provinces.id')
        .where('districts.id', id)
        .first();
}

async function updateDistrict(id, payload) {
    const updatedDistrict = await districtRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!updatedDistrict) {
        return null;
    }

    if (payload.name && payload.name !== updatedDistrict.name) {
        const nameConflict = await districtRepository()
            .where('name', payload.name)
            .whereNot('id', id)
            .first();

        if (nameConflict) {
            throw new Error('District name already exists');
        }
    }

    if (payload.code && payload.code !== updatedDistrict.code) {
        const codeConflict = await districtRepository()
            .where('code', payload.code)
            .whereNot('id', id)
            .first();

        if (codeConflict) {
            throw new Error('District code already exists');
        }
    }

    if (payload.province_id) {
        const province = await provinceRepository().where('id', payload.province_id).first();
        if (!province) {
            throw new Error('Province not found');
        }
    }

    const update = readDistrict(payload);
    await districtRepository().where('id', id).update(update);
    return { ...updatedDistrict, ...update };
}

async function deleteDistrict(id) {
    const deletedDistrict = await districtRepository()
        .where('id', id)
        .select('*')
        .first();

    if (!deletedDistrict) {
        return null;
    }

    const branches = await knex('branches')
        .where('district_id', id)
        .select('id');

    if (branches.length > 0) {
        throw new Error('Cannot delete district that has branches');
    }

    await districtRepository().where('id', id).del();
    return { ...deletedDistrict, message: 'District deleted successfully' };
}

async function deleteAllDistricts() {
    const districts = await districtRepository().select('*');
    await districtRepository().del();
    return { 
        message: 'All districts deleted successfully',
        deletedDistrictsCount: districts.length
    };
}

async function getDistrictsByProvinceId(provinceId) {
    return districtRepository()
        .select('*')
        .where('province_id', provinceId)
        .orderBy('name', 'asc');
}

async function searchProvinces(searchTerm) {
    return provinceRepository()
        .select('*')
        .where('name', 'like', `%${searchTerm}%`)
        .orderBy('name', 'asc');
}

async function searchDistricts(searchTerm, provinceId = null) {
    let query = districtRepository()
        .select('districts.*', 'provinces.name as province_name')
        .leftJoin('provinces', 'districts.province_id', 'provinces.id')
        .where('districts.name', 'like', `%${searchTerm}%`);

    if (provinceId) {
        query = query.where('districts.province_id', provinceId);
    }

    return await query.orderBy('districts.name', 'asc');
}

module.exports = {
    createProvince,
    getManyProvinces,
    getProvinceById,
    updateProvince,
    deleteProvince,
    deleteAllProvinces,
    createDistrict,
    getManyDistricts,
    getDistrictById,
    updateDistrict,
    deleteDistrict,
    deleteAllDistricts,
    getDistrictsByProvinceId,
    searchProvinces,
    searchDistricts
};