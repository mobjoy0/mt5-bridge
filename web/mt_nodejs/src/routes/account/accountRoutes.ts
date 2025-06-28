import { Router, Request, Response, NextFunction } from 'express';
import { fetchAccount } from '../../services/SocketBridgeApi';

const router = Router();

/**
 * @swagger
 * /account:
 *   get:
 *     summary: Get account info
 *     responses:
 *       200:
 *         description: Success
 */
router.get('/account', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const account = await fetchAccount();
        res.json(account);
    } catch (error) {
        next(error);
    }
});

export default router;
