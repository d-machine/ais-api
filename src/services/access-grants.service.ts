import { Pool } from 'pg';
import { AccessGrant } from '../types/models.js';

export class AccessGrantsService {
  private pool: Pool;

  constructor(pool: Pool) {
    this.pool = pool;
  }

  async findAll(): Promise<AccessGrant[]> {
    const result = await this.pool.query(
      'SELECT * FROM administration.access_grants_current'
    );
    return result.rows;
  }

  async findById(id: number): Promise<AccessGrant | null> {
    const result = await this.pool.query(
      'SELECT * FROM administration.access_grants_current WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async findByUserId(userId: number): Promise<AccessGrant[]> {
    const result = await this.pool.query(
      'SELECT * FROM administration.access_grants_current WHERE user_id = $1',
      [userId]
    );
    return result.rows;
  }

  async findByTargetId(targetId: number): Promise<AccessGrant[]> {
    const result = await this.pool.query(
      'SELECT * FROM administration.access_grants_current WHERE target_id = $1',
      [targetId]
    );
    return result.rows;
  }

  async findByAccessTypeId(accessTypeId: number): Promise<AccessGrant[]> {
    const result = await this.pool.query(
      'SELECT * FROM administration.access_grants_current WHERE access_type_id = $1',
      [accessTypeId]
    );
    return result.rows;
  }

  async findByUserAndTarget(userId: number, targetId: number): Promise<AccessGrant[]> {
    const result = await this.pool.query(
      'SELECT * FROM administration.access_grants_current WHERE user_id = $1 AND target_id = $2',
      [userId, targetId]
    );
    return result.rows;
  }

  async create(accessGrant: Partial<AccessGrant>): Promise<AccessGrant> {
    const result = await this.pool.query(
      'INSERT INTO administration.access_grants (user_id, target_id, access_type_id, last_updated_by) VALUES ($1, $2, $3, $4) RETURNING *',
      [accessGrant.user_id, accessGrant.target_id, accessGrant.access_type_id, accessGrant.last_updated_by]
    );
    return result.rows[0];
  }

  async update(id: number, accessGrant: Partial<AccessGrant>): Promise<AccessGrant | null> {
    const currentAccessGrant = await this.findById(id);
    if (!currentAccessGrant) {
      return null;
    }

    const result = await this.pool.query(
      'UPDATE administration.access_grants SET user_id = $1, target_id = $2, access_type_id = $3, last_updated_by = $4 WHERE id = $5 RETURNING *',
      [
        accessGrant.user_id || currentAccessGrant.user_id,
        accessGrant.target_id || currentAccessGrant.target_id,
        accessGrant.access_type_id || currentAccessGrant.access_type_id,
        accessGrant.last_updated_by,
        id
      ]
    );
    return result.rows[0];
  }

  async delete(id: number, userId: number): Promise<boolean> {
    const result = await this.pool.query(
      'UPDATE administration.access_grants SET deleted_at = CURRENT_TIMESTAMP, last_updated_by = $1 WHERE id = $2 AND deleted_at IS NULL RETURNING id',
      [userId, id]
    );
    return result.rowCount ? result.rowCount > 0 : false;
  }
} 