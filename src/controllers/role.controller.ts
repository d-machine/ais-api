import { Context } from 'hono';
import { RoleService } from '../services/role.service.js';
import { Pool } from 'pg';
import { _isNil } from '../utils/aisLodash.js';

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
      const id = parseInt(c.req.param('id'), 10);
      const role = await this.roleService.findById(id);
      
      if (_isNil(role)) {
        return c.json({ error: 'Role not found' }, 404);
      }
      
      return c.json(role);
    } catch (error) {
      console.error('Error getting role:', error);
      return c.json({ error: 'Failed to get role' }, 500);
    }
  };

  getRoleByName = async (c: Context) => {
    try {
      const name = c.req.param('name');
      const role = await this.roleService.findByName(name);
      
      if (_isNil(role)) {
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
      const userId = c.get('userId');
      const body = await c.req.json();
      body.last_updated_by = userId;
      const role = await this.roleService.create(body);
      return c.json(role, 201);
    } catch (error) {
      console.error('Error creating role:', error);
      return c.json({ error: 'Failed to create role' }, 500);
    }
  };

  updateRole = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');
      const body = await c.req.json();
      body.last_updated_by = userId;
      const role = await this.roleService.update(id, body);
      
      if (_isNil(role)) {
        return c.json({ error: 'Role not found' }, 404);
      }
      
      return c.json(role);
    } catch (error) {
      console.error('Error updating role:', error);
      return c.json({ error: 'Failed to update role' }, 500);
    }
  };

  deleteRole = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');

      const success = await this.roleService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Role not found' }, 404);
      }
      
      return c.json({ message: 'Role deleted successfully' });
    } catch (error) {
      console.error('Error deleting role:', error);
      return c.json({ error: 'Failed to delete role' }, 500);
    }
  };

  getRoleUsers = async (c: Context) => {
    try {
      const roleId = parseInt(c.req.param('id'), 10);
      const users = await this.roleService.getRoleUsers(roleId);
      return c.json(users);
    } catch (error) {
      console.error('Error getting role users:', error);
      return c.json({ error: 'Failed to get role users' }, 500);
    }
  };

  getRoleUsersWithDetails = async (c: Context) => {
    try {
      const roleId = parseInt(c.req.param('id'), 10);
      const users = await this.roleService.getRoleUsersWithDetails(roleId);
      return c.json(users);
    } catch (error) {
      console.error('Error getting role users with details:', error);
      return c.json({ error: 'Failed to get role users with details' }, 500);
    }
  };
} 