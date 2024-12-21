import PostgresClient from "./postgres.js";
import RedisClient from "./redis.js";

export default class DbClient {
  private postgresClient: PostgresClient;
  private redisClient: RedisClient;

  constructor() {
    this.postgresClient = new PostgresClient();
    this.redisClient = new RedisClient();
  }

  async connect() {
    try {
      await this.postgresClient.connect();
      console.log('PostgreSQL connected successfully');
      
      await this.redisClient.connect();
      console.log('Redis connected successfully');
    } catch (error) {
      console.error('Database connection failed:', error);
      throw error;
    }
  }

  async disconnect() {
    try {
      await this.postgresClient.disconnect();
      await this.redisClient.disconnect();
    } catch (error) {
      console.error('Database disconnection failed:', error);
      throw error;
    }
  }

  getPostgresClient() {
    return this.postgresClient;
  }

  getRedisClient() {
    return this.redisClient;
  }
}

// Create a singleton instance
export const dbClient = new DbClient();