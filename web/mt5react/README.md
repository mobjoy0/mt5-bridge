# MT5 Bridge — React Testing Dashboard

[![React](https://img.shields.io/badge/React-19.1-blue.svg)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8-blue.svg)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-6.3-646CFF.svg)](https://vitejs.dev/)


A React-based testing and demonstration interface for the MT5 Bridge API. This dashboard provides a visual way to interact with MetaTrader 5 through the Node.js backend and WebSocket server.

> **Note:** This is a reference implementation primarily used for testing and demonstrating the MT5 Bridge functionality.

##  Features

###  Market Data
- **Live Price Streaming** — Real-time price updates via WebSocket connection
- **Price History Charts** — Interactive candlestick charts using Lightweight Charts
- **Symbol Information** — View detailed symbol specifications
- **CSV Export** — Export historical price data to CSV format

###  Account Management
- **Account Overview** — Real-time balance, equity, margin, and profit/loss
- **Position Monitoring** — View all open positions with live P&L updates
- **Order History** — Track past orders and trades

###  Trading Operations
- **Place Orders** — Simple form to open new market/pending orders
- **Close Positions** — One-click position closing from the dashboard
- **Modify Orders** — Update stop loss and take profit levels

###  Connectivity
- **WebSocket Connection** — Direct connection to MT5 EA (port 8890) for live updates
- **REST API Integration** — All operations through the Node.js backend (port 8891)
- **Connection Status** — Visual indicators for connection health

##  Quick Start

### Prerequisites

- Node.js 18+
- MT5 SocketBridgeEA running on port 8890
- Node.js backend running on port 8891

### Installation & Running

```bash
# Navigate to the React app directory
cd mt5-bridge/web/mt5react

# Install dependencies
npm install

# Start development server
npm run dev
```

The app will be available at **http://localhost:8002**

## 🤝 Contributing

This is a testing/demo interface and contributions are especially welcome! Areas for improvement:

- 🎨 **UI/UX Design** — Modernize the interface
- 📱 **Responsive Layout** — Mobile optimization
- 🧪 **Testing** — Add unit and integration tests
- 📊 **Advanced Charts** — More technical indicators


## 🔗 Related Projects

- [MT5 SocketBridgeEA](../../MQL5) — MetaTrader 5 Expert Advisor
- [Node.js Backend](../mt_nodejs) — REST API middleware

---

Made with ❤️ by [mobjoy0](https://github.com/mobjoy0)