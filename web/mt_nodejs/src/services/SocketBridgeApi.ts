import { apiRequest } from '../utils/apiClient';


// order
export const fetchOrderList = async () => {
    return apiRequest({
        method: 'GET',
        url: '/order/list',
    });
};

export interface SendOrderRequest {
    symbol?: string;
    volume?: number;
    order_type?: string;
    sl?: number;
    tp?: number;
    price?: number;
    magic?: number;
    type_filling: string;
    comment?: string;
}
export const postSendOrder = async (body: SendOrderRequest) => {
    console.log("Posting send order...");
    return apiRequest({
        method: 'POST',
        url: '/order',
        data: body
    });
}

export interface CloseOrderRequest {
    ticket?: number;
}
export const closeSendOrder = async (body: CloseOrderRequest) => {
    console.log("Posting close order...");
    return apiRequest({
        method: 'POST',
        url: '/order/close',
        data: body
    });
}


// account
export const fetchAccount = async () => {
    console.log("Fetching account information...");
    return apiRequest({
        method: 'GET',
        url: '/account',
    });
};



//history
export interface OrderHistoryParams {
    mode?: string;
    from_date?: string;
    to_date?: string;
}
export const fetchOrderHistory = async (params?: OrderHistoryParams) => {
    console.log("Fetching order history...");
    return apiRequest({
        method: 'GET',
        url: '/history/orders',
        params
    });
};

export interface PriceHistoryParams {
    symbol?: string;
    time_frame?: string;
    from_date?: string;
    to_date?: string;
}
export const fetchPriceHistory = async (params?: PriceHistoryParams) => {
    console.log("Fetching price history...");
    return apiRequest({
        method: 'GET',
        url: '/history/prices',
        params
    });
};


//track
export interface TrackPricesBody {
    symbol: string[];
}
export const postTrackPrices = async (body: TrackPricesBody) => {
    console.log("Posting track prices...");
    return apiRequest({
        method: 'POST',
        url: '/track/prices',
        data: body
    });
}

export interface OhlcRequest {
    OHLC: OhlcEntry[];
}
export interface OhlcEntry {
    TIMEFRAME: string;
    SYMBOL: string;
    DEPTH: number;
}
export const postTrackOhlc = async (body: OhlcRequest) => {
    console.log("Posting track ohlc...");
    return apiRequest({
        method: 'POST',
        url: '/track/ohlc',
        data: body
    });
}

export const postTrackMbook = async (body: TrackPricesBody) => {
    console.log("Posting track mbook...");
    return apiRequest({
        method: 'POST',
        url: '/track/mbook',
        data: body
    });
}
export interface OrderEvents{
    enabled: string;
}
export const postTrackOrders = async (body: OrderEvents) => {
    console.log("Posting track order events...");
    return apiRequest({
        method: 'POST',
        url: '/track/orders',
        data: body
    });
}

export const getQuote = async (symbol: string) => {
    console.log(`Fetching quote for symbol: ${symbol}`);
    return apiRequest({
        method: 'GET',
        url: `/quote?symbol=${encodeURIComponent(symbol)}`,
    });
}
