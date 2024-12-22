import { Pool } from 'pg';
import { ResourceHierarchyClosure } from '../types/models.js';

export class ResourceHierarchyService {
  private pool: Pool;

  constructor(pool: Pool) {
    this.pool = pool;
  }

  async addResourceToHierarchy(resourceId: number, parentId: number, userId: number): Promise<void> {
    // Add the resource to hierarchy_closure table with all its ancestors
    await this.pool.query(
      `INSERT INTO administration.resource_hierarchy_closure (ancestor_id, descendant_id, depth, last_updated_by)
      SELECT hc.ancestor_id, $1, hc.depth + 1, $3
      FROM administration.resource_hierarchy_closure_current hc
      WHERE hc.descendant_id = $2
      UNION ALL
      SELECT $1, $1, 0, $3;`,
      [resourceId, parentId, userId]
    );
  }

  async getResourceHierarchy(userId: number): Promise<any> {
    // Get all resources that the user has access to through their roles
    const query = `
      WITH user_roles AS (
        SELECT DISTINCT role_id 
        FROM administration.user_role_current 
        WHERE user_id = $1
      ),
      accessible_resources AS (
        SELECT DISTINCT r.id, r.name, r.description, rhc.ancestor_id as parent_id
        FROM administration.resource_current r
        JOIN administration.resource_access_role_current rar ON r.id = rar.resource_id
        JOIN user_roles ur ON rar.role_id = ur.role_id
        JOIN administration.resource_hierarchy_closure_current rhc ON r.id = rhc.descendant_id
        WHERE rhc.depth = 1
      )
      SELECT 
        r.id,
        r.name,
        r.description,
        rhc.ancestor_id as parent_id,
        CASE 
          WHEN ar.id IS NOT NULL THEN true
          ELSE false
        END as has_direct_access
      FROM administration.resource_current r
      JOIN administration.resource_hierarchy_closure_current rhc ON r.id = rhc.descendant_id
      LEFT JOIN accessible_resources ar ON r.id = ar.id
      WHERE rhc.depth = 1
      ORDER BY r.name;
    `;

    const result = await this.pool.query(query, [userId]);
    const resources = result.rows;

    // Convert flat structure to tree
    const buildTree = (parentId: number | null = null): any[] => {
      return resources
        .filter(r => r.parent_id === parentId)
        .map(resource => {
          const children = buildTree(resource.id);
          const hasAccess = resource.has_direct_access || children.some(child => child.hasAccess);
          
          return {
            id: resource.id,
            name: resource.name,
            description: resource.description,
            hasAccess,
            children: children.length > 0 ? children : undefined
          };
        });
    };

    return buildTree();
  }

  async getAncestors(resourceId: number): Promise<ResourceHierarchyClosure[]> {
    const result = await this.pool.query(
      `SELECT hc.*, r.name as ancestor_name
       FROM administration.resource_hierarchy_closure_current hc
       JOIN administration.resource_current r ON hc.ancestor_id = r.id
       WHERE hc.descendant_id = $1 AND hc.depth > 0
       ORDER BY hc.depth`,
      [resourceId]
    );
    return result.rows;
  }

  async getDescendants(resourceId: number): Promise<ResourceHierarchyClosure[]> {
    const result = await this.pool.query(
      `SELECT hc.*, r.name as descendant_name
       FROM administration.resource_hierarchy_closure_current hc
       JOIN administration.resource_current r ON hc.descendant_id = r.id
       WHERE hc.ancestor_id = $1 AND hc.depth > 0
       ORDER BY hc.depth`,
      [resourceId]
    );
    return result.rows;
  }

  async getChildren(resourceId: number): Promise<ResourceHierarchyClosure[]> {
    const result = await this.pool.query(
      `SELECT hc.*, r.name as descendant_name
       FROM administration.resource_hierarchy_closure_current hc
       JOIN administration.resource_current r ON hc.descendant_id = r.id
       WHERE hc.ancestor_id = $1 AND hc.depth = 1
       ORDER BY r.name`,
      [resourceId]
    );
    return result.rows;
  }

  async getParent(resourceId: number): Promise<ResourceHierarchyClosure | null> {
    const result = await this.pool.query(
      `SELECT hc.*, r.name as ancestor_name
       FROM administration.resource_hierarchy_closure_current hc
       JOIN administration.resource_current r ON hc.ancestor_id = r.id
       WHERE hc.descendant_id = $1 AND hc.depth = 1`,
      [resourceId]
    );
    return result.rows[0] || null;
  }

  async updateResourceParent(resourceId: number, newParentId: number, userId: number): Promise<void> {
    // Start a transaction
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Delete old hierarchy relationships
      await client.query(
        `DELETE FROM administration.resource_hierarchy_closure
         WHERE descendant_id = $1 AND depth > 0`,
        [resourceId]
      );

      // Add new hierarchy relationships
      await client.query(
        `INSERT INTO administration.resource_hierarchy_closure (ancestor_id, descendant_id, depth, last_updated_by)
         SELECT hc.ancestor_id, $1, hc.depth + 1, $3
         FROM administration.resource_hierarchy_closure_current hc
         WHERE hc.descendant_id = $2`,
        [resourceId, newParentId, userId]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async deleteResourceHierarchy(resourceId: number, userId: number): Promise<void> {
    // Insert into history before deletion
    await this.pool.query(
      `INSERT INTO administration.resource_hierarchy_closure_history (
        resource_hierarchy_closure_id, ancestor_id, descendant_id, depth,
        operation, operation_at, operation_by
      )
      SELECT 
        id, ancestor_id, descendant_id, depth,
        'DELETE', NOW(), $2
      FROM administration.resource_hierarchy_closure
      WHERE descendant_id = $1 OR ancestor_id = $1`,
      [resourceId, userId]
    );

    // Delete the hierarchy relationships
    await this.pool.query(
      `DELETE FROM administration.resource_hierarchy_closure
       WHERE descendant_id = $1 OR ancestor_id = $1`,
      [resourceId]
    );
  }
} 