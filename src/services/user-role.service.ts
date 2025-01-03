import { BaseService } from './base.service.js';
import { IUserRole } from '../types/models.js';
import { Pool } from 'pg';

export class UserRoleService extends BaseService<IUserRole> {
  protected tableName = 'user_role';

  constructor(pool: Pool) {
    super(pool);
  }

  async findAll(): Promise<any[]> {
    const query = `
      SELECT ur.*, u.username, r.name as role_name,
             ur.last_updated_at as assigned_at,
             ur.last_updated_by as assigned_by
      FROM ${this.schema}.${this.tableName} ur
      JOIN ${this.schema}.user u ON ur.user_id = u.id
      JOIN ${this.schema}.role r ON ur.role_id = r.id
    `;
    const result = await this.executeQuery(query);
    return result.rows;
  }

  async findById(id: number): Promise<any | null> {
    const query = `
      SELECT ur.*, u.username, r.name as role_name,
             ur.last_updated_at as assigned_at,
             ur.last_updated_by as assigned_by
      FROM ${this.schema}.${this.tableName} ur
      JOIN ${this.schema}.user u ON ur.user_id = u.id
      JOIN ${this.schema}.role r ON ur.role_id = r.id
      WHERE ur.id = $1
    `;
    const result = await this.executeQuery(query, [id]);
    return result.rows[0] || null;
  }

  async findByUserId(userId: number): Promise<any[]> {
    const query = `
      SELECT ur.*, u.username, r.name as role_name, r.description as role_description,
             ur.last_updated_at as assigned_at,
             ur.last_updated_by as assigned_by
      FROM ${this.schema}.${this.tableName} ur
      JOIN ${this.schema}.user u ON ur.user_id = u.id
      JOIN ${this.schema}.role r ON ur.role_id = r.id
      WHERE ur.user_id = $1
    `;
    const result = await this.executeQuery(query, [userId]);
    return result.rows;
  }

  async findByRoleId(roleId: number): Promise<any[]> {
    const query = `
      SELECT ur.*, u.username, u.email, r.name as role_name,
             ur.last_updated_at as assigned_at,
             ur.last_updated_by as assigned_by
      FROM ${this.schema}.${this.tableName} ur
      JOIN ${this.schema}.user u ON ur.user_id = u.id
      JOIN ${this.schema}.role r ON ur.role_id = r.id
      WHERE ur.role_id = $1
    `;
    const result = await this.executeQuery(query, [roleId]);
    return result.rows;
  }

  async findByUserAndRole(userId: number, roleId: number): Promise<IUserRole | null> {
    const query = `
      SELECT ur.*, u.username, r.name as role_name,
             ur.last_updated_at as assigned_at,
             ur.last_updated_by as assigned_by
      FROM ${this.schema}.${this.tableName} ur
      JOIN ${this.schema}.user u ON ur.user_id = u.id
      JOIN ${this.schema}.role r ON ur.role_id = r.id
      WHERE ur.user_id = $1 AND ur.role_id = $2
    `;
    const result = await this.executeQuery<IUserRole>(query, [userId, roleId]);
    return result.rows[0] || null;
  }

  async isSuperAdmin(userId:number): Promise<boolean> {
    const query = `
      SELECT COUNT(*) as super_admin_count
      FROM ${this.schema}.${this.tableName} ur
      JOIN ${this.schema}.role r ON ur.role_id = r.id
      WHERE ur.user_id = $1 AND r.name = 'super_admin'
    `;
    const result = await this.executeQuery<any>(query, [userId]);
    return result.rows[0].super_admin_count > 0;
  }
}
