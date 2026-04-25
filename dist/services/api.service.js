import BaseService from "./base.service.js";
import ConfigService from "./config.service.js";
import QueryService from "./query.service.js";
import { _filter, _find, _get, _has, _isEmpty, _isNil, _map, } from "../utils/aisLodash.js";
export default class ApiService extends BaseService {
    constructor() {
        super();
        this._configService = new ConfigService();
        this._queryService = new QueryService();
        this.getConfig = this.getConfig.bind(this);
        this.handleQueryExecution = this.handleQueryExecution.bind(this);
        this.getMenu = this.getMenu.bind(this);
        this.buildResourceTree = this.buildResourceTree.bind(this);
        this.parseActions = this.parseActions.bind(this);
        this.checkIfUserHasAccessToAction =
            this.checkIfUserHasAccessToAction.bind(this);
    }
    async checkIfUserHasAccessToAction(userId, actionTypeRequired) {
        const superUser = await this._cache.readData(`super_user-${userId}`);
        if (superUser === "true") {
            return true;
        }
        return await this._cache.isMember(`user_access_type-${userId}`, actionTypeRequired);
    }
    async parseActions(userId, actionConfig, applicableActions) {
        const newActionConfig = {};
        const newApplicableActions = {};
        if (_isEmpty(applicableActions) || _isEmpty(actionConfig)) {
            return { newActionConfig, newApplicableActions };
        }
        for (const [mode, actions] of Object.entries(applicableActions)) {
            const formMode = mode;
            newApplicableActions[formMode] = [];
            for (const action of actions) {
                const value = _get(actionConfig, action);
                if (_isNil(value) || _isEmpty(value)) {
                    continue;
                }
                if (!_has(value, "accessTypeRequired") ||
                    (await this.checkIfUserHasAccessToAction(userId, value.accessTypeRequired))) {
                    newActionConfig[action] = value;
                    newApplicableActions[formMode]?.push(action);
                }
            }
        }
        return { newActionConfig, newApplicableActions };
    }
    async getConfig(userId, configFileName) {
        let config = await this._configService.getConfigFromCache(configFileName);
        if (_isNil(config)) {
            throw new Error(`Config file ${configFileName} not found!`);
        }
        let configToReturn = {};
        if (_has(config, "sections")) {
            config = config;
            configToReturn = {
                ...config,
                sections: await Promise.all(_map(config.sections, async (section) => {
                    const actionConfig = _get(section, "actionConfig");
                    const applicableActions = _get(section, "applicableActions");
                    const parsedActions = await this.parseActions(userId, actionConfig, applicableActions);
                    return {
                        ...section,
                        ...parsedActions,
                    };
                })),
            };
        }
        else {
            config = config;
            const actionConfig = _get(config, "actionConfig");
            const applicableActions = _get(config, "applicableActions");
            const parsedActions = await this.parseActions(userId, actionConfig, applicableActions);
            configToReturn = {
                ...config,
                ...parsedActions,
            };
        }
        return configToReturn;
    }
    async buildResourceTree(userId, resourceId, fullMenu) {
        try {
            const resource = _find(fullMenu, (resource) => resource.id === resourceId);
            if (_isNil(resource)) {
                return null;
            }
            const children = _filter(fullMenu, (resource) => resource.parent_id === resourceId);
            if (_isEmpty(children)) {
                if (await this.checkIfUserHasAccessToAction(userId, `${resource.id}-READ`)) {
                    return resource;
                }
                return null;
            }
            const childResources = await Promise.all(_map(children, async (child) => await this.buildResourceTree(userId, child.id, fullMenu)));
            const nonNullChildren = _filter(childResources, (child) => !_isNil(child));
            if (_isEmpty(nonNullChildren)) {
                return null;
            }
            return {
                ...resource,
                children: nonNullChildren,
            };
        }
        catch (error) {
            console.error("Error building resource tree:", error);
            return null;
        }
    }
    async getMobilePages(userId) {
        const mobileResources = await this.executeMultipleRowsQuery("SELECT * FROM administration.resource WHERE is_mobile = true AND is_active = true ORDER BY id ASC", []);
        const accessible = [];
        for (const resource of mobileResources) {
            const hasAccess = await this.checkIfUserHasAccessToAction(userId, `${resource.id}-READ`);
            if (hasAccess)
                accessible.push(resource);
        }
        if (accessible.length === 0) {
            return { pages: [], message: "Please ask your admin to provide access." };
        }
        return { pages: accessible };
    }
    async getMenu(userId) {
        const fullMenu = await this.executeMultipleRowsQuery("SELECT * FROM administration.resource", []);
        if (_isNil(fullMenu) || _isEmpty(fullMenu)) {
            return null;
        }
        const menuRoot = _find(fullMenu, (resource) => resource.parent_id === 0);
        if (_isNil(menuRoot)) {
            return null;
        }
        const menu = this.buildResourceTree(userId, menuRoot.id, fullMenu);
        return menu;
    }
    async handleQueryExecution(configFileName, userId, path, params, fetchQuery, mode) {
        const queryInfo = await this._configService.getConfigKeyFromCache(configFileName, [
            ...(path || []),
            "queryInfo",
        ]);
        if (_isNil(queryInfo)) {
            throw new Error(`Query info not found for config file ${configFileName} at path ${path}`);
        }
        const query = this._queryService.buildQuery(queryInfo, fetchQuery, mode);
        let _params = [...(params || [])];
        if (queryInfo.contextParams && queryInfo.contextParams.length > 0) {
            _params = [..._params, userId];
        }
        const result = await this.executeQuery({ returnType: queryInfo.returnType, query }, _params);
        return result;
    }
}
