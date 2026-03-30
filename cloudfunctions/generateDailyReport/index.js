/**
 * generateDailyReport — 每日 AI 复盘报告生成（增强版）
 *
 * 触发方式：定时触发器（交易日 15:30）或手动调用
 * 流程：抓取行情 → 聚合打卡 → 拉取社区帖子 → 计算情绪趋势 → DeepSeek 生成 → 存入 ai_reports + sentiment_history
 */
const tcb = require('@cloudbase/node-sdk');
const https = require('https');
const http = require('http');

const ENV_ID = 'prod-1-3g3ukjzod3d5e3a1';
const app = tcb.init({ env: ENV_ID });
const db = app.database();
const _ = db.command;

// ─── 行情抓取 ───

/**
 * @param {string} url
 * @returns {Promise<string>}
 */
function httpGet(url) {
  const client = url.startsWith('https') ? https : http;
  return new Promise((resolve, reject) => {
    client.get(url, { timeout: 10000 }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

/**
 * 解析腾讯财经行情字符串
 * 格式: v_sh000001="1~上证指数~000001~3250.12~3258.00~..."
 */
function parseTencentQuote(raw) {
  const match = raw.match(/"([^"]+)"/);
  if (!match) return null;
  const parts = match[1].split('~');
  if (parts.length < 35) return null;
  return {
    name: parts[1],
    code: parts[2],
    close: parseFloat(parts[3]),
    prevClose: parseFloat(parts[4]),
    open: parseFloat(parts[5]),
    volume: parts[37] || parts[36] || '',
    change: parseFloat(parts[31]) || 0,
    changePercent: parseFloat(parts[32]) || 0,
  };
}

async function fetchMarketData() {
  const symbols = {
    shIndex: 'sh000001',
    szIndex: 'sz399001',
    cyIndex: 'sz399006',
  };
  const result = {};
  for (const [key, symbol] of Object.entries(symbols)) {
    try {
      const raw = await httpGet(`http://qt.gtimg.cn/q=${symbol}`);
      const parsed = parseTencentQuote(raw);
      if (parsed) result[key] = parsed;
    } catch (e) {
      console.warn(`[fetchMarketData] ${key} 失败:`, e.message);
    }
  }
  return result;
}

// ─── 打卡聚合（含幅度分布） ───

async function fetchCheckInStats(dateStr) {
  const { data } = await db.collection('check_ins').where({ date: dateStr }).get();
  const total = data.length;
  const yesCount = data.filter((d) => d.result === 'yes').length;
  const noCount = data.filter((d) => d.result === 'no').length;
  const neutralCount = data.filter((d) => d.result === 'neutral').length;

  const magnitudeDist = { big_win: 0, small_win: 0, neutral: 0, small_loss: 0, big_loss: 0 };
  for (const d of data) {
    if (d.magnitude && magnitudeDist[d.magnitude] !== undefined) {
      magnitudeDist[d.magnitude]++;
    }
  }
  const hasMagnitude = Object.values(magnitudeDist).some((v) => v > 0);

  return {
    totalCheckIns: total,
    yesCount,
    noCount,
    neutralCount,
    yesPercent: total > 0 ? Math.round((yesCount / total) * 100) : 0,
    magnitudeDist: hasMagnitude ? magnitudeDist : null,
  };
}

// ─── 社区帖子拉取 ───

async function fetchTodayPosts(dateStr) {
  const dayStart = new Date(dateStr + 'T00:00:00+08:00').getTime();
  const dayEnd = dayStart + 86400000;

  try {
    const { data } = await db
      .collection('user_posts')
      .where({
        createdAt: _.gte(dayStart).and(_.lt(dayEnd)),
        isDeleted: _.neq(true),
      })
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    const tagCount = {};
    for (const post of data) {
      if (Array.isArray(post.tags)) {
        for (const tag of post.tags) {
          tagCount[tag] = (tagCount[tag] || 0) + 1;
        }
      }
    }
    const hotTags = Object.entries(tagCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([tag]) => tag);

    const samplePosts = data
      .filter((p) => p.content && p.content.length > 5)
      .slice(0, 8)
      .map((p) => (p.content.length > 100 ? p.content.slice(0, 100) + '…' : p.content));

    return { postCount: data.length, hotTags, samplePosts };
  } catch (e) {
    console.warn('[fetchTodayPosts] 失败:', e.message);
    return { postCount: 0, hotTags: [], samplePosts: [] };
  }
}

// ─── 情绪趋势（近 7 天） ───

async function fetchSentimentTrend(todayStr, days = 7) {
  const dates = [];
  const base = new Date(todayStr + 'T12:00:00+08:00');
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(base);
    d.setDate(d.getDate() - i);
    dates.push(
      `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    );
  }

  const trend = [];
  for (const date of dates) {
    const { data } = await db
      .collection('check_ins')
      .where({ date })
      .get()
      .catch(() => ({ data: [] }));
    const total = data.length;
    if (total === 0) {
      trend.push({ date, yesPercent: null, total: 0 });
    } else {
      const yesCount = data.filter((d) => d.result === 'yes').length;
      trend.push({ date, yesPercent: Math.round((yesCount / total) * 100), total });
    }
  }

  const validPoints = trend.filter((t) => t.yesPercent !== null);
  let trendDesc = '数据不足';
  if (validPoints.length >= 3) {
    const recent3 = validPoints.slice(-3).map((t) => t.yesPercent);
    if (recent3[2] < recent3[1] && recent3[1] < recent3[0]) trendDesc = '持续走低';
    else if (recent3[2] > recent3[1] && recent3[1] > recent3[0]) trendDesc = '持续走高';
    else if (Math.abs(recent3[2] - recent3[0]) <= 5) trendDesc = '横盘震荡';
    else trendDesc = '波动反复';
  }

  return {
    trend,
    trendLine: validPoints.map((t) => `${t.yesPercent}%`).join(' → '),
    trendDesc,
  };
}

// ─── DeepSeek 生成 ───

function buildPrompt(market, sentiment, posts, sentimentTrend) {
  const sh = market.shIndex;
  const sz = market.szIndex;
  const cy = market.cyIndex;

  let prompt = `你是"赚了吗"App 的 AI 投资教练"赚哥"。你的特点：
- 说人话，不说废话，像朋友聊天一样
- 有自己的观点，不做两头讨好的分析
- 关注散户的情绪，而不只是数据
- 适当幽默，但不轻浮
- 绝对不荐股，不给具体买卖建议
- 把社区讨论和市场数据交叉分析，不要分开说

今天的全部素材如下：

【市场数据】
- 上证指数：${sh ? sh.close : '暂无'}（${sh ? (sh.changePercent >= 0 ? '+' : '') + sh.changePercent + '%' : '暂无'}）
- 深证成指：${sz ? sz.close : '暂无'}（${sz ? (sz.changePercent >= 0 ? '+' : '') + sz.changePercent + '%' : '暂无'}）
- 创业板指：${cy ? cy.close : '暂无'}（${cy ? (cy.changePercent >= 0 ? '+' : '') + cy.changePercent + '%' : '暂无'}）

【散户体感】
- 今天 ${sentiment.totalCheckIns} 人打卡，${sentiment.yesPercent}% 觉得自己赚了`;

  if (sentiment.magnitudeDist) {
    const m = sentiment.magnitudeDist;
    prompt += `\n- 盈亏分布：大赚 ${m.big_win} 人 / 小赚 ${m.small_win} 人 / 持平 ${m.neutral} 人 / 小亏 ${m.small_loss} 人 / 大亏 ${m.big_loss} 人`;
  }

  if (sentimentTrend.trendLine) {
    prompt += `\n\n【情绪趋势（近 7 天赚钱比例）】
${sentimentTrend.trendLine}
趋势判断：${sentimentTrend.trendDesc}`;
  }

  if (posts.postCount > 0) {
    prompt += `\n\n【社区热议（今日 ${posts.postCount} 条帖子）】`;
    if (posts.hotTags.length > 0) {
      prompt += `\n- 热门话题标签：${posts.hotTags.join('、')}`;
    }
    if (posts.samplePosts.length > 0) {
      prompt += `\n- 代表性发言：`;
      posts.samplePosts.forEach((p, i) => {
        prompt += `\n  ${i + 1}. "${p}"`;
      });
    }
  }

  prompt += `

请基于以上所有素材，生成一篇有洞察力的复盘。要求：社区讨论和市场数据要交叉分析，不要分开说。

严格以 JSON 格式返回（不要包含任何其他文字，不要用 markdown 代码块包裹）：
{
  "oneLiner": "一句话总结（15字以内，像朋友圈标题，要有信息量）",
  "summary": "今日复盘（150-200字，口语化，有观点，融合市场数据和社区讨论）",
  "insight": "情绪洞察（结合情绪趋势、盈亏分布和社区讨论，60-100字）",
  "outlook": "明日展望（50-80字，给方向感但不荐股）"
}`;

  return prompt;
}

async function generateWithDeepSeek(prompt) {
  const ai = app.ai();
  const model = ai.createModel('deepseek');

  const result = await model.generateText({
    model: 'deepseek-v3.2',
    messages: [
      { role: 'system', content: '你是一个 JSON 输出助手，只输出纯 JSON，不输出任何其他文字。' },
      { role: 'user', content: prompt },
    ],
  });

  let text = result.text.trim();
  if (text.startsWith('```')) {
    text = text.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
  }

  return { parsed: JSON.parse(text), usage: result.usage };
}

// ─── sentiment_history 存档 ───

async function saveSentimentHistory(dateStr, sentiment, market, posts) {
  const historyId = `sentiment_${dateStr.replace(/-/g, '')}`;
  const record = {
    date: dateStr,
    yesPercent: sentiment.yesPercent,
    totalCheckIns: sentiment.totalCheckIns,
    magnitudeDist: sentiment.magnitudeDist || null,
    shChange: market.shIndex?.changePercent || null,
    szChange: market.szIndex?.changePercent || null,
    cyChange: market.cyIndex?.changePercent || null,
    postCount: posts.postCount,
    hotTopics: posts.hotTags,
    createdAt: Date.now(),
  };

  try {
    await db.collection('sentiment_history').doc(historyId).set(record);
    console.log(`[saveSentimentHistory] ✅ ${dateStr} 存档完成`);
  } catch (e) {
    console.warn(`[saveSentimentHistory] 存档失败（不影响报告生成）:`, e.message);
  }
}

// ─── 主函数 ───

exports.main = async (event) => {
  const now = new Date();
  const dateStr =
    event.date ||
    `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

  console.log(`[generateDailyReport] 开始生成 ${dateStr} 日报`);

  const reportId = `report_${dateStr.replace(/-/g, '')}`;
  const { data: existing } = await db.collection('ai_reports').doc(reportId).get().catch(() => ({ data: null }));
  if (existing && !event.force) {
    console.log(`[generateDailyReport] ${dateStr} 已存在，跳过`);
    return { code: 0, message: '报告已存在', data: existing };
  }

  // 1. 并行拉取所有数据
  const [market, sentiment, posts, sentimentTrend] = await Promise.all([
    fetchMarketData(),
    fetchCheckInStats(dateStr),
    fetchTodayPosts(dateStr),
    fetchSentimentTrend(dateStr, 7),
  ]);

  console.log('[generateDailyReport] 行情:', JSON.stringify(market));
  console.log('[generateDailyReport] 情绪:', JSON.stringify(sentiment));
  console.log('[generateDailyReport] 社区帖子:', posts.postCount, '条, 热词:', posts.hotTags);
  console.log('[generateDailyReport] 情绪趋势:', sentimentTrend.trendLine, sentimentTrend.trendDesc);

  // 2. DeepSeek 生成
  const prompt = buildPrompt(market, sentiment, posts, sentimentTrend);
  const { parsed: aiContent, usage } = await generateWithDeepSeek(prompt);
  console.log('[generateDailyReport] AI 生成完毕, tokens:', usage);

  // 3. 组装文档
  const reportData = {
    date: dateStr,
    type: 'daily',
    marketData: {
      shIndex: market.shIndex || null,
      szIndex: market.szIndex || null,
      cyIndex: market.cyIndex || null,
    },
    sentimentData: sentiment,
    aiContent,
    model: 'deepseek-v3.2',
    usage,
    createdAt: Date.now(),
  };

  // 4. 写入报告 + 存档 sentiment_history（并行）
  await Promise.all([
    db.collection('ai_reports').doc(reportId).set(reportData),
    saveSentimentHistory(dateStr, sentiment, market, posts),
  ]);

  const report = { _id: reportId, ...reportData };

  console.log(`[generateDailyReport] ✅ ${dateStr} 报告已保存`);
  return { code: 0, message: '生成成功', data: report };
};
