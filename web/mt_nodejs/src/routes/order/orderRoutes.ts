import { Router, Request, Response, NextFunction } from 'express';
import {closeSendOrder, fetchOrderList, postSendOrder, postTrackPrices} from '../../services/SocketBridgeApi';

const router = Router();

/**
 * @swagger
 * /order/list:
 *   get:
 *     summary: Get list of orders
 *     responses:
 *       200:
 *         description: Success
 */
router.get('/order/list', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const orders = await fetchOrderList();
        res.json(orders);
    } catch (error) {
        next(error);
    }
});


/**
 * @swagger
 * /order:
 *   post:
 *     summary: Send order
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               symbol:
 *                 type: string
 *                 example: "EURUSD"
 *               volume:
 *                 type: number
 *                 example: 0.1
 *               order_type:
 *                 type: string
 *                 example: "buy"
 *             required:
 *               - order_type
 *     responses:
 *       200:
 *         description: Success
 */
router.post('/order', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const body = req.body;
        //validate later
        const result = await postSendOrder(body);
        res.json(result);
    } catch (error) {
        next(error);
    }
});


/**
 * @swagger
 * /order/close:
 *   post:
 *     summary: close order
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               ticket:
 *                 type: integer
 *                 example: 5144525742
 *             required:
 *               - ticket
 *     responses:
 *       200:
 *         description: Success
 */
router.post('/order/close', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const body = req.body;
        //validate later
        const result = await closeSendOrder(body);
        res.json(result);
    } catch (error) {
        next(error);
    }
});

export default router;
