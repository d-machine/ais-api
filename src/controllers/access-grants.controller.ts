import { Context } from 'hono';
import { AccessGrantsService } from '../services/access-grants.service.js';
import { Pool } from 'pg';
import { _isNil } from '../utils/aisLodash.js';

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
      const id = parseInt(c.req.param('id'), 10);
      const accessGrant = await this.accessGrantsService.findById(id);
      
      if (_isNil(accessGrant)) {
        return c.json({ error: 'Access grant not found' }, 404);
      }
      
      return c.json(accessGrant);
    } catch (error) {
      console.error('Error getting access grant:', error);
      return c.json({ error: 'Failed to get access grant' }, 500);
    }
  };

  getAccessGrantsByUserId = async (c: Context) => {
    try {
      const userId = parseInt(c.req.param('userId'), 10);
      const accessGrants = await this.accessGrantsService.findByUserId(userId);
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  getAccessGrantsByTargetId = async (c: Context) => {
    try {
      const targetId = parseInt(c.req.param('targetId'), 10);
      const accessGrants = await this.accessGrantsService.findByTargetId(targetId);
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  getAccessGrantsByAccessTypeId = async (c: Context) => {
    try {
      const accessTypeId = parseInt(c.req.param('accessTypeId'), 10);
      const accessGrants = await this.accessGrantsService.findByAccessTypeId(accessTypeId);
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  getAccessGrantsByUserAndTarget = async (c: Context) => {
    try {
      const userId = parseInt(c.req.param('userId'), 10);
      const targetId = parseInt(c.req.param('targetId'), 10);
      const accessGrants = await this.accessGrantsService.findByUserAndTarget(userId, targetId);
      return c.json(accessGrants);
    } catch (error) {
      console.error('Error getting access grants:', error);
      return c.json({ error: 'Failed to get access grants' }, 500);
    }
  };

  createAccessGrant = async (c: Context) => {
    try {
      const userId = c.get('userId');
      const body = await c.req.json();
      body.user_id = parseInt(body.user_id.toString(), 10);
      body.target_id = parseInt(body.target_id.toString(), 10);
      body.access_type_id = parseInt(body.access_type_id.toString(), 10);
      body.last_updated_by = userId;
      const accessGrant = await this.accessGrantsService.create(body);
      return c.json(accessGrant, 201);
    } catch (error) {
      console.error('Error creating access grant:', error);
      return c.json({ error: 'Failed to create access grant' }, 500);
    }
  };

  updateAccessGrant = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');
      const body = await c.req.json();
      if (body.user_id) {
        body.user_id = parseInt(body.user_id.toString(), 10);
      }
      if (body.target_id) {
        body.target_id = parseInt(body.target_id.toString(), 10);
      }
      if (body.access_type_id) {
        body.access_type_id = parseInt(body.access_type_id.toString(), 10);
      }
      body.last_updated_by = userId;
      const accessGrant = await this.accessGrantsService.update(id, body);
      
      if (_isNil(accessGrant)) {
        return c.json({ error: 'Access grant not found' }, 404);
      }
      
      return c.json(accessGrant);
    } catch (error) {
      console.error('Error updating access grant:', error);
      return c.json({ error: 'Failed to update access grant' }, 500);
    }
  };

  deleteAccessGrant = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');
      
      const success = await this.accessGrantsService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Access grant not found' }, 404);
      }
      
      return c.json({ message: 'Access grant deleted successfully' });
    } catch (error) {
      console.error('Error deleting access grant:', error);
      return c.json({ error: 'Failed to delete access grant' }, 500);
    }
  };
} 