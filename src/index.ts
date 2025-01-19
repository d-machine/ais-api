import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { prettyJSON } from 'hono/pretty-json'
import { timing } from 'hono/timing'
import { dbClient } from './storage/dbClient.js'
import { createUserRouter } from './routes/user.routes.js'
import { createRoleRouter } from './routes/role.routes.js'
import { createResourceRouter } from './routes/resource.routes.js'
import { createUserRoleRouter } from './routes/user-role.routes.js'
import { createAccessGrantsRouter } from './routes/access-grants.routes.js'
import { createResourceAccessRoleRouter } from './routes/resource-access-role.routes.js'
import dbRoutes from './routes/db.routes.js'
import { serveStatic } from '@hono/node-server/serve-static';
import { authMiddleware } from './middlewares/auth.middleware.js'
import { createAuthRouter } from './routes/auth.routes.js'

const app = new Hono()

// Middleware
app.use('*', logger())
app.use('*', timing())
app.use('*', prettyJSON())
app.use('*', cors({
  origin: ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true,
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization', 'X-User-ID'],
  exposeHeaders: ['Content-Length', 'X-Request-Id'],
  maxAge: 3600,
}))

// Error handling
app.onError((err, c) => {
  console.error(`${err}`);
  return c.json({
    error: {
      message: err.message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    }
  }, 500)
})

// Not Found handling
app.notFound((c) => {
  return c.json({
    error: {
      message: 'Not Found',
      path: c.req.path
    }
  }, 404)
})

// Routes
app.get('/', (c) => c.json({ message: 'Hello Hono!' }))

app.use('/static/*', serveStatic({ root: './dist', onNotFound(path, c) {
    console.log(`${path} is not found, request to ${c.req.path}`)
  } }));

// Health check endpoint
app.get('/health', async (c) => {
  try {
    const postgres = dbClient.getPostgresClient();
    const redis = dbClient.getRedisClient();
    
    // Test PostgreSQL connection
    await postgres.getPool().query('SELECT 1');
    
    // Test Redis connection
    await redis.getClient().ping();
    
    return c.json({ 
      status: 'ok',
      postgres: 'connected',
      redis: 'connected'
    });
  } catch (error) {
    return c.json({ 
      status: 'error',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, 503);
  }
});

// Mount API routes
const postgresPool = dbClient.getPostgresClient().getPool();

app.route('/api/db', dbRoutes);

// Auth API routes
app.route('/api/auth', createAuthRouter(postgresPool));

// Apply authMiddleware
app.use('*', authMiddleware);


app.route('/api/users', createUserRouter(postgresPool))
app.route('/api/roles', createRoleRouter(postgresPool))
app.route('/api/resources', createResourceRouter(postgresPool))
app.route('/api/user-roles', createUserRoleRouter(postgresPool))
app.route('/api/access-grants', createAccessGrantsRouter(postgresPool))
app.route('/api/resource-access-roles', createResourceAccessRoleRouter(postgresPool))


const port = Number(process.env.PORT) || 3000

// Initialize database before starting server
async function startServer() {
  try {
    // Connect to databases
    await dbClient.connect();
    console.log('All database connections established');
    
    // Start server only after successful database connections
    serve({
      fetch: app.fetch,
      port
    })
    
    console.log(`Server is running on port ${port}`)

    // Handle shutdown
    process.on('SIGTERM', async () => {
      console.log('SIGTERM received. Shutting down gracefully...');
      await dbClient.disconnect();
      process.exit(0);
    });

  } catch (error) {
    console.error('Failed to start server:', error)
    process.exit(1)
  }
}

startServer()
