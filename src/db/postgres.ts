import pg from 'pg'
const { Pool } = pg

// Create a connection pool
const pool = new Pool({
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  database: process.env.POSTGRES_DB,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // How long a client is allowed to remain idle before being closed
  connectionTimeoutMillis: 2000, // How long to wait for a connection
})

// Test the connection
async function initializeDatabase() {
  try {
    const client = await pool.connect()
    console.log('Successfully connected to PostgreSQL')
    client.release()
    return pool
  } catch (err) {
    console.error('Failed to connect to PostgreSQL:', err)
    throw err
  }
}

// Export the pool and initialization function
export { pool, initializeDatabase } 