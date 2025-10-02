const multer = require('multer');
const path = require('path');
const ApiError = require('../api-error');

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'public/uploads');
    },
    filename: (req, file, cb) => {
        const uniquePrefix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'branch-' + uniquePrefix + path.extname(file.originalname));
    },
});

const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new ApiError(400, 'Only image files are allowed'), false);
    }
};

function branchImageUpload(req, res, next) {
    const upload = multer({
        storage,
        fileFilter,
        limits: {
            fileSize: 5 * 1024 * 1024
        }
    }).single('branchImage');

    upload(req, res, function (err) {
        if(err instanceof multer.MulterError) {
            if (err.code === 'LIMIT_FILE_SIZE') {
                return next(new ApiError(400, 'File size too large. Maximum size is 5MB'));
            }
            return next(new ApiError(400, 'Branch image upload failed'));
        } else if(err) {
            return next(err);
        }
        next();
    });
}

function optionalBranchImageUpload(req, res, next) {
    const contentType = req.headers['content-type'] || '';
    if (contentType.includes('multipart/form-data')) {
        return branchImageUpload(req, res, next);
    }
    return next();
}

module.exports = {
    branchImageUpload,
    optionalBranchImageUpload
};
