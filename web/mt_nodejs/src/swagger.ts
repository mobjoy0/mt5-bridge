// @ts-ignore
import swaggerJSDoc from 'swagger-jsdoc';
import path from 'path';


const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'My API',
            version: '1.0.0',
            description: 'API documentation for my Node.js backend',
        },
        servers: [
            {
                url: 'http://localhost:8891/v1',
            },
        ],
    },
    apis: [path.join(__dirname, 'routes/**/*.ts')],
};

const swaggerSpec = swaggerJSDoc(options);

export default swaggerSpec;
