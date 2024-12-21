import { BaseService } from './base.service.js';
import { Pool } from 'pg';

export class HierarchyClosureService extends BaseService<any> {
  protected tableName = 'hierarchy_closure';

  constructor(pool: Pool) {
    super(pool);
  }

  /**
   * Creates a self-reference relationship for a user with depth 0
   * This should be called whenever a new user is created
   */
  async createSelfReference(userId: number, updatedBy: number): Promise<void> {
    const query = `
      INSERT INTO ${this.schema}.${this.tableName}
      (ancestor_id, descendant_id, depth, last_updated_by)
      VALUES ($1, $1, 0, $2)
    `;
    await this.executeQuery(query, [userId, updatedBy]);
  }

  /**
   * Creates a hierarchical relationship between a user and their reporting manager
   * This includes:
   * 1. Direct relationship (depth 1) between user and manager
   * 2. Inherited relationships with manager's ancestors
   */
  async createManagerHierarchy(userId: number, managerId: number, updatedBy: number): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Create direct relationship (depth 1) between user and manager
      await client.query(`
        INSERT INTO ${this.schema}.${this.tableName}
        (ancestor_id, descendant_id, depth, last_updated_by)
        VALUES ($1, $2, 1, $3)
      `, [managerId, userId, updatedBy]);

      // Create inherited relationships with manager's ancestors
      await client.query(`
        INSERT INTO ${this.schema}.${this.tableName}
        (ancestor_id, descendant_id, depth, last_updated_by)
        SELECT hc.ancestor_id, $1, hc.depth + 1, $2
        FROM ${this.schema}.${this.tableName} hc
        WHERE hc.descendant_id = $3 AND hc.ancestor_id != hc.descendant_id
      `, [userId, updatedBy, managerId]);

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Updates a user's reporting manager by:
   * 1. Deleting all existing relationships where user is a descendant (depth >= 1)
   * 2. Creating new relationships with the new manager
   */
  async updateManagerHierarchy(userId: number, newManagerId: number | null, updatedBy: number): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Log the deletions to history
      await client.query(`
        INSERT INTO ${this.schema}.hierarchy_closure_history
        (hierarchy_closure_id, ancestor_id, descendant_id, depth, operation, operation_at, operation_by)
        SELECT id, ancestor_id, descendant_id, depth, 'DELETE', NOW(), $1
        FROM ${this.schema}.${this.tableName}
        WHERE descendant_id = $2 AND depth >= 1
      `, [updatedBy, userId]);

      // Delete existing relationships where user is a descendant (depth >= 1)
      await client.query(`
        DELETE FROM ${this.schema}.${this.tableName}
        WHERE descendant_id = $1 AND depth >= 1
      `, [userId]);

      // If new manager is provided, create new relationships
      if (newManagerId) {
        // Create direct relationship with new manager
        await client.query(`
          INSERT INTO ${this.schema}.${this.tableName}
          (ancestor_id, descendant_id, depth, last_updated_by)
          VALUES ($1, $2, 1, $3)
        `, [newManagerId, userId, updatedBy]);

        // Create inherited relationships with new manager's ancestors
        await client.query(`
          INSERT INTO ${this.schema}.${this.tableName}
          (ancestor_id, descendant_id, depth, last_updated_by)
          SELECT hc.ancestor_id, $1, hc.depth + 1, $2
          FROM ${this.schema}.${this.tableName} hc
          WHERE hc.descendant_id = $3 AND hc.ancestor_id != hc.descendant_id
        `, [userId, updatedBy, newManagerId]);
      }

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Deletes all relationships for a user (both as ancestor and descendant)
   * This should be called when a user is deleted
   */
  async deleteUserRelationships(userId: number, updatedBy: number): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Log the deletions to history
      await client.query(`
        INSERT INTO ${this.schema}.hierarchy_closure_history
        (hierarchy_closure_id, ancestor_id, descendant_id, depth, operation, operation_at, operation_by)
        SELECT id, ancestor_id, descendant_id, depth, 'DELETE', NOW(), $1
        FROM ${this.schema}.${this.tableName}
        WHERE ancestor_id = $2 OR descendant_id = $2
      `, [updatedBy, userId]);

      // Delete all relationships where user is either ancestor or descendant
      await client.query(`
        DELETE FROM ${this.schema}.${this.tableName}
        WHERE ancestor_id = $1 OR descendant_id = $1
      `, [userId]);

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getAncestors(resourceId: number): Promise<any[]> {
    const query = `
      SELECT r.*, hc.depth
      FROM ${this.schema}.${this.tableName} hc
      JOIN ${this.schema}.resource r ON hc.ancestor_id = r.id
      WHERE hc.descendant_id = $1 AND hc.depth > 0
      ORDER BY hc.depth ASC
    `;
    const result = await this.executeQuery(query, [resourceId]);
    return result.rows;
  }

  async getDescendants(resourceId: number): Promise<any[]> {
    const query = `
      SELECT r.*, hc.depth
      FROM ${this.schema}.${this.tableName} hc
      JOIN ${this.schema}.resource r ON hc.descendant_id = r.id
      WHERE hc.ancestor_id = $1 AND hc.depth > 0
      ORDER BY hc.depth ASC
    `;
    const result = await this.executeQuery(query, [resourceId]);
    return result.rows;
  }
} 