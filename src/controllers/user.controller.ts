import { Context } from 'hono';
import { UserService } from '../services/user.service.js';
import { Pool } from 'pg';
import { _isNil } from '../utils/aisLodash.js';

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
      const id = parseInt(c.req.param('id'), 10);
      const user = await this.userService.findById(id);
      
      if (_isNil(user)) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      return c.json(user);
    } catch (error) {
      console.error('Error getting user:', error);
      return c.json({ error: 'Failed to get user' }, 500);
    }
  };

  getUserByUsername = async (c: Context) => {
    try {
      const username = c.req.param('username');
      const user = await this.userService.findByUsername(username);
      
      if (_isNil(user)) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      return c.json(user);
    } catch (error) {
      console.error('Error getting user:', error);
      return c.json({ error: 'Failed to get user' }, 500);
    }
  };

  createUser = async (c: Context) => {
    try {
      const userId = c.get('userId');
      const body = await c.req.json();
      body.last_updated_by = userId;
      const user = await this.userService.create(body);
      return c.json(user, 201);
    } catch (error) {
      console.error('Error creating user:', error);
      return c.json({ error: 'Failed to create user' }, 500);
    }
  };

  updateUser = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');
      const body = await c.req.json();
      body.last_updated_by = userId;
      const user = await this.userService.update(id, body);
      
      if (_isNil(user)) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      return c.json(user);
    } catch (error) {
      console.error('Error updating user:', error);
      return c.json({ error: 'Failed to update user' }, 500);
    }
  };

  deleteUser = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');

      const deleted = await this.userService.delete(id, userId);
      
      if (!deleted) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      return c.json({ message: 'User deleted successfully' });
    } catch (error) {
      console.error('Error deleting user:', error);
      return c.json({ error: 'Failed to delete user' }, 500);
    }
  };

  getUserRoles = async (c: Context) => {
    try {
      const userId = parseInt(c.req.param('id'), 10);
      const user = await this.userService.findById(userId);
      
      if (_isNil(user)) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      const roles = await this.userService.getUserRoles(userId);
      return c.json(roles);
    } catch (error) {
      console.error('Error getting user roles:', error);
      return c.json({ error: 'Failed to get user roles' }, 500);
    }
  };

  getUserRolesWithDetails = async (c: Context) => {
    try {
      const userId = parseInt(c.req.param('id'), 10);
      const user = await this.userService.findById(userId);
      
      if (_isNil(user)) {
        return c.json({ error: 'User not found' }, 404);
      }
      
      const roles = await this.userService.getUserRolesWithDetails(userId);
      return c.json(roles);
    } catch (error) {
      console.error('Error getting user roles:', error);
      return c.json({ error: 'Failed to get user roles' }, 500);
    }
  };
} 