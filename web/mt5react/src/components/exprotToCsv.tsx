import { CSVLink } from 'react-csv';

interface CandlePoints {
    x: number; // timestamp in ms or s (assumed)
    y: [number, number, number, number];
}

interface CsvExporterProps {
    data: CandlePoints[];
    filename?: string;
    symbol?: string;
    timeframe?: string;
    fromDate?: string;
    toDate?: string;
    UTC_offset?: number; // hours offset, can be positive or negative, optional
}

export function CsvExporter({
                                data,
                                filename,
                                symbol,
                                timeframe,
                                fromDate,
                                toDate,
                                UTC_offset = 0,
                            }: CsvExporterProps) {
    const csvData = data.map(point => {
        const tsMillis = point.x > 1e12 ? point.x : point.x * 1000;

        const adjustedDate = new Date(tsMillis + UTC_offset * 3600 * 1000);

        return {
            Date: adjustedDate.toISOString(),
            Open: point.y[0],
            High: point.y[1],
            Low: point.y[2],
            Close: point.y[3],
        };
    });

    const csvHeaders = [
        { label: 'Date', key: 'Date' },
        { label: 'Open', key: 'Open' },
        { label: 'High', key: 'High' },
        { label: 'Low', key: 'Low' },
        { label: 'Close', key: 'Close' },
    ];

    const defaultFilename = `${symbol || 'chart'}_${timeframe || 'tf'}_${fromDate || 'start'}_to_${toDate || 'end'}.csv`;

    return (
        <CSVLink
            data={csvData}
            headers={csvHeaders}
            filename={filename || defaultFilename}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition cursor-pointer"
        >
            Export to CSV
        </CSVLink>
    );
}
