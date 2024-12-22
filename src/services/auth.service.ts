import { BaseService } from './base.service.js';
import { Pool } from 'pg';
import jwt from 'jsonwebtoken';
import { RefreshToken, User } from '../types/models.js';
import { UserService } from './user.service.js';
import { _get, _isNil } from '../utils/aisLodash.js';

export class AuthService extends BaseService<RefreshToken> {
  protected tableName = 'refresh_token';
  private userService: UserService;
  private readonly ACCESS_TOKEN_SECRET: string;
  private readonly REFRESH_TOKEN_SECRET: string;
  private readonly ACCESS_TOKEN_EXPIRY: string = '1d';  // 1 day
  private readonly REFRESH_TOKEN_EXPIRY: string = '30d'; // 30 days

  constructor(pool: Pool) {
    super(pool);
    this.userService = new UserService(pool);
    
    // Get secrets from environment variables
    this.ACCESS_TOKEN_SECRET = process.env.ACCESS_TOKEN_SECRET || 'access_secret';
    this.REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || 'refresh_secret';
  }

  /**
   * Override create method to prevent direct creation
   */
  async create(data: Partial<RefreshToken>): Promise<RefreshToken> {
    throw new Error('Use login or refresh methods to create tokens');
  }

  /**
   * Override update method to prevent direct updates
   */
  async update(id: number, data: Partial<RefreshToken>): Promise<RefreshToken | null> {
    throw new Error('Refresh tokens cannot be updated');
  }

  /**
   * Override delete method to use custom logout logic
   */
  async delete(id: number, userId: number): Promise<boolean> {
    throw new Error('Use logout method to delete refresh tokens');
  }

  /**
   * Authenticate user and generate tokens
   */
  async login(username: string, password: string): Promise<{ accessToken: string; refreshToken: string } | null> {
    // Find user by username
    const user = await this.userService.findByUsername(username);
    if (_isNil(user)) {
      return null;
    }

    // Validate password
    const isValid = await this.userService.validatePassword(user, password);
    if (!isValid) {
      return null;
    }

    // Generate tokens
    return this.generateTokens(user);
  }

  /**
   * Generate new access token using refresh token
   */
  async refresh(refreshToken: string): Promise<{ accessToken: string; refreshToken: string } | null> {
    try {
      // Verify refresh token
      const decoded = jwt.verify(refreshToken, this.REFRESH_TOKEN_SECRET) as { userId: number };
      
      // Check if refresh token exists in database and is valid
      const storedToken = await this.findValidRefreshToken(decoded.userId, refreshToken);
      if (_isNil(storedToken)) {
        return null;
      }

      // Get user
      const user = await this.userService.findById(decoded.userId);
      if (_isNil(user)) {
        return null;
      }

      // Generate new tokens
      return this.generateTokens(user);
    } catch (error) {
      return null;
    }
  }

  /**
   * Revoke refresh token
   */
  async logout(userId: number, refreshToken: string, updatedBy: number): Promise<boolean> {
    try {
      const query = `
        DELETE FROM ${this.schema}.${this.tableName}
        WHERE user_id = $1 AND token = $2
        RETURNING id
      `;
      const result = await this.executeQuery(query, [userId, refreshToken]);
      return result.rowCount ? result.rowCount > 0 : false;
    } catch (error) {
      console.error('Error during logout:', error);
      return false;
    }
  }

  /**
   * Generate both access and refresh tokens
   */
  private async generateTokens(user: User): Promise<{ accessToken: string; refreshToken: string }> {
    // Generate access token with numeric user ID
    const accessToken = jwt.sign(
      { userId: user.id },
      this.ACCESS_TOKEN_SECRET,
      { expiresIn: this.ACCESS_TOKEN_EXPIRY }
    );

    // Generate refresh token with numeric user ID
    const refreshToken = jwt.sign(
      { userId: user.id },
      this.REFRESH_TOKEN_SECRET,
      { expiresIn: this.REFRESH_TOKEN_EXPIRY }
    );

    // Calculate expiry date for refresh token
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 days from now

    // Store refresh token in database
    await this.storeRefreshToken({
      user_id: user.id,
      token: refreshToken,
      expires_at: expiresAt,
      last_updated_by: user.id
    });

    return { accessToken, refreshToken };
  }

  /**
   * Store refresh token in database
   */
  private async storeRefreshToken(data: Partial<RefreshToken>): Promise<void> {
    const query = `
      INSERT INTO ${this.schema}.${this.tableName}
      (user_id, token, expires_at, last_updated_by)
      VALUES ($1, $2, $3, $4)
    `;
    await this.executeQuery(query, [
      data.user_id,
      data.token,
      data.expires_at,
      data.last_updated_by
    ]);
  }

  /**
   * Find valid refresh token for user
   */
  private async findValidRefreshToken(userId: number, token: string): Promise<RefreshToken | null> {
    const query = `
      SELECT *
      FROM ${this.schema}.${this.tableName}
      WHERE user_id = $1 
        AND token = $2
        AND expires_at > CURRENT_TIMESTAMP
    `;
    const result = await this.executeQuery<RefreshToken>(query, [userId, token]);
    return _get(result, 'rows[0]', null);
  }
} 