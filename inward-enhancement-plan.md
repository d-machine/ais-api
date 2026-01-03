# Inward Process Enhancement Plan

## Overview
This document outlines all required changes to enhance the inward process with improved UI/UX, batch number tracking, and row-level action conditions.

---

## Feature 1: Enhanced Inward Details Display

### Objective
Replace the current UNION-based query with a LEFT JOIN approach that shows all PO details with their inward status, displaying PO entry numbers and row numbers for better traceability.

### Changes Required

#### 1.1 Backend - Query Updates

**Files:**
- `data/fs/configs/add-inward.yaml`
- `data/fs/configs/edit-inward.yaml`

**Section:** Inward Details → queryInfo

**Current Behavior:**
- Shows UNION of EXISTING inward rows + PENDING PO rows
- Only shows pending items where `(pod.pqty - pod.iqty) > 0`
- Uses `row_type` to distinguish rows

**New Behavior:**
- Show ALL PO detail rows using LEFT JOIN
- Display PO `entry_no` and `row_no` for identification
- Show balance qty (`eqty - iqty`) instead of just ordered qty
- If inward detail exists → show inward data + "Edit" action
- If no inward detail → show PO data with 0 inward qty + "Add" action

**New Query Structure:**
```sql
SELECT 
  -- PO Detail Info (always from PO)
  pod.id as po_detail_id,
  poh.entry_no as po_entry_no,
  pod.row_no as po_row_no,
  pod.item_id as material_id,
  m.name as material_name,
  pod.quom,
  u.name as uom_name,
  pod.eqty as po_eqty,
  (pod.eqty - COALESCE(pod.iqty, 0)) as balance_qty,
  
  -- Inward Detail Info (if exists for this header)
  id.id as inward_detail_id,
  COALESCE(id.eqty, 0) as inward_qty,
  COALESCE(id.pqty, 0) as physical_qty,
  id.expiry_dt,
  id.batch_no,
  
  -- Row Type Logic
  CASE 
    WHEN id.id IS NOT NULL THEN 'EXISTING'
    ELSE 'PENDING'
  END as row_type,
  
  -- Action Label
  CASE 
    WHEN id.id IS NOT NULL THEN 'Edit'
    ELSE 'Add'
  END as action_label

FROM wms.purchase_order_details pod
JOIN wms.purchase_order_header poh ON pod.header_id = poh.id
JOIN wms.material m ON pod.item_id = m.id
LEFT JOIN wms.uom u ON pod.quom = u.id

-- LEFT JOIN to check if inward detail exists for this PO detail + header combo
LEFT JOIN wms.inward_details id ON 
  id.po_detail_id = pod.id 
  AND id.header_id = $1 
  AND id.is_active = true

WHERE poh.id = ANY(
  string_to_array(
    (SELECT po_ids FROM wms.inward_header WHERE id = $1), 
    ','
  )::int[]
)
AND pod.is_active = true

ORDER BY poh.entry_no, pod.row_no
```

#### 1.2 Backend - Column Configuration

**Files:**
- `data/fs/configs/add-inward.yaml`
- `data/fs/configs/edit-inward.yaml`

**Section:** Inward Details → columns

**New Columns:**
```yaml
columns:
  - name: po_entry_no
    label: PO No
    visible: true
    width: 120
    
  - name: po_row_no
    label: Row #
    visible: true
    width: 80
    align: center
    
  - name: material_name
    label: Material
    visible: true
    width: 200
    
  - name: po_eqty
    label: Ordered Qty
    visible: true
    width: 100
    align: right
    
  - name: balance_qty
    label: Balance Qty
    visible: true
    width: 100
    align: right
    dataType: number
    
  - name: inward_qty
    label: Inwarded Qty
    visible: true
    width: 120
    align: right
    dataType: number
```

#### 1.3 Backend - Action Configuration

**Files:**
- `data/fs/configs/add-inward.yaml`
- `data/fs/configs/edit-inward.yaml`

**Section:** Inward Details → actionConfig

**Current:**
- Single `edit` action for all rows

**New:**
```yaml
actionConfig:
  add:
    label: Add
    actionType: DISPLAY_FORM
    level: ROW
    condition: row.row_type === 'PENDING'
    formConfig: process-inward-detail
    payload:
      - po_detail_id
      - po_entry_no
      - po_row_no
      - material_id
      - material_name
      - balance_qty
      - quom
      - uom_name
    onSuccess: refresh
    
  edit:
    label: Edit
    actionType: DISPLAY_FORM
    level: ROW
    condition: row.row_type === 'EXISTING'
    formConfig: process-inward-detail
    payload:
      - inward_detail_id  # as 'id'
      - po_detail_id
      - po_entry_no
      - po_row_no
      - material_id
      - material_name
      - balance_qty
      - inward_qty
      - physical_qty
      - expiry_dt
      - batch_no
      - quom
      - uom_name
    onSuccess: refresh
```

---

## Feature 2: Row-Level Action Conditions Support

### Objective
Enable conditional display of row-level actions based on row data (e.g., show "Add" for pending items, "Edit" for existing items).

### Changes Required

#### 2.1 Frontend - TypeScript Types

**File:** `ais-react-tw/src/types/config.ts`

**Interface:** `IActionConfig`

**Add property:**
```typescript
export interface IActionConfig {
  label: string;
  actionType: typeof ACTION_TYPES[keyof typeof ACTION_TYPES];
  visible?: boolean;
  level?: TActionLevel; // Ensure this exists
  
  // ADD THIS:
  condition?: string; // JavaScript expression evaluated against row context
  
  // ... rest of existing properties
}
```

#### 2.2 Frontend - Condition Evaluator Utility

**File:** `ais-react-tw/src/utils/condition-evaluator.ts` (NEW FILE)

**Content:**
```typescript
/**
 * Safely evaluates a condition string against a row context
 * @param condition - String like "row.status === 'Draft'"
 * @param row - The row data object
 * @returns boolean - Whether condition passes
 */
export const evaluateCondition = (condition: string, row: any): boolean => {
  if (!condition) return true; // No condition = always show
  
  try {
    // Create a function that has 'row' in scope
    const func = new Function('row', `return ${condition}`);
    return func(row);
  } catch (error) {
    console.error('Condition evaluation error:', error, 'Condition:', condition);
    return false; // Fail safe - hide action if condition is invalid
  }
};
```

#### 2.3 Frontend - ListRenderer Update

**File:** `ais-react-tw/src/components/ListRenderer.tsx`

**Location:** Around line 301-307 (ROW action rendering)

**Add import:**
```typescript
import { evaluateCondition } from '../utils/condition-evaluator';
```

**Update code:**
```typescript
// BEFORE (current):
{getActionsByLevel(activeConfig.actionConfig, ACTION_LEVELS.ROW).map(([key, action]) => (
  <button
    key={key}
    onClick={() => handleActionClick(key, action, row)}
    // ... button props
  >
    {action.label}
  </button>
))}

// AFTER (new):
{getActionsByLevel(activeConfig.actionConfig, ACTION_LEVELS.ROW)
  .filter(([_, action]) => evaluateCondition(action.condition || '', row))
  .map(([key, action]) => (
    <button
      key={key}
      onClick={() => handleActionClick(key, action, row)}
      // ... button props
    >
      {action.label}
    </button>
  ))}
```

---

## Feature 3: Batch Number Tracking

### Objective
Add batch number field to inward details for tracking material batches from vendors.

### Changes Required

#### 3.1 Database - Schema Update

**File:** `data/fs/setup-queries/inward_details.sql`

**Table:** `wms.inward_details`

**Add column after `expiry_dt`:**
```sql
batch_no VARCHAR(100),
```

**Table:** `wms.inward_details_history`

**Add column after `expiry_dt`:**
```sql
batch_no VARCHAR(100),
```

#### 3.2 Database - Insert Function Update

**File:** `data/fs/setup-queries/query_functions.sql`

**Function:** `wms.insert_inward_details()`

**Add parameter after `p_expiry_dt`:**
```sql
p_batch_no VARCHAR(100),
```

**Update INSERT statement:**
```sql
INSERT INTO wms.inward_details (
    header_id, entry_no, row_no, material_id, po_detail_id,
    quom, euom, puom, eqty, pqty, pur_rate, amount, expiry_dt, batch_no, remarks, lub
)
VALUES (
    p_header_id, _entry_no, _row_no, p_material_id, p_po_detail_id,
    p_quom, p_euom, p_puom, p_eqty, p_pqty, p_pur_rate, p_amount, p_expiry_dt, p_batch_no, p_remarks, p_current_user_id
)
```

#### 3.3 Database - Update Function Update

**File:** `data/fs/setup-queries/query_functions.sql`

**Function:** `wms.update_inward_details()`

**Add parameter after `p_amount`:**
```sql
p_batch_no VARCHAR(100),
```

**Update UPDATE statement:**
```sql
UPDATE wms.inward_details
SET material_id = p_material_id,
    po_detail_id = p_po_detail_id,
    quom = p_quom,
    euom = p_euom,
    puom = p_puom,
    eqty = p_eqty,
    pqty = p_pqty,
    pur_rate = p_pur_rate,
    amount = p_amount,
    batch_no = p_batch_no,
    remarks = p_remarks,
    lub = p_current_user_id,
    lua = NOW()
WHERE id = p_id;
```

#### 3.4 Form Configuration - Query Update

**File:** `data/fs/configs/process-inward-detail.yaml`

**Section:** queryInfo → query

**Add to SELECT for existing rows:**
```sql
CASE WHEN $1 > 0 THEN d.batch_no ELSE '' END as batch_no,
```

#### 3.5 Form Configuration - Field Addition

**File:** `data/fs/configs/process-inward-detail.yaml`

**Section:** fields

**Add field after `expiry_dt`:**
```yaml
- name: batch_no
  label: Batch Number
  type: TEXT
  required: false
  placeholder: "Enter batch/lot number"
```

#### 3.6 Form Configuration - Action Payload Update

**File:** `data/fs/configs/process-inward-detail.yaml`

**Section:** actionConfig → SAVE → queryInfo → payload

**Current payload order:**
```yaml
payload:
  - id
  - header_id
  - item_id
  - po_detail_id
  - euom
  - puom
  - quom
  - eqty
  - pqty
  - remarks
  - expiry_dt
```

**New payload order (add batch_no after expiry_dt):**
```yaml
payload:
  - id
  - header_id
  - item_id
  - po_detail_id
  - euom
  - puom
  - quom
  - eqty
  - pqty
  - pur_rate
  - amount
  - batch_no
  - remarks
  - expiry_dt
```

**Note:** The query also needs to be updated to match the parameter order:
```sql
SELECT CASE 
  WHEN $1 > 0 THEN wms.update_inward_details($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
  ELSE wms.insert_inward_details($2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
END as id;
```

#### 3.7 List Configuration - Query Update

**Files:**
- `data/fs/configs/add-inward.yaml`
- `data/fs/configs/edit-inward.yaml`

**Section:** Inward Details → queryInfo → query

**Add to EXISTING rows SELECT:**
```sql
d.batch_no,
```

**Add to PENDING rows SELECT:**
```sql
'' as batch_no,
```

---

## Task Checklist

### Phase 1: Frontend - Action Conditions Support
- [ ] Add `condition?: string` property to `IActionConfig` interface in `ais-react-tw/src/types/config.ts`
- [ ] Create new file `ais-react-tw/src/utils/condition-evaluator.ts` with `evaluateCondition()` function
- [ ] Update `ais-react-tw/src/components/ListRenderer.tsx` to import and use `evaluateCondition()`
- [ ] Test condition evaluation with existing configs (e.g., `list-inwards.yaml`)

### Phase 2: Database - Batch Number Support
- [ ] Update `data/fs/setup-queries/inward_details.sql` to add `batch_no` column to main table
- [ ] Update `data/fs/setup-queries/inward_details.sql` to add `batch_no` column to history table
- [ ] Run migration/recreate tables to apply schema changes
- [ ] Update `wms.insert_inward_details()` function in `query_functions.sql` - add parameter
- [ ] Update `wms.insert_inward_details()` function in `query_functions.sql` - add to INSERT
- [ ] Update `wms.update_inward_details()` function in `query_functions.sql` - add parameter
- [ ] Update `wms.update_inward_details()` function in `query_functions.sql` - add to UPDATE
- [ ] Test functions manually via SQL client

### Phase 3: Backend Config - Batch Number in Forms
- [ ] Update `data/fs/configs/process-inward-detail.yaml` query to include `batch_no` in SELECT
- [ ] Add `batch_no` field definition in `process-inward-detail.yaml` fields section
- [ ] Update SAVE action payload in `process-inward-detail.yaml` to include `batch_no`
- [ ] Update SAVE action query parameter count in `process-inward-detail.yaml`
- [ ] Test form creation and editing with batch number field

### Phase 4: Backend Config - Enhanced Inward Details List
- [ ] Replace UNION query with LEFT JOIN query in `add-inward.yaml` Inward Details section
- [ ] Update columns configuration in `add-inward.yaml` to include PO info and batch number
- [ ] Split `edit` action into separate `add` and `edit` actions with conditions in `add-inward.yaml`
- [ ] Update action payloads to include all required fields in `add-inward.yaml`
- [ ] Repeat all changes for `edit-inward.yaml` Inward Details section
- [ ] Test inward creation flow with new list display
- [ ] Test inward editing flow with new list display

### Phase 5: Testing & Validation
- [ ] Test Add action visibility (should show only for PENDING rows)
- [ ] Test Edit action visibility (should show only for EXISTING rows)
- [ ] Test batch number input and save in inward detail form
- [ ] Test batch number display in inward details list
- [ ] Test PO entry number and row number display
- [ ] Test balance quantity calculation
- [ ] Test partial inward receiving across multiple inward entries
- [ ] Test data integrity - verify all fields save correctly to database
- [ ] Test existing inward entries (backward compatibility)

### Phase 6: Documentation & Cleanup
- [ ] Update user documentation with batch number usage
- [ ] Add inline comments to complex queries
- [ ] Review and optimize query performance if needed
- [ ] Update API documentation if applicable

---

## Implementation Notes

### Dependencies
- Phase 1 must be completed before Phase 4 (action conditions needed for split add/edit actions)
- Phase 2 must be completed before Phase 3 (database schema needed for form)
- Phase 3 should be completed before Phase 4 (batch field needed in list queries)

### Estimated Effort
- Phase 1: 2-3 hours (frontend changes + testing)
- Phase 2: 1-2 hours (database schema + function updates)
- Phase 3: 1-2 hours (form configuration changes)
- Phase 4: 3-4 hours (complex query rewrite + testing)
- Phase 5: 2-3 hours (comprehensive testing)
- Phase 6: 1 hour (documentation)

**Total: 10-15 hours**

### Risk Mitigation
1. **Backup database** before schema changes
2. **Test in development environment** before production
3. **Implement phases incrementally** to isolate issues
4. **Keep old queries commented** for rollback if needed
5. **Verify backward compatibility** with existing inward entries

---

## Success Criteria

### Functional Requirements
✅ Row-level actions conditionally display based on row data  
✅ Batch numbers can be entered and saved for each inward detail  
✅ All PO details display with their inward status  
✅ PO entry number and row number visible for traceability  
✅ Balance quantity shows remaining items to be received  
✅ Add action available only for pending items  
✅ Edit action available only for existing inward items  
✅ Existing inward data preserved and displayed correctly  

### Non-Functional Requirements
✅ No breaking changes to existing functionality  
✅ Database performance remains acceptable  
✅ UI remains responsive and intuitive  
✅ Code is maintainable and well-documented  

---

## Rollback Plan

If issues arise during implementation:

1. **Phase 1 Rollback**: Remove condition filtering, all actions visible
2. **Phase 2 Rollback**: Drop `batch_no` column, revert function signatures
3. **Phase 3 Rollback**: Remove `batch_no` from form configs
4. **Phase 4 Rollback**: Restore original UNION-based queries

Keep backups of:
- Original SQL files
- Original YAML configs
- Database schema snapshot

---

## Related Documentation

- [Inward Process Explanation](./docs/inward-process.md) (if exists)
- [Database Schema Documentation](./docs/database-schema.md) (if exists)
- [Configuration Guide](./docs/config-guide.md) (if exists)

---

**Document Version:** 1.0  
**Created:** January 1, 2026  
**Last Updated:** January 1, 2026  
**Status:** Planning Phase
