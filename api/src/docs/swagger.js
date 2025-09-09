const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const options = {
    failOnErrors: true,
    definition: {
        openapi: '3.1.0',
        info: {
            title: 'LVTN Restaurant Management API',
            version: '1.0.0',
            description: 'API cho hệ thống quản lý nhà hàng LVTN với tính năng quản lý đa chi nhánh, tầng, bàn',
        },
        servers: [
            {
                url: 'http://localhost:3000',
                description: 'Development server',
            },
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'JWT token for authentication'
                }
            }
        },
        security: [
            {
                bearerAuth: []
            }
        ]
    },
    apis: ['./src/routes/*.js', './src/docs/components.yaml'],
};
const specs = swaggerJsdoc(options);
const swaggerOptions = {
    swaggerOptions: {
        persistAuthorization: true,
        displayRequestDuration: true,
        docExpansion: 'list',
        filter: true,
        showRequestHeaders: true,
        tryItOutEnabled: true,
        requestInterceptor: (req) => {
            return req;
        }
    },
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'LVTN E-commerce API Documentation'
};

module.exports = {
    specs,
    swaggerUi,
    swaggerOptions
};