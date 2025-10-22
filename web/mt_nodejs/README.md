# MT5 Bridge — Node.js Backend

[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8-blue.svg)](https://www.typescriptlang.org/)
[![Express](https://img.shields.io/badge/Express-5.1-lightgrey.svg)](https://expressjs.com/)

A TypeScript-based REST API middleware that acts as a bridge between your frontend application and the MetaTrader 5 SocketBridgeEA. It proxies requests to the MT5 Expert Advisor and provides a clean, documented API interface with Swagger documentation.

##  Purpose

This backend server serves as an intermediary layer that:
- **Forwards requests** from your React frontend to the MT5 EA (running on port 8890)
- **Proxies responses** back to the client with proper error handling
- **Provides API documentation** via Swagger UI
- **Handles CORS** for cross-origin requests
- **Adds validation** and error handling layer
- **Abstracts MT5 complexity** from the frontend

##  Architecture

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   React      │  HTTP   │   Node.js    │  HTTP   │  MT5 EA      │
│   Frontend   │───────▶ │   Backend    │───────▶ │SocketBridge  │
│  (Port 3000) │  :8891  │  (Port 8891) │  :8890  │ (Port 8890)  │
└──────────────┘         └──────────────┘         └──────────────┘
                               │
                               │ Swagger UI
                               ▼
                            /api-docs
```

##  Quick Start

### Prerequisites

- Node.js 18+ or higher
- npm or yarn
- MT5 SocketBridgeEA running on port 8890

### Installation

```bash
# Clone the repository
git clone https://github.com/mobjoy0/mt5-bridge.git
cd mt5-bridge/web/mt_nodejs

# Install dependencies
npm install
```

### Running the Server

```bash
# Development mode (with auto-reload)
npm run dev

# Build TypeScript
npm run build

# Production mode
npm start
```

The server will start on **http://localhost:8891**

##  API Documentation

Once the server is running, access the interactive Swagger documentation at:

```
http://localhost:8891/api-docs
```

##  Usage Examples

### JavaScript/Fetch

```javascript
// Get account information
const response = await fetch('http://localhost:8891/api/v1/account');
const account = await response.json();
console.log(account);
```


##  Project Structure

```
mt_nodejs/
├── src/
│   ├── routes/          # API route handlers
│   ├── services/        # Business logic and MT5 communication
│   ├── utils/           # error handling
│   └── index.ts         # Application entry point
├── package.json
├── tsconfig.json
└── README.md
```




### Adding New Endpoints

1. Define the route in `src/routes/`
2. Add Swagger documentation using JSDoc comments
3. Implement the service logic in `src/services/`
4. Test via Swagger UI at `/api-docs`

Example:

```typescript
/**
 * @swagger
 * /api/v1/price:
 *   get:
 *     summary: Get symbol price
 *     parameters:
 *       - name: symbol
 *         in: query
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Price data
 */
router.get('/price', async (req, res) => {
  const { symbol } = req.query;
  const data = await mt5Service.getPrice(symbol);
  res.json(data);
});
```

##  Error Handling

The backend includes comprehensive error handling:

- **Connection errors** — Detects when MT5 EA is unreachable
- **Validation errors** — Returns clear error messages for invalid requests
- **Timeout handling** — Prevents hanging requests
- **HTTP error responses** — Proper status codes (400, 404, 500, etc.)


##  Deployment

### Docker

```dockerfile
FROM node:22.12.0

WORKDIR /app

COPY package*.json ./

RUN npm install --production
COPY . .

EXPOSE 8891

CMD ["node", "index.js"]

```

##  Troubleshooting

### Cannot connect to MT5 EA

**Error:** `ECONNREFUSED localhost:8890`

**Solutions:**
1. Verify MT5 SocketBridgeEA is running and attached to a chart
2. Check AutoTrading is enabled in MT5
3. Check firewall settings


## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🔗 Related Projects

- [MT5 SocketBridgeEA](../../MQL5) — MetaTrader 5 Expert Advisor
- [React Frontend](../mt5react) — Web interface (if applicable)
---

Made with ❤️ by [mobjoy0](https://github.com/mobjoy0)