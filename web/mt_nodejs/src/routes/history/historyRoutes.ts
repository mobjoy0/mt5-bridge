import { Router, Request, Response, NextFunction } from 'express';
import {fetchOrderHistory, fetchPriceHistory} from '../../services/SocketBridgeApi';

const router = Router();

/**
 * @swagger
 * /history/orders:
 *   get:
 *     summary: Get order history
 *     parameters:
 *       - in: query
 *         name: mode
 *         schema:
 *           type: string
 *           enum: [positions, orders, deals]
 *         required: false
 *         description: Filter by type (positions, orders, or deals)
 *       - in: query
 *         name: from_date
 *         schema:
 *           type: string
 *           format: date
 *         required: false
 *         description: Start date in YYYY-MM-DD format
 *       - in: query
 *         name: to_date
 *         schema:
 *           type: string
 *           format: date
 *         required: false
 *         description: End date in YYYY-MM-DD format
 *     responses:
 *       200:
 *         description: Success
 */
router.get('/history/orders', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { mode, from_date, to_date } = req.query;

        const history = await fetchOrderHistory({
            mode: mode as string,
            from_date: from_date as string,
            to_date: to_date as string,
        });

        res.json(history);
    } catch (error) {
        next(error);
    }
});

/**
 * @swagger
 * /history/prices:
 *   get:
 *     summary: Get price history
 *     parameters:
 *       - in: query
 *         name: mode
 *         schema:
 *           type: string
 *           enum: [positions, orders, deals]
 *         required: false
 *         description: Filter by type (positions, orders, or deals)
 *       - in: query
 *         name: from_date
 *         schema:
 *           type: string
 *           format: date
 *         required: false
 *         description: Start date in YYYY-MM-DD format
 *       - in: query
 *         name: to_date
 *         schema:
 *           type: string
 *           format: date
 *         required: false
 *         description: End date in YYYY-MM-DD format
 *     responses:
 *       200:
 *         description: Success
 */
router.get('/history/prices', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { symbol, time_frame, from_date, to_date } = req.query;

        const prices = await fetchPriceHistory({
            symbol: symbol as string,
            time_frame: time_frame as string,
            from_date: from_date as string,
            to_date: to_date as string,
        });

        res.json(prices);
    } catch (error) {
        next(error);
    }
});

export default router;