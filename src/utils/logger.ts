import path from "path";
import { createLogger, format, transports } from "winston";
import DailyRotateFile from "winston-daily-rotate-file";

const LOG_DIR = process.env.LOG_DIR
  ? path.resolve(process.env.LOG_DIR)
  : path.join(process.cwd(), "..", "ais-logs");

const LOG_MAX_FILES = process.env.LOG_MAX_FILES ?? "14d";
const LOG_ZIP_ARCHIVE = process.env.LOG_ZIP_ARCHIVE === "true";

const jsonFormat = format.combine(
  format.timestamp({ format: "YYYY-MM-DDTHH:mm:ss.SSSZ" }),
  format.errors({ stack: true }),
  format.json()
);

const dailyRotateTransport = new DailyRotateFile({
  dirname: LOG_DIR,
  filename: "app-%DATE%.log",
  datePattern: "YYYY-MM-DD",
  zippedArchive: LOG_ZIP_ARCHIVE,
  maxFiles: LOG_MAX_FILES,
  format: jsonFormat,
});

const consoleTransport = new transports.Console({
  format: format.combine(
    format.colorize(),
    format.timestamp({ format: "YYYY-MM-DDTHH:mm:ss.SSSZ" }),
    format.printf(({ timestamp, level, message, logtype, context, ...rest }) => {
      const ctx = context ? `[${context}]` : "";
      const extras = Object.keys(rest).length ? ` ${JSON.stringify(rest)}` : "";
      return `${timestamp} ${level} ${ctx} ${message}${extras}`;
    })
  ),
});

const appLogger = createLogger({
  level: "info",
  transports: [dailyRotateTransport, consoleTransport],
  exitOnError: false,
});

export interface LogEntry {
  context: string;
  message: string;
  status?: number;
  method?: string;
  path?: string;
  errorMessage?: string;
  stack?: string;
  query?: string;
  requestId?: string;
  [key: string]: unknown;
}

export function logError(entry: LogEntry): void {
  appLogger.error(entry.message, { logtype: "error", ...entry });
}

export function logWarn(entry: LogEntry): void {
  appLogger.warn(entry.message, { logtype: "warn", ...entry });
}

export function logInfo(entry: LogEntry): void {
  appLogger.info(entry.message, { logtype: "info", ...entry });
}

export default appLogger;
