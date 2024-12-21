import { Pool, QueryResult } from "pg";

export abstract class BaseService<T> {
  protected abstract tableName: string;
  protected pool: Pool;
  protected schema = "administration";

  constructor(pool: Pool) {
    this.pool = pool;
  }

  async findAll(): Promise<T[]> {
    const query = `SELECT * FROM ${this.schema}.${this.tableName}`;
    const result = await this.pool.query(query);
    return result.rows;
  }

  async findById(id: number): Promise<T | null> {
    const query = `SELECT * FROM ${this.schema}.${this.tableName} WHERE id = $1`;
    const result = await this.pool.query(query, [id]);
    return result.rows[0] || null;
  }

  async create(data: Partial<T>): Promise<T> {
    const keys = Object.keys(data);
    const values = Object.values(data);
    const placeholders = values.map((_, i) => `$${i + 1}`).join(", ");
    const columns = keys.join(", ");

    const query = `
      INSERT INTO ${this.schema}.${this.tableName} (${columns})
      VALUES (${placeholders})
      RETURNING *
    `;

    const result = await this.pool.query(query, values);
    return result.rows[0];
  }

  async update(id: number, data: Partial<T>): Promise<T | null> {
    const keys = Object.keys(data);
    const values = Object.values(data);
    const setClause = keys.map((key, i) => `${key} = $${i + 1}`).join(", ");

    const query = `
      UPDATE ${this.schema}.${this.tableName}
      SET ${setClause}, last_updated_at = CURRENT_TIMESTAMP
      WHERE id = $${values.length + 1}
      RETURNING *
    `;

    const result = await this.pool.query(query, [...values, id]);
    return result.rows[0] || null;
  }

  async delete(id: number, userId: number): Promise<boolean> {
    try {
      const query = `SELECT ${this.schema}.delete_${this.tableName}($1, $2)`;
      await this.pool.query(query, [id, userId]);
      return true;
    } catch (error) {
      console.error(`Error deleting ${this.tableName}:`, error);
      return false;
    }
  }

  protected async executeQuery<R extends Record<string, any>>(
    query: string,
    params: any[] = []
  ): Promise<QueryResult<R>> {
    return this.pool.query<R>(query, params);
  }
}
