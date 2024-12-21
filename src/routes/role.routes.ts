import { Hono } from 'hono';
import { RoleController } from '../controllers/role.controller.js';
import { Pool } from 'pg';

export const createRoleRouter = (pool: Pool) => {
  const app = new Hono();
  const roleController = new RoleController(pool);

  app.get('/', roleController.getRoles);
  app.get('/name/:name', roleController.getRoleByName);
  app.get('/:id', roleController.getRoleById);
  app.get('/:id/users', roleController.getRoleUsers);
  app.get('/:id/users/details', roleController.getRoleUsersWithDetails);
  app.post('/', roleController.createRole);
  app.put('/:id', roleController.updateRole);
  app.delete('/:id', roleController.deleteRole);

  return app;
}; 