export class HttpError extends Error {
    statusCode: number;
    details?: any;

    constructor(statusCode: number, message: string, details?: any) {
        super(message);
        this.statusCode = statusCode;
        this.details = details;
        Object.setPrototypeOf(this, HttpError.prototype); // Required for `instanceof` to work
    }
}
