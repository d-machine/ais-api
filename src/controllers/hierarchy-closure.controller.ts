import { Context } from 'hono';
import { HierarchyClosureService } from '../services/hierarchy-closure.service.js';
import { Pool } from 'pg';
import { toNumberOrThrow } from '../utils/id-converter.js';

export class HierarchyClosureController {
  private hierarchyClosureService: HierarchyClosureService;

  constructor(pool: Pool) {
    this.hierarchyClosureService = new HierarchyClosureService(pool);
  }

  getHierarchyClosures = async (c: Context) => {
    try {
      const hierarchyClosures = await this.hierarchyClosureService.findAll();
      return c.json(hierarchyClosures);
    } catch (error) {
      console.error('Error getting hierarchy closures:', error);
      return c.json({ error: 'Failed to get hierarchy closures' }, 500);
    }
  };

  getHierarchyClosureById = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'hierarchyClosureId');
      const hierarchyClosure = await this.hierarchyClosureService.findById(id);
      
      if (!hierarchyClosure) {
        return c.json({ error: 'Hierarchy closure not found' }, 404);
      }
      
      return c.json(hierarchyClosure);
    } catch (error) {
      console.error('Error getting hierarchy closure:', error);
      if (error instanceof Error && error.message.startsWith('Invalid hierarchyClosureId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get hierarchy closure' }, 500);
    }
  };

  createHierarchyClosure = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      body.ancestor_id = toNumberOrThrow(body.ancestor_id.toString(), 'ancestorId');
      body.descendant_id = toNumberOrThrow(body.descendant_id.toString(), 'descendantId');
      body.last_updated_by = userId;
      const hierarchyClosure = await this.hierarchyClosureService.create(body);
      return c.json(hierarchyClosure, 201);
    } catch (error) {
      console.error('Error creating hierarchy closure:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid ancestorId') ||
        error.message.startsWith('Invalid descendantId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to create hierarchy closure' }, 500);
    }
  };

  updateHierarchyClosure = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'hierarchyClosureId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      if (body.ancestor_id) {
        body.ancestor_id = toNumberOrThrow(body.ancestor_id.toString(), 'ancestorId');
      }
      if (body.descendant_id) {
        body.descendant_id = toNumberOrThrow(body.descendant_id.toString(), 'descendantId');
      }
      body.last_updated_by = userId;
      const hierarchyClosure = await this.hierarchyClosureService.update(id, body);
      
      if (!hierarchyClosure) {
        return c.json({ error: 'Hierarchy closure not found' }, 404);
      }
      
      return c.json(hierarchyClosure);
    } catch (error) {
      console.error('Error updating hierarchy closure:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid hierarchyClosureId') ||
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid ancestorId') ||
        error.message.startsWith('Invalid descendantId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to update hierarchy closure' }, 500);
    }
  };

  deleteHierarchyClosure = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'hierarchyClosureId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');

      const success = await this.hierarchyClosureService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Hierarchy closure not found' }, 404);
      }
      
      return c.json({ message: 'Hierarchy closure deleted successfully' });
    } catch (error) {
      console.error('Error deleting hierarchy closure:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid hierarchyClosureId') ||
        error.message.startsWith('Invalid X-User-ID')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to delete hierarchy closure' }, 500);
    }
  };

  getAncestors = async (c: Context) => {
    try {
      const resourceId = toNumberOrThrow(c.req.param('resourceId'), 'resourceId');
      const ancestors = await this.hierarchyClosureService.getAncestors(resourceId);
      return c.json(ancestors);
    } catch (error) {
      console.error('Error getting ancestors:', error);
      if (error instanceof Error && error.message.startsWith('Invalid resourceId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get ancestors' }, 500);
    }
  };

  getDescendants = async (c: Context) => {
    try {
      const resourceId = toNumberOrThrow(c.req.param('resourceId'), 'resourceId');
      const descendants = await this.hierarchyClosureService.getDescendants(resourceId);
      return c.json(descendants);
    } catch (error) {
      console.error('Error getting descendants:', error);
      if (error instanceof Error && error.message.startsWith('Invalid resourceId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get descendants' }, 500);
    }
  };
} 