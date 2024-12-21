enum ESectionType {
    FIELDS = 'fields',
    TABLE = 'table'
}

enum EInputType {
    TEXT = 'text',
    SELECT = 'select',
    BUTTON = 'button'
}

interface IDependency {
    dependency: string;
    section: string;
    fields: Array<{as: string, key: string}>;
}

type TField = ITextField | ISelect | IButton;

interface IInput {
    name: string;
    label: string;
    required: boolean;
    readOnly: boolean;
    inputWidth: number;
    fieldWidth: number;
    dependencies?: Array<IDependency>;
}

interface ITextField extends IInput {
    type: EInputType.TEXT;
}

interface ISelect extends IInput {
    type: EInputType.SELECT;
    selectQuery: string;
}

enum EButtonType {
    ADD = 'add',
    EDIT = 'edit',
    SAVE = 'save',
    DELETE = 'delete',
    CANCEL = 'cancel'
}

interface IButton extends IInput {
    type: EInputType.BUTTON;
    buttonType: EButtonType;
    value: string;
}

interface IFieldsSection {
    section: string;
    sectionType: ESectionType.FIELDS;
    fields: Array<TField>;
}

interface ITableSection {
    section: string;
    sectionType: ESectionType.TABLE;
    caption?: TField;
    columns: Array<TField>;
}

type TColumn = TField & {columnWidth: number};

type TForm = Array<IFieldsSection | ITableSection>;