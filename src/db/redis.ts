import redis, { RedisClientType } from 'redis';

export default class RedisClient {
  private client?: RedisClientType;

  constructor() {
    this.client = redis.createClient({
      url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`,
      password: process.env.REDIS_PASSWORD,
    });

    this.client.on('error', (err) => {
      console.error('Redis Client Error:', err);
    });
  }

  async connect() {
    if (!this.client) {
      throw new Error('Redis client not initialized');
    }

    try {
      await this.client.connect();
      return this.client;
    } catch (err) {
      console.error("Failed to connect to Redis:", err);
      throw err;
    }
  }

  async disconnect() {
    try {
      await this.client?.disconnect();
    } catch (err) {
      console.error("Error disconnecting from Redis:", err);
      throw err;
    }
  }

  getClient() {
    if (!this.client) {
      throw new Error('Redis client not initialized');
    }
    return this.client;
  }

  // Database selection
  async selectDb(db: number) {
    try {
      await this.client?.select(db);
    } catch (err) {
      console.error(`Error selecting Redis database ${db}:`, err);
      throw err;
    }
  }
}
