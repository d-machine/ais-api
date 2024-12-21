import { Context } from 'hono';
import { ResourceAccessRoleService } from '../services/resource-access-role.service.js';
import { Pool } from 'pg';
import { toNumberOrThrow } from '../utils/id-converter.js';

export class ResourceAccessRoleController {
  private resourceAccessRoleService: ResourceAccessRoleService;

  constructor(pool: Pool) {
    this.resourceAccessRoleService = new ResourceAccessRoleService(pool);
  }

  getResourceAccessRoles = async (c: Context) => {
    try {
      const resourceAccessRoles = await this.resourceAccessRoleService.findAll();
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  getResourceAccessRoleById = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'resourceAccessRoleId');
      const resourceAccessRole = await this.resourceAccessRoleService.findById(id);
      
      if (!resourceAccessRole) {
        return c.json({ error: 'Resource access role not found' }, 404);
      }
      
      return c.json(resourceAccessRole);
    } catch (error) {
      console.error('Error getting resource access role:', error);
      if (error instanceof Error && error.message.startsWith('Invalid resourceAccessRoleId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get resource access role' }, 500);
    }
  };

  getResourceAccessRolesByResourceId = async (c: Context) => {
    try {
      const resourceId = toNumberOrThrow(c.req.param('resourceId'), 'resourceId');
      const resourceAccessRoles = await this.resourceAccessRoleService.findByResourceId(resourceId);
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      if (error instanceof Error && error.message.startsWith('Invalid resourceId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  getResourceAccessRolesByRoleId = async (c: Context) => {
    try {
      const roleId = toNumberOrThrow(c.req.param('roleId'), 'roleId');
      const resourceAccessRoles = await this.resourceAccessRoleService.findByRoleId(roleId);
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      if (error instanceof Error && error.message.startsWith('Invalid roleId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  getResourceAccessRolesByAccessTypeId = async (c: Context) => {
    try {
      const accessTypeId = toNumberOrThrow(c.req.param('accessTypeId'), 'accessTypeId');
      const resourceAccessRoles = await this.resourceAccessRoleService.findByAccessTypeId(accessTypeId);
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      if (error instanceof Error && error.message.startsWith('Invalid accessTypeId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  getResourceAccessRolesByResourceAndRole = async (c: Context) => {
    try {
      const resourceId = toNumberOrThrow(c.req.param('resourceId'), 'resourceId');
      const roleId = toNumberOrThrow(c.req.param('roleId'), 'roleId');
      const resourceAccessRoles = await this.resourceAccessRoleService.findByResourceAndRole(resourceId, roleId);
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid resourceId') ||
        error.message.startsWith('Invalid roleId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  createResourceAccessRole = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      body.resource_id = toNumberOrThrow(body.resource_id.toString(), 'resourceId');
      body.role_id = toNumberOrThrow(body.role_id.toString(), 'roleId');
      body.access_type_id = toNumberOrThrow(body.access_type_id.toString(), 'accessTypeId');
      body.last_updated_by = userId;
      const resourceAccessRole = await this.resourceAccessRoleService.create(body);
      return c.json(resourceAccessRole, 201);
    } catch (error) {
      console.error('Error creating resource access role:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid resourceId') ||
        error.message.startsWith('Invalid roleId') ||
        error.message.startsWith('Invalid accessTypeId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to create resource access role' }, 500);
    }
  };

  updateResourceAccessRole = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'resourceAccessRoleId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      if (body.resource_id) {
        body.resource_id = toNumberOrThrow(body.resource_id.toString(), 'resourceId');
      }
      if (body.role_id) {
        body.role_id = toNumberOrThrow(body.role_id.toString(), 'roleId');
      }
      if (body.access_type_id) {
        body.access_type_id = toNumberOrThrow(body.access_type_id.toString(), 'accessTypeId');
      }
      body.last_updated_by = userId;
      const resourceAccessRole = await this.resourceAccessRoleService.update(id, body);
      
      if (!resourceAccessRole) {
        return c.json({ error: 'Resource access role not found' }, 404);
      }
      
      return c.json(resourceAccessRole);
    } catch (error) {
      console.error('Error updating resource access role:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid resourceAccessRoleId') ||
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid resourceId') ||
        error.message.startsWith('Invalid roleId') ||
        error.message.startsWith('Invalid accessTypeId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to update resource access role' }, 500);
    }
  };

  deleteResourceAccessRole = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'resourceAccessRoleId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');

      const success = await this.resourceAccessRoleService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Resource access role not found' }, 404);
      }
      
      return c.json({ message: 'Resource access role deleted successfully' });
    } catch (error) {
      console.error('Error deleting resource access role:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid resourceAccessRoleId') ||
        error.message.startsWith('Invalid X-User-ID')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to delete resource access role' }, 500);
    }
  };
} 