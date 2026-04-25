export var EActionType;
(function (EActionType) {
    EActionType["DISPLAY_FORM"] = "DISPLAY_FORM";
    EActionType["EXECUTE_QUERY"] = "EXECUTE_QUERY";
    EActionType["FUNCTION_CALL"] = "FUNCTION_CALL";
})(EActionType || (EActionType = {}));
export var EFilterType;
(function (EFilterType) {
    EFilterType["STRING"] = "STRING";
    EFilterType["NUMBER"] = "NUMBER";
    EFilterType["DATE"] = "DATE";
    EFilterType["BOOLEAN"] = "BOOLEAN";
    EFilterType["SELECT"] = "SELECT";
})(EFilterType || (EFilterType = {}));
export var EInputType;
(function (EInputType) {
    EInputType["TEXT"] = "TEXT";
    EInputType["DATE"] = "DATE";
    EInputType["SELECT"] = "SELECT";
    EInputType["BUTTON"] = "BUTTON";
    EInputType["TEXTAREA"] = "TEXTAREA";
})(EInputType || (EInputType = {}));
export var ESectionType;
(function (ESectionType) {
    ESectionType["FIELDS"] = "FIELDS";
    ESectionType["TABLE"] = "TABLE";
    ESectionType["REPORT"] = "REPORT";
    ESectionType["CHART"] = "CHART";
})(ESectionType || (ESectionType = {}));
export const FORM_MODES = {
    ADD: "ADD",
    EDIT: "EDIT",
    VIEW: "VIEW",
};
export var EChartType;
(function (EChartType) {
    EChartType["LINE"] = "LINE";
    EChartType["BAR"] = "BAR";
    EChartType["PIE"] = "PIE";
})(EChartType || (EChartType = {}));
