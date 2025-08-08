import { useEffect, useState } from "react";
import { getOrders, type OrderResponse, type Order } from "../api/nodejsApiClient";
import { closeOrder } from "../api/nodejsApiClient";
import { toast } from "react-toastify";

export function OrdersList() {
    const [ordersData, setOrdersData] = useState<OrderResponse | null>(null);
    const [loading, setLoading] = useState(true);
    const [closingOrders, setClosingOrders] = useState<Set<number>>(new Set());

    async function fetchOrders() {
        try {
            setLoading(true);
            const data = await getOrders();
            setOrdersData(data);
        } catch (error) {
            if (error instanceof Error) {
                toast.error(error.message);
            } else {
                toast.error("Unknown error");
            }
        } finally {
            setLoading(false);
        }
    }

    async function handleCloseOrder(ticket: number) {
        try {
            setClosingOrders(prev => new Set([...prev, ticket]));
            await closeOrder(ticket);
            toast.success(`Order ${ticket} closed successfully`);
            // Refresh orders after closing
            await fetchOrders();
        } catch (error) {
            if (error instanceof Error) {
                toast.error(`Failed to close order ${ticket}: ${error.message}`);
            } else {
                toast.error(`Failed to close order ${ticket}: Unknown error`);
            }
        } finally {
            setClosingOrders(prev => {
                const newSet = new Set(prev);
                newSet.delete(ticket);
                return newSet;
            });
        }
    }

    useEffect(() => {
        fetchOrders();
    }, []);

    if (loading) return <p>Loading orders...</p>;
    if (!ordersData) return null;

    const renderOrder = (order: Order) => {
        const date = new Date(order.open_time);
        const formattedDate = date.toLocaleString();
        const isProfitable = order.profit >= 0;
        const isClosing = closingOrders.has(order.ticket);

        return (
            <div
                key={order.ticket}
                style={{
                    backgroundColor: '#1a1a1a',
                    border: '1px solid #333',
                    borderRadius: '8px',
                    padding: '16px',
                    marginBottom: '12px',
                    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                }}
            >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
                    <div>
                        <h4 style={{ margin: '0 0 4px 0', color: '#fff', fontSize: '1.1rem' }}>
                            {order.symbol}
                        </h4>
                        <p style={{ margin: '0', color: '#888', fontSize: '0.85rem' }}>
                            Ticket: {order.ticket}
                        </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px' }}>
                        <div style={{ textAlign: 'right' }}>
                            <div
                                style={{
                                    color: isProfitable ? '#4ade80' : '#ef4444',
                                    fontSize: '1.2rem',
                                    fontWeight: 'bold',
                                    margin: '0',
                                }}
                            >
                                {isProfitable ? '+' : ''}{order.profit.toFixed(2)}
                            </div>
                            <p style={{ margin: '4px 0 0 0', color: '#888', fontSize: '0.8rem' }}>
                                Profit
                            </p>
                        </div>
                        <button
                            onClick={() => handleCloseOrder(order.ticket)}
                            disabled={isClosing}
                            style={{
                                padding: '6px 12px',
                                fontSize: '0.85rem',
                                cursor: isClosing ? 'not-allowed' : 'pointer',
                                borderRadius: '4px',
                                border: 'none',
                                backgroundColor: '#dc2626',
                                color: 'white',
                                opacity: isClosing ? 0.6 : 1,
                                transition: 'all 0.2s ease',
                                minWidth: '60px',
                            }}
                        >
                            {isClosing ? '...' : 'Close'}
                        </button>
                    </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(120px, 1fr))', gap: '12px' }}>
                    <div>
                        <p style={{ margin: '0 0 2px 0', color: '#888', fontSize: '0.8rem' }}>Volume</p>
                        <p style={{ margin: '0', color: '#fff', fontWeight: '500' }}>{order.volume}</p>
                    </div>
                    <div>
                        <p style={{ margin: '0 0 2px 0', color: '#888', fontSize: '0.8rem' }}>Open Price</p>
                        <p style={{ margin: '0', color: '#fff', fontWeight: '500' }}>{order.price_open}</p>
                    </div>
                    <div>
                        <p style={{ margin: '0 0 2px 0', color: '#888', fontSize: '0.8rem' }}>Current Price</p>
                        <p style={{ margin: '0', color: '#fff', fontWeight: '500' }}>{order.price_current.toFixed(5)}</p>
                    </div>
                    <div>
                        <p style={{ margin: '0 0 2px 0', color: '#888', fontSize: '0.8rem' }}>Time</p>
                        <p style={{ margin: '0', color: '#fff', fontWeight: '500', fontSize: '0.85rem' }}>{formattedDate}</p>
                    </div>
                </div>
            </div>
        );
    };

    return (
        <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
                <h2 style={{ color: '#fff', margin: '0' }}>Orders ({ordersData.ordersCount})</h2>
                <button
                    onClick={fetchOrders}
                    disabled={loading}
                    style={{
                        padding: '10px 20px',
                        fontSize: '1rem',
                        cursor: loading ? 'not-allowed' : 'pointer',
                        borderRadius: '6px',
                        border: 'none',
                        backgroundColor: '#007bff',
                        color: 'white',
                        opacity: loading ? 0.6 : 1,
                        transition: 'all 0.2s ease',
                    }}
                >
                    {loading ? 'Refreshing...' : 'Refresh'}
                </button>
            </div>

            <div style={{ marginBottom: '32px' }}>
                <h3 style={{ color: '#fff', marginBottom: '16px' }}>Opened Positions</h3>
                {ordersData.opened.length === 0 ? (
                    <div
                        style={{
                            backgroundColor: '#1a1a1a',
                            border: '1px solid #333',
                            borderRadius: '8px',
                            padding: '20px',
                            textAlign: 'center',
                            color: '#888',
                        }}
                    >
                        No opened positions.
                    </div>
                ) : (
                    <div>{ordersData.opened.map(renderOrder)}</div>
                )}
            </div>

            <div>
                <h3 style={{ color: '#fff', marginBottom: '16px' }}>Pending Orders</h3>
                {ordersData.pending.length === 0 ? (
                    <div
                        style={{
                            backgroundColor: '#1a1a1a',
                            border: '1px solid #333',
                            borderRadius: '8px',
                            padding: '20px',
                            textAlign: 'center',
                            color: '#888',
                        }}
                    >
                        No pending orders.
                    </div>
                ) : (
                    <div>{ordersData.pending.map(renderOrder)}</div>
                )}
            </div>
        </div>
    );
}