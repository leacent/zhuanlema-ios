/**
 * getProfile 云函数单元测试
 *
 * 覆盖场景：
 * 1. 未登录 → 返回失败
 * 2. 已有用户 → 返回现有资料
 * 3. 新用户 → AI 生成昵称 + 随机头像 → 创建文档
 * 4. AI 失败 → 使用预定义随机昵称兜底
 * 5. avatar_pool 为空 → 使用内置兜底头像
 */
const sdk = require("@cloudbase/node-sdk");

// 必须在 require index.js 之前配置 mock
let getProfile;

beforeAll(() => {
  // getProfile/index.js 在顶层调用 cloud.init()，mock 已在 jest.config moduleNameMapper 生效
  getProfile = require("../index").main;
});

afterEach(() => {
  sdk.__resetAllMocks();
});

describe("getProfile", () => {
  test("未登录时返回失败", async () => {
    // auth.getUserInfo 抛出异常（模拟未登录），且 event 无 access_token
    sdk.__mockAuthGetUserInfo(() => { throw new Error("no auth"); });

    const result = await getProfile({}, {});

    expect(result.success).toBe(false);
    expect(result.message).toBe("未登录");
  });

  test("已有用户返回现有资料", async () => {
    const mockUser = {
      _id: "test-uid",
      nickname: "老韭菜",
      avatar: "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a1&size=200",
      phone_number: "13800138000",
      createdAt: 1700000000000,
    };

    sdk.__mockCollection("users", {
      docGet: jest.fn().mockResolvedValue({ data: [mockUser] }),
    });

    const result = await getProfile({}, {});

    expect(result.success).toBe(true);
    expect(result.data.nickname).toBe("老韭菜");
    expect(result.data.avatar).toContain("dicebear.com");
    expect(result.data._id).toBe("test-uid");
  });

  test("新用户 AI 生成昵称 + 随机头像创建文档", async () => {
    // users 集合返回空（新用户）
    sdk.__mockCollection("users", {
      docGet: jest.fn().mockResolvedValue({ data: [] }),
      docSet: jest.fn().mockResolvedValue({}),
    });

    // avatar_pool 返回头像
    sdk.__mockCollection("avatar_pool", {
      get: jest.fn().mockResolvedValue({
        data: [
          { url: "https://api.dicebear.com/7.x/fun-emoji/png?seed=d1&size=200" },
        ],
      }),
    });

    // AI 返回昵称
    sdk.__mockAIGenerateText({ text: "快乐小牛" });

    const result = await getProfile({}, {});

    expect(result.success).toBe(true);
    expect(result.data.nickname).toBe("快乐小牛");
    expect(result.data.avatar).toContain("dicebear.com");
  });

  test("AI 失败时使用预定义随机昵称兜底", async () => {
    sdk.__mockCollection("users", {
      docGet: jest.fn().mockResolvedValue({ data: [] }),
      docSet: jest.fn().mockResolvedValue({}),
    });

    sdk.__mockCollection("avatar_pool", {
      get: jest.fn().mockResolvedValue({
        data: [{ url: "https://example.com/avatar.png" }],
      }),
    });

    // AI 抛出异常
    sdk.__mockAIGenerateText(Promise.reject(new Error("AI 服务不可用")));

    const result = await getProfile({}, {});

    expect(result.success).toBe(true);
    // 昵称不应为 "用户"，应该是预定义池中的随机昵称 + 3位数字
    expect(result.data.nickname).not.toBe("用户");
    expect(result.data.nickname.length).toBeGreaterThan(2);
  });

  test("avatar_pool 为空时使用内置兜底头像", async () => {
    sdk.__mockCollection("users", {
      docGet: jest.fn().mockResolvedValue({ data: [] }),
      docSet: jest.fn().mockResolvedValue({}),
    });

    // avatar_pool 返回空
    sdk.__mockCollection("avatar_pool", {
      get: jest.fn().mockResolvedValue({ data: [] }),
    });

    const result = await getProfile({}, {});

    expect(result.success).toBe(true);
    // 兜底头像应包含 dicebear.com 和 png
    expect(result.data.avatar).toContain("dicebear.com");
    expect(result.data.avatar).toContain("png");
  });
});
