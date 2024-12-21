import { BaseService } from './base.service.js';
import { AccessType } from '../types/models.js';
import { Pool } from 'pg';

export class AccessTypeService extends BaseService<AccessType> {
  protected tableName = 'access_type';

  constructor(pool: Pool) {
    super(pool);
  }

  async findByName(name: string): Promise<AccessType | null> {
    const query = `
      SELECT * FROM ${this.schema}.${this.tableName}
      WHERE name = $1
    `;
    const result = await this.executeQuery<AccessType>(query, [name]);
    return result.rows[0] || null;
  }
} 