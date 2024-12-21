import { Context } from 'hono';
import { UserRoleService } from '../services/user-role.service.js';
import { Pool } from 'pg';
import { toNumberOrThrow } from '../utils/id-converter.js';

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
      const id = toNumberOrThrow(c.req.param('id'), 'userRoleId');
      const userRole = await this.userRoleService.findById(id);
      
      if (!userRole) {
        return c.json({ error: 'User role not found' }, 404);
      }
      
      return c.json(userRole);
    } catch (error) {
      console.error('Error getting user role:', error);
      if (error instanceof Error && error.message.startsWith('Invalid userRoleId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get user role' }, 500);
    }
  };

  getUserRolesByUserId = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.param('userId'), 'userId');
      const userRoles = await this.userRoleService.findByUserId(userId);
      return c.json(userRoles);
    } catch (error) {
      console.error('Error getting user roles:', error);
      if (error instanceof Error && error.message.startsWith('Invalid userId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get user roles' }, 500);
    }
  };

  getUserRolesByRoleId = async (c: Context) => {
    try {
      const roleId = toNumberOrThrow(c.req.param('roleId'), 'roleId');
      const userRoles = await this.userRoleService.findByRoleId(roleId);
      return c.json(userRoles);
    } catch (error) {
      console.error('Error getting user roles:', error);
      if (error instanceof Error && error.message.startsWith('Invalid roleId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get user roles' }, 500);
    }
  };

  createUserRole = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      body.user_id = toNumberOrThrow(body.user_id.toString(), 'userId');
      body.role_id = toNumberOrThrow(body.role_id.toString(), 'roleId');
      body.last_updated_by = userId;
      const userRole = await this.userRoleService.create(body);
      return c.json(userRole, 201);
    } catch (error) {
      console.error('Error creating user role:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid userId') ||
        error.message.startsWith('Invalid roleId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to create user role' }, 500);
    }
  };

  updateUserRole = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'userRoleId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      if (body.user_id) {
        body.user_id = toNumberOrThrow(body.user_id.toString(), 'userId');
      }
      if (body.role_id) {
        body.role_id = toNumberOrThrow(body.role_id.toString(), 'roleId');
      }
      body.last_updated_by = userId;
      const userRole = await this.userRoleService.update(id, body);
      
      if (!userRole) {
        return c.json({ error: 'User role not found' }, 404);
      }
      
      return c.json(userRole);
    } catch (error) {
      console.error('Error updating user role:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid userRoleId') ||
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid userId') ||
        error.message.startsWith('Invalid roleId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to update user role' }, 500);
    }
  };

  deleteUserRole = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'userRoleId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');

      const success = await this.userRoleService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'User role not found' }, 404);
      }
      
      return c.json({ message: 'User role deleted successfully' });
    } catch (error) {
      console.error('Error deleting user role:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid userRoleId') ||
        error.message.startsWith('Invalid X-User-ID')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to delete user role' }, 500);
    }
  };
} 