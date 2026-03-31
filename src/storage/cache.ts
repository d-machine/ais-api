import redis, { RedisClientType } from "redis";
import { logError } from "../utils/logger.js";

export default class CacheClient {
  private client?: RedisClientType;
  private static instance: CacheClient;

  private constructor() {}

  public static getInstance(): CacheClient {
    if (!CacheClient.instance) {
      CacheClient.instance = new CacheClient();
    }
    return CacheClient.instance;
  }

  public async initialize() {
    if (this.client) {
      return;
    }

    this.client = redis.createClient({
      url: `redis://${process.env.REDIS_HOST || "localhost"}:${
        process.env.REDIS_PORT || 6379
      }`,
      password: process.env.REDIS_PASSWORD,
    });

    this.client.on("error", (err) => {
      logError({
        context: "Cache:Redis",
        message: "Redis client error",
        errorMessage: err.message,
        stack: err.stack,
      });
    });

    await this.client.connect();
  }

  public async ping() {
    if (!this.client) {
      throw new Error("Redis client not initialized");
    }
    return await this.client.ping();
  }

  public async saveData(key: string, data: string) {
    if (!this.client) {
      throw new Error("Redis client not initialized");
    }
    await this.client.set(key, data);
  }

  public async readData(key: string) {
    if (!this.client) {
      throw new Error("Redis client not initialized");
    }
    return await this.client.get(key);
  }

  public async deleteKey(key: string) {
    if (!this.client) {
      throw new Error("Redis client not initialized");
    }
    await this.client.del(key);
  }

  public async updateData(key: string, data: string) {
    if (!this.client) {
      throw new Error("Redis client not initialized");
    }
    await this.client.set(key, data);
  }

  public async saveSet(key: string, args: string | Array<string>) {
    if (!this.client) {
      throw new Error("Redis client not initialized");
    }
    await this.client.sAdd(key, args);
  }

  public async isMember(key: string, value: string) {
    if (!this.client) {
      throw new Error("Redis client not initialized");
    }
    return await this.client.sIsMember(key, value);
  }

  public async disconnect() {
    if (this.client) {
      await this.client.quit();
      this.client = undefined;
    }
  }
}
