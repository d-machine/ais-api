import { Context } from 'hono';
import { AccessTypeService } from '../services/access-type.service.js';
import { Pool } from 'pg';
import { _isNil } from '../utils/aisLodash.js';

export class AccessTypeController {
  private accessTypeService: AccessTypeService;

  constructor(pool: Pool) {
    this.accessTypeService = new AccessTypeService(pool);
  }

  getAccessTypes = async (c: Context) => {
    try {
      const accessTypes = await this.accessTypeService.findAll();
      return c.json(accessTypes);
    } catch (error) {
      console.error('Error getting access types:', error);
      return c.json({ error: 'Failed to get access types' }, 500);
    }
  };

  getAccessTypeById = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const accessType = await this.accessTypeService.findById(id);
      
      if (_isNil(accessType)) {
        return c.json({ error: 'Access type not found' }, 404);
      }
      
      return c.json(accessType);
    } catch (error) {
      console.error('Error getting access type:', error);
      return c.json({ error: 'Failed to get access type' }, 500);
    }
  };

  getAccessTypeByName = async (c: Context) => {
    try {
      const name = c.req.param('name');
      const accessType = await this.accessTypeService.findByName(name);
      
      if (_isNil(accessType)) {
        return c.json({ error: 'Access type not found' }, 404);
      }
      
      return c.json(accessType);
    } catch (error) {
      console.error('Error getting access type:', error);
      return c.json({ error: 'Failed to get access type' }, 500);
    }
  };

  createAccessType = async (c: Context) => {
    try {
      const userId = c.get('userId');
      const body = await c.req.json();
      body.last_updated_by = userId;
      const accessType = await this.accessTypeService.create(body);
      return c.json(accessType, 201);
    } catch (error) {
      console.error('Error creating access type:', error);
      return c.json({ error: 'Failed to create access type' }, 500);
    }
  };

  updateAccessType = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');
      const body = await c.req.json();
      body.last_updated_by = userId;
      const accessType = await this.accessTypeService.update(id, body);
      
      if (_isNil(accessType)) {
        return c.json({ error: 'Access type not found' }, 404);
      }
      
      return c.json(accessType);
    } catch (error) {
      console.error('Error updating access type:', error);
      return c.json({ error: 'Failed to update access type' }, 500);
    }
  };

  deleteAccessType = async (c: Context) => {
    try {
      const id = parseInt(c.req.param('id'), 10);
      const userId = c.get('userId');

      const success = await this.accessTypeService.delete(id, userId);
      
      if (!success) {
        return c.json({ error: 'Access type not found' }, 404);
      }
      
      return c.json({ message: 'Access type deleted successfully' });
    } catch (error) {
      console.error('Error deleting access type:', error);
      return c.json({ error: 'Failed to delete access type' }, 500);
    }
  };
} 