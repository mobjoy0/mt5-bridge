import { Router, Request, Response, NextFunction } from 'express';
import {fetchPriceHistory, getQuote} from '../services/SocketBridgeApi';

const router = Router();

/**
 * @swagger
 * /quote:
 *   get:
 *     summary: Get quote info
 *     parameters:
 *       - in: query
 *         name: symbol
 *         schema:
 *           type: string
 *         required: true
 *         description: Symbol to get quote for
 *     responses:
 *       200:
 *         description: Success
 */
router.get('/quote', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { symbol } = req.query;

        const quote = await getQuote(symbol as string);

        res.json(quote);
    } catch (error) {
        next(error);
    }
});


export default router;
