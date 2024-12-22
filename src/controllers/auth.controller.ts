import { Context } from 'hono';
import { AuthService } from '../services/auth.service.js';
import { Pool } from 'pg';
import { _isEmpty, _isNil } from '../utils/aisLodash.js';

export class AuthController {
  private authService: AuthService;

  constructor(pool: Pool) {
    this.authService = new AuthService(pool);
  }

  login = async (c: Context) => {
    try {
      const { username, password } = await c.req.json();

      if (_isEmpty(username) || _isEmpty(password)) {
        return c.json({ error: 'Username and password are required' }, 400);
      }

      const tokens = await this.authService.login(username, password);
      
      if (_isNil(tokens)) {
        return c.json({ error: 'Invalid username or password' }, 401);
      }
      
      return c.json(tokens);
    } catch (error) {
      console.error('Error during login:', error);
      return c.json({ error: 'Failed to login' }, 500);
    }
  };

  refresh = async (c: Context) => {
    try {
      const refreshToken = c.req.header('X-Refresh-Token');
      
      if (_isNil(refreshToken)) {
        return c.json({ error: 'Refresh token is required' }, 400);
      }

      const tokens = await this.authService.refresh(refreshToken);
      
      if (_isNil(tokens)) {
        return c.json({ error: 'Invalid or expired refresh token' }, 401);
      }
      
      return c.json(tokens);
    } catch (error) {
      console.error('Error during token refresh:', error);
      return c.json({ error: 'Failed to refresh token' }, 500);
    }
  };

  logout = async (c: Context) => {
    try {
      const userId = c.get('userId');
      const refreshToken = c.req.header('X-Refresh-Token');
      
      if (_isNil(refreshToken)) {
        return c.json({ error: 'Refresh token is required' }, 400);
      }

      const success = await this.authService.logout(userId, refreshToken, userId);
      
      if (!success) {
        return c.json({ error: 'Failed to logout' }, 400);
      }
      
      return c.json({ message: 'Logged out successfully' });
    } catch (error) {
      console.error('Error during logout:', error);
      return c.json({ error: 'Failed to logout' }, 500);
    }
  };
} 