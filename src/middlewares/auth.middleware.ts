import { Context, Next } from 'hono';
import jwt from 'jsonwebtoken';
import { _has, _isNil } from '../utils/aisLodash.js';

declare module 'hono' {
  interface ContextVariableMap {
    userId: number;
  }
}

async function authMiddleware(c: Context, next: Next) {
  try {
    const accessToken = c.req.header('Authorization')?.replace('Bearer ', '');

    console.log(`Access token: ${accessToken}`);

    if (_isNil(accessToken)) {
      return c.json({ error: 'Access token is required' }, 401);
    }

    const secret = process.env.JWT_SECRET;
    console.log(`JWT secret: ${secret}`);
    const decoded = jwt.verify(accessToken, secret || 'ais_dev_secret');

    console.log(`Decoded access token: ${JSON.stringify(decoded)}`);

    // Check if decoded is an object and has userId
    if (_isNil(decoded) || !_has(decoded, 'userId') || typeof decoded.userId !== 'number') {
      return c.json({ error: 'Invalid token format' }, 401);
    }

    // Set userId in app.locals
    c.set('userId', decoded.userId);
    
    await next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      return c.json({ error: 'Access token has expired' }, 401);
    }
    if (error instanceof jwt.JsonWebTokenError) {
      return c.json({ error: 'Invalid access token' }, 401);
    }
    console.error('Error verifying access token:', error);
    return c.json({ error: 'Failed to verify access token' }, 500);
  }
};

export default authMiddleware;