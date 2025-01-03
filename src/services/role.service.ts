import { BaseService } from './base.service.js';
import { IRole } from '../types/models.js';
import { Pool } from 'pg';

export class RoleService extends BaseService<IRole> {
  protected tableName = 'role';

  constructor(pool: Pool) {
    super(pool);
  }

  async findByName(name: string): Promise<IRole | null> {
    const query = `SELECT * FROM ${this.schema}.${this.tableName} WHERE name = $1`;
    const result = await this.executeQuery<IRole>(query, [name]);
    return result.rows[0] || null;
  }

  async getRoleUsers(roleId: number): Promise<any[]> {
    const query = `
      SELECT u.id, u.username, u.email, u.first_name, u.last_name,
             u.last_updated_at, u.last_updated_by,
             ur.last_updated_at as role_assigned_at,
             ur.last_updated_by as role_assigned_by
      FROM ${this.schema}.user u
      JOIN ${this.schema}.user_role ur ON u.id = ur.user_id
      WHERE ur.role_id = $1
    `;
    const result = await this.executeQuery(query, [roleId]);
    return result.rows;
  }

  async getRoleUsersWithDetails(roleId: number): Promise<any[]> {
    const query = `
      SELECT ur.id, ur.user_id, ur.role_id,
             ur.last_updated_at as role_assigned_at,
             ur.last_updated_by as role_assigned_by,
             u.username, u.email, u.first_name, u.last_name,
             u.last_updated_at as user_updated_at,
             u.last_updated_by as user_updated_by,
             r.name as role_name, r.description as role_description,
             r.last_updated_at as role_updated_at,
             r.last_updated_by as role_updated_by
      FROM ${this.schema}.user_role ur
      JOIN ${this.schema}.user u ON ur.user_id = u.id
      JOIN ${this.schema}.role r ON ur.role_id = r.id
      WHERE ur.role_id = $1
    `;
    const result = await this.executeQuery(query, [roleId]);
    return result.rows;
  }
} 