import { Context } from 'hono';
import { ResourceService } from '../services/resource.service.js';
import { Pool } from 'pg';
import { _isNil } from '../utils/aisLodash.js';

export class ResourceController {
  private resourceService: ResourceService;

  constructor(pool: Pool) {
    this.resourceService = new ResourceService(pool);
  }

  getResources = async (c: Context) => {
    try {
      const resources = await this.resourceService.findAll();
      return c.json(resources);
    } catch (error) {
      console.error('Error getting resources:', error);
      return c.json({ error: 'Failed to get resources' }, 500);
    }
  };

  getResourceById = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const resource = await this.resourceService.findById(id);
      
      if (_isNil(resource)) {
        return c.json({ error: 'Resource not found' }, 404);
      }
      
      return c.json(resource);
    } catch (error) {
      console.error('Error getting resource:', error);
      return c.json({ error: 'Failed to get resource' }, 500);
    }
  };

  getResourceByName = async (c: Context) => {
    try {
      const name = c.req.param('name');
      const resource = await this.resourceService.findByName(name);
      
      if (_isNil(resource)) {
        return c.json({ error: 'Resource not found' }, 404);
      }
      
      return c.json(resource);
    } catch (error) {
      console.error('Error getting resource:', error);
      return c.json({ error: 'Failed to get resource' }, 500);
    }
  };

  createResource = async (c: Context) => {
    try {
      const userId = c.get('userId');
      const body = await c.req.json();
      if (body.parent_id) {
        body.parent_id = parseInt(body.parent_id.toString(), 10);
      }
      body.last_updated_by = userId;
      const resource = await this.resourceService.create(body);
      return c.json(resource, 201);
    } catch (error) {
      console.error('Error creating resource:', error);
      return c.json({ error: 'Failed to create resource' }, 500);
    }
  };

  updateResource = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');
      const body = await c.req.json();
      if (body.parent_id) {
        body.parent_id = parseInt(body.parent_id.toString(), 10);
      }
      body.last_updated_by = userId;
      const resource = await this.resourceService.update(id, body);
      
      if (_isNil(resource)) {
        return c.json({ error: 'Resource not found' }, 404);
      }
      
      return c.json(resource);
    } catch (error) {
      console.error('Error updating resource:', error);
      return c.json({ error: 'Failed to update resource' }, 500);
    }
  };

  deleteResource = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');

      const success = await this.resourceService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Resource not found' }, 404);
      }
      
      return c.json({ message: 'Resource deleted successfully' });
    } catch (error) {
      console.error('Error deleting resource:', error);
      return c.json({ error: 'Failed to delete resource' }, 500);
    }
  };
} 