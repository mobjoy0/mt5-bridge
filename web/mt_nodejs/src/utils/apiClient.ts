import axios, { AxiosRequestConfig } from 'axios';
import { HttpError } from './HttpError';

const api = axios.create({
    baseURL: 'http://127.0.0.1:8890/v1',
});

export async function apiRequest<T>(config: AxiosRequestConfig): Promise<T> {
    try {
        const response = await api.request<T>(config);
        return response.data;
    } catch (err: any) {
        if (axios.isAxiosError(err)) {
            const status = err.response?.status || 500;
            const data = err.response?.data;

            // Extract detail message if available
            const detailMessage =
                typeof data === 'object' && data?.detail
                    ? String(data.detail)
                    : err.response?.statusText || 'External API error';

            // Explicit cases
            if (!err.response) {
                throw new HttpError(503, 'External API is unreachable.');
            }

            if (status >= 500) {
                // preserve original status and details instead of forcing 503 without details
                throw new HttpError(status, detailMessage, data);
            }

            if (status === 404) {
                throw new HttpError(404, 'Resource not found.', data);
            }

            if (status === 401) {
                throw new HttpError(401, 'Unauthorized access to external API.', data);
            }


            // Default: forward external error with extracted message
            throw new HttpError(status, detailMessage, data);
        }

        // Non-Axios or unexpected error
        throw new HttpError(500, 'Unexpected error when calling external API.');
    }
}
