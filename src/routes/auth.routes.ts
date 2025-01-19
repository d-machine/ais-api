import { Hono } from 'hono';
import AuthController from '../controllers/auth.controller.js';

export const createAuthRouter = () => {
  const app = new Hono();
  const authController = new AuthController();

  app.post('/login', authController.login);
  app.post('/refresh', authController.refresh);
  app.post('/logout', authController.logout);

  return app;
};