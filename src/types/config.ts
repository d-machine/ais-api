import { EQueryReturnType, IFilterInfo, ISortInfo } from "./general.js";

export enum EActionType {
  DISPLAY_FORM = "DISPLAY_FORM",
  EXECUTE_QUERY = "EXECUTE_QUERY",
  FUNCTION_CALL = "FUNCTION_CALL"
}

export enum EFilterType {
  STRING = "STRING",
  NUMBER = "NUMBER",
  DATE = "DATE",
  BOOLEAN = "BOOLEAN",
  SELECT = "SELECT",
}

export enum EInputType {
  TEXT = "TEXT",
  DATE = "DATE",
  SELECT = "SELECT",
  BUTTON = "BUTTON",
  TEXTAREA = "TEXTAREA",
}

export enum ESectionType {
  FIELDS = "FIELDS",
  TABLE = "TABLE",
}

export interface IBaseActionConfig {
  label: string;
  payload?: Array<string>;
  onSuccess?: string;
  onFailure?: string;
  accessTypeRequired?: string;
}

export interface IDisplayFormConfig extends IBaseActionConfig {
  type: EActionType.DISPLAY_FORM;
  formConfig: string;
}

export interface IExecuteQueryConfig extends IBaseActionConfig {
  type: EActionType.EXECUTE_QUERY;
  queryInfo: IQueryInfo;
}

export interface IActionConfig {
  [key: string]: IDisplayFormConfig | IExecuteQueryConfig;
}

export interface IFieldTrasformMap {
  as: string;
  key: string;
}

export interface IDependency {
  dependency: string;
  fields: IFieldTrasformMap[];
}

export interface IInputBase {
  name: string;
  label: string;
  required: boolean;
  readOnly: boolean;
  width: number;
  input_width: number;
  dependencies?: IDependency[];
}

export interface IInputText extends IInputBase {
  type: EInputType.TEXT;
  selectQuery?: string;
  regularExpression?: string;
  minLength?: number;
  maxLength?: number;
}

export interface IQueryInfo {
  returnType: EQueryReturnType;
  query: string;
  payload?: Array<string | number>;
  options?: {
    applyAccessLevelRestrictions?: boolean;
    applyPagenation?: boolean;
    applySorting?: boolean;
    applyFiltering?: boolean;
    defaultFilter?: IFilterInfo;
    defaultSort?: Array<ISortInfo>;
    pageSize?: number;
  };
}

export interface IInputSelectBase extends IInputBase {
  type: EInputType.SELECT;
  multi?: boolean;
  selectHandler: string;
  currentSelection: Array<IFieldTrasformMap>;
  selectParser: string;
  fields_to_extract: Array<IFieldTrasformMap>;
}

export interface IInputSelectWithQuery extends IInputSelectBase {
  queryInfo: IQueryInfo;
}

export interface IInputSelectWithOptions extends IInputSelectBase {
  options: Array<{id: string | number; label: string | number}>;
}

export type TInputSelect = IInputSelectWithQuery | IInputSelectWithOptions;

export interface IInputDate extends IInputBase {
  type: EInputType.DATE;
  minDate?: string;
  maxDate?: string;
}

export interface IInputButton extends IInputBase {
  type: EInputType.BUTTON;
  value: string;
  triggerQuery?: string;
}

export interface IInputTextArea extends IInputBase {
  type: EInputType.TEXTAREA;
  rows?: number;
  minLength?: number;
  maxLength?: number;
  regularExpression?: string;
}

export type TInput =
  | IInputText
  | TInputSelect
  | IInputDate
  | IInputButton
  | IInputTextArea;

export interface IListColumn {
  name: string;
  label: string;
  width: number;
  sortable: boolean;
  filterType?: EFilterType;
}

export interface IListConfig{
  queryInfo: IQueryInfo;
  applicableActions?: Array<string>;
  actionConfig?: IActionConfig;
  columns?: Array<IListColumn>;
}

export interface IBaseSectionConfig {
  sectionName: string;
  applicableActions?: Array<string>;
  actionConfig?: IActionConfig;
}

export interface IFieldsSection extends IBaseSectionConfig {
  sectionType: ESectionType.FIELDS;
  fields: Array<TInput>;
}

export interface ITableSection extends IBaseSectionConfig {
  sectionType: ESectionType.TABLE;
  listConfig: IListConfig;
}

export interface IFormConfig {
  formTitle?: string;
  sections: Array<IFieldsSection | ITableSection>;
}
