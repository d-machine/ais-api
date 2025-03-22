import BaseService from "./base.service.js";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import { _findIndex, _forEach, _map, _split } from "../utils/aisLodash.js";

export default class AuthService extends BaseService {
  private readonly JWT_SECRET = process.env.JWT_SECRET || "ais_dev_secret";
  private readonly TOKEN_EXPIRY = process.env.JWT_EXPIRATION_IN_HOURS || 12;
  private readonly REFRESH_TOKEN_EXPIRY = process.env.JWT_REFRESH_EXPIRATION_IN_DAYS || 30;

  constructor() {
    super();
    this.checkIfSuperUser = this.checkIfSuperUser.bind(this);
    this.fetchAndCacheUserClaims = this.fetchAndCacheUserClaims.bind(this);
    this.saveRefreshToken = this.saveRefreshToken.bind(this);
    this.generateTokens = this.generateTokens.bind(this);
    this.login = this.login.bind(this);
    this.refresh = this.refresh.bind(this);
    this.validateToken = this.validateToken.bind(this);
    this.logout = this.logout.bind(this);
  }

  private async checkIfSuperUser(userId: number) {
    const user = await this.executeMultipleRowsQuery(
      `
      SELECT
        ur.role_id
      FROM
        administration.user u
        JOIN administration.user_role ur ON u.id = ur.user_id
      WHERE
        u.id = $1`,
      [userId]
    );


    return _findIndex(user, { role_id: 1 }) !== -1;
  }

  private async fetchAndCacheUserClaims(userId: number) {

    const isSuperUser = await this.checkIfSuperUser(userId);
    await this._cache.saveData(`super_user-${userId}`, isSuperUser ? "true" : "false");

    if (isSuperUser) {
      return;
    }

    const userClaims = await this.executeMultipleRowsQuery(
      `
      SELECT
        c.resource_id, c.access_type_ids, c.access_level_id
      FROM
        administration.user u
        JOIN administration.user_role ur ON u.id = ur.user_id
        JOIN administration.role r ON ur.role_id = r.id
        JOIN administration.claim c ON r.id = c.role_id
      WHERE u.id = $1
      `,
      [userId]
    );

    if (userClaims) {
      _forEach(userClaims.rows, async (row) => {
        const accessTypeIds = _split(row.access_type_ids, ",");
        await this._cache.saveData(`user_access_level-${userId}`, `${row.resource_id}:${row.access_level_id}`);
        await this._cache.saveSet(
          `user_access_type-${userId}`,
          _map(accessTypeIds, (accessTypeId) => `${row.resource_id}:${accessTypeId}`)
        );
      });
    }
  }

  private async saveRefreshToken(userId: number, token: string) {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 days from now

    await this.executeSingleRowQuery(
      "INSERT INTO administration.refresh_token (user_id, token, expires_at) VALUES ($1, $2, $3)",
      [userId, token, expiresAt]
    );
  }

  private generateTokens(userId: number) {
    const token = jwt.sign({ userId }, this.JWT_SECRET, {
      expiresIn: `${this.TOKEN_EXPIRY}h`,
    });

    const refreshToken = jwt.sign({ userId }, this.JWT_SECRET, {
      expiresIn: `${this.REFRESH_TOKEN_EXPIRY}d`,
    });

    this.saveRefreshToken(userId, refreshToken);

    return { token, refreshToken };
  }

  public async login(username: string, password: string) {
    const user = await this.executeSingleRowQuery("SELECT id, username, password FROM administration.user WHERE username = $1", [
      username,
    ]);

    if (!user) {
      throw new Error("User not found");
    }

    let isValidPassword = false;

    if (user.username === process.env.ADMIN_USERNAME) {
      isValidPassword = user.password === process.env.ADMIN_PASSWORD;
    } else {
      isValidPassword = await bcrypt.compare(password, user.password);
    }

    if (!isValidPassword) {
      throw new Error("Invalid password");
    }

    await this.fetchAndCacheUserClaims(user.id);

    return this.generateTokens(user.id);
  }

  public async refresh(refreshToken: string) {
    try {
      const decoded = jwt.verify(refreshToken, this.JWT_SECRET) as {
        userId: number;
      };

      const refreshTokenRow = await this.executeSingleRowQuery(
        "SELECT * FROM administration.refresh_token WHERE user_id = $1 AND token = $2",
        [decoded.userId, refreshToken]
      );

      if (!refreshTokenRow) {
        throw new Error("Refresh token is invalid");
      }

      await this.fetchAndCacheUserClaims(decoded.userId);

      return this.generateTokens(decoded.userId);
    } catch (error) {
      throw new Error("Invalid refresh token");
    }
  }

  public async validateToken(token: string) {
    try {
      return jwt.verify(token, this.JWT_SECRET) as {
        userId: number;
        username: string;
      };
    } catch (error) {
      throw new Error("Invalid token");
    }
  }

  public async logout(userId: number) {
    await this.executeSingleRowQuery("DELETE FROM administration.refresh_token WHERE user_id = $1", [userId]);

    await this._cache.deleteKey(`user_access_level:${userId}`);
    await this._cache.deleteKey(`user_access_type:${userId}`);
  }
}
