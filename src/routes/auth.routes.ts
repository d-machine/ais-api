import { Hono } from 'hono';
import AuthController from '../controllers/auth.controller.js';
import authMiddleware from '../middlewares/auth.middleware.js';

function createAuthRouter() {
  const app = new Hono();
  const authController = new AuthController();

  app.post('/login', authController.login);
  app.post('/refresh', authController.refresh);

  app.use('*', authMiddleware);
  app.post('/logout', authController.logout);

  return app;
}

export default createAuthRouter;