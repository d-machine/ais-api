export const enum ESortOrder {
    ASC = 'asc',
    DESC = 'desc'
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