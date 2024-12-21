import pg from 'pg'
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default class PostgresClient {
  private pool?: pg.Pool;

  constructor() {
    // Check if environment variables are loaded
    if (!process.env.POSTGRES_USER || !process.env.POSTGRES_PASSWORD || !process.env.POSTGRES_DB) {
      throw new Error('Required PostgreSQL environment variables are not set');
    }

    this.pool = new pg.Pool({
      user: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      host: process.env.POSTGRES_HOST || 'localhost',
      port: parseInt(process.env.POSTGRES_PORT || '5432'),
      database: process.env.POSTGRES_DB,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    // Handle pool errors
    this.pool.on('error', (err) => {
      console.error('Unexpected error on idle PostgreSQL client', err);
    });
  }

  async connect() {
    if (!this.pool) {
      throw new Error('PostgreSQL pool not initialized');
    }

    try {
      const client = await this.pool.connect();
      client.release();
      return this.pool;
    } catch (err) {
      console.error("Failed to connect to PostgreSQL:", err);
      throw err;
    }
  }

  async disconnect() {
    try {
      await this.pool?.end();
    } catch (err) {
      console.error("Error disconnecting from PostgreSQL:", err);
      throw err;
    }
  }

  getPool() {
    if (!this.pool) {
      throw new Error('PostgreSQL pool not initialized');
    }
    return this.pool;
  }

  async executeSqlFile(filePath: string) {
    try {
      const fullPath = path.join(__dirname, filePath);
      const query = fs.readFileSync(fullPath, 'utf-8');
      await this.pool?.query(query);
      return true;
    } catch (error) {
      console.error(`Error executing SQL file ${filePath}:`, error);
      throw error;
    }
  }

  private async readSqlFiles() {
    const tablesDir = path.join(__dirname, 'tables');
    const sqlFiles = [
      'init.sql',
      'user.sql',
      'role.sql',
      'user_role.sql',
      'access_type.sql',
      'access_grants.sql',
      'resource.sql',
      'resource_access_role.sql',
      'hierarchy_closure.sql'
    ];

    let combinedSql = '';
    for (const file of sqlFiles) {
      const filePath = path.join(tablesDir, file);
      const sql = fs.readFileSync(filePath, 'utf-8');
      combinedSql += sql + '\n';
    }
    return combinedSql;
  }

  async initializeDatabase() {
    try {
      const sql = await this.readSqlFiles();
      await this.pool?.query(sql);
      return true;
    } catch (error) {
      console.error('Error initializing database:', error);
      throw error;
    }
  }
}