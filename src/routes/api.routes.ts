import { Hono } from 'hono';
import { Pool } from 'pg';
import { IFetchQuery } from '../types/general.js';
import ApiController from '../controllers/api.controller.js';

export const createAllRoutes = () => {
  const app = new Hono();

  const apiController = new ApiController();

  app.post('/getMenu', apiController.getMenu);
  app.post('/getConfig', apiController.getConfig);
  app.post('/executeQuery', apiController.executeQuery);

  return app;
};
