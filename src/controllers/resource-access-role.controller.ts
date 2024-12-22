import { Context } from 'hono';
import { ResourceAccessRoleService } from '../services/resource-access-role.service.js';
import { Pool } from 'pg';
import { _isNil } from '../utils/aisLodash.js';

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
      const id = parseInt(c.req.param('id'), 10);
      const resourceAccessRole = await this.resourceAccessRoleService.findById(id);
      
      if (_isNil(resourceAccessRole)) {
        return c.json({ error: 'Resource access role not found' }, 404);
      }
      
      return c.json(resourceAccessRole);
    } catch (error) {
      console.error('Error getting resource access role:', error);
      return c.json({ error: 'Failed to get resource access role' }, 500);
    }
  };

  getResourceAccessRolesByResourceId = async (c: Context) => {
    try {
      const resourceId = parseInt(c.req.param('resourceId'), 10);
      const resourceAccessRoles = await this.resourceAccessRoleService.findByResourceId(resourceId);
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  getResourceAccessRolesByRoleId = async (c: Context) => {
    try {
      const roleId = parseInt(c.req.param('roleId'), 10);
      const resourceAccessRoles = await this.resourceAccessRoleService.findByRoleId(roleId);
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  getResourceAccessRolesByAccessTypeId = async (c: Context) => {
    try {
      const accessTypeId = parseInt(c.req.param('accessTypeId'), 10);
      const resourceAccessRoles = await this.resourceAccessRoleService.findByAccessTypeId(accessTypeId);
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  getResourceAccessRolesByResourceAndRole = async (c: Context) => {
    try {
      const resourceId = parseInt(c.req.param('resourceId'), 10);
      const roleId = parseInt(c.req.param('roleId'), 10);
      const resourceAccessRoles = await this.resourceAccessRoleService.findByResourceAndRole(resourceId, roleId);
      return c.json(resourceAccessRoles);
    } catch (error) {
      console.error('Error getting resource access roles:', error);
      return c.json({ error: 'Failed to get resource access roles' }, 500);
    }
  };

  createResourceAccessRole = async (c: Context) => {
    try {
      const userId = c.get('userId');
      const body = await c.req.json();
      body.resource_id = parseInt(body.resource_id.toString(), 10);
      body.role_id = parseInt(body.role_id.toString(), 10);
      body.access_type_id = parseInt(body.access_type_id.toString(), 10);
      body.last_updated_by = userId;
      const resourceAccessRole = await this.resourceAccessRoleService.create(body);
      return c.json(resourceAccessRole, 201);
    } catch (error) {
      console.error('Error creating resource access role:', error);
      return c.json({ error: 'Failed to create resource access role' }, 500);
    }
  };

  updateResourceAccessRole = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');
      const body = await c.req.json();
      if (body.resource_id) {
        body.resource_id = parseInt(body.resource_id.toString(), 10);
      }
      if (body.role_id) {
        body.role_id = parseInt(body.role_id.toString(), 10);
      }
      if (body.access_type_id) {
        body.access_type_id = parseInt(body.access_type_id.toString(), 10);
      }
      body.last_updated_by = userId;
      const resourceAccessRole = await this.resourceAccessRoleService.update(id, body);
      
      if (_isNil(resourceAccessRole)) {
        return c.json({ error: 'Resource access role not found' }, 404);
      }
      
      return c.json(resourceAccessRole);
    } catch (error) {
      console.error('Error updating resource access role:', error);
      return c.json({ error: 'Failed to update resource access role' }, 500);
    }
  };

  deleteResourceAccessRole = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');

      const success = await this.resourceAccessRoleService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Resource access role not found' }, 404);
      }
      
      return c.json({ message: 'Resource access role deleted successfully' });
    } catch (error) {
      console.error('Error deleting resource access role:', error);
      return c.json({ error: 'Failed to delete resource access role' }, 500);
    }
  };
} 