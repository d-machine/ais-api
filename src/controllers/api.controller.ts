import { Context } from "hono";
import ApiService from "../services/api.service.js";

export default class ApiController {
  async getMenu(c: Context) {
    try {
      const menuService = new ApiService();
      const userId = c.get("userId");
      const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;

      if (body.isMobile === true) {
        const result = await menuService.getMobilePages(userId);
        return c.json(result);
      }

      const menu = await menuService.getMenu(userId);
      return c.json(menu);
    } catch (error) {
      console.error("Menu error:", error);
      return c.json({ error: "Failed to get menu" }, 500);
    }
  }

  async getConfig(c: Context) {
    try {
      const apiService = new ApiService();
      const body = await c.req.json();
      const config = await apiService.getConfig(
        c.get("userId"),
        body.configFile
      );

      return c.json(config);
    } catch (error) {
      console.error("Config error:", error);
      return c.json({ error: "Failed to get config" }, 500);
    }
  }

  async executeQuery(c: Context) {
    try {
      const apiService = new ApiService();
      const body = await c.req.json();
      const userId = c.get("userId");

      console.log("Execute query request:", {
        fetchQuery: body.fetchQuery,
        configFile: body.configFile,
        path: body.path,
        payload: body.payload
      });

      // Regular config-based query execution
      try {
        const result = await apiService.handleQueryExecution(
          body.configFile,
          userId,
          body.path,
          body.payload,
          body.fetchQuery,
          body.mode
        );
        return c.json(result);
      } catch (error: any) {
        console.error("Config query execution error:", error);
        return c.json({
          error: "Config-based query execution failed",
          details: error?.message || "Unknown error"
        }, 500);
      }
    } catch (error: any) {
      console.error("General query execution error:", error);
      return c.json({
        error: "Failed to execute query",
        details: error?.message || "Unknown error"
      }, 500);
    }
  }
}
