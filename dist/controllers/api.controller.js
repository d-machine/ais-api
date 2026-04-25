import ApiService from "../services/api.service.js";
import { logError, logInfo } from "../utils/logger.js";
export default class ApiController {
    async getMenu(c) {
        try {
            const menuService = new ApiService();
            const userId = c.get("userId");
            const body = await c.req.json().catch(() => ({}));
            if (body.isMobile === true) {
                const result = await menuService.getMobilePages(userId);
                return c.json(result);
            }
            const menu = await menuService.getMenu(userId);
            return c.json(menu);
        }
        catch (error) {
            logError({
                context: "Controller:Api",
                message: "Menu error",
                method: c.req.method,
                path: c.req.path,
                status: 500,
                errorMessage: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
            });
            return c.json({ error: "Failed to get menu" }, 500);
        }
    }
    async getConfig(c) {
        try {
            const apiService = new ApiService();
            const body = await c.req.json();
            const config = await apiService.getConfig(c.get("userId"), body.configFile);
            return c.json(config);
        }
        catch (error) {
            logError({
                context: "Controller:Api",
                message: "Config error",
                method: c.req.method,
                path: c.req.path,
                status: 500,
                errorMessage: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
            });
            return c.json({ error: "Failed to get config" }, 500);
        }
    }
    async executeQuery(c) {
        try {
            const apiService = new ApiService();
            const body = await c.req.json();
            const userId = c.get("userId");
            logInfo({
                context: "Controller:Api",
                message: "Execute query request",
                method: c.req.method,
                path: c.req.path,
                fetchQuery: body.fetchQuery,
                configFile: body.configFile,
            });
            // Regular config-based query execution
            try {
                const result = await apiService.handleQueryExecution(body.configFile, userId, body.path, body.payload, body.fetchQuery, body.mode);
                return c.json(result);
            }
            catch (error) {
                logError({
                    context: "Controller:Api",
                    message: "Config query execution error",
                    method: c.req.method,
                    path: c.req.path,
                    status: 500,
                    errorMessage: error?.message,
                    stack: error?.stack,
                });
                return c.json({
                    error: "Config-based query execution failed",
                    details: error?.message || "Unknown error"
                }, 500);
            }
        }
        catch (error) {
            logError({
                context: "Controller:Api",
                message: "General query execution error",
                method: c.req.method,
                path: c.req.path,
                status: 500,
                errorMessage: error?.message,
                stack: error?.stack,
            });
            return c.json({
                error: "Failed to execute query",
                details: error?.message || "Unknown error"
            }, 500);
        }
    }
}
