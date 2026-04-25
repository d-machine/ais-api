import redis from "redis";
import { logError } from "../utils/logger.js";
export default class CacheClient {
    constructor() { }
    static getInstance() {
        if (!CacheClient.instance) {
            CacheClient.instance = new CacheClient();
        }
        return CacheClient.instance;
    }
    async initialize() {
        if (this.client) {
            return;
        }
        this.client = redis.createClient({
            url: `redis://${process.env.REDIS_HOST || "localhost"}:${process.env.REDIS_PORT || 6379}`,
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
    async ping() {
        if (!this.client) {
            throw new Error("Redis client not initialized");
        }
        return await this.client.ping();
    }
    async saveData(key, data) {
        if (!this.client) {
            throw new Error("Redis client not initialized");
        }
        await this.client.set(key, data);
    }
    async readData(key) {
        if (!this.client) {
            throw new Error("Redis client not initialized");
        }
        return await this.client.get(key);
    }
    async deleteKey(key) {
        if (!this.client) {
            throw new Error("Redis client not initialized");
        }
        await this.client.del(key);
    }
    async updateData(key, data) {
        if (!this.client) {
            throw new Error("Redis client not initialized");
        }
        await this.client.set(key, data);
    }
    async saveSet(key, args) {
        if (!this.client) {
            throw new Error("Redis client not initialized");
        }
        await this.client.sAdd(key, args);
    }
    async isMember(key, value) {
        if (!this.client) {
            throw new Error("Redis client not initialized");
        }
        return await this.client.sIsMember(key, value);
    }
    async disconnect() {
        if (this.client) {
            await this.client.quit();
            this.client = undefined;
        }
    }
}
