import { Context } from 'hono';
import { AccessGrantsService } from '../services/access-grants.service.js';
import { Pool } from 'pg';
import { toNumberOrThrow } from '../utils/id-converter.js';

export class AccessGrantsController {
  private accessGrantsService: AccessGrantsService;

  constructor(pool: Pool) {
    this.accessGrantsService = new AccessGrantsService(pool);
  }

  getAccessGrants = async (c: Context) => {
    try {
      const accessGrants = await this.accessGrantsService.findAll();
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  getAccessGrantById = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'accessGrantId');
      const accessGrant = await this.accessGrantsService.findById(id);
      
      if (!accessGrant) {
        return c.json({ error: 'Access grant not found' }, 404);
      }
      
      return c.json(accessGrant);
    } catch (error) {
      console.error('Error getting access grant:', error);
      if (error instanceof Error && error.message.startsWith('Invalid accessGrantId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get access grant' }, 500);
    }
  };

  getAccessGrantsByUserId = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.param('userId'), 'userId');
      const accessGrants = await this.accessGrantsService.findByUserId(userId);
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      if (error instanceof Error && error.message.startsWith('Invalid userId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  getAccessGrantsByTargetId = async (c: Context) => {
    try {
      const targetId = toNumberOrThrow(c.req.param('targetId'), 'targetId');
      const accessGrants = await this.accessGrantsService.findByTargetId(targetId);
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      if (error instanceof Error && error.message.startsWith('Invalid targetId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  getAccessGrantsByAccessTypeId = async (c: Context) => {
    try {
      const accessTypeId = toNumberOrThrow(c.req.param('accessTypeId'), 'accessTypeId');
      const accessGrants = await this.accessGrantsService.findByAccessTypeId(accessTypeId);
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      if (error instanceof Error && error.message.startsWith('Invalid accessTypeId')) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  getAccessGrantsByUserAndTarget = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.param('userId'), 'userId');
      const targetId = toNumberOrThrow(c.req.param('targetId'), 'targetId');
      const accessGrants = await this.accessGrantsService.findByUserAndTarget(userId, targetId);
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid userId') ||
        error.message.startsWith('Invalid targetId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  createAccessGrant = async (c: Context) => {
    try {
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      body.user_id = toNumberOrThrow(body.user_id.toString(), 'userId');
      body.access_type_id = toNumberOrThrow(body.access_type_id.toString(), 'accessTypeId');
      body.resource_id = toNumberOrThrow(body.resource_id.toString(), 'resourceId');
      body.last_updated_by = userId;
      const accessGrant = await this.accessGrantsService.create(body);
      return c.json(accessGrant, 201);
    } catch (error) {
      console.error('Error creating access grant:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid userId') ||
        error.message.startsWith('Invalid accessTypeId') ||
        error.message.startsWith('Invalid resourceId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to create access grant' }, 500);
    }
  };

  updateAccessGrant = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'accessGrantId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');
      const body = await c.req.json();
      if (body.user_id) {
        body.user_id = toNumberOrThrow(body.user_id.toString(), 'userId');
      }
      if (body.access_type_id) {
        body.access_type_id = toNumberOrThrow(body.access_type_id.toString(), 'accessTypeId');
      }
      if (body.resource_id) {
        body.resource_id = toNumberOrThrow(body.resource_id.toString(), 'resourceId');
      }
      body.last_updated_by = userId;
      const accessGrant = await this.accessGrantsService.update(id, body);
      
      if (!accessGrant) {
        return c.json({ error: 'Access grant not found' }, 404);
      }
      
      return c.json(accessGrant);
    } catch (error) {
      console.error('Error updating access grant:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid accessGrantId') ||
        error.message.startsWith('Invalid X-User-ID') ||
        error.message.startsWith('Invalid userId') ||
        error.message.startsWith('Invalid accessTypeId') ||
        error.message.startsWith('Invalid resourceId')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to update access grant' }, 500);
    }
  };

  deleteAccessGrant = async (c: Context) => {
    try {
      const id = toNumberOrThrow(c.req.param('id'), 'accessGrantId');
      const userId = toNumberOrThrow(c.req.header('X-User-ID'), 'X-User-ID');

      const success = await this.accessGrantsService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Access grant not found' }, 404);
      }
      
      return c.json({ message: 'Access grant deleted successfully' });
    } catch (error) {
      console.error('Error deleting access grant:', error);
      if (error instanceof Error && (
        error.message.startsWith('Invalid accessGrantId') ||
        error.message.startsWith('Invalid X-User-ID')
      )) {
        return c.json({ error: error.message }, 400);
      }
      return c.json({ error: 'Failed to delete access grant' }, 500);
    }
  };
} 