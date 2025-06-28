import { HttpError } from './HttpError';

export const NotFound = (msg = 'Not Found') => new HttpError(404, msg);
export const BadRequest = (msg = 'Bad Request') => new HttpError(400, msg);
export const Unauthorized = (msg = 'Unauthorized') => new HttpError(401, msg);
export const SeriviceUnavailable = (msg = 'Service Unavailable') => new HttpError(503, msg);
