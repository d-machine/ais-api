import DBClient from "../storage/db.js";
import CacheClient from "../storage/cache.js";
import { logError, logInfo } from "../utils/logger.js";
export default class BaseService {
    constructor() {
        this._db = DBClient.getInstance();
        this._cache = CacheClient.getInstance();
        this.executeMultipleRowsQuery = this.executeMultipleRowsQuery.bind(this);
        this.executeSingleRowQuery = this.executeSingleRowQuery.bind(this);
        this.executeScalarArrayQuery = this.executeScalarArrayQuery.bind(this);
        this.executeScalarQuery = this.executeScalarQuery.bind(this);
        this.executeQuery = this.executeQuery.bind(this);
        this.executeDirectQuery = this.executeDirectQuery.bind(this);
    }
    async executeQuery({ returnType, query }, params = []) {
        try {
            logInfo({ context: "Service:Base", message: "Executing query", query, returnType });
            return await this._db.executeQuery(returnType, query, params);
        }
        catch (error) {
            logError({
                context: "Service:Base",
                message: "Error executing query",
                errorMessage: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
                query,
            });
            throw error;
        }
    }
    // Public method for direct query execution from controller
    async executeDirectQuery(returnType, query, params = []) {
        return this.executeQuery({ returnType, query }, params);
    }
    async executeScalarQuery(query, params = []) {
        return this.executeQuery({ returnType: "SCALAR" /* EQueryReturnType.SCALAR */, query }, params);
    }
    async executeScalarArrayQuery(query, params = []) {
        return this.executeQuery({ returnType: "SCALAR_ARRAY" /* EQueryReturnType.SCALAR_ARRAY */, query }, params);
    }
    async executeSingleRowQuery(query, params = []) {
        return this.executeQuery({ returnType: "SINGLE_ROW" /* EQueryReturnType.SINGLE_ROW */, query }, params);
    }
    async executeMultipleRowsQuery(query, params = []) {
        return this.executeQuery({ returnType: "MULTIPLE_ROWS" /* EQueryReturnType.MULTIPLE_ROWS */, query }, params);
    }
}
