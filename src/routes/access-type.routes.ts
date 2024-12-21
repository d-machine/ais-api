import { Hono } from 'hono';
import { AccessTypeController } from '../controllers/access-type.controller.js';
import { Pool } from 'pg';

export const createAccessTypeRouter = (pool: Pool) => {
  const app = new Hono();
  const accessTypeController = new AccessTypeController(pool);

  app.get('/', accessTypeController.getAccessTypes);
  app.get('/:id', accessTypeController.getAccessTypeById);
  app.get('/name/:name', accessTypeController.getAccessTypeByName);
  app.post('/', accessTypeController.createAccessType);
  app.put('/:id', accessTypeController.updateAccessType);
  app.delete('/:id', accessTypeController.deleteAccessType);

  return app;
}; 