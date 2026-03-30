/**
 * aiMarketBrief — 实时三大指数 + AI 盘面简报
 *
 * 参数（经 parseEvent 合并）：可选 { hint?: string }，hint 会经 sanitize 后写入素材（可扩展）
 */
const https = require('https');
const http = require('http');
const { app, parseEvent, sanitizeUserContent } = require('./cloudbase-common');

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

function parseTencentQuote(raw) {
  const match = raw.match(/"([^"]+)"/);
  if (!match) return null;
  const parts = match[1].split('~');
  if (parts.length < 35) return null;

  const close = parseFloat(parts[3]);
  const prevClose = parseFloat(parts[4]);
  const changePercent = parseFloat(parts[32]) || 0;

  if (isNaN(close) || close <= 0 || isNaN(prevClose) || prevClose <= 0) {
    return null;
  }

  return {
    name: parts[1],
    code: parts[2],
    close,
    prevClose,
    changePercent,
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
      const raw = await httpGet(`https://qt.gtimg.cn/q=${symbol}`);
      const parsed = parseTencentQuote(raw);
      if (parsed) result[key] = parsed;
    } catch (e) {
      console.warn(`[aiMarketBrief] ${key} 请求失败:`, e.message);
    }
  }

  return result;
}

function buildPrompt(market, hintLine) {
  const fmt = (key) => {
    const q = market[key];
    if (!q) return '- 暂无数据';
    const sign = q.changePercent >= 0 ? '+' : '';
    return `- ${q.name}：${q.close}（${sign}${q.changePercent}%）`;
  };

  let prompt = `根据下列行情写一段 80 字以内的口语化盘面简报（像朋友聊天）。
不荐股、不预测明日涨跌、不编造新闻或政策。

【行情】
${fmt('shIndex')}
${fmt('szIndex')}
${fmt('cyIndex')}`;

  if (hintLine) {
    prompt += `\n\n【用户补充】\n${hintLine}`;
  }

  return prompt;
}

exports.main = async (event) => {
  const params = parseEvent(event);
  const hintLine = params.hint ? sanitizeUserContent(String(params.hint), 100) : '';

  try {
    const market = await fetchMarketData();
    if (!market.shIndex && !market.szIndex && !market.cyIndex) {
      return { success: false, message: '行情获取失败' };
    }

    const ai = app.ai();
    const model = ai.createModel('deepseek');

    const result = await model.generateText({
      model: 'deepseek-v3.2',
      messages: [
        { role: 'system', content: '你是"赚了吗"App 的盘面播报助手，只输出简报正文，不要标题或列表符号。' },
        { role: 'user', content: buildPrompt(market, hintLine) },
      ],
    });

    const stripForClient = (q) =>
      q ? { name: q.name, close: q.close, changePercent: q.changePercent } : null;

    return {
      success: true,
      data: {
        brief: (result.text || '').trim(),
        marketData: {
          shIndex: stripForClient(market.shIndex),
          szIndex: stripForClient(market.szIndex),
          cyIndex: stripForClient(market.cyIndex),
        },
        usage: result.usage,
      },
    };
  } catch (error) {
    console.error('[aiMarketBrief] 错误:', error);
    return { success: false, message: error.message };
  }
};
