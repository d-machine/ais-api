import BaseService from "./base.service.js";
import { IQueryInfo } from "../types/config.js";
import { _isNil, _map } from "../utils/aisLodash.js";
import {
  EFilterOperator,
  IFetchQuery,
  IFilterInfo,
  ISortInfo,
} from "../types/general.js";
import { DEFAULT_PAGE_SIZE } from "../constants/config.js";

export default class QueryService extends BaseService {
  constructor() {
    super();
    this.buildWhereClause = this.buildWhereClause.bind(this);
    this.buildOrderByClause = this.buildOrderByClause.bind(this);
    this.buildPaginationClause = this.buildPaginationClause.bind(this);
    this.buildQuery = this.buildQuery.bind(this);
  }

  private buildWhereClause(filters: Array<IFilterInfo>): string {
    const filterClauses = _map(filters, (filter) => {
      switch (filter.operator) {
        case EFilterOperator.IS_NULL:
          return `${filter.field} IS NULL`;
        case EFilterOperator.IS_NOT_NULL:
          return `${filter.field} IS NOT NULL`;
        case EFilterOperator.IN:
          return `${filter.field} IN (${filter.value})`;
        case EFilterOperator.NOT_IN:
          return `${filter.field} NOT IN (${filter.value})`;
        case EFilterOperator.BETWEEN:
          return `${filter.field} BETWEEN ${filter.value}`;
        case EFilterOperator.NOT_BETWEEN:
          return `${filter.field} NOT BETWEEN ${filter.value}`;
        case EFilterOperator.CONTAINS:
          return `${filter.field} LIKE %${filter.value}%`;
        case EFilterOperator.NOT_CONTAINS:
          return `${filter.field} NOT LIKE %${filter.value}%`;
        case EFilterOperator.STARTS_WITH:
          return `${filter.field} LIKE ${filter.value}%`;
        case EFilterOperator.NOT_STARTS_WITH:
          return `${filter.field} NOT LIKE ${filter.value}%`;
        case EFilterOperator.ENDS_WITH:
          return `${filter.field} LIKE %${filter.value}`;
        case EFilterOperator.NOT_ENDS_WITH:
          return `${filter.field} NOT LIKE %${filter.value}`;
        default:
          return `${filter.field} ${filter.operator || "LIKE"} %${
            filter.value
          }%`;
      }
    }).join(" AND ");

    if (filterClauses.length === 0) {
      return "";
    }

    return `WHERE ${filterClauses}`;
  }

  private buildOrderByClause(sorts: ISortInfo[]) {
    if (_isNil(sorts) || sorts.length === 0) {
      return "";
    }

    const orderBy = _map(sorts, (sort) => `${sort.field} ${sort.order}`).join(
      ", "
    );

    if (orderBy.length === 0) {
      return "";
    }

    return `ORDER BY ${orderBy}`;
  }

  private buildPaginationClause(offset: number, limit: number) {
    return `LIMIT ${limit} OFFSET ${offset}`;
  }

  public buildQuery(queryInfo: IQueryInfo, fetchQuery?: IFetchQuery) {
    let query = queryInfo.query;

    const { filtersData, sortData, paginationData } = fetchQuery || {};

    const queryOptions = queryInfo.options || {};

    const { applyFiltering, applySorting, applyPagenation } = queryOptions;

    const filters = applyFiltering ? filtersData : [];
    const sorts = applySorting ? sortData : [];
    const offset = applyPagenation ? paginationData?.offset || 0 : undefined;
    const limit = applyPagenation
      ? paginationData?.limit || DEFAULT_PAGE_SIZE
      : undefined;

    if (filters && filters.length > 0) {
      query += ` ${this.buildWhereClause(filters)}`;
    }

    if (sorts && sorts.length > 0) {
      query += ` ${this.buildOrderByClause(sorts)}`;
    }

    if (!_isNil(offset) && !_isNil(limit)) {
      query += ` ${this.buildPaginationClause(offset, limit)}`;
    }

    return query;
  }
}
