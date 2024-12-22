import { BaseService } from './base.service.js';
import { User } from '../types/models.js';
import { Pool } from 'pg';
import bcrypt from 'bcrypt';
import { HierarchyClosureService } from './hierarchy-closure.service.js';
import { _get, _isEmpty, _isNil } from '../utils/aisLodash.js';

export class UserService extends BaseService<User> {
  protected tableName = 'user';
  private hierarchyClosureService: HierarchyClosureService;

  constructor(pool: Pool) {
    super(pool);
    this.hierarchyClosureService = new HierarchyClosureService(pool);
  }

  async create(data: Partial<User>): Promise<User> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Hash password if provided
      if (!_isNil(data.password)) {
        data.password = await bcrypt.hash(data.password, 10);
      }

      // Create the user
      const result = await super.create(data);

      // Create self-reference in hierarchy
      if (typeof data.last_updated_by === 'number') {
        await this.hierarchyClosureService.createSelfReference(result.id, data.last_updated_by);

        // If reporting manager is provided in the request body, create hierarchy relationships
        if (!_isNil(data.reporting_manager_id)) {
          await this.hierarchyClosureService.createManagerHierarchy(
            result.id,
            data.reporting_manager_id,
            data.last_updated_by
          );
        }
      }

      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async update(id: number, data: Partial<User>): Promise<User | null> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Get current reporting manager from hierarchy closure
      const query = `
        SELECT ancestor_id as reporting_manager_id
        FROM ${this.schema}.hierarchy_closure
        WHERE descendant_id = $1 AND depth = 1
      `;
      const result = await this.executeQuery<{ reporting_manager_id: number }>(query, [id]);
      const currentReportingManagerId = _get(result, 'rows[0].reporting_manager_id', null);

      const reportingManagerChanged = !_isNil(data.reporting_manager_id) &&
        currentReportingManagerId !== data.reporting_manager_id;

      // Hash password if provided
      if (!_isNil(data.password)) {
        data.password = await bcrypt.hash(data.password, 10);
      }

      // Update user data
      const updatedUser = await super.update(id, data);

      // If reporting manager has changed and last_updated_by is provided, update hierarchy
      if (reportingManagerChanged && updatedUser && typeof data.last_updated_by === 'number') {
        await this.hierarchyClosureService.updateManagerHierarchy(
          id,
          data.reporting_manager_id || null,
          data.last_updated_by
        );
      }

      await client.query('COMMIT');
      return updatedUser;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async delete(id: number, userId: number): Promise<boolean> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const user = await this.findById(id);
      if (!user) {
        return false;
      }

      // Delete hierarchy relationships first
      await this.hierarchyClosureService.deleteUserRelationships(id, userId);

      // Then delete the user
      const deleted = await super.delete(id, userId);

      await client.query('COMMIT');
      return deleted;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async findByEmail(email: string): Promise<User | null> {
    const query = `
      SELECT * FROM ${this.schema}.${this.tableName}
      WHERE email = $1
    `;
    const result = await this.executeQuery<User>(query, [email]);
    return result.rows[0] || null;
  }

  async findByUsername(username: string): Promise<User | null> {
    const query = `
      SELECT * FROM ${this.schema}.${this.tableName}
      WHERE username = $1
    `;
    const result = await this.executeQuery<User>(query, [username]);
    return result.rows[0] || null;
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.password);
  }

  async getUserRoles(userId: number): Promise<any[]> {
    const query = `
      SELECT r.id, r.name, r.description, r.team, r.department,
             r.last_updated_at, r.last_updated_by,
             ur.last_updated_at as role_assigned_at,
             ur.last_updated_by as role_assigned_by
      FROM ${this.schema}.role r
      JOIN ${this.schema}.user_role ur ON r.id = ur.role_id
      WHERE ur.user_id = $1
    `;
    const result = await this.executeQuery(query, [userId]);
    return result.rows;
  }

  async getUserRolesWithDetails(userId: number): Promise<any[]> {
    const query = `
      SELECT ur.id, ur.user_id, ur.role_id, 
             ur.last_updated_at as role_assigned_at,
             ur.last_updated_by as role_assigned_by,
             u.username, u.email, u.first_name, u.last_name,
             r.name as role_name, r.description as role_description,
             r.team, r.department,
             r.last_updated_at as role_updated_at,
             r.last_updated_by as role_updated_by
      FROM ${this.schema}.user_role ur
      JOIN ${this.schema}.user u ON ur.user_id = u.id
      JOIN ${this.schema}.role r ON ur.role_id = r.id
      WHERE ur.user_id = $1
    `;
    const result = await this.executeQuery(query, [userId]);
    return result.rows;
  }
} 