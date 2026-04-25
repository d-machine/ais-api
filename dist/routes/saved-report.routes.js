import { Hono } from "hono";
import SavedReportController from "../controllers/saved-report.controller.js";
import authMiddleware from "../middlewares/auth.middleware.js";
function createSavedReportRoutes() {
    const app = new Hono();
    const ctrl = new SavedReportController();
    app.use("*", authMiddleware);
    app.post("/list", ctrl.list);
    app.post("/save", ctrl.save);
    app.patch("/:id/rename", ctrl.rename);
    app.delete("/:id", ctrl.remove);
    return app;
}
export default createSavedReportRoutes;
