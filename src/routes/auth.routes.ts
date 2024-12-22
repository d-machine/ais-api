import { Hono } from 'hono';
import { AuthController } from '../controllers/auth.controller.js';
import { Pool } from 'pg';

export const createAuthRouter = (pool: Pool) => {
  const app = new Hono();
  const authController = new AuthController(pool);

  app.post('/login', authController.login);
  app.post('/refresh', authController.refresh);
  app.post('/logout', authController.logout);

  return app;
}; 