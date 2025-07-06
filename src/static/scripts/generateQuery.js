export function generateCompleteQuery(tableName, columnsString) {
    // Extract schema name if present in the table name
    let schemaName = 'dbo';
    let actualTableName = tableName;
    if (tableName.includes('.')) {
        [schemaName, actualTableName] = tableName.split('.');
    }

    const historyTableName = actualTableName + '_history';
    const triggerFunctionName = actualTableName + '_trigger';
    const deleteFunctionName = 'delete_' + actualTableName;

    // Parse columns string to handle multi-line and properly split columns
    const parseColumns = (str) => {
        const result = [];
        let current = '';
        let parenthesesCount = 0;

        for (let i = 0; i < str.length; i++) {
            const char = str[i];
            if (char === '(') parenthesesCount++;
            if (char === ')') parenthesesCount--;

            if (char === ',' && parenthesesCount === 0) {
                if (current.trim()) {
                    result.push(current.trim());
                }
                current = '';
            } else {
                current += char;
            }
        }
        if (current.trim()) {
            result.push(current.trim());
        }
        return result;
    };

    const columns = parseColumns(columnsString);

    // Extract column names and their definitions
    const columnDefinitions = columns.map(col => {
        // Skip standalone UNIQUE constraints
        if (col.trim().toLowerCase().startsWith('unique')) {
            return null;
        }
        // First word before any whitespace is the column name
        const nameMatch = col.match(/^(\w+)([\s\S]+)$/);
        if (!nameMatch) return null;

        const [, name, rest] = nameMatch;
        return {
            name,
            definition: rest.trim(),
            isPrimary: rest.toLowerCase().includes('primary key'),
            isUnique: rest.toLowerCase().includes('unique'),
            hasReferences: rest.toLowerCase().includes('references'),
            fullDefinition: col
        };
    }).filter(col => col !== null);

    // Get non-primary key columns for history table and triggers
    const nonPrimaryColumns = columnDefinitions.filter(col => !col.isPrimary);
    const columnNames = nonPrimaryColumns.map(col => col.name);

    // Create history table column definitions
    const historyColumns = nonPrimaryColumns.map(col => {
        let def = col.definition;
        // Remove UNIQUE constraints including multi-column UNIQUE
        def = def.replace(/\s+UNIQUE(\s*\([^)]+\))?/gi, '');
        // Remove PRIMARY KEY constraints
        def = def.replace(/\s+PRIMARY\s+KEY\b/gi, '');
        // Remove REFERENCES clauses
        def = def.replace(/\s+REFERENCES\s+[^,)]+/gi, '');
        // Remove DEFAULT clauses
        def = def.replace(/\s+DEFAULT\s+[^,)]+/gi, '');
        // Remove any trailing parentheses
        def = def.replace(/\s*\)[^,]*$/, '');
        return `    ${col.name} ${def.trim()}`;
    });

    return `-- Drop table if exists
-- DROP TABLE IF EXISTS ${schemaName}.${actualTableName};
-- DROP TABLE IF EXISTS ${schemaName}.${historyTableName};
-- DROP FUNCTION IF EXISTS ${schemaName}.${triggerFunctionName};
-- DROP FUNCTION IF EXISTS ${schemaName}.${deleteFunctionName};

-- Create ${actualTableName} table
CREATE TABLE IF NOT EXISTS ${schemaName}.${actualTableName} (
${columnsString.trim()}
);

-- Create temporal table for ${actualTableName}
CREATE TABLE IF NOT EXISTS ${schemaName}.${historyTableName} (
    history_id SERIAL PRIMARY KEY,
    ${actualTableName}_id INTEGER,
${historyColumns.join(',\n')},
    operation VARCHAR(10),
    operation_at TIMESTAMP,
    operation_by INTEGER REFERENCES ${schemaName}.user(id)
);

-- Create trigger function for ${actualTableName}
CREATE OR REPLACE FUNCTION ${schemaName}.${triggerFunctionName}()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO ${schemaName}.${historyTableName} (
            ${actualTableName}_id,
            ${columnNames.join(',\n            ')},
            operation, operation_at, operation_by
        )
        VALUES (
            NEW.id,
            ${columnNames.map(name => `NEW.${name}`).join(',\n            ')},
            'INSERT', NEW.lua, NEW.lub
        );
    ELSIF TG_OP = 'UPDATE' THEN
        IF (OLD.is_active = true AND NEW.is_active = false) THEN
            INSERT INTO ${schemaName}.${historyTableName} (
                ${actualTableName}_id,
                ${columnNames.join(',\n        ')},
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id,
                ${columnNames.map(name => `NEW.${name}`).join(',\n        ')},
                'DELETE', NEW.lua, NEW.lub
            );
        ELSE
            INSERT INTO ${schemaName}.${historyTableName} (
                ${actualTableName}_id,
                ${columnNames.join(',\n        ')},
                operation, operation_at, operation_by
            )
            VALUES (
                NEW.id,
                ${columnNames.map(name => `NEW.${name}`).join(',\n        ')},
                'UPDATE', NEW.lua, NEW.lub
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for ${actualTableName}
DROP TRIGGER IF EXISTS ${actualTableName}_insert_trigger ON ${schemaName}.${actualTableName};
CREATE TRIGGER ${actualTableName}_insert_trigger
    AFTER INSERT ON ${schemaName}.${actualTableName}
    FOR EACH ROW
    EXECUTE FUNCTION ${schemaName}.${triggerFunctionName}();

DROP TRIGGER IF EXISTS ${actualTableName}_update_trigger ON ${schemaName}.${actualTableName};
CREATE TRIGGER ${actualTableName}_update_trigger
    AFTER UPDATE ON ${schemaName}.${actualTableName}
    FOR EACH ROW
    EXECUTE FUNCTION ${schemaName}.${triggerFunctionName}();

-- Function to delete ${actualTableName}
CREATE OR REPLACE FUNCTION ${schemaName}.${deleteFunctionName}(
    ${actualTableName}_id_to_delete INTEGER,
    deleted_by_user_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insert into history before deletion
    INSERT INTO ${schemaName}.${historyTableName} (
        ${actualTableName}_id,
        ${columnNames.join(',\n        ')},
        operation, operation_at, operation_by
    )
    SELECT 
        id,
        ${columnNames.join(',\n        ')},
        'DELETE', NOW(), deleted_by_user_id
    FROM ${schemaName}.${actualTableName}
    WHERE id = ${actualTableName}_id_to_delete;

    -- Delete the ${actualTableName}
    DELETE FROM ${schemaName}.${actualTableName} 
    WHERE id = ${actualTableName}_id_to_delete;
END;
$$ LANGUAGE plpgsql;`;
} 