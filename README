# MT5 Bridge

[![MT5](https://img.shields.io/badge/MetaTrader-5-blue.svg)](https://www.metatrader5.com/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![React](https://img.shields.io/badge/React-19.1-blue.svg)](https://reactjs.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A complete bridge system that connects MetaTrader 5 to modern web applications through REST APIs and WebSocket streaming. Built with MQL5, Node.js, and React.

## 🎯 Overview

MT5 Bridge enables external applications to interact with MetaTrader 5 in real-time by exposing trading and market data through a multi-layer architecture:

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   React     │  HTTP   │   Node.js   │  HTTP   │   MT5 EA    │
│  Dashboard  │───────▶│   Backend    │───────▶│SocketBridge │
│ (Port 8002) │  :8891  │ (Port 8891) │  :8890  │ (Port 8890) │
└─────────────┘         └─────────────┘         └─────────────┘
      │                                                 │
      │                                                 │
      └─────────────── WebSocket ───────────────────────┘
                      (Direct Connection)
```

## ✨ Key Features

- **🔌 Real-Time Streaming** — WebSocket connection for live price updates
- **🌐 REST API** — Complete HTTP API for trading and account management
- **📊 Market Data** — Access to prices, quotes, and symbol information
- **💰 Account Management** — Real-time balance, equity, and margin data
- **📈 Order Management** — Place, modify, and close orders programmatically
- **📉 Price History** — Historical data with interactive charts
- **📤 CSV Export** — Export market data for analysis
- **🔒 Lightweight** — No external dependencies, runs entirely within MT5

##  Architecture

The project consists of four main components:

### 1. **MetaTrader 5 Expert Advisor** → [📖 Documentation](MQL5/README.md)
An embedded HTTP and WebSocket server that runs inside the MT5 terminal, exposing trading and market data through REST API (port 8890) and WebSocket connections.

### 2. **Node.js Backend** → [📖 Documentation](web/mt_nodejs/README.md)
A TypeScript-based middleware that proxies requests between the frontend and MT5 EA, providing Swagger documentation and error handling (port 8891).

### 3. **React Dashboard** → [📖 Documentation](web/mt5react/README.md)
A testing and demonstration interface with live charts, account monitoring, order management, and CSV export capabilities.

### 4. **MT5 Docker Container** → [📖 Documentation](mt5-container/README.md)
A Dockerized Debian XFCE environment with VNC/NoVNC access, pre-configured with Wine and MetaTrader 5. Access the desktop via browser at `http://localhost:6080`.

##  Quick Start

### Prerequisites

- MetaTrader 5 terminal (build 3000+)
- Node.js 18+ or Docker
- npm or yarn

### Option 1: Manual Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mobjoy0/mt5-bridge.git
   cd mt5-bridge
   ```

2. **Setup MT5 Expert Advisor**
   ```bash
   # Copy files to MT5 data folder
   # MQL5/Experts/SocketBridge/
   # MQL5/Include/SocketBridge/
   
   # Compile in MetaEditor and attach to any chart
   # Enable AutoTrading in MT5
   ```

3. **Setup Node.js Backend**
   ```bash
   cd web/mt_nodejs
   npm install
   npm run dev
   ```

4. **Setup React Dashboard**
   ```bash
   cd web/mt5react
   npm install
   npm run dev
   ```

5. **Access the Dashboard**
   ```
   http://localhost:8002
   ```

### Option 2: Docker

```bash
# Build and run with Docker Compose
docker-compose up -d

# Access the services
# Node.js Backend: http://localhost:8891
# React Dashboard: http://localhost:8002
# MetaTrader 5 (VNC / NoVNC): http://localhost:6080
```
>After the MT5 container is running, please refer to [Documentation](mt5-container/README.md) for instructions on installing and setting up MetaTrader 5 inside the container.

##  Documentation

Detailed documentation for each component:

- **[MQL5 Expert Advisor](MQL5/README.md)** — Setup, REST endpoints, WebSocket protocol
- **[Node.js Backend](web/mt_nodejs/README.md)** — Installation, configuration, Swagger API docs
- **[React Dashboard](web/mt5react/README.md)** — Features and usage
- **[MT5 Docker Container](mt5-container/README.md)** — VNC setup, Wine configuration, first-time installation

**Interactive API Documentation:** `http://localhost:8891/api-docs` (when running)

##  API Overview

The bridge provides REST API and WebSocket streaming for MT5 integration.

**REST Base URL:** `http://localhost:8891/api/v1`  
**WebSocket URL:** `ws://localhost:8890`

For complete API reference, see the [MQL5 EA Documentation](MQL5/README.md) or access the Swagger UI at `http://localhost:8891/api-docs`.

## 💡 Use Cases

- **Algorithmic Trading Bots** — Execute automated strategies from external systems
- **Custom Trading Dashboards** — Build web-based interfaces for MT5
- **Risk Management Tools** — Monitor positions and account metrics in real-time
- **Trade Analytics** — Export and analyze trading data
- **Mobile Trading Apps** — Connect mobile apps to MT5 via the API
- **Trading Signal Distribution** — Broadcast trades to multiple accounts

##  Technology Stack

| Component | Technologies |
|-----------|--------------|
| **MT5 EA** | MQL5 |
| **Backend** | Node.js, TypeScript, Express, Swagger |
| **Frontend** | React, TypeScript, Vite, Lightweight Charts, ApexCharts |
| **Communication** | REST API, WebSocket (RFC 6455) |

## 🤝 Contributing

Contributions are welcome! Here are some areas where you can help:

- 🎨 **UI/UX Improvements** — Enhance the React dashboard
- 📱 **Mobile Support** — Responsive design and mobile app
- 🧪 **Testing** — Unit and integration tests
- 📊 **Advanced Features** — Technical indicators, backtesting, etc.
- 🌐 **Internationalization** — Multi-language support
- 📖 **Documentation** — Improve guides and examples

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🔒 Security

- Never expose your MT5 EA ports (8890, 8891) to the public internet without proper authentication
- Use this system on demo accounts for testing before live trading
- Always implement proper risk management

## ⚠️ Disclaimer

This software is provided for educational and development purposes. Use at your own risk. Always test thoroughly on a demo account before deploying to live trading environments. Trading involves substantial risk of loss.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Star History

If you find this project useful, please consider giving it a ⭐ on GitHub!


---

**Made with ❤️ for the trading community**