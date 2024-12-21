import { Context } from 'hono';
import { RoleService } from '../services/role.service.js';
import { Pool } from 'pg';
import { toNumberOrThrow } from '../utils/id-converter.js';

export class RoleController {
  private roleService: RoleService;

  constructor(pool: Pool) {
    this.roleService = new RoleService(pool);
  }

  getRoles = async (c: Context) => {
    try {
      const roles = await this.roleService.findAll();
      return c.json(roles);
    } catch (error) {
      console.error('Error getting roles:', error);
      return c.json({ error: 'Failed to get roles' }, 500);
    }
  };

  getRoleById = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'roleId');
      const role = await this.roleService.findById(id);
      
      if (!role) {
        return c.json({ error: 'Role not found' }, 404);
      }
      
      return c.json(role);
    } catch (error) {
      console.error('Error getting role:', error);
      if (error instanceof Error && error.message.startsWith('Invalid roleId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get role' }, 500);
    }
  };

  getRoleByName = async (c: Context) => {
    try {
      const name = c.req.param('name');
      const role = await this.roleService.findByName(name);
      
      if (!role) {
        return c.json({ error: 'Role not found' }, 404);
      }
      
      return c.json(role);
    } catch (error) {
      console.error('Error getting role:', error);
      return c.json({ error: 'Failed to get role' }, 500);
    }
  };

  createRole = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      body.last_updated_by = userId;
      const role = await this.roleService.create(body);
      return c.json(role, 201);
    } catch (error) {
      console.error('Error creating role:', error);
      if (error instanceof Error && error.message.startsWith('Invalid X-User-ID')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to create role' }, 500);
    }
  };

  updateRole = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'roleId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      body.last_updated_by = userId;
      const role = await this.roleService.update(id, body);
      
      if (!role) {
        return c.json({ error: 'Role not found' }, 404);
      }
      
      return c.json(role);
    } catch (error) {
      console.error('Error updating role:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid roleId') ||
        error.message.startsWith('Invalid X-User-ID')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to update role' }, 500);
    }
  };

  deleteRole = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'roleId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');

      const success = await this.roleService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Role not found' }, 404);
      }
      
      return c.json({ message: 'Role deleted successfully' });
    } catch (error) {
      console.error('Error deleting role:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid roleId') ||
        error.message.startsWith('Invalid X-User-ID')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to delete role' }, 500);
    }
  };

  getRoleUsers = async (c: Context) => {
    try {
      const roleId = toNumberOrThrow(c.req.param('roleId'), 'roleId');
      const users = await this.roleService.getRoleUsers(roleId);
      return c.json(users);
    } catch (error) {
      console.error('Error getting role users:', error);
      if (error instanceof Error && error.message.startsWith('Invalid roleId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get role users' }, 500);
    }
  };

  getRoleUsersWithDetails = async (c: Context) => {
    try {
      const roleId = toNumberOrThrow(c.req.param('roleId'), 'roleId');
      const users = await this.roleService.getRoleUsersWithDetails(roleId);
      return c.json(users);
    } catch (error) {
      console.error('Error getting role users with details:', error);
      if (error instanceof Error && error.message.startsWith('Invalid roleId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get role users with details' }, 500);
    }
  };
} 