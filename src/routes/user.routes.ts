import { Hono } from 'hono';
import { UserController } from '../controllers/user.controller.js';
import { Pool } from 'pg';

export const createUserRouter = (pool: Pool) => {
  const app = new Hono();
  const userController = new UserController(pool);

  app.get('/', userController.getUsers);
  app.get('/username/:username', userController.getUserByUsername);
  app.get('/:id', userController.getUserById);
  app.get('/:id/roles', userController.getUserRoles);
  app.get('/:id/roles/details', userController.getUserRolesWithDetails);
  app.post('/', userController.createUser);
  app.put('/:id', userController.updateUser);
  app.delete('/:id', userController.deleteUser);

  return app;
}; 