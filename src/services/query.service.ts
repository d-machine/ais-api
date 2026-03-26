import BaseService from "./base.service.js";
import { IQueryInfo, TFormMode } from "../types/config.js";
import { _isEmpty, _isNil, _map } from "../utils/aisLodash.js";
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
      let filterValue = filter.value;
      if (typeof filter.value === "string") {
        filterValue = `'${filter.value.trim()}'`;
      }
      switch (filter.operator) {
        case EFilterOperator.IS_NULL:
          return `${filter.field} IS NULL`;
        case EFilterOperator.IS_NOT_NULL:
          return `${filter.field} IS NOT NULL`;
        case EFilterOperator.EQUAL:
          return `${filter.field} = ${filterValue}`;
        case EFilterOperator.NOT_EQUAL:
          return `${filter.field} != ${filterValue}`;
        case EFilterOperator.LESS_THAN_OR_EQUAL:
          return `${filter.field}::DATE <= ${filterValue}`;
        case EFilterOperator.GREATER_THAN_OR_EQUAL:
          return `${filter.field}::DATE >= ${filterValue}`;
        case EFilterOperator.IN:
          return `${filter.field} IN (${filterValue})`;
        case EFilterOperator.NOT_IN:
          return `${filter.field} NOT IN (${filterValue})`;
        case EFilterOperator.BETWEEN:
          return `${filter.field} BETWEEN ${filterValue}`;
        case EFilterOperator.NOT_BETWEEN:
          return `${filter.field} NOT BETWEEN ${filterValue}`;
        case EFilterOperator.CONTAINS:
          return `${filter.field} LIKE '%${filterValue}%'`;
        case EFilterOperator.NOT_CONTAINS:
          return `${filter.field} NOT LIKE %${filterValue}%`;
        case EFilterOperator.STARTS_WITH:
          return `${filter.field} LIKE ${filterValue}%`;
        case EFilterOperator.NOT_STARTS_WITH:
          return `${filter.field} NOT LIKE ${filterValue}%`;
        case EFilterOperator.ENDS_WITH:
          return `${filter.field} LIKE %${filterValue}`;
        case EFilterOperator.NOT_ENDS_WITH:
          return `${filter.field} NOT LIKE %${filterValue}`;
        default:
          return `${filter.field} ${filter.operator || "LIKE"} %${filterValue
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

  public buildQuery(queryInfo: IQueryInfo, fetchQuery?: IFetchQuery, mode?: TFormMode) {
    let query = '';
    if (typeof queryInfo.query === 'string') {
      query = queryInfo.query;
    } else if (mode) {
      query = queryInfo.query[mode];
    }

    if (_isEmpty(query)) {
      throw new Error("Query is empty");
    }

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
