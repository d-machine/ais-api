import { Hono } from 'hono';
import { DbController } from '../controllers/db.controller.js';

const router = new Hono();

router.post('/initialize', DbController.initialize);

export default router; 