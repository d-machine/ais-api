import { Hono } from 'hono';
import { UserRoleController } from '../controllers/user-role.controller.js';
import { Pool } from 'pg';

export const createUserRoleRouter = (pool: Pool) => {
  const app = new Hono();
  const userRoleController = new UserRoleController(pool);

  app.get('/', userRoleController.getUserRoles);
  app.get('/user/:userId', userRoleController.getUserRolesByUserId);
  app.get('/role/:roleId', userRoleController.getUserRolesByRoleId);
  app.get('/:id', userRoleController.getUserRoleById);
  app.post('/', userRoleController.createUserRole);
  app.put('/:id', userRoleController.updateUserRole);
  app.delete('/:id', userRoleController.deleteUserRole);

  return app;
}; 