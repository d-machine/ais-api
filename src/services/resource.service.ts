import { Pool } from 'pg';
import { Resource } from '../types/models.js';
import { ResourceHierarchyService } from './resource-hierarchy.service.js';
import { _isNil } from '../utils/aisLodash.js';

export class ResourceService {
  private pool: Pool;
  private resourceHierarchyService: ResourceHierarchyService;

  constructor(pool: Pool) {
    this.pool = pool;
    this.resourceHierarchyService = new ResourceHierarchyService(pool);
  }

  async findAll(): Promise<Resource[]> {
    const result = await this.pool.query(
      'SELECT * FROM administration.resource_current'
    );
    return result.rows;
  }

  async findById(id: number): Promise<Resource | null> {
    const result = await this.pool.query(
      'SELECT * FROM administration.resource_current WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async findByName(name: string): Promise<Resource | null> {
    const result = await this.pool.query(
      'SELECT * FROM administration.resource_current WHERE name = $1',
      [name]
    );
    return result.rows[0] || null;
  }

  async create(resource: Partial<Resource>): Promise<Resource> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Create the resource
      const result = await client.query(
        'INSERT INTO administration.resource (name, description, last_updated_by) VALUES ($1, $2, $3) RETURNING *',
        [resource.name, resource.description, resource.last_updated_by]
      );
      const newResource = result.rows[0];

      // Add to hierarchy if parent_id is provided
      if (!_isNil(resource.parent_id) && typeof resource.last_updated_by === 'number') {
        await this.resourceHierarchyService.addResourceToHierarchy(
          newResource.id,
          resource.parent_id,
          resource.last_updated_by
        );
      }

      await client.query('COMMIT');
      return newResource;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async update(id: number, resource: Partial<Resource>): Promise<Resource | null> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const currentResource = await this.findById(id);
      if (!currentResource) {
        return null;
      }

      // Get current parent_id from hierarchy
      const currentParent = await this.resourceHierarchyService.getParent(id);
      const currentParentId = currentParent?.ancestor_id;

      // Update the resource
      const result = await client.query(
        'UPDATE administration.resource SET name = $1, description = $2, last_updated_by = $3 WHERE id = $4 RETURNING *',
        [
          resource.name || currentResource.name,
          resource.description || currentResource.description,
          resource.last_updated_by,
          id
        ]
      );
      const updatedResource = result.rows[0];

      // Update hierarchy if parent_id has changed
      if (!_isNil(resource.parent_id) && resource.parent_id !== currentParentId && typeof resource.last_updated_by === 'number') {
        await this.resourceHierarchyService.updateResourceParent(
          id,
          resource.parent_id,
          resource.last_updated_by
        );
      }

      await client.query('COMMIT');
      return updatedResource;
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

      // Delete the resource hierarchy first
      await this.resourceHierarchyService.deleteResourceHierarchy(id, userId);

      // Delete the resource
      const result = await client.query(
        'DELETE FROM administration.resource WHERE id = $1 RETURNING id',
        [id]
      );

      await client.query('COMMIT');
      return result.rowCount ? result.rowCount > 0 : false;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getResourceHierarchy(userId: number): Promise<any> {
    return this.resourceHierarchyService.getResourceHierarchy(userId);
  }
} 