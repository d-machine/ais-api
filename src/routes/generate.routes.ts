import { Hono } from 'hono';
import { serveStatic } from '@hono/node-server/serve-static';

const router = new Hono();

// Serve the HTML page
router.get('/*', serveStatic({ root: './src/public/' }));

// Serve the JavaScript file
// router.get('/scripts/*', serveStatic({ root: './src/public' }));

export default router; 