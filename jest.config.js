/**
 * Jest configuration for CloudBase cloud functions
 * 每个云函数的测试放在 cloudfunctions/<name>/__tests__/ 下
 */
module.exports = {
  testEnvironment: "node",
  roots: ["<rootDir>/cloudfunctions"],
  testMatch: ["**/__tests__/**/*.test.js"],
  // 全局 mock @cloudbase/node-sdk，避免真实连接
  moduleNameMapper: {
    "^@cloudbase/node-sdk$": "<rootDir>/cloudfunctions/__mocks__/@cloudbase/node-sdk.js",
  },
  collectCoverageFrom: [
    "cloudfunctions/*/index.js",
    "!cloudfunctions/__mocks__/**",
  ],
};
