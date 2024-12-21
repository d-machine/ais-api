import { Context } from 'hono';
import { ResourceService } from '../services/resource.service.js';
import { Pool } from 'pg';
import { toNumberOrThrow } from '../utils/id-converter.js';

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
      const id = toNumberOrThrow(c.req.param('id'), 'resourceId');
      const resource = await this.resourceService.findById(id);
      
      if (!resource) {
        return c.json({ error: 'Resource not found' }, 404);
      }
      
      return c.json(resource);
    } catch (error) {
      console.error('Error getting resource:', error);
      if (error instanceof Error && error.message.startsWith('Invalid resourceId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get resource' }, 500);
    }
  };

  getResourceByName = async (c: Context) => {
    try {
      const name = c.req.param('name');
      const resource = await this.resourceService.findByName(name);
      
      if (!resource) {
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
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      if (body.parent_id) {
        body.parent_id = toNumberOrThrow(body.parent_id.toString(), 'parentId');
      }
      body.last_updated_by = userId;
      const resource = await this.resourceService.create(body);
      return c.json(resource, 201);
    } catch (error) {
      console.error('Error creating resource:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid parentId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to create resource' }, 500);
    }
  };

  updateResource = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'resourceId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      if (body.parent_id) {
        body.parent_id = toNumberOrThrow(body.parent_id.toString(), 'parentId');
      }
      body.last_updated_by = userId;
      const resource = await this.resourceService.update(id, body);
      
      if (!resource) {
        return c.json({ error: 'Resource not found' }, 404);
      }
      
      return c.json(resource);
    } catch (error) {
      console.error('Error updating resource:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid resourceId') ||
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid parentId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to update resource' }, 500);
    }
  };

  deleteResource = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'resourceId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');

      const success = await this.resourceService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Resource not found' }, 404);
      }
      
      return c.json({ message: 'Resource deleted successfully' });
    } catch (error) {
      console.error('Error deleting resource:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid resourceId') ||
        error.message.startsWith('Invalid X-User-ID')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to delete resource' }, 500);
    }
  };
} 