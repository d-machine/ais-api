import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { prettyJSON } from 'hono/pretty-json'
import { timing } from 'hono/timing'
import { initializeDatabase } from './db/postgres'

const app = new Hono()

// Middleware
app.use('*', logger())
app.use('*', timing())
app.use('*', prettyJSON())
app.use('*', cors({
  origin: ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true,
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
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

// Health check endpoint
app.get('/health', async (c) => {
  try {
    // Test database connection
    await initializeDatabase()
    return c.json({ status: 'ok', database: 'connected' })
  } catch (error) {
    return c.json({ status: 'error', database: 'disconnected' }, 503)
  }
})

const port = process.env.PORT || 3000

// Initialize database before starting server
async function startServer() {
  try {
    await initializeDatabase()
    console.log('Database initialized')
    
    serve({
      fetch: app.fetch,
      port
    })
    
    console.log(`Server is running on port ${port}`)
  } catch (error) {
    console.error('Failed to start server:', error)
    process.exit(1)
  }
}

startServer()
