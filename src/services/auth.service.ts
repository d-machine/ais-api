import { BaseService } from './base.service.js';
import { Pool } from 'pg';
import jwt from 'jsonwebtoken';
import { IRefreshToken, IUser } from '../types/models.js';
import { UserService } from './user.service.js';
import { _forEach, _get, _isNil } from '../utils/aisLodash.js';
import { ResourceService } from './resource.service.js';
// import { ResourceHierarchyService } from './resource-hierarchy.service.js';

export class AuthService extends BaseService<IRefreshToken> {
  protected tableName = 'refresh_token';
  private userService: UserService;
  private resourceService: ResourceService;
  private readonly ACCESS_TOKEN_SECRET: string;
  private readonly REFRESH_TOKEN_SECRET: string;
  private readonly ACCESS_TOKEN_EXPIRY: string = '1d';  // 1 day
  private readonly REFRESH_TOKEN_EXPIRY: string = '30d'; // 30 days

  constructor(pool: Pool) {
    super(pool);
    this.userService = new UserService(pool);
    this.resourceService = new ResourceService(pool);
    
    // Get secrets from environment variables
    this.ACCESS_TOKEN_SECRET = process.env.ACCESS_TOKEN_SECRET || 'access_secret';
    this.REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || 'refresh_secret';
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

    await this.resourceService.generateResourceTree(user.id);

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

      await this.resourceService.generateResourceTree(user.id);

      // Generate new tokens
      return this.generateTokens(user);
    } catch (error) {
      return null;
    }
  }

  /**
   * Revoke refresh token
   */
  async logout(userId: number): Promise<boolean> {

    const query = `SELECT * FROM ${this.schema}.${this.tableName} WHERE userId = $1`;
    const result = await this.pool.query<IRefreshToken>(query, [userId]);
    
    if (result.rowCount === 0) {
      return true;
    }

    _forEach(result.rows, row => this.delete(row.id, userId));

    return true;
  }

  /**
   * Generate both access and refresh tokens
   */
  private async generateTokens(user: IUser): Promise<{ accessToken: string; refreshToken: string }> {
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
      expires_at: expiresAt
    });

    return { accessToken, refreshToken };
  }

  /**
   * Store refresh token in database
   */
  private async storeRefreshToken(data: Partial<IRefreshToken>): Promise<void> {
    const query = `
      INSERT INTO ${this.schema}.${this.tableName}
      (user_id, token, expires_at)
      VALUES ($1, $2, $3)
    `;
    await this.executeQuery(query, [
      data.user_id,
      data.token,
      data.expires_at
    ]);
  }

  /**
   * Find valid refresh token for user
   */
  private async findValidRefreshToken(userId: number, token: string): Promise<IRefreshToken | null> {
    const query = `
      SELECT *
      FROM ${this.schema}.${this.tableName}
      WHERE user_id = $1 
        AND token = $2
        AND expires_at > CURRENT_TIMESTAMP
    `;
    const result = await this.executeQuery<IRefreshToken>(query, [userId, token]);
    return _get(result, 'rows[0]', null);
  }
} 