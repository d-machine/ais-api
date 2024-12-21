import { Hono } from 'hono';
import { ResourceAccessRoleController } from '../controllers/resource-access-role.controller.js';
import { Pool } from 'pg';

export const createResourceAccessRoleRouter = (pool: Pool) => {
  const app = new Hono();
  const resourceAccessRoleController = new ResourceAccessRoleController(pool);

  app.get('/', resourceAccessRoleController.getResourceAccessRoles);
  app.get('/resource/:resourceId', resourceAccessRoleController.getResourceAccessRolesByResourceId);
  app.get('/role/:roleId', resourceAccessRoleController.getResourceAccessRolesByRoleId);
  app.get('/access-type/:accessTypeId', resourceAccessRoleController.getResourceAccessRolesByAccessTypeId);
  app.get('/resource/:resourceId/role/:roleId', resourceAccessRoleController.getResourceAccessRolesByResourceAndRole);
  app.get('/:id', resourceAccessRoleController.getResourceAccessRoleById);
  app.post('/', resourceAccessRoleController.createResourceAccessRole);
  app.put('/:id', resourceAccessRoleController.updateResourceAccessRole);
  app.delete('/:id', resourceAccessRoleController.deleteResourceAccessRole);

  return app;
}; 