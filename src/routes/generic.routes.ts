import { Hono } from 'hono';
import ApiController from '../controllers/api.controller.js';
import authMiddleware from '../middlewares/auth.middleware.js';

function createGenericRoutes() {
  const app = new Hono();

  const apiController = new ApiController();
  
  app.use('*', authMiddleware);

  app.post('/getMenu', apiController.getMenu);
  app.post('/getConfig', apiController.getConfig);
  app.post('/executeQuery', apiController.executeQuery);

  return app;
};

export default createGenericRoutes;
