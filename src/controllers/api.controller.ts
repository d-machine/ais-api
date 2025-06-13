import { Context } from "hono";
import ApiService from "../services/api.service.js";
import BaseService from "../services/base.service.js";
import { EQueryReturnType } from "../types/general.js";

export default class ApiController {
  async getMenu(c: Context) {
    try {
      const menuService = new ApiService();
      const menu = await menuService.getMenu(c.get("userId"));
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
        query: body.query,
        configFile: body.configFile,
        path: body.path,
        payload: body.payload
      });
      
      // Check if this is a direct query execution
      if (body.query) {
        try {
          const baseService = new BaseService();
          const returnType = body.returnType || EQueryReturnType.SCALAR;
          const result = await baseService.executeDirectQuery(
            returnType,
            body.query,
            body.payload || []
          );
          return c.json(result);
        } catch (error: any) {
          console.error("Direct query execution error:", error);
          return c.json({ 
            error: "Direct query execution failed", 
            details: error?.message || "Unknown error" 
          }, 500);
        }
      }
      
      // Regular config-based query execution
      try {
        const result = await apiService.handleQueryExecution(
          body.configFile,
          userId,
          body.path,
          body.payload,
          body.fetchQuery
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
