import pg from "pg";
import fs from "fs";
import path from "path";
import { _isNil } from "../utils/aisLodash.js";
import { logError, logInfo } from "../utils/logger.js";
export default class DBClient {
    constructor() { }
    static getInstance() {
        if (!DBClient.instance) {
            DBClient.instance = new DBClient();
        }
        return DBClient.instance;
    }
    async initialize() {
        this.pool = new pg.Pool({
            user: process.env.POSTGRES_USER,
            password: process.env.POSTGRES_PASSWORD,
            host: process.env.POSTGRES_HOST || "localhost",
            port: parseInt(process.env.POSTGRES_PORT || "5432"),
            database: process.env.POSTGRES_DB,
            max: 20,
            idleTimeoutMillis: 30000,
            connectionTimeoutMillis: 2000,
        });
        // Handle pool errors
        this.pool.on("error", (err) => {
            logError({
                context: "DB:Pool",
                message: "Unexpected error on idle PostgreSQL client",
                errorMessage: err.message,
                stack: err.stack,
            });
        });
        await this.pool.connect();
    }
    async setupDatabase() {
        try {
            // Order of SQL files to execute
            const sqlFiles = [
                "schema.sql",
                "status_code.sql",
                "user.sql",
                "role.sql",
                "resource.sql",
                "claim.sql",
                "user_role.sql",
                "refresh_token.sql",
                // "access_grants.sql",
                // Geographical tables
                "country.sql",
                "state.sql",
                "client_config.sql",
                "city.sql",
                "district.sql",
                "city_district.sql",
                "address.sql",
                // transport
                "transport.sql",
                // material
                "hsn.sql",
                "item_category.sql",
                "item_brand.sql",
                "uom.sql",
                "uom_conversion.sql",
                "material.sql",
                "material_ean.sql",
                // warehouse
                "rack.sql",
                // broker
                "broker.sql",
                // party
                "party_category.sql",
                "party.sql",
                "party_contact_details.sql",
                "vendor_category.sql",
                "vendor.sql",
                "vendor_contact_details.sql",
                // purchase_order
                "purchase_order_header.sql",
                "purchase_order_details.sql",
                //
                "inward_header.sql",
                "inward_details.sql",
                // sales_order
                "sales_order_header.sql",
                "sales_order_details.sql",
                // picking_list
                "picking_list_header.sql",
                "picking_list_details.sql",
                "picking_list_so_allocation.sql",
                //dispatch
                "dispatch_header.sql",
                "dispatch_details.sql",
                // purchase return
                "purchase_return_header.sql",
                "purchase_return_details.sql",
                // sales return
                "sales_return_header.sql",
                "sales_return_details.sql",
                // stock
                "stock.sql",
                // stock snapshot (monthly point-in-time)
                "stock_snapshot.sql",
                // saved reports
                "saved_report.sql",
                // query functions
                "query_functions.sql",
                "initial_data.sql",
            ];
            // Get the base directory for SQL files
            const baseDir = path.join(process.cwd(), "data", "fs", "setup-queries");
            // Execute each SQL file in order
            for (const file of sqlFiles) {
                const filePath = path.join(baseDir, file);
                try {
                    logInfo({ context: "DB:Client", message: `Executing SQL file: ${file}` });
                    const query = fs.readFileSync(filePath, "utf-8").replace(/^\uFEFF/, "");
                    await this.pool?.query(query);
                    logInfo({ context: "DB:Client", message: `Successfully executed SQL file: ${file}` });
                }
                catch (error) {
                    logError({
                        context: "DB:Client",
                        message: `Error executing SQL file: ${file}`,
                        errorMessage: error instanceof Error ? error.message : String(error),
                        stack: error instanceof Error ? error.stack : undefined,
                    });
                    throw error;
                }
            }
        }
        catch (error) {
            logError({
                context: "DB:Client",
                message: "Database initialization failed",
                errorMessage: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
            });
            throw error;
        }
    }
    async executeQuery(queryType, query, params = []) {
        try {
            logInfo({ context: "DB:Client", message: "Executing query", queryType, query });
            if (!this.pool) {
                logError({ context: "DB:Client", message: "Database pool not initialized" });
                throw new Error("Database pool not initialized");
            }
            const result = await this.pool.query(query, params);
            logInfo({ context: "DB:Client", message: "Query result", rowCount: result.rowCount });
            if (_isNil(result)) {
                return null;
            }
            if (result.rows.length === 0) {
                return queryType === "MULTIPLE_ROWS" /* EQueryReturnType.MULTIPLE_ROWS */ ? [] : null;
            }
            switch (queryType) {
                case "SINGLE_ROW" /* EQueryReturnType.SINGLE_ROW */:
                    return result.rows[0];
                case "MULTIPLE_ROWS" /* EQueryReturnType.MULTIPLE_ROWS */:
                    return result.rows;
                case "SCALAR" /* EQueryReturnType.SCALAR */:
                case "SCALAR_ARRAY" /* EQueryReturnType.SCALAR_ARRAY */:
                    // Check if the first row exists and has any properties
                    if (Object.keys(result.rows[0]).length === 0) {
                        return null;
                    }
                    // Get the first column of the first row, whatever its name is
                    return result.rows[0][Object.keys(result.rows[0])[0]];
                default:
                    return null;
            }
        }
        catch (error) {
            logError({
                context: "DB:Client",
                message: "Database error executing query",
                errorMessage: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
                query,
            });
            throw error;
        }
    }
    async disconnect() {
        try {
            await this.pool?.end();
            this.pool = undefined;
        }
        catch (error) {
            logError({
                context: "DB:Client",
                message: "Error disconnecting from database",
                errorMessage: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
            });
            throw error;
        }
    }
}
