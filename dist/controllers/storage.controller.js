import DBClient from "../storage/db.js";
import ConfigService from "../services/config.service.js";
import { logError } from "../utils/logger.js";
export default class StorageController {
    async initializeDb(c) {
        try {
            const _db = DBClient.getInstance();
            await _db.setupDatabase();
            return c.json({
                status: "ok",
                message: "Database initialized",
            });
        }
        catch (error) {
            logError({
                context: "Controller:Storage",
                message: "Database initialization failed",
                method: c.req.method,
                path: c.req.path,
                status: 500,
                errorMessage: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
            });
            return c.json({ error: "Database initialization failed" }, 500);
        }
    }
    async initializeCache(c) {
        try {
            const configService = new ConfigService();
            await configService.loadConfigsToCache();
            return c.json({
                status: "ok",
                message: "Configs loaded to cache",
            });
        }
        catch (error) {
            logError({
                context: "Controller:Storage",
                message: "Cache initialization failed",
                method: c.req.method,
                path: c.req.path,
                status: 500,
                errorMessage: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
            });
            return c.json({ error: "Cache initialization failed" }, 500);
        }
    }
}
