import { BaseService } from "./base.service.js";
import { IUser } from "../types/models.js";
import { Pool } from "pg";
import bcrypt from "bcrypt";
import { _get, _isEmpty, _isNil, _map } from "../utils/aisLodash.js";

export class UserService extends BaseService<IUser> {
  protected tableName = "user";

  constructor(pool: Pool) {
    super(pool);
  }

  async create(data: Partial<IUser>): Promise<IUser> {
    if (!_isNil(data.password)) {
      data.password = await bcrypt.hash(data.password, 10);
    }

    data.reportsTo = !_isNil(data.reportsTo) ? data.reportsTo : 0;

    return await super.create(data);
  }

  async update(id: number, data: Partial<IUser>): Promise<IUser | null> {
    // Hash password if provided
    if (!_isNil(data.password)) {
      data.password = await bcrypt.hash(data.password, 10);
    }

    data.reportsTo = !_isNil(data.reportsTo) ? data.reportsTo : 0;

    return await super.update(id, data);
  }

  /**
   * Retrieves a list of all descendants (direct and indirect reports) for a given user.
   * 
   * This method uses a recursive Common Table Expression (CTE) to traverse the
   * employee hierarchy and find all users who report to the specified user,
   * either directly or indirectly.
   *
   * @param userId - The ID of the user whose descendants are to be retrieved.
   * @returns A Promise that resolves to an array of objects, each containing a userId
   *          representing a descendant of the specified user.
   */
  async getDescendantsList(userId: number): Promise<Array<{ userId: number }>> {
    const query = `
      WITH RECURSIVE employee_hierarchy AS (
        SELECT id as userId, reportsTo
        FROM ${this.schema}.${this.tableName}
        WHERE reportsTo = $1

        UNION ALL

        SELECT e.id, e.reportsTo
        FROM ${this.schema}.${this.tableName} e
        INNER JOIN employee_hierarchy eh ON e.reportsTo = eh.userId
      )
      SELECT userId FROM employee_hierarchy
    `;

    const result = await this.executeQuery(query, [userId]);
    return _map(result.rows, (row) => row.userId);
  }


  async findByEmail(email: string): Promise<IUser | null> {
    const query = `
      SELECT * FROM ${this.schema}.${this.tableName}
      WHERE email = $1
    `;
    const result = await this.executeQuery<IUser>(query, [email]);
    return result.rows[0] || null;
  }

  async findByUsername(username: string): Promise<IUser | null> {
    const query = `
      SELECT * FROM ${this.schema}.${this.tableName}
      WHERE username = $1
    `;
    const result = await this.executeQuery<IUser>(query, [username]);
    return result.rows[0] || null;
  }

  async validatePassword(user: IUser, password: string): Promise<boolean> {
    if (user.password === password) {
        return true;
    }
    return bcrypt.compare(password, user.password);
  }

  async getUserRoles(userId: number): Promise<any[]> {
    const query = `
      SELECT r.id, r.name, r.description, r.team, r.department,
             r.last_updated_at, r.last_updated_by,
             ur.last_updated_at as role_assigned_at,
             ur.last_updated_by as role_assigned_by
      FROM ${this.schema}.role r
      JOIN ${this.schema}.user_role ur ON r.id = ur.role_id
      WHERE ur.user_id = $1
    `;
    const result = await this.executeQuery(query, [userId]);
    return result.rows;
  }

  async getUserRolesWithDetails(userId: number): Promise<any[]> {
    const query = `
      SELECT ur.id, ur.user_id, ur.role_id, 
             ur.last_updated_at as role_assigned_at,
             ur.last_updated_by as role_assigned_by,
             u.username, u.email, u.first_name, u.last_name,
             r.name as role_name, r.description as role_description,
             r.team, r.department,
             r.last_updated_at as role_updated_at,
             r.last_updated_by as role_updated_by
      FROM ${this.schema}.user_role ur
      JOIN ${this.schema}.user u ON ur.user_id = u.id
      JOIN ${this.schema}.role r ON ur.role_id = r.id
      WHERE ur.user_id = $1
    `;
    const result = await this.executeQuery(query, [userId]);
    return result.rows;
  }
}
