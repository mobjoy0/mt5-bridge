const BASE_URL = 'http://localhost:8891/v1'; // your Express server port

export interface Account {
    login: number;
    name: string;
    equity: number;
    balance: number;
}

export interface OrderRequest {
    symbol: string;
    volume: number;
    order_type: "buy" | "sell";
    deviation: number;
    sl?: number;
    tp?: number;
    comment?: string;
}

export interface Order{
    price_open: number;
    ticket: number;
    symbol: string;
    open_time: number;
    volume: number;
    volume_initial: number;
    price_current: number;
    profit: number;

}

export interface OrderResponse {
    message: string;
    ordersCount: number;
    opened: Order[];
    pending: Order[];
}

export interface OrderHistoryResponse {
    message: string;
    orderCount: number;
    from_date: number;
    to_date: number;
    data: Order[];
}


export async function getAccount(): Promise<Account> {
    const res = await fetch(`${BASE_URL}/account`);
    console.log('Fetching account info from:', `${BASE_URL}/account`);
    if (!res.ok) {
        console.error(`Failed to fetch account: ${res.status} ${res.statusText}`);
        const errorData = await res.json();
        throw new Error(errorData.detail);
    }
    return res.json();
}

export async function placeOrder(order: OrderRequest): Promise<void> {
    const res = await fetch(`${BASE_URL}/order`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(order),
    });
    if (!res.ok) {
        const errorData = await res.json();
        console.error(`Failed to place order: ${res.status} ${res.statusText}`, errorData);

        const detail =
            errorData.error?.details ??
            errorData.error?.message ??
            `Unknown error (status: ${res.status})`;

        throw new Error(detail);
    }
}
export async function closeOrder(ticket: number): Promise<void> {
    const res = await fetch(`${BASE_URL}/order/close`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ ticket }),
    });

    if (!res.ok) {
        const errorData = await res.json();
        console.error(`Failed to close order ${ticket}: ${res.status} ${res.statusText}`, errorData);

        const detail =
            errorData.error?.details ??
            errorData.error?.message ??
            `Unknown error (status: ${res.status})`;

        throw new Error(detail);
    }
}

export async function getOrders(): Promise<OrderResponse> {
    const res = await fetch(`${BASE_URL}/order/list`);

    if (!res.ok) {
        let errorMessage = `Failed to fetch orders: ${res.status} ${res.statusText}`;

        const errorData = await res.json();
        errorMessage = errorData?.details || errorMessage;

        console.error(errorMessage);
        throw new Error(errorMessage);
    }

    return res.json();
}


export async function getOrderHistory(fromDate: string, toDate: string): Promise<OrderHistoryResponse> {
    const queryParams = new URLSearchParams({
        mode: "positions",
        from_date: fromDate,
        to_date: toDate,
    });

    const res = await fetch(`${BASE_URL}/history/orders?${queryParams.toString()}`);

    if (!res.ok) {
        let errorMessage = `Failed to fetch order history: ${res.status} ${res.statusText}`;

        const errorData = await res.json();
        errorMessage = errorData?.details || errorMessage;

        console.error(errorMessage);
        throw new Error(errorMessage);
    }

    console.log(`orders:`, res);
    return res.json();
}



export interface Rate {
    time: number;
    open: number;
    high: number;
    low: number;
    close: number;
    volume: number;
    spread: number;
    real_volume: number;
}

export interface HistoricalData {
    symbol: string;
    timeframe: string;
    UTC_offset: number;
    data: Rate[];
}


export async function getHistoricalData(
    symbol: string,
    from_date: string,
    to_date?: string,
    time_frame?: string
): Promise<HistoricalData> {
    const params: Record<string, string> = {
        symbol,
        from_date,
    };

    if (to_date) {
        params.to_date = to_date;
    }

    if (time_frame) {
        params.time_frame = time_frame;
    }

    const query = new URLSearchParams(params);
    console.log('fetching url:', `${BASE_URL}/history/prices?${query.toString()}`);

    const res = await fetch(`${BASE_URL}/history/prices?${query.toString()}`, {
        method: "GET",
        headers: {
            "Content-Type": "application/json",
        }
    });

    if (!res.ok) {
        let errorMessage = '';
        const errorData = await res.json();
        errorMessage = errorData?.details || `Failed to fetch historical data`;
        throw new Error(errorMessage);
    }

    return res.json();
}

export interface Quote {
    symbol: string;
    bid: number;
    ask: number;
    flags: number;
    time: string;
    volume: number;

}

export async function getQuote(symbol: string): Promise<Quote> {
    const res = await fetch(`${BASE_URL}/quote?symbol=${encodeURIComponent(symbol)}`, {
        method: "GET",
        headers: {
            "Content-Type": "application/json",
        }
    });


    if (!res.ok) {
        let errorMessage = '';
        const errorData = await res.json();
        errorMessage = errorData?.details || `Failed to fetch quote for ${symbol}`;
        throw new Error(errorMessage);
    }

    return res.json();
}






