import { Router, Request, Response, NextFunction } from 'express';
import { postTrackMbook, postTrackOhlc, postTrackOrders, postTrackPrices } from '../../services/SocketBridgeApi';

const router = Router();

/**
 * @swagger
 * /track/prices:
 *   post:
 *     summary: Track symbols
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               symbols:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["EURUSD", "GBPUSD"]
 *     responses:
 *       200:
 *         description: Tracking initiated successfully
 */
router.post('/track/prices', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const body = req.body;
        const result = await postTrackPrices(body);
        res.json(result);
    } catch (error) {
        next(error);
    }
});

/**
 * @swagger
 * /track/ohlc:
 *   post:
 *     summary: Track OHLC data
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               ohlc:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     time_frame:
 *                       type: string
 *                       example: M1
 *                     symbol:
 *                       type: string
 *                       example: EURUSD
 *                     depth:
 *                       type: integer
 *                       example: 3
 *     responses:
 *       200:
 *         description: Tracking initiated successfully
 */
router.post('/track/ohlc', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const body = req.body;
        const result = await postTrackOhlc(body);
        res.json(result);
    } catch (error) {
        next(error);
    }
});

/**
 * @swagger
 * /track/mbook:
 *   post:
 *     summary: Track market book data
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               symbols:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["EURUSD", "USDJPY"]
 *     responses:
 *       200:
 *         description: Tracking initiated successfully
 */
router.post('/track/mbook', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const body = req.body;
        const result = await postTrackMbook(body);
        res.json(result);
    } catch (error) {
        next(error);
    }
});

/**
 * @swagger
 * /track/orders:
 *   post:
 *     summary: Track order events
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               symbols:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["BTCUSD", "ETHUSD"]
 *     responses:
 *       200:
 *         description: Tracking initiated successfully
 */
router.post('/track/orders', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const body = req.body;
        const result = await postTrackOrders(body);
        res.json(result);
    } catch (error) {
        next(error);
    }
});

export default router;
