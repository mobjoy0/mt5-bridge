import express from 'express';
import cors from 'cors';
import dataRoute from './routes/dataRoute';
import swaggerUi from 'swagger-ui-express';
import swaggerSpec from './swagger';
import { Request, Response, NextFunction } from 'express';
import { HttpError } from './utils/HttpError';

const app = express();

app.use(cors());
app.use(express.json());

app.use('/v1', dataRoute);

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));



app.use((err: Error, req: Request, res: Response, next: NextFunction): void => {
    console.error(err);

    if (err instanceof HttpError) {
        res.status(err.statusCode).json({
            error: {
                message: err.message,
                statusCode: err.statusCode,
                details: err.details.details ?? null,
            },
        });
        return;
    }

    res.status(500).json({
        error: {
            message: 'Internal Server Error',
            statusCode: 500,

        },
    });
});




const PORT = process.env.PORT || 8891;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
