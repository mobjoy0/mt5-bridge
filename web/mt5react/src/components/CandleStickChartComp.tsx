import { useEffect, useState } from 'react';
import ApexChart from 'react-apexcharts';
import { getHistoricalData } from '../api/nodejsApiClient.ts';
import {CsvExporter} from "./exprotToCsv.tsx";

export interface CandlePoint {
    x: number; // Changed from Date to number (timestamp)
    y: [number, number, number, number];
}

const TIMEFRAMES = [
    { value: 'M1', label: '1 Minute' },
    { value: 'M5', label: '5 Minutes' },
    { value: 'M15', label: '15 Minutes' },
    { value: 'H1', label: '1 Hour' },
    { value: 'H4', label: '4 Hours' },
    { value: 'D1', label: '1 Day' }
];

// Function to check if a date is a weekend
const isWeekend = (date: Date): boolean => {
    const day = date.getDay();
    return day === 0 || day === 6; // Sunday = 0, Saturday = 6
};

// Function to filter out weekend data and create continuous timestamps
const filterWeekendData = (data: CandlePoint[]): CandlePoint[] => {
    const filteredData: CandlePoint[] = [];
    let continuousIndex = 0;

    for (let i = 0; i < data.length; i++) {
        const date = new Date(data[i].x);

        // Skip weekend data
        if (!isWeekend(date)) {
            filteredData.push({
                x: continuousIndex, // Use continuous index instead of actual timestamp
                y: data[i].y
            });
            continuousIndex++;
        }
    }

    return filteredData;
};

// Function to create custom labels for x-axis
const createCustomLabels = (originalData: CandlePoint[]): string[] => {
    const labels: string[] = [];
    let filteredIndex = 0;

    for (let i = 0; i < originalData.length; i++) {
        const date = new Date(originalData[i].x);

        if (!isWeekend(date)) {
            labels.push(date.toLocaleDateString());
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            filteredIndex++;
        }
    }

    return labels;
};

export function CandleChart() {
    const [seriesData, setSeriesData] = useState<CandlePoint[]>([]);
    const [originalData, setOriginalData] = useState<CandlePoint[]>([]);
    const [customLabels, setCustomLabels] = useState<string[]>([]);
    const [timeframe, setTimeframe] = useState('H4');
    const [fromDate, setFromDate] = useState('2025-06-05');
    const [symbol, setSymbol] = useState('EURUSD');
    const [isLoading, setIsLoading] = useState(false);
    const [toast, setToast] = useState<{ message: string; type: 'error' | 'success' } | null>(null);
    const [toDate, setToDate] = useState(new Date().toISOString().split('T')[0]);

    const showToast = (message: string, type: 'error' | 'success') => {
        setToast({ message, type });
        setTimeout(() => setToast(null), 5000);
    };

    const fetchData = async (tf: string, from: string, to: string, sym: string) => {
        setIsLoading(true);
        try {
            console.log("too is:" , to)
            const res = await getHistoricalData(sym, from, to, tf);
            console.log("data:", res.UTC_offset);

            const transformed: CandlePoint[] = res.data.map((item: any) => ({
                x: new Date(item.time).getTime(), // Convert ISO string to ms timestamp
                y: [item.open, item.high, item.low, item.close],
            }));

            setOriginalData(transformed);

            const filtered = filterWeekendData(transformed);
            const labels = createCustomLabels(transformed);
            setSeriesData(filtered);
            setCustomLabels(labels);
            showToast(`Successfully loaded ${filtered.length} weekday data points for ${sym}`, 'success');
        } catch (error: any) {
            const msg = error?.message ?? 'Failed to fetch data';
            showToast(msg, 'error');
            setSeriesData([]);
            setOriginalData([]);
            setCustomLabels([]);
        } finally {
            setIsLoading(false);
        }
    };



    useEffect(() => {
        fetchData(timeframe, fromDate, toDate, symbol);
    }, [timeframe, fromDate, toDate, symbol]);

    const options: ApexCharts.ApexOptions = {
        chart: {
            type: 'candlestick',
            height: 500,
            background: 'transparent',
            toolbar: {
                show: true,
                tools: {
                    download: false,
                    selection: true,
                    zoom: true,
                    zoomin: true,
                    zoomout: true,
                    pan: true,
                    reset: true
                }
            },
            animations: {
                enabled: true,
                speed: 800,
                animateGradually: {
                    enabled: true,
                    delay: 150
                },
                dynamicAnimation: {
                    enabled: true,
                    speed: 350
                }
            }
        },
        theme: {
            mode: 'light'
        },
        title: {
            text: `${symbol} Price Chart`,
            align: 'left',
            style: {
                fontSize: '20px',
                fontWeight: '600',
                color: '#1f2937'
            }
        },
        subtitle: {
            text: `${TIMEFRAMES.find(tf => tf.value === timeframe)?.label} intervals from ${fromDate}`,
            align: 'left',
            style: {
                fontSize: '14px',
                color: '#6b7280'
            }
        },
        xaxis: {
            type: 'category',
            categories: customLabels,
            labels: {
                datetimeUTC: false,
                style: {
                    colors: '#6b7280',
                    fontSize: '12px'
                },
                rotate: -45,
                rotateAlways: true
            },
            axisBorder: {
                show: true,
                color: '#e5e7eb'
            },
            axisTicks: {
                show: true,
                color: '#e5e7eb'
            }
        },
        yaxis: {
            tooltip: { enabled: true },
            labels: {
                style: {
                    colors: '#6b7280',
                    fontSize: '12px'
                },
                formatter: (value: number) => value.toFixed(5)
            }
        },
        grid: {
            borderColor: '#f3f4f6',
            strokeDashArray: 3
        },
        plotOptions: {
            candlestick: {
                colors: {
                    upward: '#10b981',
                    downward: '#ef4444'
                },
                wick: {
                    useFillColor: true
                }
            }
        },
        tooltip: {
            theme: 'light',
            style: {
                fontSize: '12px'
            },
            custom: ({ seriesIndex, dataPointIndex, w }) => {
                const data = w.globals.initialSeries[seriesIndex].data[dataPointIndex];
                const label = customLabels[dataPointIndex] || 'N/A';
                return `
                    <div class="p-3 bg-white border rounded shadow-lg">
                        <div class="font-semibold mb-2">${label}</div>
                        <div class="text-sm">
                            <div>Open: ${data.y[0].toFixed(5)}</div>
                            <div>High: ${data.y[1].toFixed(5)}</div>
                            <div>Low: ${data.y[2].toFixed(5)}</div>
                            <div>Close: ${data.y[3].toFixed(5)}</div>
                        </div>
                    </div>
                `;
            }
        }
    };

    return (
        <div className="bg-white rounded-xl shadow-lg p-6 border border-gray-100">
            <div className="mb-6">
                <h2 className="text-2xl font-bold text-gray-900 mb-2">{symbol} Trading Chart</h2>
            </div>

            <div className="flex flex-wrap gap-4 mb-6 p-4 bg-gray-50 rounded-lg border">
                <div className="flex flex-col">
                    <label htmlFor="fromDate" className="text-sm font-medium text-gray-700 mb-2">From Date</label>
                    <input
                        id="fromDate"
                        type="date"
                        value={fromDate}
                        onChange={(e) => setFromDate(e.target.value)}
                        max={new Date().toISOString().split('T')[0]}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white shadow-sm text-gray-900"
                        style={{color: '#111827'}}
                    />
                </div>

                <div className="flex flex-col">
                    <label htmlFor="toDate" className="text-sm font-medium text-gray-700 mb-2">To Date</label>
                    <input
                        id="toDate"
                        type="date"
                        value={toDate}
                        onChange={(e) => setToDate(e.target.value)}
                        min={fromDate}
                        max={new Date().toISOString().split('T')[0]}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white shadow-sm text-gray-900"
                        style={{color: '#111827'}}
                    />
                </div>

                <div className="flex flex-col">
                    <label htmlFor="symbol" className="text-sm font-medium text-gray-700 mb-2">Symbol</label>
                    <input
                        id="symbol"
                        type="text"
                        value={symbol}
                        onChange={(e) => setSymbol(e.target.value.toUpperCase())}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white shadow-sm text-gray-900"
                        style={{color: '#111827'}}
                        placeholder=""
                    />
                </div>

                <div className="flex flex-col">
                    <label htmlFor="timeframe" className="text-sm font-medium text-gray-700 mb-2">Timeframe</label>
                    <select
                        id="timeframe"
                        value={timeframe}
                        onChange={(e) => setTimeframe(e.target.value)}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white shadow-sm cursor-pointer text-gray-900"
                        style={{color: '#111827'}}
                    >
                        {TIMEFRAMES.map(tf => (
                            <option key={tf.value} value={tf.value}>{tf.label}</option>
                        ))}
                    </select>
                </div>

                <div className="flex flex-col justify-end">
                    <label className="text-sm font-medium text-gray-700 mb-2">Export</label>
                    <CsvExporter
                        data={originalData}
                        symbol={symbol}
                        timeframe={timeframe}
                        fromDate={fromDate}
                        toDate={toDate}
                    />
                </div>

                {isLoading && (
                    <div className="flex items-end">
                        <div className="flex items-center space-x-2 px-3 py-2">
                            <div
                                className="animate-spin rounded-full h-4 w-4 border-2 border-blue-500 border-t-transparent"></div>
                            <span className="text-sm text-gray-600">Loading...</span>
                        </div>
                    </div>
                )}
            </div>

            <div className="relative">
                <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
                    <ApexChart
                        options={options}
                        series={[{name: 'EUR/USD', data: seriesData}]}
                        type="candlestick"
                        height={500}
                    />
                </div>
            </div>

            {toast && (
                <div
                    className={`fixed top-4 right-4 z-50 px-6 py-4 rounded-lg shadow-lg border-l-4 transition-all duration-300 ${
                        toast.type === 'error'
                            ? 'bg-red-50 border-l-red-500 text-red-800'
                            : 'bg-green-50 border-l-green-500 text-green-800'
                    }`}>
                    <div className="flex items-center justify-between">
                        <div className="flex items-center">
                            <div className={`w-5 h-5 mr-3 ${
                                toast.type === 'error' ? 'text-red-500' : 'text-green-500'
                            }`}>
                                {toast.type === 'error' ? (
                                    <svg fill="currentColor" viewBox="0 0 20 20">
                                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                                    </svg>
                                ) : (
                                    <svg fill="currentColor" viewBox="0 0 20 20">
                                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                                    </svg>
                                )}
                            </div>
                            <p className="font-medium">{toast.message}</p>
                        </div>
                        <button onClick={() => setToast(null)} className={`ml-4 ${
                            toast.type === 'error' ? 'text-red-600 hover:text-red-800' : 'text-green-600 hover:text-green-800'
                        }`}>
                            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                            </svg>
                        </button>
                    </div>
                </div>
            )}

            <div className="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4 p-4 bg-gray-50 rounded-lg">
                <div className="text-center">
                    <p className="text-sm text-gray-600">Data Points</p>
                    <p className="text-lg font-semibold text-gray-900">{seriesData.length}</p>
                </div>
                <div className="text-center">
                    <p className="text-sm text-gray-600">Timeframe</p>
                    <p className="text-lg font-semibold text-gray-900">
                        {TIMEFRAMES.find(tf => tf.value === timeframe)?.label}
                    </p>
                </div>
                <div className="text-center">
                    <p className="text-sm text-gray-600">Date Range</p>
                    <p className="text-lg font-semibold text-gray-900">{fromDate} → {toDate}</p>
                </div>
            </div>
        </div>
    );
}