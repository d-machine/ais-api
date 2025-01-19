export const enum ESortOrder {
  ASC = "asc",
  DESC = "desc",
}

export const enum EFilterOperator {
  EQUAL = "EQUAL",
  NOT_EQUAL = "NOT_EQUAL",
  GREATER_THAN = "GREATER_THAN",
  LESS_THAN = "LESS_THAN",
  GREATER_THAN_OR_EQUAL = "GREATER_THAN_OR_EQUAL",
  LESS_THAN_OR_EQUAL = "LESS_THAN_OR_EQUAL",
  IN = "IN",
  NOT_IN = "NOT_IN",
  BETWEEN = "BETWEEN",
  NOT_BETWEEN = "NOT_BETWEEN",
  CONTAINS = "CONTAINS",
  NOT_CONTAINS = "NOT_CONTAINS",
  STARTS_WITH = "STARTS_WITH",
  NOT_STARTS_WITH = "NOT_STARTS_WITH",
  ENDS_WITH = "ENDS_WITH",
  NOT_ENDS_WITH = "NOT_ENDS_WITH",
  IS_NULL = "IS_NULL",
  IS_NOT_NULL = "IS_NOT_NULL",
}

export interface ISortInfo {
  field: string;
  order: ESortOrder;
}

export interface IPaginationInfo {
  offset: number;
  limit: number;
}

export interface IFilterInfo {
  field: string;
  value: string;
  operator?: string;
}

export interface IFetchQuery {
  sortData?: ISortInfo[];
  paginationData?: IPaginationInfo;
  filtersData?: IFilterInfo[];
}

export const enum EQueryReturnType {
  SINGLE_ROW = "SINGLE_ROW",
  MULTIPLE_ROWS = "MULTIPLE_ROWS",
  SCALAR = "SCALAR",
  SCALAR_ARRAY = "SCALAR_ARRAY"
}
