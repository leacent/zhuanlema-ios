/**
 * @cloudbase/node-sdk mock
 * 为云函数单元测试提供可控的 mock 实现
 *
 * 用法：在测试中通过 mockCollection / mockAI 等控制返回值
 * 示例：
 *   const sdk = require("@cloudbase/node-sdk");
 *   sdk.__mockCollection("users", { get: jest.fn().mockResolvedValue({ data: [...] }) });
 */

// ---- 内部状态 ----

/** 集合级 mock：{ collectionName: { get, add, remove, update, ... } } */
const _collections = {};

/** AI mock */
let _aiGenerateText = jest.fn().mockResolvedValue({ text: "测试昵称" });
let _aiCreateModel = jest.fn().mockReturnValue({ generateText: _aiGenerateText });

/** getTempFileURL mock */
let _getTempFileURL = jest.fn().mockResolvedValue({ fileList: [] });

/** auth mock */
let _getUserInfo = jest.fn().mockReturnValue({ uid: "test-uid", customUserId: null });

// ---- doc / collection builder ----

function createDocRef(collectionName, docId) {
  const col = _collections[collectionName] || {};
  return {
    get: col.docGet || jest.fn().mockResolvedValue({ data: [] }),
    set: col.docSet || jest.fn().mockResolvedValue({}),
    update: col.docUpdate || jest.fn().mockResolvedValue({}),
    remove: col.docRemove || jest.fn().mockResolvedValue({ deleted: 1 }),
  };
}

function createCollectionRef(name) {
  const col = _collections[name] || {};
  const ref = {
    doc: (id) => createDocRef(name, id),
    where: col.where || jest.fn().mockReturnValue({
      limit: jest.fn().mockReturnValue({
        get: col.get || jest.fn().mockResolvedValue({ data: [] }),
      }),
      get: col.get || jest.fn().mockResolvedValue({ data: [] }),
      remove: col.remove || jest.fn().mockResolvedValue({ deleted: 0 }),
    }),
    limit: jest.fn().mockReturnValue({
      get: col.get || jest.fn().mockResolvedValue({ data: [] }),
    }),
    get: col.get || jest.fn().mockResolvedValue({ data: [] }),
    add: col.add || jest.fn().mockResolvedValue({ id: "mock-id" }),
  };
  return ref;
}

// ---- 公开 API（与真实 SDK 同构） ----

const database = jest.fn().mockReturnValue({
  collection: jest.fn((name) => createCollectionRef(name)),
});

const auth = jest.fn().mockReturnValue({
  getUserInfo: (...args) => _getUserInfo(...args),
});

const ai = jest.fn().mockReturnValue({
  createModel: (...args) => _aiCreateModel(...args),
});

const init = jest.fn().mockReturnValue({
  database,
  auth,
  ai,
  getTempFileURL: (...args) => _getTempFileURL(...args),
});

// ---- 测试辅助方法 ----

/** 设置某个集合的 mock 行为 */
function __mockCollection(name, overrides) {
  _collections[name] = { ..._collections[name], ...overrides };
}

/** 设置 AI generateText 的返回值 */
function __mockAIGenerateText(result) {
  _aiGenerateText.mockResolvedValue(result);
}

/** 设置 auth.getUserInfo 的返回值 */
function __mockAuthGetUserInfo(result) {
  _getUserInfo.mockReturnValue(result);
}

/** 重置所有 mock 状态 */
function __resetAllMocks() {
  Object.keys(_collections).forEach((k) => delete _collections[k]);
  _aiGenerateText.mockResolvedValue({ text: "测试昵称" });
  _getUserInfo.mockReturnValue({ uid: "test-uid", customUserId: null });
  _getTempFileURL.mockResolvedValue({ fileList: [] });
  init.mockClear();
  database.mockClear();
  auth.mockClear();
  ai.mockClear();
}

module.exports = {
  init,
  __mockCollection,
  __mockAIGenerateText,
  __mockAuthGetUserInfo,
  __resetAllMocks,
};
