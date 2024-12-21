import { Context } from 'hono';
import { UserService } from '../services/user.service.js';
import { Pool } from 'pg';
import { toNumberOrThrow } from '../utils/id-converter.js';

export class UserController {
  private userService: UserService;

  constructor(pool: Pool) {
    this.userService = new UserService(pool);
  }

  getUsers = async (c: Context) => {
    try {
      const users = await this.userService.findAll();
      return c.json(users);
    } catch (error) {
      console.error('Error getting users:', error);
      return c.json({ error: 'Failed to get users' }, 500);
    }
  };

  getUserById = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'userId');
      const user = await this.userService.findById(id);
      
      if (!user) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      return c.json(user);
    } catch (error) {
      console.error('Error getting user:', error);
      if (error instanceof Error && error.message.startsWith('Invalid userId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get user' }, 500);
    }
  };

  createUser = async (c: Context) => {
    try {
      const data = await c.req.json();
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      
      // Convert reporting_manager_id to number if present
      if (data.reporting_manager_id) {
        const managerId = toNumberOrThrow(data.reporting_manager_id, 'reporting_manager_id');
        data.reporting_manager_id = managerId;
      }

      data.last_updated_by = userId;
      const user = await this.userService.create(data);
      return c.json(user, 201);
    } catch (error) {
      console.error('Error creating user:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid userId') ||
        error.message.startsWith('Invalid reporting_manager_id')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to create user' }, 500);
    }
  };

  updateUser = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'userId');
      const data = await c.req.json();
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');

      // Convert reporting_manager_id to number if present
      if (data.reporting_manager_id) {
        const managerId = toNumberOrThrow(data.reporting_manager_id, 'reporting_manager_id');
        data.reporting_manager_id = managerId;
      }

      data.last_updated_by = userId;
      const user = await this.userService.update(id, data);
      
      if (!user) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      return c.json(user);
    } catch (error) {
      console.error('Error updating user:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid userId') ||
        error.message.startsWith('Invalid reporting_manager_id')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to update user' }, 500);
    }
  };

  deleteUser = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'userId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');

      const deleted = await this.userService.delete(id, userId);
      
      if (!deleted) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      return c.json({ message: 'User deleted successfully' });
    } catch (error) {
      console.error('Error deleting user:', error);
      if (error instanceof Error && error.message.startsWith('Invalid userId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to delete user' }, 500);
    }
  };

  getUserByUsername = async (c: Context) => {
    try {
      const username = c.req.param('username');
      const user = await this.userService.findByUsername(username);
      
      if (!user) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      return c.json(user);
    } catch (error) {
      console.error('Error getting user by username:', error);
      return c.json({ error: 'Failed to get user' }, 500);
    }
  };

  getUserRoles = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.param('userId'), 'userId');
      const roles = await this.userService.getUserRoles(userId);
      return c.json(roles);
    } catch (error) {
      console.error('Error getting user roles:', error);
      if (error instanceof Error && error.message.startsWith('Invalid userId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get user roles' }, 500);
    }
  };

  getUserRolesWithDetails = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.param('userId'), 'userId');
      const roles = await this.userService.getUserRolesWithDetails(userId);
      return c.json(roles);
    } catch (error) {
      console.error('Error getting user roles with details:', error);
      if (error instanceof Error && error.message.startsWith('Invalid userId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get user roles with details' }, 500);
    }
  };
} 