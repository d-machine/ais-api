import pg from "pg";
import fs from "fs";
import path from "path";

import { EQueryReturnType } from "../types/general.js";
import { _isNil } from "../utils/aisLodash.js";

export default class DBClient {
  private pool?: pg.Pool;
  private static instance: DBClient;

  private constructor() {}

  public static getInstance(): DBClient {
    if (!DBClient.instance) {
      DBClient.instance = new DBClient();
    }
    return DBClient.instance;
  }

  public async initialize() {
    this.pool = new pg.Pool({
      user: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      host: process.env.POSTGRES_HOST || "localhost",
      port: parseInt(process.env.POSTGRES_PORT || "5432"),
      database: process.env.POSTGRES_DB,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    // Handle pool errors
    this.pool.on("error", (err) => {
      console.error("Unexpected error on idle PostgreSQL client", err);
    });

    await this.pool.connect();
  }

  public async setupDatabase() {
    try {
      // Order of SQL files to execute
      const sqlFiles = [
        "schema.sql",
        "user.sql",
        "role.sql",
        "resource.sql",
        "claim.sql",
        "user_role.sql",
        "refresh_token.sql",
        "country_master.sql",
        "query_functions.sql",
        "initial_data.sql",
      ];

      // Get the base directory for SQL files
      const baseDir = path.join(process.cwd(), "data", "fs", "setup-queries");

      // Execute each SQL file in order
      for (const file of sqlFiles) {
        const filePath = path.join(baseDir, file);

        try {
          console.log(`Executing SQL file: ${file}`);
          const query = fs.readFileSync(filePath, "utf-8");
          await this.pool?.query(query);
          console.log(`Successfully executed SQL file: ${file}`);
        } catch (error) {
          console.error(`Error executing ${file}:`, error);
          throw error;
        }
      }

    } catch (error) {
      console.error("Database initialization failed:", error);
      throw error;
    }
  }

  public async executeQuery(
    queryType: EQueryReturnType,
    query: string,
    params: any[] = []
  ) {
    try {
      console.log("DB Client executing query:", { queryType, query, params });
      
      if (!this.pool) {
        console.error("Database pool not initialized");
        throw new Error("Database pool not initialized");
      }
      
      const result = await this.pool.query(query, params);
      console.log("Query result:", { rowCount: result.rowCount });

      if (_isNil(result) || result.rows.length === 0) {
        return null;
      }

      switch (queryType) {
        case EQueryReturnType.SINGLE_ROW:
          return result.rows[0];
        case EQueryReturnType.MULTIPLE_ROWS:
          return result.rows;
        case EQueryReturnType.SCALAR:
        case EQueryReturnType.SCALAR_ARRAY:
          // Check if the first row exists and has any properties
          if (Object.keys(result.rows[0]).length === 0) {
            return null;
          }
          // Get the first column of the first row, whatever its name is
          return result.rows[0][Object.keys(result.rows[0])[0]];
        default:
          return null;
      }
    } catch (error) {
      console.error("Database error executing query:", error);
      console.error("Query details:", { queryType, query, params });
      throw error;
    }
  }

  public async disconnect() {
    try {
      await this.pool?.end();
      this.pool = undefined;
    } catch (error) {
      console.error("Error disconnecting from database:", error);
      throw error;
    }
  }
}
