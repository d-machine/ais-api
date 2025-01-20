import { Context } from "hono";
import AuthService from "../services/auth.service.js";

export default class AuthController {
  protected authService: AuthService;

  constructor() {
    this.authService = new AuthService();
    this.login = this.login.bind(this);
    this.refresh = this.refresh.bind(this);
    this.logout = this.logout.bind(this);
  }

  async login(c: Context) {
    const body = await c.req.json();

    if (!body.username || !body.password) {
      return c.json({ error: "Username and password are required" }, 400);
    }

    try {
      const result = await this.authService.login(body.username, body.password);

      return c.json(result, 200);
    } catch (error) {
      console.log("Error logging in:", error);
      return c.json({ error: "An error occurred while logging in" }, 500);
    }
  }

  async refresh(c: Context) {
    const body = await c.req.json();

    if (!body.refreshToken) {
      return c.json({ error: "Refresh token is required" }, 400);
    }

    try {
      const result = await this.authService.refresh(body.refreshToken);

      return c.json(result, 200);
    } catch (error) {
      console.log("Error refreshing token:", error);
      return c.json({ error: "An error occurred while refreshing token" }, 500);
    }
  }

  async logout(c: Context) {
    const userId = c.get("userId");

    try {
      await this.authService.logout(userId);

      return c.json({ success: true }, 200);
    } catch (error) {
      console.log("Error logging out:", error);
      return c.json({ error: "An error occurred while logging out" }, 500);
    }
  }
}
