import { Hono } from 'hono';
import { AccessGrantsController } from '../controllers/access-grants.controller.js';
import { Pool } from 'pg';

export const createAccessGrantsRouter = (pool: Pool) => {
  const app = new Hono();
  const accessGrantsController = new AccessGrantsController(pool);

  app.get('/', accessGrantsController.getAccessGrants);
  app.get('/user/:userId', accessGrantsController.getAccessGrantsByUserId);
  app.get('/target/:targetId', accessGrantsController.getAccessGrantsByTargetId);
  app.get('/user/:userId/target/:targetId', accessGrantsController.getAccessGrantsByUserAndTarget);
  app.get('/:id', accessGrantsController.getAccessGrantById);
  app.post('/', accessGrantsController.createAccessGrant);
  app.put('/:id', accessGrantsController.updateAccessGrant);
  app.delete('/:id', accessGrantsController.deleteAccessGrant);

  return app;
}; 