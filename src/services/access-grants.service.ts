import { BaseService } from './base.service.js';
import { AccessGrant } from '../types/models.js';
import { Pool } from 'pg';

export class AccessGrantsService extends BaseService<AccessGrant> {
  protected tableName = 'access_grants';

  constructor(pool: Pool) {
    super(pool);
  }

  async findAll(): Promise<any[]> {
    const query = `
      SELECT ag.*, 
             u.username as user_username,
             t.username as target_username,
             at.name as access_type_name,
             at.description as access_type_description
      FROM ${this.schema}.${this.tableName} ag
      JOIN ${this.schema}.user u ON ag.user_id = u.id
      JOIN ${this.schema}.user t ON ag.target_id = t.id
      JOIN ${this.schema}.access_type at ON ag.access_type_id = at.id
    `;
    const result = await this.executeQuery(query);
    return result.rows;
  }

  async findById(id: number): Promise<any | null> {
    const query = `
      SELECT ag.*, 
             u.username as user_username,
             t.username as target_username,
             at.name as access_type_name,
             at.description as access_type_description
      FROM ${this.schema}.${this.tableName} ag
      JOIN ${this.schema}.user u ON ag.user_id = u.id
      JOIN ${this.schema}.user t ON ag.target_id = t.id
      JOIN ${this.schema}.access_type at ON ag.access_type_id = at.id
      WHERE ag.id = $1
    `;
    const result = await this.executeQuery(query, [id]);
    return result.rows[0] || null;
  }

  async findByUserId(userId: number): Promise<any[]> {
    const query = `
      SELECT ag.*, 
             u.username as user_username,
             t.username as target_username,
             at.name as access_type_name,
             at.description as access_type_description
      FROM ${this.schema}.${this.tableName} ag
      JOIN ${this.schema}.user u ON ag.user_id = u.id
      JOIN ${this.schema}.user t ON ag.target_id = t.id
      JOIN ${this.schema}.access_type at ON ag.access_type_id = at.id
      WHERE ag.user_id = $1
    `;
    const result = await this.executeQuery(query, [userId]);
    return result.rows;
  }

  async findByTargetId(targetId: number): Promise<any[]> {
    const query = `
      SELECT ag.*, 
             u.username as user_username,
             t.username as target_username,
             at.name as access_type_name,
             at.description as access_type_description
      FROM ${this.schema}.${this.tableName} ag
      JOIN ${this.schema}.user u ON ag.user_id = u.id
      JOIN ${this.schema}.user t ON ag.target_id = t.id
      JOIN ${this.schema}.access_type at ON ag.access_type_id = at.id
      WHERE ag.target_id = $1
    `;
    const result = await this.executeQuery(query, [targetId]);
    return result.rows;
  }

  async findByAccessTypeId(accessTypeId: number): Promise<any[]> {
    const query = `
      SELECT ag.*, 
             u.username as user_username,
             t.username as target_username,
             at.name as access_type_name,
             at.description as access_type_description
      FROM ${this.schema}.${this.tableName} ag
      JOIN ${this.schema}.user u ON ag.user_id = u.id
      JOIN ${this.schema}.user t ON ag.target_id = t.id
      JOIN ${this.schema}.access_type at ON ag.access_type_id = at.id
      WHERE ag.access_type_id = $1
    `;
    const result = await this.executeQuery(query, [accessTypeId]);
    return result.rows;
  }

  async findByUserAndTarget(userId: number, targetId: number): Promise<any[]> {
    const query = `
      SELECT ag.*, 
             u.username as user_username,
             t.username as target_username,
             at.name as access_type_name,
             at.description as access_type_description
      FROM ${this.schema}.${this.tableName} ag
      JOIN ${this.schema}.user u ON ag.user_id = u.id
      JOIN ${this.schema}.user t ON ag.target_id = t.id
      JOIN ${this.schema}.access_type at ON ag.access_type_id = at.id
      WHERE ag.user_id = $1 AND ag.target_id = $2
    `;
    const result = await this.executeQuery(query, [userId, targetId]);
    return result.rows;
  }
} 