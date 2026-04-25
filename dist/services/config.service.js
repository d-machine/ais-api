import fs from "fs";
import path from "path";
import yaml from "js-yaml";
import { _get, _isNil, _replace } from "../utils/aisLodash.js";
import BaseService from "./base.service.js";
export default class ConfigService extends BaseService {
    constructor() {
        super();
        this.loadConfigsToCache = this.loadConfigsToCache.bind(this);
        this.getConfigFromCache = this.getConfigFromCache.bind(this);
        this.getConfigKeyFromCache = this.getConfigKeyFromCache.bind(this);
        this.configFiles = this.configFiles.bind(this);
    }
    async configFiles() {
        const configPath = path.join(process.cwd(), "data", "fs", "configs");
        return fs.readdirSync(configPath);
    }
    async loadConfigsToCache() {
        try {
            const files = await this.configFiles();
            for (const file of files) {
                const filePath = path.join(process.cwd(), "data", "fs", "configs", file);
                const fileContent = fs.readFileSync(filePath, "utf-8");
                const config = yaml.load(fileContent);
                await this._cache.saveData(_replace(file, ".yaml", ""), JSON.stringify(config));
            }
        }
        catch (error) {
            console.error("Error loading configs to cache:", error);
            throw error;
        }
    }
    async getConfigFromCache(fileName) {
        const data = await this._cache.readData(fileName);
        if (_isNil(data)) {
            return null;
        }
        return JSON.parse(data);
    }
    async getConfigKeyFromCache(fileName, path) {
        const data = await this._cache.readData(fileName);
        if (_isNil(data)) {
            return null;
        }
        return _get(JSON.parse(data), path);
    }
}
