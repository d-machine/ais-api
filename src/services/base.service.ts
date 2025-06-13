import DBClient from "../storage/db.js";
import CacheClient from "../storage/cache.js";
import { EQueryReturnType } from "../types/general.js";
import { IQueryInfo } from "../types/config.js";

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

  protected async executeQuery(queryInfo: IQueryInfo, params: any[] = []) {
    try {
      const { returnType, query } = queryInfo;
      console.log("Executing query:", { query, params, returnType });
      return await this._db.executeQuery(returnType, query, params);
    } catch (error) {
      console.error("Error executing query:", error);
      console.error("Query details:", { query: queryInfo.query, params });
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
