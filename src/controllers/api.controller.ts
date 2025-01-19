import { Context } from "hono";
import ApiService from "../services/api.service.js";

export default class ApiController {
  async getMenu(c: Context) {
    try {
      const menuService = new ApiService();
      const menu = await menuService.getMenu(c.get("userId"));
      return c.json(menu);
    } catch (error) {
      console.log("Error getting menu:", error);
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
      console.log("Error getting config:", error);
      return c.json({ error: "Failed to get config" }, 500);
    }
  }

  async executeQuery(c: Context) {
    try {
      const apiService = new ApiService();
      const body = await c.req.json();
      const result = await apiService.handleQueryExecution(
        body.configFile,
        body.path,
        body.payload,
        body.fetchQuery
      );
      return c.json(result);
    } catch (error) {
      console.log("Error executing query:", error);
      return c.json({ error: "Failed to execute query" }, 500);
    }
  }
}
