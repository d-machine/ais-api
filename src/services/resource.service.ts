import { Pool } from "pg";
import {
  IAccessibleResource,
  IResource,
  IResourceTreeNode,
} from "../types/models.js";
import {
  _filter,
  _find,
  _findIndex,
  _forEach,
  _has,
  _isEmpty,
  _isNil,
  _map,
} from "../utils/aisLodash.js";
import { BaseService } from "./base.service.js";
import { RedisClientType } from "redis";
import { dbClient } from "../db/dbClient.js";

export class ResourceService extends BaseService<IResource> {
  protected tableName = "resource";
  private redisClient: RedisClientType

  constructor(pool: Pool) {
    super(pool);
    this.redisClient = dbClient.getRedisClient().getClient();
  }

  async findAll(): Promise<IResource[]> {
    const result = await this.pool.query(
      `SELECT * FROM ${this.schema}.${this.tableName}`
    );
    return result.rows;
  }

  async findById(id: number): Promise<IResource | null> {
    const result = await this.pool.query(
      `SELECT * FROM ${this.schema}.${this.tableName} WHERE id = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  async findByName(name: string): Promise<IResource | null> {
    const result = await this.pool.query(
      `SELECT * FROM ${this.schema}.${this.tableName} WHERE name = $1`,
      [name]
    );
    return result.rows[0] || null;
  }

  async create(resource: Partial<IResource>): Promise<IResource> {
    if (_isNil(resource.parent_id)) {
      resource.parent_id = (await this.findByName("Main Menu"))?.id || 0;
    }

    return await super.create(resource);
  }

  async update(
    id: number,
    resource: Partial<IResource>
  ): Promise<IResource | null> {
    if (_isNil(resource.parent_id)) {
      resource.parent_id = (await this.findByName("Main Menu"))?.id || 0;
    }

    return await super.update(id, resource);
  }

  async generateResourceTree(userId: number) {
    const accessibleResources = await this.getAccessibleResources(userId);

    const isSuperAdmin = _findIndex(accessibleResources, (resource) => resource.role_name === "super_admin") >= 0;
    this.redisClient.set(`user-${userId}-isSuperAdmin`, isSuperAdmin ? 1 : 0);

    if(isSuperAdmin) {
        return;
    }

    const mainMenu = await this.findByName("main_menu");

    if (!mainMenu) {
      return;
    }

    _forEach(accessibleResources, res => {
        this.redisClient.set(`user-${userId}-res-${res.resource_id}`, JSON.stringify(res));
    })

    const tree = this.buildResourceTree(mainMenu.id, accessibleResources);

    this.redisClient.set(`user-${userId}-tree`, JSON.stringify(tree));
  }

  private async getAccessibleResources(
    userId: number
  ): Promise<Array<IAccessibleResource>> {
    const query = `
    WITH RECURSIVE roles as (
        SELECT DISTINCT r.id as role_id, r.name as role_name, NULL::text as access_type
        FROM ${this.schema}.user_role ur
        JOIN ${this.schema}.role r ON ur.role_id = r.id
        WHERE ur.user_id = $1

        UNION ALL

        SELECT r.id as role_id, r.name as role_name, ag.access_type::text
        FROM ${this.schema}.access_grants ag
        JOIN ${this.schema}.user_role ur ON ur.user_id = ag.target_id
        JOIN ${this.schema}.role r ON ur.role_id = r.id
        WHERE ag.user_id = $1
    ),
    resource_hierarchy AS (
        SELECT DISTINCT rar.resource_id,  r.role_id, r.role_name, rar.access_level,
        COALESCE(r.access_type::text, rar.access_type::text) as access_type
        FROM ${this.schema}.resource_access_role rar
        JOIN roles r ON r.role_id = rar.role_id

        UNION ALL

        SELECT distinct r.parent_id as resource_id, rh.role_id,
        rh.role_name, rh.access_level, rh.access_type
        FROM ${this.schema}.resource r
        INNER JOIN resource_hierarchy rh ON r.id = rh.resource_id
    )
    SELECT rh.*, r.parent_id FROM resource_hierarchy rh
    JOIN ${this.schema}.resource r ON r.id = rh.resource_id;
    `;
    return (await this.executeQuery<IAccessibleResource>(query, [userId])).rows;
  }

  private buildResourceTree(
    rootResourceId: number,
    accessibleResources: Array<IAccessibleResource>
  ): IResourceTreeNode | null {
    const _rootAr = _find(accessibleResources, (ar) => ar.resource_id === rootResourceId);

    if (!_rootAr) {
      return null;
    }

    const _output = { ..._rootAr };

    const _childrenAr = _filter(
      accessibleResources,
      (ar) => ar.parent_id === rootResourceId
    );

    if (_isNil(_childrenAr) || _isEmpty(_childrenAr)) {
      return _output;
    }

    return {
      ..._rootAr,
      children: _filter(
        _map(_childrenAr, (car) =>
          this.buildResourceTree(car.resource_id, accessibleResources)
        ),
        (far) => !_isNil(far)
      ),
    };
  }
}
