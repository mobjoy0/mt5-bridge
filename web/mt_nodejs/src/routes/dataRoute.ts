import { Router } from 'express';
import orderRoutes from './order/orderRoutes';
import accountRoutes from './account/accountRoutes';
import historyRoutes from "./history/historyRoutes";
import trackRoutes from "./track/trackRoutes";

const router = Router();

router.use(orderRoutes);
router.use(accountRoutes);
router.use(historyRoutes);
router.use(trackRoutes);

export default router;
