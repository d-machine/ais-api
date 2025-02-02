import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { prettyJSON } from "hono/pretty-json";
import { timing } from "hono/timing";
import createAuthRouter from "./routes/auth.routes.js";
import createGenericRoutes from "./routes/generic.routes.js";
import createStorageRouter from "./routes/storage.routes.js";
import { serveStatic } from "@hono/node-server/serve-static";
import DBClient from "./storage/db.js";
import CacheClient from "./storage/cache.js";
import { EQueryReturnType } from "./types/general.js";

const app = new Hono();

// Middleware
app.use("*", logger());
app.use("*", timing());
app.use("*", prettyJSON());
app.use(
  "*",
  cors({
    origin: "*",
    credentials: false,
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization", "X-User-ID"],
    exposeHeaders: ["Content-Length", "X-Request-Id"],
    maxAge: 3600,
  })
);

// Error handling
app.onError((err, c) => {
  console.error(`${err}`);
  return c.json(
    {
      error: {
        message: err.message,
        ...(process.env.NODE_ENV === "development" && { stack: err.stack }),
      },
    },
    500
  );
});

// Not Found handling
app.notFound((c) => {
  return c.json(
    {
      error: {
        message: "Not Found",
        path: c.req.path,
      },
    },
    404
  );
});

// Routes
app.get("/", (c) => c.json({ message: "Hello Hono!" }));

app.use(
  "/static/*",
  serveStatic({
    root: "./dist",
    onNotFound(path, c) {
      console.log(`${path} is not found, request to ${c.req.path}`);
    },
  })
);

// Health check endpoint
app.get("/health", async (c) => {
  try {
    const _db = DBClient.getInstance();
    const _cache = CacheClient.getInstance();

    // Test PostgreSQL connection
    await _db.executeQuery(EQueryReturnType.SCALAR, "SELECT 1");

    // Test Redis connection
    await _cache.ping();

    return c.json({
      status: "ok",
      postgres: "connected",
      redis: "connected",
    });
  } catch (error) {
    return c.json(
      {
        status: "error",
        message: error instanceof Error ? error.message : "Unknown error",
      },
      503
    );
  }
});

// DB API routes
app.route("/api/storage", createStorageRouter());

// Auth API routes
app.route("/api/auth", createAuthRouter());

// Generic API routes
app.route("/api/generic", createGenericRoutes());

const port = Number(process.env.PORT) || 3000;

// Initialize database before starting server
async function startServer() {
  try {
    // Connect to databases and redis
    await Promise.all([
      DBClient.getInstance().initialize(),
      CacheClient.getInstance().initialize(),
    ]);
    console.log("All database connections established");

    // Start server only after successful database connections
    serve({ fetch: app.fetch, port });

    console.log(`Server is running on port ${port}`);

    // Handle shutdown
    process.on("SIGTERM", async () => {
      console.log("SIGTERM received. Shutting down gracefully...");
      await DBClient.getInstance().disconnect();
      await CacheClient.getInstance().disconnect();
      process.exit(0);
    });
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
}

startServer();
