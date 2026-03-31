import DBClient from "../storage/db.js";
import CacheClient from "../storage/cache.js";
import { EQueryReturnType } from "../types/general.js";
import { logError, logInfo } from "../utils/logger.js";

export default class BaseService {
  protected _db: DBClient;
  protected _cache: CacheClient;

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

  protected async executeQuery({ returnType, query }: { returnType: EQueryReturnType, query: string }, params: any[] = []) {
    try {
      logInfo({ context: "Service:Base", message: "Executing query", query, returnType });
      return await this._db.executeQuery(returnType, query, params);
    } catch (error) {
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
  public async executeDirectQuery(returnType: EQueryReturnType, query: string, params: any[] = []) {
    return this.executeQuery({ returnType, query }, params);
  }

  protected async executeScalarQuery(query: string, params: any[] = []) {
    return this.executeQuery({ returnType: EQueryReturnType.SCALAR, query }, params);
  }

  protected async executeScalarArrayQuery(query: string, params: any[] = []) {
    return this.executeQuery({ returnType: EQueryReturnType.SCALAR_ARRAY, query }, params);
  }

  protected async executeSingleRowQuery(query: string, params: any[] = []) {
    return this.executeQuery({ returnType: EQueryReturnType.SINGLE_ROW, query }, params);
  }

  protected async executeMultipleRowsQuery(query: string, params: any[] = []) {
    return this.executeQuery({ returnType: EQueryReturnType.MULTIPLE_ROWS, query }, params);
  }
}
