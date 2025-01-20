import { Context } from "hono";
import DBClient from "../storage/db.js";
import ConfigService from "../services/config.service.js";

export default class StorageController {
  async initializeDb(c: Context) {
    const _db = DBClient.getInstance();
    await _db.setupDatabase();
    return c.json({
      status: "ok",
      message: "Database initialized",
    });
  }

  async initializeCache(c: Context) {
    const configService = new ConfigService();
    await configService.loadConfigsToCache();

    return c.json({
      status: "ok",
      message: "Configs loaded to cache",
    });
  }
}
