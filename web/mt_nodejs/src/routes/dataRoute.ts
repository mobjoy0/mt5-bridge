import { Router } from 'express';
import orderRoutes from './order/orderRoutes';
import accountRoutes from './account/accountRoutes';
import historyRoutes from "./history/historyRoutes";
import trackRoutes from "./track/trackRoutes";
import Others from "./Others";

const router = Router();

router.use(orderRoutes);
router.use(accountRoutes);
router.use(historyRoutes);
router.use(trackRoutes);
router.use(Others);

export default router;
