import React, {useEffect, useState} from 'react';
import {AlertCircle, CreditCard, DollarSign, Loader2, RefreshCw, TrendingUp, User} from 'lucide-react';
import {getAccount} from "../api/nodejsApiClient.ts";

interface Account {
    login: number;
    name: string;
    equity: number;
    balance: number;
}

const AccountInfo: React.FC = () => {
    const [account, setAccount] = useState<Account | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const fetchAccount = async () => {
        setLoading(true);
        setError(null);
        try {
            console.log('Fetching account data...');
            const data = await getAccount();
            console.log('Fetched account data:', data);
            setAccount(data);
        } catch (err: unknown) {
            if (err instanceof Error) {
                setError(err.message);
            } else {
                setError('Failed to load account info');
            }
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAccount();
    }, []);

    // Loading State
    if (loading) {
        return (
            <div className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-2xl p-6 text-white shadow-xl border border-slate-700 min-h-[280px] flex items-center justify-center">
                <div className="text-center">
                    <Loader2 className="w-8 h-8 animate-spin mx-auto mb-4 text-blue-400" />
                    <p className="text-slate-300">Loading account info...</p>
                </div>
            </div>
        );
    }

    // Error State
    if (error) {
        return (
            <div className="bg-gradient-to-br from-red-900 to-red-800 rounded-2xl p-6 text-white shadow-xl border border-red-700 min-h-[280px]">
                <div className="flex items-center gap-3 mb-4">
                    <div className="p-2 bg-red-500 rounded-lg">
                        <AlertCircle className="w-5 h-5" />
                    </div>
                    <h2 className="text-xl font-semibold">Account Error</h2>
                </div>

                <div className="bg-red-800/50 rounded-xl p-4 border border-red-600 mb-4">
                    <p className="text-red-200 mb-3">{error}</p>
                    <button
                        onClick={fetchAccount}
                        className="flex items-center gap-2 bg-red-600 hover:bg-red-700 px-4 py-2 rounded-lg transition-colors duration-200 text-sm font-medium"
                    >
                        <RefreshCw className="w-4 h-4" />
                        Retry
                    </button>
                </div>
            </div>
        );
    }

    // Success State
    const profitLoss = account ? account.equity - account.balance : 0;
    const profitLossPercentage = account ? ((profitLoss / account.balance) * 100) : 0;

    return (
        <div className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-2xl p-6 text-white shadow-xl border border-slate-700 relative overflow-hidden">
            {/* Background Pattern */}
            <div className="absolute inset-0 opacity-5">
                <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500 rounded-full -translate-y-16 translate-x-16"></div>
                <div className="absolute bottom-0 left-0 w-24 h-24 bg-purple-500 rounded-full translate-y-12 -translate-x-12"></div>
            </div>

            {/* Header */}
            <div className="flex items-center justify-between mb-6 relative z-10">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-500 rounded-lg">
                        <User className="w-5 h-5" />
                    </div>
                    <h2 className="text-xl font-semibold">Account Info</h2>
                </div>
                <button
                    onClick={fetchAccount}
                    className="p-2 hover:bg-slate-700 rounded-lg transition-colors duration-200"
                    title="Refresh account data"
                >
                    <RefreshCw className="w-4 h-4 text-slate-400 hover:text-white" />
                </button>
            </div>

            {/* Account Details Grid */}
            <div className="grid grid-cols-2 gap-4 relative z-10">
                {/* Login */}
                <div className="bg-slate-800/50 rounded-xl p-4 border border-slate-600">
                    <div className="flex items-center gap-2 mb-2">
                        <CreditCard className="w-4 h-4 text-slate-400" />
                        <span className="text-sm text-slate-400">Login</span>
                    </div>
                    <p className="font-mono text-lg font-medium">{account?.login}</p>
                </div>

                {/* Name */}
                <div className="bg-slate-800/50 rounded-xl p-4 border border-slate-600">
                    <div className="flex items-center gap-2 mb-2">
                        <User className="w-4 h-4 text-slate-400" />
                        <span className="text-sm text-slate-400">Name</span>
                    </div>
                    <p className="font-medium text-lg truncate" title={account?.name}>
                        {account?.name}
                    </p>
                </div>

                {/* Equity */}
                <div className={`rounded-xl p-4 border ${
                    profitLoss >= 0
                        ? 'bg-gradient-to-r from-green-500/20 to-emerald-500/20 border-green-500/30'
                        : 'bg-gradient-to-r from-red-500/20 to-red-500/20 border-red-500/30'
                }`}>
                    <div className="flex items-center gap-2 mb-2">
                        <TrendingUp className={`w-4 h-4 ${profitLoss >= 0 ? 'text-green-400' : 'text-red-400'}`} />
                        <span className={`text-sm ${profitLoss >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                            Equity
                        </span>
                    </div>
                    <p className={`font-bold text-xl ${profitLoss >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                        ${account?.equity.toFixed(2)}
                    </p>
                    {profitLoss !== 0 && (
                        <p className={`text-xs mt-1 ${profitLoss >= 0 ? 'text-green-300' : 'text-red-300'}`}>
                            {profitLoss >= 0 ? '+' : ''}${profitLoss.toFixed(2)} ({profitLossPercentage >= 0 ? '+' : ''}{profitLossPercentage.toFixed(2)}%)
                        </p>
                    )}
                </div>

                {/* Balance */}
                <div className="bg-slate-800/50 rounded-xl p-4 border border-slate-600">
                    <div className="flex items-center gap-2 mb-2">
                        <DollarSign className="w-4 h-4 text-slate-400" />
                        <span className="text-sm text-slate-400">Balance</span>
                    </div>
                    <p className="font-bold text-xl">${account?.balance.toFixed(2)}</p>
                </div>
            </div>

            {/* Account Status Indicator */}
            <div className="mt-4 flex items-center justify-between text-xs text-slate-400 relative z-10">
                <span>Last updated: {new Date().toLocaleTimeString()}</span>
                <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                    <span>Live</span>
                </div>
            </div>
        </div>
    );
};

export default AccountInfo;