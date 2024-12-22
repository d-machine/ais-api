import { Context } from 'hono';
import { UserRoleService } from '../services/user-role.service.js';
import { Pool } from 'pg';
import { _isNil } from '../utils/aisLodash.js';

export class UserRoleController {
  private userRoleService: UserRoleService;

  constructor(pool: Pool) {
    this.userRoleService = new UserRoleService(pool);
  }

  getUserRoles = async (c: Context) => {
    try {
      const userRoles = await this.userRoleService.findAll();
      return c.json(userRoles);
    } catch (error) {
      console.error('Error getting user roles:', error);
      return c.json({ error: 'Failed to get user roles' }, 500);
    }
  };

  getUserRoleById = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userRole = await this.userRoleService.findById(id);
      
      if (_isNil(userRole)) {
        return c.json({ error: 'User role not found' }, 404);
      }
      
      return c.json(userRole);
    } catch (error) {
      console.error('Error getting user role:', error);
      return c.json({ error: 'Failed to get user role' }, 500);
    }
  };

  getUserRolesByUserId = async (c: Context) => {
    try {
      const userId = parseInt(c.req.param('userId'), 10);
      const userRoles = await this.userRoleService.findByUserId(userId);
      return c.json(userRoles);
    } catch (error) {
      console.error('Error getting user roles:', error);
      return c.json({ error: 'Failed to get user roles' }, 500);
    }
  };

  getUserRolesByRoleId = async (c: Context) => {
    try {
      const roleId = parseInt(c.req.param('roleId'), 10);
      const userRoles = await this.userRoleService.findByRoleId(roleId);
      return c.json(userRoles);
    } catch (error) {
      console.error('Error getting user roles:', error);
      return c.json({ error: 'Failed to get user roles' }, 500);
    }
  };

  createUserRole = async (c: Context) => {
    try {
      const userId = c.get('userId');
      const body = await c.req.json();
      body.user_id = parseInt(body.user_id.toString(), 10);
      body.role_id = parseInt(body.role_id.toString(), 10);
      body.last_updated_by = userId;
      const userRole = await this.userRoleService.create(body);
      return c.json(userRole, 201);
    } catch (error) {
      console.error('Error creating user role:', error);
      return c.json({ error: 'Failed to create user role' }, 500);
    }
  };

  updateUserRole = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');
      const body = await c.req.json();
      if (body.user_id) {
        body.user_id = parseInt(body.user_id.toString(), 10);
      }
      if (body.role_id) {
        body.role_id = parseInt(body.role_id.toString(), 10);
      }
      body.last_updated_by = userId;
      const userRole = await this.userRoleService.update(id, body);
      
      if (_isNil(userRole)) {
        return c.json({ error: 'User role not found' }, 404);
      }
      
      return c.json(userRole);
    } catch (error) {
      console.error('Error updating user role:', error);
      return c.json({ error: 'Failed to update user role' }, 500);
    }
  };

  deleteUserRole = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');

      const success = await this.userRoleService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'User role not found' }, 404);
      }
      
      return c.json({ message: 'User role deleted successfully' });
    } catch (error) {
      console.error('Error deleting user role:', error);
      return c.json({ error: 'Failed to delete user role' }, 500);
    }
  };
} 