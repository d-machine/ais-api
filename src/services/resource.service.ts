import { BaseService } from './base.service.js';
import { Resource } from '../types/models.js';
import { Pool } from 'pg';

export class ResourceService extends BaseService<Resource> {
  protected tableName = 'resource';

  constructor(pool: Pool) {
    super(pool);
  }

  async findByName(name: string): Promise<Resource | null> {
    const query = `
      SELECT * FROM ${this.schema}.${this.tableName}
      WHERE name = $1
    `;
    const result = await this.executeQuery<Resource>(query, [name]);
    return result.rows[0] || null;
  }
} 