import { Context } from "hono";
import SavedReportService from "../services/saved-report.service.js";
import { logError } from "../utils/logger.js";

export default class SavedReportController {
  async list(c: Context) {
    try {
      const userId = c.get("userId");
      const { configFile, sectionName } = await c.req.json();
      const svc = new SavedReportService();
      const rows = await svc.list(userId, configFile, sectionName);
      return c.json(rows ?? []);
    } catch (error) {
      logError({ context: "Controller:SavedReport", message: "list failed", errorMessage: String(error) });
      return c.json({ error: "Failed to list saved reports" }, 500);
    }
  }

  async save(c: Context) {
    try {
      const userId = c.get("userId");
      const body = await c.req.json();
      const svc = new SavedReportService();
      const row = await svc.save(userId, body);
      return c.json(row);
    } catch (error) {
      logError({ context: "Controller:SavedReport", message: "save failed", errorMessage: String(error) });
      return c.json({ error: "Failed to save report" }, 500);
    }
  }

  async rename(c: Context) {
    try {
      const userId = c.get("userId");
      const id = Number(c.req.param("id"));
      const { name } = await c.req.json();
      const svc = new SavedReportService();
      const row = await svc.rename(userId, id, name);
      if (!row) return c.json({ error: "Not found or not authorized" }, 404);
      return c.json(row);
    } catch (error) {
      logError({ context: "Controller:SavedReport", message: "rename failed", errorMessage: String(error) });
      return c.json({ error: "Failed to rename report" }, 500);
    }
  }

  async remove(c: Context) {
    try {
      const userId = c.get("userId");
      const id = Number(c.req.param("id"));
      const svc = new SavedReportService();
      const deleted = await svc.delete(userId, id);
      if (!deleted) return c.json({ error: "Not found or not authorized" }, 404);
      return c.json({ success: true });
    } catch (error) {
      logError({ context: "Controller:SavedReport", message: "delete failed", errorMessage: String(error) });
      return c.json({ error: "Failed to delete report" }, 500);
    }
  }
}
