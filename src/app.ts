import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Pool } from 'pg';
import { createAuthRouter } from './routes/auth.routes.js';
import { createUserRouter } from './routes/user.routes.js';
import { createRoleRouter } from './routes/role.routes.js';
import { createResourceRouter } from './routes/resource.routes.js';
import { createUserRoleRouter } from './routes/user-role.routes.js';
import { createAccessTypeRouter } from './routes/access-type.routes.js';
import { createAccessGrantsRouter } from './routes/access-grants.routes.js';
import { createResourceAccessRoleRouter } from './routes/resource-access-role.routes.js';
import { verifyAccessToken } from './middlewares/auth.middleware.js';

const app = new Hono();

// Configure CORS
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization', 'X-Refresh-Token', 'X-User-ID'],
  exposeHeaders: ['Content-Length', 'X-Refresh-Token'],
  maxAge: 86400,
  credentials: true,
}));

// Create database pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'ais',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

// Mount auth routes (no token verification needed)
app.route('/auth', createAuthRouter(pool));

// Protected routes (require token verification)
const protectedRoutes = new Hono();

protectedRoutes.use('*', verifyAccessToken);

protectedRoutes.route('/users', createUserRouter(pool));
protectedRoutes.route('/roles', createRoleRouter(pool));
protectedRoutes.route('/resources', createResourceRouter(pool));
protectedRoutes.route('/user-roles', createUserRoleRouter(pool));
protectedRoutes.route('/access-types', createAccessTypeRouter(pool));
protectedRoutes.route('/access-grants', createAccessGrantsRouter(pool));
protectedRoutes.route('/resource-access-roles', createResourceAccessRoleRouter(pool));

app.route('/api', protectedRoutes);

// Health check endpoint
app.get('/health', (c) => c.json({ status: 'ok' }));

export default app; 