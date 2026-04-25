import BaseService from "./base.service.js";
export default class SavedReportService extends BaseService {
    async list(userId, configFile, sectionName) {
        return this.executeMultipleRowsQuery(`SELECT id, name, config_file, section_name, visible_columns, group_by, filters, sort, is_shared, created_by
       FROM wms.saved_report
       WHERE config_file = $1 AND section_name = $2
         AND (created_by = $3 OR is_shared = true)
       ORDER BY name`, [configFile, sectionName, userId]);
    }
    async save(userId, payload) {
        return this.executeSingleRowQuery(`INSERT INTO wms.saved_report
         (name, config_file, section_name, visible_columns, group_by, filters, sort, is_shared, created_by, lub)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9)
       RETURNING id, name`, [
            payload.name,
            payload.configFile,
            payload.sectionName,
            JSON.stringify(payload.visibleColumns ?? []),
            JSON.stringify(payload.groupBy ?? []),
            JSON.stringify(payload.filters ?? []),
            JSON.stringify(payload.sort ?? null),
            payload.isShared ?? false,
            userId,
        ]);
    }
    async rename(userId, id, name) {
        return this.executeSingleRowQuery(`UPDATE wms.saved_report SET name = $1, lub = $2, lua = NOW()
       WHERE id = $3 AND created_by = $2
       RETURNING id, name`, [name, userId, id]);
    }
    async delete(userId, id) {
        return this.executeScalarQuery(`DELETE FROM wms.saved_report WHERE id = $1 AND created_by = $2 RETURNING id`, [id, userId]);
    }
}
