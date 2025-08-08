import React, { useEffect, useState } from "react";
import { getOrderHistory, type Order } from "../api/nodejsApiClient.ts"; // adjust import path if needed

const OrderHistory: React.FC = () => {
    const [orders, setOrders] = useState<Order[]>([]);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

    // Date filter states
    const [fromDate, setFromDate] = useState<string>("");
    const [toDate, setToDate] = useState<string>("");

    // Set default dates (last 30 days)
    useEffect(() => {
        const today = new Date();
        const thirtyDaysAgo = new Date(today);
        thirtyDaysAgo.setDate(today.getDate() - 30);

        setToDate(today.toISOString().split('T')[0]);
        setFromDate(thirtyDaysAgo.toISOString().split('T')[0]);
    }, []);

    // Initial fetch - call without date parameters first
    useEffect(() => {
        const fetchHistory = async () => {
            try {
                setLoading(true);
                setError(null);

                const today = new Date();
                const pastDate = new Date();
                pastDate.setDate(today.getDate() - 30);

                const to = today.toISOString().split('T')[0];      // e.g., "2025-07-01"
                const from = pastDate.toISOString().split('T')[0]; // e.g., "2025-06-01"

                const data = await getOrderHistory(from, to);
                setOrders(data.data || []);
            } catch (err: any) {
                console.error("Error fetching order history:", err);
                setError(err.message || "Failed to fetch order history.");
            } finally {
                setLoading(false);
            }
        };

        fetchHistory();
    }, []);


    const handleDateFilter = async () => {
        if (!fromDate || !toDate) return;

        try {
            setLoading(true);
            setError(null);

            // Format dates as YYYY-MM-DD strings instead of ISO
            const fromDateFormatted = fromDate; // Already in YYYY-MM-DD format from input
            const toDateFormatted = toDate;     // Already in YYYY-MM-DD format from input

            // Call your API function with formatted dates
            const data = await getOrderHistory(fromDateFormatted, toDateFormatted);
            setOrders(data.data || []);
        } catch (err: any) {
            console.error("Error fetching filtered history:", err);
            setError(err.message || "Failed to fetch filtered order history.");
        } finally {
            setLoading(false);
        }
    };

    const handleReset = async () => {
        try {
            setLoading(true);
            setError(null);
            // Reset to original call without parameters
            const data = await getOrderHistory("2025-06-01", "2025-06-28");
            setOrders(data.data || []);

            // Reset dates
            const today = new Date();
            const thirtyDaysAgo = new Date(today);
            thirtyDaysAgo.setDate(today.getDate() - 30);

            setToDate(today.toISOString().split('T')[0]);
            setFromDate(thirtyDaysAgo.toISOString().split('T')[0]);
        } catch (err: any) {
            console.error("Error resetting history:", err);
            setError(err.message || "Failed to reset order history.");
        } finally {
            setLoading(false);
        }
    };

    const formatDate = (dateValue: string | number) => {
        try {
            // Handle both timestamp and date string
            const date = typeof dateValue === 'number' ? new Date(dateValue) : new Date(dateValue);

            // Check if date is valid
            if (isNaN(date.getTime())) {
                return "Invalid Date";
            }

            return date.toLocaleString();
        } catch (error) {
            return "Invalid Date";
        }
    };

    if (loading) {
        return (
            <div style={{
                minHeight: '100vh',
                background: 'linear-gradient(135deg, #1e293b 0%, #0f172a 50%, #1e1b4b 100%)',
                padding: '20px',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center'
            }}>
                <div style={{
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    borderRadius: '16px',
                    padding: '40px',
                    color: '#fff',
                    fontSize: '1.2rem',
                    fontWeight: '600',
                    boxShadow: '0 8px 32px rgba(0,0,0,0.3)'
                }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div style={{
                            width: '24px',
                            height: '24px',
                            border: '3px solid rgba(255,255,255,0.3)',
                            borderTop: '3px solid #fff',
                            borderRadius: '50%',
                            animation: 'spin 1s linear infinite'
                        }}></div>
                        Loading order history...
                    </div>
                </div>
                <style>{`
                    @keyframes spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                `}</style>
            </div>
        );
    }

    if (error) {
        return (
            <div style={{
                minHeight: '100vh',
                background: 'linear-gradient(135deg, #1e293b 0%, #0f172a 50%, #1e1b4b 100%)',
                padding: '20px',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center'
            }}>
                <div style={{
                    background: 'linear-gradient(135deg, #ef4444, #dc2626)',
                    color: '#fff',
                    padding: '30px',
                    borderRadius: '16px',
                    boxShadow: '0 8px 32px rgba(239, 68, 68, 0.3)',
                    textAlign: 'center',
                    maxWidth: '500px'
                }}>
                    <div style={{ fontSize: '2rem', marginBottom: '16px' }}>⚠️</div>
                    <h3 style={{ margin: '0 0 12px 0', fontSize: '1.4rem', fontWeight: '700' }}>Error</h3>
                    <p style={{ margin: '0', fontSize: '1.1rem' }}>{error}</p>
                </div>
            </div>
        );
    }

    return (
        <div style={{
            minHeight: '100vh',
            background: 'linear-gradient(135deg, #1e293b 0%, #0f172a 50%, #1e1b4b 100%)',
            padding: '20px'
        }}>
            <style>{`
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
                @keyframes glow {
                    0%, 100% { box-shadow: 0 0 20px rgba(59, 130, 246, 0.5); }
                    50% { box-shadow: 0 0 40px rgba(59, 130, 246, 0.8); }
                }
                @keyframes float {
                    0%, 100% { transform: translateY(0px); }
                    50% { transform: translateY(-5px); }
                }
            `}</style>

            <div style={{ maxWidth: '1400px', margin: '0 auto' }}>
                {/* Header */}
                <div style={{
                    padding: '30px',
                    background: 'linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)',
                    backdropFilter: 'blur(20px)',
                    borderRadius: '20px',
                    border: '1px solid rgba(255,255,255,0.1)',
                    boxShadow: '0 8px 32px rgba(0,0,0,0.3)',
                    marginBottom: '30px'
                }}>
                    <h1 style={{
                        color: '#fff',
                        margin: '0',
                        fontSize: '2.5rem',
                        fontWeight: '800',
                        background: 'linear-gradient(135deg, #3b82f6, #8b5cf6, #ec4899)',
                        WebkitBackgroundClip: 'text',
                        WebkitTextFillColor: 'transparent',
                        backgroundClip: 'text'
                    }}>
                        📊 Order History
                    </h1>
                </div>

                {/* Date Filter Section */}
                <div style={{
                    background: 'linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)',
                    backdropFilter: 'blur(10px)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '20px',
                    padding: '30px',
                    marginBottom: '30px',
                    boxShadow: '0 8px 32px rgba(0,0,0,0.2)'
                }}>
                    <h3 style={{
                        color: '#fff',
                        margin: '0 0 20px 0',
                        fontSize: '1.3rem',
                        fontWeight: '600'
                    }}>
                        🗓️ Filter by Date Range
                    </h3>

                    <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'end', gap: '20px' }}>
                        <div>
                            <label style={{
                                display: 'block',
                                fontSize: '0.9rem',
                                fontWeight: '600',
                                color: 'rgba(255,255,255,0.8)',
                                marginBottom: '8px',
                                textTransform: 'uppercase',
                                letterSpacing: '0.5px'
                            }}>
                                From Date
                            </label>
                            <input
                                type="date"
                                value={fromDate}
                                onChange={(e) => setFromDate(e.target.value)}
                                style={{
                                    background: 'rgba(255,255,255,0.1)',
                                    border: '1px solid rgba(255,255,255,0.2)',
                                    borderRadius: '12px',
                                    padding: '12px 16px',
                                    fontSize: '1rem',
                                    color: '#fff',
                                    outline: 'none',
                                    transition: 'all 0.3s ease',
                                    backdropFilter: 'blur(10px)'
                                }}
                                onFocus={(e) => {
                                    e.target.style.border = '1px solid rgba(59, 130, 246, 0.5)';
                                    e.target.style.boxShadow = '0 0 20px rgba(59, 130, 246, 0.3)';
                                }}
                                onBlur={(e) => {
                                    e.target.style.border = '1px solid rgba(255,255,255,0.2)';
                                    e.target.style.boxShadow = 'none';
                                }}
                            />
                        </div>

                        <div>
                            <label style={{
                                display: 'block',
                                fontSize: '0.9rem',
                                fontWeight: '600',
                                color: 'rgba(255,255,255,0.8)',
                                marginBottom: '8px',
                                textTransform: 'uppercase',
                                letterSpacing: '0.5px'
                            }}>
                                To Date
                            </label>
                            <input
                                type="date"
                                value={toDate}
                                onChange={(e) => setToDate(e.target.value)}
                                style={{
                                    background: 'rgba(255,255,255,0.1)',
                                    border: '1px solid rgba(255,255,255,0.2)',
                                    borderRadius: '12px',
                                    padding: '12px 16px',
                                    fontSize: '1rem',
                                    color: '#fff',
                                    outline: 'none',
                                    transition: 'all 0.3s ease',
                                    backdropFilter: 'blur(10px)'
                                }}
                                onFocus={(e) => {
                                    e.target.style.border = '1px solid rgba(59, 130, 246, 0.5)';
                                    e.target.style.boxShadow = '0 0 20px rgba(59, 130, 246, 0.3)';
                                }}
                                onBlur={(e) => {
                                    e.target.style.border = '1px solid rgba(255,255,255,0.2)';
                                    e.target.style.boxShadow = 'none';
                                }}
                            />
                        </div>

                        <div style={{ display: 'flex', gap: '12px' }}>
                            <button
                                onClick={handleDateFilter}
                                disabled={!fromDate || !toDate || loading}
                                style={{
                                    background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                                    color: 'white',
                                    padding: '12px 24px',
                                    borderRadius: '12px',
                                    fontSize: '1rem',
                                    fontWeight: '600',
                                    border: 'none',
                                    cursor: loading ? 'not-allowed' : 'pointer',
                                    transition: 'all 0.3s ease',
                                    boxShadow: '0 4px 15px rgba(59, 130, 246, 0.4)',
                                    textTransform: 'uppercase',
                                    letterSpacing: '0.5px',
                                    opacity: (!fromDate || !toDate || loading) ? 0.5 : 1
                                }}
                                onMouseEnter={(e) => {
                                    if (!loading && fromDate && toDate) {
                                        e.currentTarget.style.transform = 'translateY(-2px)';
                                        e.currentTarget.style.boxShadow = '0 6px 20px rgba(59, 130, 246, 0.6)';
                                    }
                                }}
                                onMouseLeave={(e) => {
                                    if (!loading) {
                                        e.currentTarget.style.transform = 'translateY(0)';
                                        e.currentTarget.style.boxShadow = '0 4px 15px rgba(59, 130, 246, 0.4)';
                                    }
                                }}
                            >
                                Apply Filter
                            </button>

                            <button
                                onClick={handleReset}
                                disabled={loading}
                                style={{
                                    background: 'linear-gradient(135deg, #6b7280, #4b5563)',
                                    color: 'white',
                                    padding: '12px 24px',
                                    borderRadius: '12px',
                                    fontSize: '1rem',
                                    fontWeight: '600',
                                    border: 'none',
                                    cursor: loading ? 'not-allowed' : 'pointer',
                                    transition: 'all 0.3s ease',
                                    boxShadow: '0 4px 15px rgba(107, 114, 128, 0.4)',
                                    textTransform: 'uppercase',
                                    letterSpacing: '0.5px',
                                    opacity: loading ? 0.5 : 1
                                }}
                                onMouseEnter={(e) => {
                                    if (!loading) {
                                        e.currentTarget.style.transform = 'translateY(-2px)';
                                        e.currentTarget.style.boxShadow = '0 6px 20px rgba(107, 114, 128, 0.6)';
                                    }
                                }}
                                onMouseLeave={(e) => {
                                    if (!loading) {
                                        e.currentTarget.style.transform = 'translateY(0)';
                                        e.currentTarget.style.boxShadow = '0 4px 15px rgba(107, 114, 128, 0.4)';
                                    }
                                }}
                            >
                                Reset
                            </button>
                        </div>
                    </div>
                </div>

                {/* Results Summary */}
                <div style={{
                    background: 'linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)',
                    backdropFilter: 'blur(10px)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '16px',
                    padding: '20px',
                    marginBottom: '20px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '16px'
                }}>
                    <div style={{
                        background: orders.length === 0
                            ? 'linear-gradient(135deg, #6b7280, #4b5563)'
                            : 'linear-gradient(135deg, #10b981, #059669)',
                        color: 'white',
                        padding: '8px 20px',
                        borderRadius: '20px',
                        fontSize: '1rem',
                        fontWeight: '700',
                        boxShadow: orders.length === 0
                            ? '0 4px 15px rgba(107, 114, 128, 0.3)'
                            : '0 4px 15px rgba(16, 185, 129, 0.3)'
                    }}>
                        {orders.length} {orders.length === 1 ? 'Order' : 'Orders'}
                    </div>
                    <p style={{
                        color: 'rgba(255,255,255,0.8)',
                        margin: '0',
                        fontSize: '1.1rem',
                        fontWeight: '500'
                    }}>
                        {orders.length === 0
                            ? "No orders found for the selected period."
                            : `Found ${orders.length} order${orders.length !== 1 ? 's' : ''} in your trading history`
                        }
                    </p>
                </div>

                {/* Table */}
                {orders.length > 0 && (
                    <div style={{
                        background: 'linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)',
                        backdropFilter: 'blur(10px)',
                        border: '1px solid rgba(255,255,255,0.1)',
                        borderRadius: '20px',
                        padding: '0',
                        overflow: 'hidden',
                        boxShadow: '0 8px 32px rgba(0,0,0,0.2)'
                    }}>
                        <div style={{ overflowX: 'auto' }}>
                            <table style={{
                                width: '100%',
                                minWidth: '800px',
                                borderCollapse: 'collapse'
                            }}>
                                <thead>
                                <tr style={{
                                    background: 'linear-gradient(135deg, rgba(0,0,0,0.3) 0%, rgba(0,0,0,0.2) 100%)'
                                }}>
                                    <th style={{
                                        padding: '20px 16px',
                                        fontSize: '0.9rem',
                                        fontWeight: '700',
                                        color: '#fff',
                                        textAlign: 'left',
                                        textTransform: 'uppercase',
                                        letterSpacing: '1px',
                                        borderBottom: '1px solid rgba(255,255,255,0.1)'
                                    }}>Ticket</th>
                                    <th style={{
                                        padding: '20px 16px',
                                        fontSize: '0.9rem',
                                        fontWeight: '700',
                                        color: '#fff',
                                        textAlign: 'left',
                                        textTransform: 'uppercase',
                                        letterSpacing: '1px',
                                        borderBottom: '1px solid rgba(255,255,255,0.1)'
                                    }}>Symbol</th>
                                    <th style={{
                                        padding: '20px 16px',
                                        fontSize: '0.9rem',
                                        fontWeight: '700',
                                        color: '#fff',
                                        textAlign: 'left',
                                        textTransform: 'uppercase',
                                        letterSpacing: '1px',
                                        borderBottom: '1px solid rgba(255,255,255,0.1)'
                                    }}>Volume</th>
                                    <th style={{
                                        padding: '20px 16px',
                                        fontSize: '0.9rem',
                                        fontWeight: '700',
                                        color: '#fff',
                                        textAlign: 'left',
                                        textTransform: 'uppercase',
                                        letterSpacing: '1px',
                                        borderBottom: '1px solid rgba(255,255,255,0.1)'
                                    }}>Open Price</th>
                                    <th style={{
                                        padding: '20px 16px',
                                        fontSize: '0.9rem',
                                        fontWeight: '700',
                                        color: '#fff',
                                        textAlign: 'left',
                                        textTransform: 'uppercase',
                                        letterSpacing: '1px',
                                        borderBottom: '1px solid rgba(255,255,255,0.1)'
                                    }}>Current Price</th>
                                    <th style={{
                                        padding: '20px 16px',
                                        fontSize: '0.9rem',
                                        fontWeight: '700',
                                        color: '#fff',
                                        textAlign: 'left',
                                        textTransform: 'uppercase',
                                        letterSpacing: '1px',
                                        borderBottom: '1px solid rgba(255,255,255,0.1)'
                                    }}>Time</th>
                                </tr>
                                </thead>
                                <tbody>
                                {orders.map((order, index) => (
                                    <tr
                                        key={order.ticket}
                                        style={{
                                            borderBottom: index < orders.length - 1 ? '1px solid rgba(255,255,255,0.1)' : 'none',
                                            transition: 'all 0.3s ease'
                                        }}
                                        onMouseEnter={(e) => {
                                            e.currentTarget.style.background = 'rgba(255,255,255,0.1)';
                                        }}
                                        onMouseLeave={(e) => {
                                            e.currentTarget.style.background = 'transparent';
                                        }}
                                    >
                                        <td style={{
                                            padding: '16px',
                                            fontSize: '1rem',
                                            color: '#fff',
                                            fontWeight: '600'
                                        }}>#{order.ticket}</td>
                                        <td style={{
                                            padding: '16px',
                                            fontSize: '1.1rem',
                                            color: '#fff',
                                            fontWeight: '700'
                                        }}>{order.symbol}</td>
                                        <td style={{
                                            padding: '16px',
                                            fontSize: '1rem',
                                            color: 'rgba(255,255,255,0.8)',
                                            fontWeight: '500'
                                        }}>{order.volume}</td>
                                        <td style={{
                                            padding: '16px',
                                            fontSize: '1rem',
                                            color: 'rgba(255,255,255,0.8)',
                                            fontWeight: '600'
                                        }}>
                                            {order.open_price !== undefined ? order.open_price.toFixed(5) : "0.00000"}
                                        </td>
                                        <td style={{
                                            padding: '16px',
                                            fontSize: '1rem',
                                            color: '#10b981',
                                            fontWeight: '600'
                                        }}>
                                            {order.price_current !== undefined ? order.price_current.toFixed(5) : "0.00000"}
                                        </td>
                                        <td style={{
                                            padding: '16px',
                                            fontSize: '0.95rem',
                                            color: 'rgba(255,255,255,0.7)',
                                            fontWeight: '500',
                                            whiteSpace: 'nowrap'
                                        }}>
                                            {formatDate(order.open_time * 1000)}
                                        </td>
                                    </tr>
                                ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}

                {/* Empty State */}
                {orders.length === 0 && (
                    <div style={{
                        background: 'linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)',
                        backdropFilter: 'blur(10px)',
                        border: '1px solid rgba(255,255,255,0.1)',
                        borderRadius: '20px',
                        padding: '60px 40px',
                        textAlign: 'center',
                        color: 'rgba(255,255,255,0.6)',
                        fontSize: '1.2rem',
                        fontWeight: '500',
                        animation: 'float 3s ease-in-out infinite'
                    }}>
                        <div style={{ fontSize: '4rem', marginBottom: '20px' }}>📊</div>
                        <h3 style={{ margin: '0 0 12px 0', color: '#fff', fontSize: '1.5rem' }}>No Orders Found</h3>
                        <p style={{ margin: '0', maxWidth: '400px', marginLeft: 'auto', marginRight: 'auto' }}>
                            No trading orders were found for the selected date range. Try adjusting your date filters or check back later.
                        </p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default OrderHistory;