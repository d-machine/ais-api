import { Hono } from 'hono';
import StorageController from '../controllers/storage.controller.js';

function createStorageRouter() {
  const app = new Hono();
  const storageController = new StorageController();

  app.post('/initializeDatabase', storageController.initializeDb);
  app.post('/loadConfigs', storageController.initializeCache);

  return app;
}

export default createStorageRouter;
