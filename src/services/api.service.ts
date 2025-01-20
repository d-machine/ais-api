import BaseService from "./base.service.js";
import ConfigService from "./config.service.js";
import QueryService from "./query.service.js";
import { IListConfig, IFormConfig, IActionConfig, IQueryInfo } from "../types/config.js";
import { _filter, _find, _forEach, _get, _has, _isEmpty, _isNil, _map } from "../utils/aisLodash.js";
import { IFetchQuery } from "../types/general.js";

export default class ApiService extends BaseService {
  private _configService: ConfigService;
  private _queryService: QueryService;

  constructor() {
    super();
    this._configService = new ConfigService();
    this._queryService = new QueryService();
    this.getConfig = this.getConfig.bind(this);
    this.handleQueryExecution = this.handleQueryExecution.bind(this);
    this.getMenu = this.getMenu.bind(this);
    this.buildResourceTree = this.buildResourceTree.bind(this);
    this.parseActions = this.parseActions.bind(this);
    this.checkIfUserHasAccessToAction = this.checkIfUserHasAccessToAction.bind(this);
  }

  private async checkIfUserHasAccessToAction(userId: number, actionTypeRequired: string) {
    const superUser = await this._cache.readData(`super_user-${userId}`);

    if (superUser === "true") {
      return true;
    }

    return await this._cache.isMember(`user_access_type-${userId}`, actionTypeRequired);
  }

  private async parseActions(userId: number, actionConfig?: IActionConfig, applicableActions?: Array<string>) {
    const newActionConfig: IActionConfig = {};
    const newApplicableActions: Array<string> = [];

    if (_isNil(actionConfig) || _isNil(applicableActions) || applicableActions.length === 0 || _isEmpty(actionConfig)) {
      return { newActionConfig, newApplicableActions };
    }

    _forEach(applicableActions, async (action) => {
      const value = _get(actionConfig, action);
      if (_isNil(value) || _isEmpty(value)) {
        return;
      }
      if (
        !_has(value, "accessTypeRequired") ||
        (await this.checkIfUserHasAccessToAction(userId, value.accessTypeRequired as string))
      ) {
        newActionConfig[action] = value;
        newApplicableActions.push(action);
      }
    });

    return { newActionConfig, newApplicableActions };
  }

  public async getConfig(userId: number, configFileName: string) {
    let config: IListConfig | IFormConfig = await this._configService.getConfigFromCache(configFileName);

    if (_isNil(config)) {
      throw new Error(`Config file ${configFileName} not found!`);
    }

    console.log(config, '<><><><>');

    let configToReturn = {};

    if (_has(config, "sections")) {
      config = config as IFormConfig;
      configToReturn = _map(config.sections, (section) => {
        const actionConfig = _get(section, "actionConfig");
        const applicableActions = _get(section, "applicableActions");

        return {
          ...section,
          ...this.parseActions(userId, actionConfig, applicableActions),
        };
      });
    } else {
      config = config as IListConfig;
      const actionConfig = _get(config, "actionConfig");
      const applicableActions = _get(config, "applicableActions");

      configToReturn = {
        ...config,
        ...this.parseActions(userId, actionConfig, applicableActions),
      };
    }

    return configToReturn;
  }

  private async buildResourceTree(userId: number, resourceId: number, fullMenu: any[]): Promise<any> {
    try {
      const resource = _find(fullMenu, (resource) => resource.id === resourceId);

      if (_isNil(resource)) {
        return null;
      }

      const children = _filter(fullMenu, (resource) => resource.parent_id === resourceId);

      console.log(resource, '->', children);

      if (_isEmpty(children)) {
        if (await this.checkIfUserHasAccessToAction(userId, `${resource.id}-READ`)) {
          return resource;
        }
        return null;
      }

      const childResources = await Promise.all(
        _map(children, async (child) => await this.buildResourceTree(userId, child.id, fullMenu))
      );

      const nonNullChildren = _filter(childResources, (child) => !_isNil(child));

      if (_isEmpty(nonNullChildren)) {
        return null;
      }

      return {
        ...resource,
        children: nonNullChildren,
      };
    } catch (error) {
      console.error("Error building resource tree:", error);
      return null;
    }
  }

  public async getMenu(userId: number) {
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

  public async handleQueryExecution(
    configFileName: string,
    path?: Array<string>,
    params?: Array<IQueryInfo>,
    fetchQuery?: IFetchQuery
  ): Promise<any> {
    const queryInfo: IQueryInfo = await this._configService.getConfigKeyFromCache(configFileName, [...(path || []), "queryInfo"]);
    if (_isNil(queryInfo)) {
      throw new Error(`Query info not found for config file ${configFileName} at path ${path}`);
    }
    const query = this._queryService.buildQuery(queryInfo, fetchQuery);
    const result = await this.executeQuery({ returnType: queryInfo.returnType, query }, params);
    return result;
  }
}
