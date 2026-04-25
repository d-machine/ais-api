import BaseService from "./base.service.js";
import { _isEmpty, _isNil, _map } from "../utils/aisLodash.js";
import { DEFAULT_PAGE_SIZE } from "../constants/config.js";
export default class QueryService extends BaseService {
    constructor() {
        super();
        this.buildWhereClause = this.buildWhereClause.bind(this);
        this.buildGroupByClause = this.buildGroupByClause.bind(this);
        this.buildOrderByClause = this.buildOrderByClause.bind(this);
        this.buildPaginationClause = this.buildPaginationClause.bind(this);
        this.buildQuery = this.buildQuery.bind(this);
    }
    buildWhereClause(filters) {
        const filterClauses = _map(filters, (filter) => {
            let filterValue = filter.value;
            if (typeof filter.value === "string") {
                filterValue = `'${filter.value.trim()}'`;
            }
            switch (filter.operator) {
                case "IS_NULL" /* EFilterOperator.IS_NULL */:
                    return `${filter.field} IS NULL`;
                case "IS_NOT_NULL" /* EFilterOperator.IS_NOT_NULL */:
                    return `${filter.field} IS NOT NULL`;
                case "EQUAL" /* EFilterOperator.EQUAL */:
                    return `${filter.field} = ${filterValue}`;
                case "NOT_EQUAL" /* EFilterOperator.NOT_EQUAL */:
                    return `${filter.field} != ${filterValue}`;
                case "LESS_THAN_OR_EQUAL" /* EFilterOperator.LESS_THAN_OR_EQUAL */:
                    return `${filter.field}::DATE <= ${filterValue}`;
                case "GREATER_THAN_OR_EQUAL" /* EFilterOperator.GREATER_THAN_OR_EQUAL */:
                    return `${filter.field}::DATE >= ${filterValue}`;
                case "IN" /* EFilterOperator.IN */:
                    return `${filter.field} IN (${filterValue})`;
                case "NOT_IN" /* EFilterOperator.NOT_IN */:
                    return `${filter.field} NOT IN (${filterValue})`;
                case "BETWEEN" /* EFilterOperator.BETWEEN */:
                    return `${filter.field} BETWEEN ${filterValue}`;
                case "NOT_BETWEEN" /* EFilterOperator.NOT_BETWEEN */:
                    return `${filter.field} NOT BETWEEN ${filterValue}`;
                case "CONTAINS" /* EFilterOperator.CONTAINS */:
                    return `${filter.field} ILIKE '%${filter.value}%'`;
                case "NOT_CONTAINS" /* EFilterOperator.NOT_CONTAINS */:
                    return `${filter.field} NOT ILIKE '%${filter.value}%'`;
                case "STARTS_WITH" /* EFilterOperator.STARTS_WITH */:
                    return `${filter.field} ILIKE '${filter.value}%'`;
                case "NOT_STARTS_WITH" /* EFilterOperator.NOT_STARTS_WITH */:
                    return `${filter.field} NOT ILIKE '${filter.value}%'`;
                case "ENDS_WITH" /* EFilterOperator.ENDS_WITH */:
                    return `${filter.field} ILIKE '%${filter.value}'`;
                case "NOT_ENDS_WITH" /* EFilterOperator.NOT_ENDS_WITH */:
                    return `${filter.field} NOT ILIKE '%${filter.value}'`;
                default:
                    return `${filter.field} ILIKE '%${filter.value}%'`;
            }
        }).join(" AND ");
        if (filterClauses.length === 0) {
            return "";
        }
        return `WHERE ${filterClauses}`;
    }
    buildGroupByClause(fields) {
        if (_isNil(fields) || fields.length === 0) {
            return "";
        }
        return `GROUP BY ${fields.join(", ")}`;
    }
    buildOrderByClause(sorts) {
        if (_isNil(sorts) || sorts.length === 0) {
            return "";
        }
        const orderBy = _map(sorts, (sort) => `${sort.field} ${sort.order}`).join(", ");
        if (orderBy.length === 0) {
            return "";
        }
        return `ORDER BY ${orderBy}`;
    }
    buildPaginationClause(offset, limit) {
        return `LIMIT ${limit} OFFSET ${offset}`;
    }
    buildQuery(queryInfo, fetchQuery, mode) {
        let query = '';
        if (typeof queryInfo.query === 'string') {
            query = queryInfo.query;
        }
        else if (mode) {
            query = queryInfo.query[mode];
        }
        if (_isEmpty(query)) {
            throw new Error("Query is empty");
        }
        const { filtersData, sortData, paginationData, groupByData } = fetchQuery || {};
        const queryOptions = queryInfo.options || {};
        const { applyFiltering, applySorting, applyPagination, applyGroupBy } = queryOptions;
        const filters = applyFiltering ? filtersData : [];
        const sorts = applySorting ? sortData : [];
        const groupBy = applyGroupBy
            ? (groupByData && groupByData.length > 0 ? groupByData : queryOptions.defaultGroupBy)
            : [];
        const offset = applyPagination ? paginationData?.offset || 0 : undefined;
        const limit = applyPagination
            ? paginationData?.limit || DEFAULT_PAGE_SIZE
            : undefined;
        if (filters && filters.length > 0) {
            query += ` ${this.buildWhereClause(filters)}`;
        }
        if (groupBy && groupBy.length > 0) {
            query += ` ${this.buildGroupByClause(groupBy)}`;
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
