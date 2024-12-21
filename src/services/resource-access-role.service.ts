import { BaseService } from './base.service.js';
import { ResourceAccessRole } from '../types/models.js';
import { Pool } from 'pg';

export class ResourceAccessRoleService extends BaseService<ResourceAccessRole> {
  protected tableName = 'resource_access_role';

  constructor(pool: Pool) {
    super(pool);
  }

  async findAll(): Promise<any[]> {
    const query = `
      SELECT rar.*, 
             r.name as resource_name,
             r.description as resource_description,
             at.name as access_type_name,
             at.description as access_type_description,
             ro.name as role_name,
             ro.description as role_description
      FROM ${this.schema}.${this.tableName} rar
      JOIN ${this.schema}.resource r ON rar.resource_id = r.id
      JOIN ${this.schema}.access_type at ON rar.access_type_id = at.id
      JOIN ${this.schema}.role ro ON rar.role_id = ro.id
    `;
    const result = await this.executeQuery(query);
    return result.rows;
  }

  async findById(id: number): Promise<any | null> {
    const query = `
      SELECT rar.*, 
             r.name as resource_name,
             r.description as resource_description,
             at.name as access_type_name,
             at.description as access_type_description,
             ro.name as role_name,
             ro.description as role_description
      FROM ${this.schema}.${this.tableName} rar
      JOIN ${this.schema}.resource r ON rar.resource_id = r.id
      JOIN ${this.schema}.access_type at ON rar.access_type_id = at.id
      JOIN ${this.schema}.role ro ON rar.role_id = ro.id
      WHERE rar.id = $1
    `;
    const result = await this.executeQuery(query, [id]);
    return result.rows[0] || null;
  }

  async findByResourceId(resourceId: number): Promise<any[]> {
    const query = `
      SELECT rar.*, 
             r.name as resource_name,
             r.description as resource_description,
             at.name as access_type_name,
             at.description as access_type_description,
             ro.name as role_name,
             ro.description as role_description
      FROM ${this.schema}.${this.tableName} rar
      JOIN ${this.schema}.resource r ON rar.resource_id = r.id
      JOIN ${this.schema}.access_type at ON rar.access_type_id = at.id
      JOIN ${this.schema}.role ro ON rar.role_id = ro.id
      WHERE rar.resource_id = $1
    `;
    const result = await this.executeQuery(query, [resourceId]);
    return result.rows;
  }

  async findByRoleId(roleId: number): Promise<any[]> {
    const query = `
      SELECT rar.*, 
             r.name as resource_name,
             r.description as resource_description,
             at.name as access_type_name,
             at.description as access_type_description,
             ro.name as role_name,
             ro.description as role_description
      FROM ${this.schema}.${this.tableName} rar
      JOIN ${this.schema}.resource r ON rar.resource_id = r.id
      JOIN ${this.schema}.access_type at ON rar.access_type_id = at.id
      JOIN ${this.schema}.role ro ON rar.role_id = ro.id
      WHERE rar.role_id = $1
    `;
    const result = await this.executeQuery(query, [roleId]);
    return result.rows;
  }

  async findByAccessTypeId(accessTypeId: number): Promise<any[]> {
    const query = `
      SELECT rar.*, 
             r.name as resource_name,
             r.description as resource_description,
             at.name as access_type_name,
             at.description as access_type_description,
             ro.name as role_name,
             ro.description as role_description
      FROM ${this.schema}.${this.tableName} rar
      JOIN ${this.schema}.resource r ON rar.resource_id = r.id
      JOIN ${this.schema}.access_type at ON rar.access_type_id = at.id
      JOIN ${this.schema}.role ro ON rar.role_id = ro.id
      WHERE rar.access_type_id = $1
    `;
    const result = await this.executeQuery(query, [accessTypeId]);
    return result.rows;
  }

  async findByResourceAndRole(resourceId: number, roleId: number): Promise<any[]> {
    const query = `
      SELECT rar.*, 
             r.name as resource_name,
             r.description as resource_description,
             at.name as access_type_name,
             at.description as access_type_description,
             ro.name as role_name,
             ro.description as role_description
      FROM ${this.schema}.${this.tableName} rar
      JOIN ${this.schema}.resource r ON rar.resource_id = r.id
      JOIN ${this.schema}.access_type at ON rar.access_type_id = at.id
      JOIN ${this.schema}.role ro ON rar.role_id = ro.id
      WHERE rar.resource_id = $1 AND rar.role_id = $2
    `;
    const result = await this.executeQuery(query, [resourceId, roleId]);
    return result.rows;
  }
} 