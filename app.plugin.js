const { createRunOncePlugin, withInfoPlist } = require("@expo/config-plugins");

/**
 * Optional Expo config plugin for `react-native-vungle`.
 *
 * @param {import('@expo/config-types').ExpoConfig} config
 * @param {{
 *   skAdNetworkIdentifiers?: string[];
 * }} [props]
 */
function withReactNativeVungle(config, props = {}) {
  const ids = props.skAdNetworkIdentifiers;
  if (!Array.isArray(ids) || ids.length === 0) {
    return config;
  }

  return withInfoPlist(config, (configMod) => {
    const existing = configMod.modResults.SKAdNetworkItems ?? [];
    const merged = [...existing];
    for (const id of ids) {
      if (typeof id !== "string" || id.length === 0) {
        continue;
      }
      const exists = merged.some((item) => item?.SKAdNetworkIdentifier === id);
      if (!exists) {
        merged.push({ SKAdNetworkIdentifier: id });
      }
    }
    configMod.modResults.SKAdNetworkItems = merged;
    return configMod;
  });
}

module.exports = createRunOncePlugin(
  withReactNativeVungle,
  "react-native-vungle",
  "react-native-vungle"
);
