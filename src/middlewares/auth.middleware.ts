import { Context, Next } from 'hono';
import jwt from 'jsonwebtoken';
import { _has, _isNil } from '../utils/aisLodash.js';
import { logError, logWarn } from '../utils/logger.js';

declare module 'hono' {
  interface ContextVariableMap {
    userId: number;
  }
}

async function authMiddleware(c: Context, next: Next) {
  try {
    const accessToken = c.req.header('Authorization')?.replace('Bearer ', '');


    if (_isNil(accessToken)) {
      return c.json({ error: 'Access token is required' }, 401);
    }

    const secret = process.env.JWT_SECRET;
    const decoded = jwt.verify(accessToken, secret || 'ais_dev_secret');


    // Check if decoded is an object and has userId
    if (_isNil(decoded) || !_has(decoded, 'userId') || typeof decoded.userId !== 'number') {
      return c.json({ error: 'Invalid token format' }, 401);
    }

    // Set userId in app.locals
    c.set('userId', decoded.userId);
    
    await next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      logWarn({
        context: "Auth",
        message: "Access token expired",
        method: c.req.method,
        path: c.req.path,
        status: 401,
        errorMessage: error.message,
      });
      return c.json({ error: 'Access token has expired' }, 401);
    }
    if (error instanceof jwt.JsonWebTokenError) {
      logWarn({
        context: "Auth",
        message: "Invalid access token",
        method: c.req.method,
        path: c.req.path,
        status: 401,
        errorMessage: error.message,
      });
      return c.json({ error: 'Invalid access token' }, 401);
    }
    logError({
      context: "Auth",
      message: "Error verifying access token",
      method: c.req.method,
      path: c.req.path,
      status: 500,
      errorMessage: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });
    return c.json({ error: 'Failed to verify access token' }, 500);
  }
};

export default authMiddleware;