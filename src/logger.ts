const PREFIX = "[react-native-vungle]";

export type VungleLogLevel = "debug" | "info" | "warn" | "error";

let loggingEnabled = typeof __DEV__ !== "undefined" ? __DEV__ : true;

export function setJsLoggingEnabled(enabled: boolean): void {
  loggingEnabled = enabled;
}

export function isJsLoggingEnabled(): boolean {
  return loggingEnabled;
}

function log(level: VungleLogLevel, step: string, detail?: string): void {
  if (!loggingEnabled) {
    return;
  }
  const line = detail === undefined ? `${PREFIX} [${level}] ${step}` : `${PREFIX} [${level}] ${step} — ${detail}`;
  switch (level) {
    case "debug":
      console.debug(line);
      break;
    case "info":
      console.info(line);
      break;
    case "warn":
      console.warn(line);
      break;
    case "error":
      console.error(line);
      break;
    default:
      console.log(line);
  }
}

export const vungleLog = {
  debug(step: string, detail?: string) {
    log("debug", step, detail);
  },
  info(step: string, detail?: string) {
    log("info", step, detail);
  },
  warn(step: string, detail?: string) {
    log("warn", step, detail);
  },
  error(step: string, detail?: string) {
    log("error", step, detail);
  },
};
