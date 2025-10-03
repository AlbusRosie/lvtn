const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'public/uploads/');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'category-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    } else {
        cb(new Error('Only image files are allowed!'), false);
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024
    }
});

const categoryImageUpload = upload.single('categoryImage');

const optionalCategoryImageUpload = (req, res, next) => {
    categoryImageUpload(req, res, (err) => {
        if (err instanceof multer.MulterError) {
            if (err.code === 'LIMIT_FILE_SIZE') {
                return res.status(400).json({
                    status: 'error',
                    message: 'File size too large. Maximum size is 5MB.'
                });
            }
            if (err.code === 'LIMIT_UNEXPECTED_FILE') {
                return res.status(400).json({
                    status: 'error',
                    message: 'Unexpected field. Please use "categoryImage" as field name.'
                });
            }
            return res.status(400).json({
                status: 'error',
                message: err.message
            });
        } else if (err) {
            return res.status(400).json({
                status: 'error',
                message: err.message
            });
        }
        next();
    });
};

module.exports = {
    categoryImageUpload,
    optionalCategoryImageUpload
};
