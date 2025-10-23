# SocketBridgeEA — MetaTrader 5 REST & WebSocket Server

[![MT5](https://img.shields.io/badge/MetaTrader-5-blue.svg)](https://www.metatrader5.com/)
[![MQL5](https://img.shields.io/badge/MQL5-Expert%20Advisor-green.svg)](https://www.mql5.com/)

A production-ready Expert Advisor that embeds an HTTP REST API and WebSocket server directly inside MetaTrader 5, enabling real-time market data streaming and account management for external applications.

##  Features

- **RESTful API** — Query account info, positions, orders, and symbol data
- **WebSocket Streaming** — Subscribe to real-time price updates with low latency
- **Subscription-Based** — Efficient data transmission only for tracked symbols
- **Zero Dependencies** — Self-contained MQL5 implementation with no external libraries
- **Production Ready** — Built-in error handling and connection management

##  Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [API Reference](#-api-reference)
  - [REST Endpoints](#rest-endpoints)
  - [WebSocket Protocol](#websocket-protocol)
- [Usage Examples](#-usage-examples)
- [Architecture](#-architecture)
- [Contributing](#-contributing)

##  Installation

### Prerequisites

- MetaTrader 5 terminal
- MetaEditor for compilation
- Active trading account or demo account

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/mobjoy0/mt5-bridge.git
   cd mt5-bridge
   ```

2. **Copy files to MT5 data folder**
   ```
   MQL5/
   ├── Experts/
   │   └── SocketBridge/
   │       └── SocketBridgeEA.mq5
   └── Include/
       └── SocketBridge/
           ├── HttpServer.mqh
           ├── WebSocketServer.mqh
           └── ... (other includes)
   ```

3. **Compile the EA**
   - Open `SocketBridgeEA.mq5` in MetaEditor
   - Press F7 or click Compile
   - Verify no compilation errors

4. **Attach to chart**
   - Open any chart in MT5
   - Drag `SocketBridgeEA` from Navigator → Expert Advisors
   - Allow DLL imports
   - Enable **AutoTrading** 
   - Verify connection in Experts tab: `WebSocket server initialized on port 8890`


##  Quick Start

### REST API Request Example

```bash
# Get current quote for EURUSD
curl http://localhost:8890/v1/quote?symbol=EURUSD

# Response
{
    "symbol": "EURUSD",
    "ask": 1.15728,
    "bid": 1.15710,
    "flags": 1028,
    "time": "2025.08.06T01:32:08.111Z",
    "volume": 0
}
```

### WebSocket Subscription Example

```javascript
const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:8890');

ws.on('open', () => {
  // Subscribe to price updates
  ws.send(JSON.stringify({
    endpoint: '/v1/track/prices',
    symbols: ['EURUSD', 'GBPUSD', 'USDJPY']
  }));
});

ws.on('message', (data) => {
  const update = JSON.parse(data);
  console.log('Price update:', update);
  // { symbol: 'EURUSD', bid: 1.08542, ask: 1.08545, timestamp: ... }
});

// Unsubscribe from all updates
ws.send(JSON.stringify({
  endpoint: '/v1/track/prices',
  symbols: []
}));
```

##  API Reference

### Base URL

```
http://localhost:8890/v1
ws://localhost:8890
```

### REST Endpoints

#### Market Data

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/price?symbol=<string>` | GET | Get current bid/ask prices for a symbol |
| `/v1/quote?symbol=<string>` | GET | Get detailed quote information for a symbol |
| `/v1/symbol/info?symbol=<string>` | GET | Get comprehensive symbol specifications |
| `/v1/symbol/list` | GET | Get list of all available symbols in MT5 |

#### Account Information

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/account` | GET | Get account balance, equity, margin, and other details |

#### Order Management

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/order/info?ticket=<ulong>` | GET | Get detailed information for a specific order ticket |
| `/v1/order/list` | GET | Get list of all orders (open positions and pending) |
| `/v1/order` | POST | Open a new trading order |
| `/v1/order/close` | POST | Close an existing position |
| `/v1/order/modify` | POST | Modify an existing order or position |

#### History

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/history/prices?symbol=<string>&timeframe=<string>&from_date=<string>&to_date=<string>` | GET | Get historical price data for a specific symbol and timeframe |
| `/v1/history/orders?from_date=<string>&to_date=<string>&mode=<string>` | GET | Get order history within a date range, optionally filtered by mode (e.g. closed, cancelled) |

#### Live Data

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/track/mbook` | POST | Subscribe to live market book (order book) updates |
| `/v1/track/ohlc` | POST | Subscribe to live OHLC (candlestick) data updates |
| `/v1/track/orders` | POST | Enable live order tracking notifications |
| `/v1/track/prices` | POST | Subscribe to real-time price updates |


---


### WebSocket Protocol

The WebSocket connection supports subscription-based real-time updates.

#### Connection

```javascript
const ws = new WebSocket('ws://localhost:8890');
```

#### Subscribe to Price Updates

Send a JSON message to start receiving price updates:

```json
{
  "endpoint": "/v1/track/prices",
  "symbols": ["EURUSD", "GBPUSD", "XAUUSD"]
}
```

**Streaming Response:**
```json
{
  "type": "price_update",
  "symbol": "EURUSD",
  "bid": 1.08542,
  "ask": 1.08545,
  "timestamp": "2025-10-22T14:30:15.123Z"
}
```

#### Unsubscribe from All Updates

```json
{
  "endpoint": "/v1/track/prices",
  "symbols": []
}
```

> **Note:** The EA only sends updates for subscribed symbols. No updates are sent on initial connection until a subscription message is received.

##  Usage Examples
### Python Integration

```python
import asyncio
import websockets
import json
import requests

BASE_URL = 'http://localhost:8890/v1'

# REST API
def get_positions():
    response = requests.get(f'{BASE_URL}/positions')
    return response.json()

# WebSocket
async def stream_prices():
    uri = 'ws://localhost:8890'
    async with websockets.connect(uri) as ws:
        # Subscribe
        await ws.send(json.dumps({
            'endpoint': '/v1/track/prices',
            'symbols': ['EURUSD', 'GBPUSD']
        }))
        
        # Receive updates
        async for message in ws:
            data = json.loads(message)
            print(f"{data['symbol']}: {data['bid']} / {data['ask']}")

asyncio.run(stream_prices())
```

##  Architecture

```
┌─────────────────┐
│  External App   │
│ (Node.js/Python)│
└────────┬────────┘
         │ HTTP / WebSocket
         │ Port 8890
┌────────▼────────┐
│  SocketBridgeEA │
│   ┌──────────┐  │
│   │REST API  │  │
│   ├──────────┤  │
│   │WebSocket │  │
│   │Streaming │  │
│   └──────────┘  │
└────────┬────────┘
         │ MQL5 API
┌────────▼────────┐
│  MetaTrader 5   │
│   Terminal      │
└─────────────────┘
```

### Design Principles

- **Subscription model:** Data sent only for tracked symbols
- **Non-blocking:** Asynchronous event-driven architecture
- **Stateless REST:** Each HTTP request is independent
- **Stateful WebSocket:** Maintains subscription state per connection

##  Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## ⚠️ Disclaimer

This software is provided for educational and development purposes. Use at your own risk. Always test thoroughly on a demo account before deploying to live trading environments.

##  Troubleshooting

### EA won't start
- Verify AutoTrading is enabled (green button in toolbar)
- Check Experts tab for error messages
- Ensure port 8890 is not in use by another process

### WebSocket not receiving updates
- Confirm you've sent a subscription message with valid symbols
- Check symbol names match exactly (case-sensitive)
- Verify symbols are available in Market Watch

### REST endpoints return errors
- Ensure the EA is attached to an active chart
- Check URL format: `http://localhost:8890/v1/endpoint`
- Review MT5 Journal tab for connection logs

---

Made with ❤️ by [mobjoy0](https://github.com/mobjoy0)