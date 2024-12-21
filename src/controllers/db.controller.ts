import { Context } from 'hono';
import { dbClient } from '../db/dbClient.js';

export class DbController {
    static async initialize(c: Context) {
        try {
            const postgresClient = dbClient.getPostgresClient();
            await postgresClient.initializeDatabase();
            return c.json({ 
                success: true, 
                message: 'Database initialized successfully' 
            });
        } catch (error) {
            console.error('Database initialization failed:', error);
            return c.json({ 
                success: false, 
                message: 'Database initialization failed', 
                error: error instanceof Error ? error.message : 'Unknown error'
            }, 500);
        }
    }
} 