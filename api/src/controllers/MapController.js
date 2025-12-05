const ApiError = require('../api-error');
const { success } = require('../jsend');
async function getMapboxApiKey(req, res, next) {
    try {
        const mapboxKey = process.env.MAPBOX_KEY_PUBLIC || 
                         process.env.MAPBOX_KEY || 
                         null;
        if (!mapboxKey) {
            return next(new ApiError(404, 'Mapbox API key not configured. Please set MAPBOX_KEY_PUBLIC or MAPBOX_KEY in .env file'));
        }
        if (!mapboxKey.startsWith('pk.')) {
            return next(new ApiError(400, 'Mapbox API key phải là public token (bắt đầu bằng pk.). Geocoding API yêu cầu public token.'));
        }
        res.json(success({
            apiKey: mapboxKey
        }));
    } catch (error) {
        next(new ApiError(500, 'Failed to get Mapbox API key', error.message));
    }
}
async function getGoogleMapsApiKey(req, res, next) {
    try {
        const googleMapsKey = process.env.GGMAP_WEB || null;
        if (!googleMapsKey) {
            return next(new ApiError(404, 'Google Maps API key not configured. Please set GGMAP_WEB in .env file'));
        }
        res.json(success({
            apiKey: googleMapsKey
        }));
    } catch (error) {
        next(new ApiError(500, 'Failed to get Google Maps API key', error.message));
    }
}
async function getVietmapApiKey(req, res, next) {
    try {
        const vietmapKey = process.env.VIETMAP_KEY || null;
        if (!vietmapKey) {
            return next(new ApiError(404, 'Vietmap API key not configured. Please set VIETMAP_KEY in .env file'));
        }
        res.json(success({
            apiKey: vietmapKey
        }));
    } catch (error) {
        next(new ApiError(500, 'Failed to get Vietmap API key', error.message));
    }
}
async function vietmapAutocomplete(req, res, next) {
    try {
        const { text, focus, display_type, cityId, distId, wardId, circle_center, circle_radius, cats, layers } = req.query;
        const vietmapKey = process.env.VIETMAP_KEY || null;
        if (!vietmapKey) {
            return next(new ApiError(404, 'Vietmap API key not configured'));
        }
        if (!text || text.trim().length < 2) {
            return res.json(success([]));
        }
        const axios = require('axios');
        const encodedText = encodeURIComponent(text.trim());
        let url = `https://api.vietmap.vn/v1/autocomplete?apikey=${vietmapKey}&text=${encodedText}`;
        if (focus) {
            url += `&focus=${encodeURIComponent(focus)}`;
        }
        if (display_type) {
            url += `&display_type=${encodeURIComponent(display_type)}`;
        }
        if (cityId) {
            url += `&cityId=${encodeURIComponent(cityId)}`;
        }
        if (distId) {
            url += `&distId=${encodeURIComponent(distId)}`;
        }
        if (wardId) {
            url += `&wardId=${encodeURIComponent(wardId)}`;
        }
        if (circle_center) {
            url += `&circle_center=${encodeURIComponent(circle_center)}`;
        }
        if (circle_radius) {
            url += `&circle_radius=${encodeURIComponent(circle_radius)}`;
        }
        if (cats) {
            url += `&cats=${encodeURIComponent(cats)}`;
        }
        if (layers) {
            url += `&layers=${encodeURIComponent(layers)}`;
        }
        try {
            const response = await axios.get(url, {
                timeout: 10000,
                validateStatus: () => true
            });
            if (response.status === 200 && response.data) {
                const data = Array.isArray(response.data) ? response.data : (response.data.data || []);
                return res.json(success(data));
            } else if (response.status === 423) {
                return next(new ApiError(429, 'Vietmap API request limit exceeded. Please try again later.', response.data || 'Your request is limited'));
            } else if (response.status === 401 || response.status === 403) {
                return next(new ApiError(403, 'Vietmap API authentication failed. Please check your API key.', response.data));
            } else {
                const errorMessage = typeof response.data === 'string' ? response.data : JSON.stringify(response.data);
                return next(new ApiError(502, `Vietmap API returned error (${response.status})`, errorMessage));
            }
        } catch (error) {
            if (error.response) {
                if (error.response.status === 423) {
                    return next(new ApiError(429, 'Vietmap API request limit exceeded', error.response.data || 'Your request is limited'));
                } else if (error.response.status === 401 || error.response.status === 403) {
                    return next(new ApiError(403, 'Vietmap API authentication failed', error.response.data));
                }
            }
            if (error.request) {
                return next(new ApiError(504, 'Vietmap API request timeout or network error', error.message));
            }
            return next(new ApiError(500, 'Failed to call Vietmap Autocomplete API', error.message));
        }
    } catch (error) {
        next(new ApiError(500, 'Failed to process autocomplete request', error.message));
    }
}
async function vietmapSearch(req, res, next) {
    try {
        const { text, focus, display_type, layers, circle_center, circle_radius, cats, cityId, distId, wardId } = req.query;
        const vietmapKey = process.env.VIETMAP_KEY || null;
        if (!vietmapKey) {
            return next(new ApiError(404, 'Vietmap API key not configured'));
        }
        if (!text || text.trim().length < 2) {
            return res.json(success({ data: [] }));
        }
        const axios = require('axios');
        const encodedText = encodeURIComponent(text.trim());
        let url = `https://api.vietmap.vn/v1/search?apikey=${vietmapKey}&text=${encodedText}`;
        if (focus) {
            url += `&focus=${encodeURIComponent(focus)}`;
        }
        if (display_type) {
            url += `&display_type=${encodeURIComponent(display_type)}`;
        }
        if (layers) {
            url += `&layers=${encodeURIComponent(layers)}`;
        }
        if (circle_center) {
            url += `&circle_center=${encodeURIComponent(circle_center)}`;
        }
        if (circle_radius) {
            url += `&circle_radius=${encodeURIComponent(circle_radius)}`;
        }
        if (cats) {
            url += `&cats=${encodeURIComponent(cats)}`;
        }
        if (cityId) {
            url += `&cityId=${encodeURIComponent(cityId)}`;
        }
        if (distId) {
            url += `&distId=${encodeURIComponent(distId)}`;
        }
        if (wardId) {
            url += `&wardId=${encodeURIComponent(wardId)}`;
        }
        try {
            const response = await axios.get(url, {
                timeout: 10000,
                validateStatus: () => true
            });
            if (response.status === 200 && response.data) {
                return res.json(success(response.data));
            } else {
                throw new Error(`API returned status ${response.status}: ${JSON.stringify(response.data)}`);
            }
        } catch (error) {
            if (error.response) {
            }
            return next(new ApiError(500, 'Failed to call Vietmap Search API', error.message));
        }
    } catch (error) {
        next(new ApiError(500, 'Failed to process search request', error.message));
    }
}
async function vietmapPlaceDetails(req, res, next) {
    try {
        const { refid } = req.query;
        const vietmapKey = process.env.VIETMAP_KEY || null;
        if (!vietmapKey) {
            return next(new ApiError(404, 'Vietmap API key not configured'));
        }
        if (!refid) {
            return next(new ApiError(400, 'refid is required'));
        }
        const axios = require('axios');
        const encodedRefId = encodeURIComponent(refid);
        const url = `https://api.vietmap.vn/v1/place?apikey=${vietmapKey}&refid=${encodedRefId}`;
        try {
            const response = await axios.get(url, {
                timeout: 10000,
                validateStatus: () => true
            });
            if (response.status === 200 && response.data) {
                return res.json(success(response.data));
            } else {
                throw new Error(`API returned status ${response.status}: ${JSON.stringify(response.data)}`);
            }
        } catch (error) {
            if (error.response) {
            }
            return next(new ApiError(500, 'Failed to call Vietmap Place API', error.message));
        }
    } catch (error) {
        next(new ApiError(500, 'Failed to process place details request', error.message));
    }
}
async function mapboxGeocode(req, res, next) {
    try {
        const { query, proximity, limit = '10' } = req.query;
        const mapboxKey = process.env.MAPBOX_KEY_PUBLIC || 
                         process.env.MAPBOX_KEY || 
                         null;
        if (!mapboxKey) {
            return next(new ApiError(404, 'Mapbox API key not configured'));
        }
        if (!query || query.trim().length < 2) {
            return res.json(success({ features: [] }));
        }
        const axios = require('axios');
        const encodedQuery = encodeURIComponent(query.trim());
        let url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedQuery}.json?access_token=${mapboxKey}&limit=${limit}`;
        if (query.trim().length >= 3) {
            url += '&country=VN&types=address,poi,place';
        }
        if (proximity) {
            url += `&proximity=${encodeURIComponent(proximity)}`;
        }
        try {
            const response = await axios.get(url, {
                timeout: 20000, 
                validateStatus: () => true
            });
            if (response.status === 200 && response.data) {
                return res.json(success(response.data));
            } else if (response.status === 401 || response.status === 403) {
                return next(new ApiError(403, 'Mapbox API authentication failed. Please check your API key.', response.data));
            } else {
                const errorMessage = typeof response.data === 'string' ? response.data : JSON.stringify(response.data);
                return next(new ApiError(502, `Mapbox API returned error (${response.status})`, errorMessage));
            }
        } catch (error) {
            if (error.response) {
                if (error.response.status === 401 || error.response.status === 403) {
                    return next(new ApiError(403, 'Mapbox API authentication failed', error.response.data));
                }
            }
            if (error.request) {
                return next(new ApiError(504, 'Mapbox API request timeout or network error', error.message));
            }
            return next(new ApiError(500, 'Failed to call Mapbox Geocoding API', error.message));
        }
    } catch (error) {
        next(new ApiError(500, 'Failed to process geocode request', error.message));
    }
}
async function mapboxPlaceDetails(req, res, next) {
    try {
        const { placeId } = req.query;
        const mapboxKey = process.env.MAPBOX_KEY_PUBLIC || 
                         process.env.MAPBOX_KEY || 
                         null;
        if (!mapboxKey) {
            return next(new ApiError(404, 'Mapbox API key not configured'));
        }
        if (!placeId) {
            return next(new ApiError(400, 'placeId is required'));
        }
        const axios = require('axios');
        const encodedPlaceId = encodeURIComponent(placeId);
        const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedPlaceId}.json?access_token=${mapboxKey}`;
        try {
            const response = await axios.get(url, {
                timeout: 15000,
                validateStatus: () => true
            });
            if (response.status === 200 && response.data) {
                return res.json(success(response.data));
            } else {
                throw new Error(`API returned status ${response.status}: ${JSON.stringify(response.data)}`);
            }
        } catch (error) {
            if (error.response) {
            }
            return next(new ApiError(500, 'Failed to call Mapbox Place Details API', error.message));
        }
    } catch (error) {
        next(new ApiError(500, 'Failed to process place details request', error.message));
    }
}
module.exports = {
    getMapboxApiKey,
    getGoogleMapsApiKey,
    getVietmapApiKey,
    vietmapAutocomplete,
    vietmapSearch,
    vietmapPlaceDetails,
    mapboxGeocode,
    mapboxPlaceDetails
};
