import React, { useState, useEffect } from 'react';
import { TrendingUp, DollarSign, AlertTriangle, Target, Activity } from 'lucide-react';
import {getQuote, placeOrder} from "../api/nodejsApiClient";
import {toast} from "react-toastify";

interface OrderRequest {
    symbol: string;
    volume: number;
    order_type: "buy" | "sell";
    deviation: number;
    sl?: number;
    tp?: number;
    comment?: string;
}

interface Quote {
    symbol: string;
    bid: number;
    ask: number;
    flags: number;
    time: string;
    volume: number;
}

const OrderRequestForm: React.FC = () => {
    const [formData, setFormData] = useState<OrderRequest>({
        symbol: "",
        volume: 0.1,
        order_type: "buy",
        deviation: 5,
        sl: undefined,
        tp: undefined,
        comment: "FastAPI trade",
    });

    const [quote, setQuote] = useState<Quote | null>(null);
    const [loadingQuote, setLoadingQuote] = useState(false);
    const [quoteError, setQuoteError] = useState<string | null>(null);

    // Fetch quote when symbol changes
    useEffect(() => {
        if (formData.symbol.length >= 3) {
            fetchQuote();
        } else {
            setQuote(null);
            setQuoteError(null);
        }
    }, [formData.symbol]);

    const fetchQuote = async () => {
        if (!formData.symbol || formData.symbol.length < 3) return;

        setLoadingQuote(true);
        setQuoteError(null);

        try {
            const quoteData = await getQuote(formData.symbol.toUpperCase());
            setQuote(quoteData);
        } catch (error) {
            setQuoteError(error instanceof Error ? error.message : "Failed to fetch quote");
            setQuote(null);
        } finally {
            setLoadingQuote(false);
        }
    };

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
        const { name, value } = e.target;

        setFormData(prev => ({
            ...prev,
            [name]: name === "volume" || name === "sl" || name === "tp" || name === "deviation"
                ? value === "" ? undefined : parseFloat(value)
                : value,
        }));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            formData.symbol = formData.symbol.toUpperCase()
            console.log("Placing order with data:", formData);
            await placeOrder(formData);
            toast.success("Order placed successfully!");
        } catch (error) {
            if (error instanceof Error) {
                console.error("Error object:", error);
                console.error("error.message:", error.message);
                toast.error(error.message || "Something went wrong");
            } else {
                toast.error("Failed to place order: Unknown error");
            }
        }
    };

    const getCurrentPrice = () => {
        if (!quote) return null;
        return formData.order_type === "buy" ? quote.ask : quote.bid;
    };

    const getSpread = () => {
        if (!quote) return null;
        return quote.ask - quote.bid;
    };

    return (
        <div className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-3xl p-6 shadow-2xl border border-blue-800/30 w-full max-w-4xl backdrop-blur-sm overflow-hidden">
            {/* Header */}
            <div className="flex items-center gap-3 mb-6">
                <div className="p-3 bg-gradient-to-r from-blue-600 to-blue-500 rounded-xl shadow-lg">
                    <TrendingUp className="w-6 h-6 text-white" />
                </div>
                <div>
                    <h2 className="text-2xl font-bold text-white mb-1">Place Trade Order</h2>
                    <p className="text-blue-300 text-xs">Execute your trading strategy</p>
                </div>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6">
                {/* Symbol and Volume Row */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                    <div className="space-y-2">
                        <label className="text-xs font-semibold text-blue-200 flex items-center gap-2">
                            <DollarSign className="w-3 h-3 text-blue-400" />
                            Trading Symbol
                        </label>
                        <input
                            type="text"
                            name="symbol"
                            placeholder="e.g. EURUSD"
                            value={formData.symbol}
                            onChange={handleChange}
                            required
                            minLength={3}
                            className="w-full px-4 py-3 rounded-xl border border-blue-700/50 bg-slate-800/80 backdrop-blur-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 transition-all duration-300 text-white placeholder-slate-400 font-mono uppercase shadow-inner"
                        />
                    </div>

                    <div className="space-y-2">
                        <label className="text-xs font-semibold text-blue-200">Trade Volume</label>
                        <input
                            type="number"
                            name="volume"
                            placeholder="e.g. 0.1"
                            value={formData.volume}
                            onChange={handleChange}
                            step="0.01"
                            min={0.01}
                            required
                            className="w-full px-4 py-3 rounded-xl border border-blue-700/50 bg-slate-800/80 backdrop-blur-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 transition-all duration-300 text-white placeholder-slate-400 shadow-inner"
                        />
                    </div>
                </div>

                {/* Live Price Display */}
                {formData.symbol.length >= 3 && (
                    <div className="bg-gradient-to-r from-emerald-900/30 to-blue-900/30 rounded-xl p-4 border border-emerald-700/30 backdrop-blur-sm">
                        <div className="flex items-center gap-2 mb-3">
                            <div className="p-1 bg-gradient-to-r from-emerald-500 to-blue-500 rounded-lg">
                                <Activity className="w-4 h-4 text-white" />
                            </div>
                            <h3 className="text-lg font-bold text-white">Live Market Price</h3>
                            {loadingQuote && (
                                <div className="w-4 h-4 border-2 border-blue-400 border-t-transparent rounded-full animate-spin"></div>
                            )}
                        </div>

                        {quote && !loadingQuote && (
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                                <div className="text-center">
                                    <p className="text-xs text-blue-300 mb-1">BID</p>
                                    <p className="text-xl font-bold text-red-400 font-mono">{quote.bid.toFixed(5)}</p>
                                </div>
                                <div className="text-center">
                                    <p className="text-xs text-blue-300 mb-1">ASK</p>
                                    <p className="text-xl font-bold text-green-400 font-mono">{quote.ask.toFixed(5)}</p>
                                </div>
                                <div className="text-center">
                                    <p className="text-xs text-blue-300 mb-1">SPREAD</p>
                                    <p className="text-lg font-bold text-yellow-400 font-mono">{getSpread()?.toFixed(5)}</p>
                                </div>
                            </div>
                        )}

                        {quote && !loadingQuote && (
                            <div className="mt-3 p-3 bg-slate-800/50 rounded-lg">
                                <p className="text-xs text-blue-300 mb-1">
                                    {formData.order_type === "buy" ? "Order will execute at ASK price" : "Order will execute at BID price"}
                                </p>
                                <p className="text-sm font-bold text-white font-mono">
                                    Execution Price: {getCurrentPrice()?.toFixed(5)}
                                </p>
                            </div>
                        )}

                        {quoteError && (
                            <div className="text-center py-4">
                                <p className="text-red-400 text-sm">{quoteError}</p>
                                <button
                                    type="button"
                                    onClick={fetchQuote}
                                    className="mt-2 text-xs text-blue-400 hover:text-blue-300 underline"
                                >
                                    Retry
                                </button>
                            </div>
                        )}

                        {loadingQuote && (
                            <div className="text-center py-4">
                                <p className="text-blue-300 text-sm">Loading price data...</p>
                            </div>
                        )}
                    </div>
                )}

                {/* Order Type and Deviation Row */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                    <div className="space-y-2">
                        <label className="text-xs font-semibold text-blue-200">Order Direction</label>
                        <select
                            name="order_type"
                            value={formData.order_type}
                            onChange={handleChange}
                            className="w-full px-4 py-3 rounded-xl border border-blue-700/50 bg-slate-800/80 backdrop-blur-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 transition-all duration-300 text-white shadow-inner"
                        >
                            <option value="buy" className="bg-slate-800">🟢 Long Position (Buy)</option>
                            <option value="sell" className="bg-slate-800">🔴 Short Position (Sell)</option>
                        </select>
                    </div>

                    <div className="space-y-2">
                        <label className="text-xs font-semibold text-blue-200">Slippage Tolerance</label>
                        <input
                            type="number"
                            name="deviation"
                            placeholder="Pips deviation"
                            value={formData.deviation}
                            onChange={handleChange}
                            min={0}
                            step={1}
                            className="w-full px-4 py-3 rounded-xl border border-blue-700/50 bg-slate-800/80 backdrop-blur-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 transition-all duration-300 text-white placeholder-slate-400 shadow-inner"
                        />
                    </div>
                </div>

                {/* Risk Management Section */}
                <div className="bg-gradient-to-r from-blue-900/40 to-slate-900/40 rounded-xl p-4 border border-blue-700/30 backdrop-blur-sm">
                    <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
                        <div className="p-1 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
                            <AlertTriangle className="w-4 h-4 text-white" />
                        </div>
                        Risk Management
                    </h3>
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-xs font-semibold text-blue-200 flex items-center gap-2">
                                <AlertTriangle className="w-3 h-3 text-red-400" />
                                Stop Loss Level
                            </label>
                            <input
                                type="number"
                                name="sl"
                                placeholder="Optional"
                                value={formData.sl ?? ""}
                                onChange={handleChange}
                                step="0.0001"
                                min={0}
                                className="w-full px-4 py-3 rounded-xl border border-red-700/50 bg-slate-800/60 backdrop-blur-sm focus:border-red-500 focus:ring-2 focus:ring-red-500/20 transition-all duration-300 text-white placeholder-slate-400 shadow-inner"
                            />
                        </div>

                        <div className="space-y-2">
                            <label className="text-xs font-semibold text-blue-200 flex items-center gap-2">
                                <Target className="w-3 h-3 text-green-400" />
                                Take Profit Level
                            </label>
                            <input
                                type="number"
                                name="tp"
                                placeholder="Optional"
                                value={formData.tp ?? ""}
                                onChange={handleChange}
                                step="0.0001"
                                min={0}
                                className="w-full px-4 py-3 rounded-xl border border-green-700/50 bg-slate-800/60 backdrop-blur-sm focus:border-green-500 focus:ring-2 focus:ring-green-500/20 transition-all duration-300 text-white placeholder-slate-400 shadow-inner"
                            />
                        </div>
                    </div>
                </div>

                {/* Comment Section */}
                <div className="space-y-2">
                    <label className="text-xs font-semibold text-blue-200">Order Comment</label>
                    <input
                        type="text"
                        name="comment"
                        placeholder="Add a note..."
                        value={formData.comment ?? ""}
                        onChange={handleChange}
                        maxLength={100}
                        className="w-full px-4 py-3 rounded-xl border border-blue-700/50 bg-slate-800/80 backdrop-blur-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 transition-all duration-300 text-white placeholder-slate-400 shadow-inner"
                    />
                </div>

                {/* Submit Button */}
                <div className="pt-4">
                    <button
                        type="submit"
                        className="w-full bg-gradient-to-r from-blue-600 via-blue-700 to-blue-800 hover:from-blue-700 hover:via-blue-800 hover:to-blue-900 text-white font-bold py-4 px-6 rounded-xl transition-all duration-300 transform hover:scale-[1.01] active:scale-[0.99] shadow-xl hover:shadow-blue-500/25 flex items-center justify-center gap-2"
                    >
                        <TrendingUp className="w-5 h-5" />
                        Execute Trade Order
                    </button>
                </div>

                {/* Order Summary */}
                <div className="bg-gradient-to-r from-slate-800/60 to-blue-900/40 rounded-xl p-4 border border-blue-700/30 backdrop-blur-sm">
                    <h4 className="text-sm font-bold text-white mb-3 flex items-center gap-2">
                        <div className="w-2 h-2 bg-blue-400 rounded-full animate-pulse"></div>
                        Order Summary
                    </h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-blue-100 text-sm">
                        <div className="space-y-1">
                            <p className="flex justify-between">
                                <span className="text-blue-300">Symbol:</span>
                                <span className="font-mono font-bold text-white text-xs">{formData.symbol || 'Not specified'}</span>
                            </p>
                            <p className="flex justify-between">
                                <span className="text-blue-300">Volume:</span>
                                <span className="font-bold text-white text-xs">{formData.volume}</span>
                            </p>
                            <p className="flex justify-between">
                                <span className="text-blue-300">Direction:</span>
                                <span className={`font-bold text-xs ${formData.order_type === 'buy' ? 'text-green-400' : 'text-red-400'}`}>
                                    {formData.order_type === 'buy' ? '📈 LONG' : '📉 SHORT'}
                                </span>
                            </p>
                            {quote && (
                                <p className="flex justify-between">
                                    <span className="text-blue-300">Est. Price:</span>
                                    <span className="font-bold text-yellow-400 text-xs font-mono">{getCurrentPrice()?.toFixed(5)}</span>
                                </p>
                            )}
                        </div>
                        <div className="space-y-1">
                            <p className="flex justify-between">
                                <span className="text-blue-300">Slippage:</span>
                                <span className="font-bold text-white text-xs">{formData.deviation} pips</span>
                            </p>
                            {formData.sl && (
                                <p className="flex justify-between">
                                    <span className="text-blue-300">Stop Loss:</span>
                                    <span className="font-bold text-red-400 text-xs">{formData.sl}</span>
                                </p>
                            )}
                            {formData.tp && (
                                <p className="flex justify-between">
                                    <span className="text-blue-300">Take Profit:</span>
                                    <span className="font-bold text-green-400 text-xs">{formData.tp}</span>
                                </p>
                            )}
                        </div>
                    </div>
                </div>
            </form>
        </div>
    );
};

export default OrderRequestForm;