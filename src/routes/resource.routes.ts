import { Hono } from 'hono';
import { ResourceController } from '../controllers/resource.controller.js';
import { Pool } from 'pg';

export const createResourceRouter = (pool: Pool) => {
  const app = new Hono();
  const resourceController = new ResourceController(pool);

  app.get('/', resourceController.getResources);
  app.get('/name/:name', resourceController.getResourceByName);
  app.get('/:id', resourceController.getResourceById);
  app.post('/', resourceController.createResource);
  app.put('/:id', resourceController.updateResource);
  app.delete('/:id', resourceController.deleteResource);

  return app;
}; 