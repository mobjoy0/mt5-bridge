import { BrowserRouter as Router, Routes, Route, Link } from "react-router-dom";
import AccountInfo from "./components/AccountInfo";
import OrderRequest from "./components/OrderRequest";
import { OrdersList } from "./components/OrderList";
import { ToastContainer } from "react-toastify";
import OrderHistory from "./components/OrderHistory.tsx";
import {CandleChart} from "./components/CandleStickChartComp.tsx";
import WsStreaming from "./components/WsStreaming.tsx"; // import your WS streaming component

function App() {
    return (
        <Router>
            <div className="bg-gray-900 text-white h-screen w-screen flex">
                {/* Side Navigation */}
                <nav className="bg-gray-800 w-64 h-full p-6 flex flex-col gap-4">
                    <div className="text-xl font-bold mb-6 text-center">Navigation</div>
                    <Link
                        to="/"
                        className="block py-3 px-4 rounded hover:bg-gray-700 transition-colors"
                    >
                        Orders
                    </Link>
                    <Link
                        to="/request"
                        className="block py-3 px-4 rounded hover:bg-gray-700 transition-colors"
                    >
                        Order Request
                    </Link>
                    <Link
                        to="/account"
                        className="block py-3 px-4 rounded hover:bg-gray-700 transition-colors"
                    >
                        Account Info
                    </Link>
                    <Link
                        to="/history"
                        className="block py-3 px-4 rounded hover:bg-gray-700 transition-colors"
                    >
                        History
                    </Link>
                    <Link
                        to="/chart"
                        className="block py-3 px-4 rounded hover:bg-gray-700 transition-colors"
                    >
                        Chart
                    </Link>
                    {/* New WebSocket Streaming tab */}
                    <Link
                        to="/ws"
                        className="block py-3 px-4 rounded hover:bg-gray-700 transition-colors"
                    >
                        WS Streaming
                    </Link>
                </nav>

                {/* Main Content - Scrollable */}
                <main className="flex-1 h-full overflow-y-auto">
                    <div className="p-6">
                        <Routes>
                            <Route path="/" element={<OrdersList />} />
                            <Route path="/request" element={
                                <div className="flex items-center justify-center min-h-full">
                                    <OrderRequest />
                                </div>
                            } />
                            <Route path="/account" element={
                                <div className="flex items-center justify-center min-h-full">
                                    <AccountInfo />
                                </div>
                            } />
                            <Route path="/history" element={<OrderHistory />} />
                            <Route path="/chart" element={<CandleChart />} />
                            {/* New route for WS streaming */}
                            <Route path="/ws" element={<WsStreaming />} />
                        </Routes>
                    </div>
                </main>

                <ToastContainer
                    style={{ width: '400px', height: '100px' }}
                    position="top-right"
                    autoClose={3000}
                    hideProgressBar={false}
                    newestOnTop
                    closeOnClick
                    pauseOnHover
                    draggable
                    theme="light"
                />
            </div>
        </Router>
    );
}

export default App;