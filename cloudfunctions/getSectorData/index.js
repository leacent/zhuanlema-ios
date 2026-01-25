/**
 * 获取板块数据云函数（全量、按市场）
 * A股：东方财富 行业/概念；港股：东方财富列表+代表股聚合（缺则个股接口补全）；美股：东方财富行业ETF（新浪/腾讯无公开板块列表接口）
 *
 * @param {Object} event - 云函数事件参数
 * @param {string} event.type - 板块类型: 'industry' | 'concept'
 * @param {string} event.region - 市场: 'a_share' | 'hong_kong' | 'us'
 * @returns {Object} - 返回标准化的板块数据
 */
const https = require('https');

const PZ_FULL = 80;

function httpsGet(url, referer = 'https://quote.eastmoney.com/') {
  return new Promise((resolve, reject) => {
    const opts = {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': referer
      }
    };
    const handler = (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
      res.on('error', reject);
    };
    if (url.startsWith('https:')) {
      https.get(url, opts, handler).on('error', reject);
    } else {
      const http = require('http');
      http.get(url, opts, handler).on('error', reject);
    }
  });
}

function formatVolume(amount) {
  if (!amount || amount === 0) return '-';
  if (amount >= 100000000) return (amount / 100000000).toFixed(2) + '亿';
  if (amount >= 10000) return (amount / 10000).toFixed(2) + '万';
  return amount.toString();
}

// 港股行业 + 代表股（用于腾讯行情聚合出真实涨跌幅）
const HK_INDUSTRY_REPRESENTATIVE = [
  { name: '科技', codes: ['00700', '09988', '09618', '09999', '09888'] },
  { name: '金融', codes: ['01288', '02318', '03988', '00939', '03690'] },
  { name: '地产', codes: ['01109', '00813', '00101', '00688', '01997'] },
  { name: '消费', codes: ['01810', '00388', '02319', '09633', '01024'] },
  { name: '医药', codes: ['02269', '01093', '01833', '03759', '02607'] },
  { name: '能源', codes: ['00386', '00883', '00914', '01171', '00338'] },
  { name: '工业', codes: ['00669', '01766', '02357', '01929', '00606'] },
  { name: '电讯', codes: ['00941', '00728', '00384', '00823'] },
  { name: '公用', codes: ['00002', '00003', '02638', '01952'] },
  { name: '综合', codes: ['00001', '00175', '00267', '00688'] }
];

/** 港股代码标准化：统一成无前导0的数字串，便于匹配 */
function normalizeHkCode(c) {
  const s = String(c ?? '').replace(/^0+/, '') || '0';
  return s === '' ? '0' : s;
}

/**
 * 东方财富 港股个股列表（大名单）；用双重 key 存储（原始 + 去前导0）确保匹配
 */
async function fetchEastMoneyHkStockList() {
  const fs = 'm:128+t:3,m:128+t:4,m:128+t:1,m:128+t:2';
  const url = `https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=800&po=1&np=1&fltt=2&invt=2&fid=f3&fs=${encodeURIComponent(fs)}&fields=f2,f3,f4,f12,f14,f20`;
  const response = await httpsGet(url);
  const json = JSON.parse(response);
  if (!json?.data?.diff) return {};
  const out = {};
  json.data.diff.forEach(item => {
    const raw = item.f12 != null ? String(item.f12) : '';
    const normalized = normalizeHkCode(raw);
    const record = {
      name: item.f14 != null ? String(item.f14) : raw,
      changePercent: item.f3 != null ? Number(item.f3) : 0
    };
    const key = normalized || raw;
    if (key) out[key] = record;
  });
  return out;
}

/** 东方财富 单只港股行情（备用：列表无数据时用 secid=128.代码 拉取） */
async function fetchEastMoneyHkSingleQuote(code) {
  const secid = '128.' + String(code).padStart(5, '0');
  const url = `https://push2.eastmoney.com/api/qt/stock/get?secid=${secid}&fields=f43,f44,f45,f57,f58,f169,f170,f46,f60`;
  try {
    const res = await httpsGet(url);
    const json = JSON.parse(res);
    const d = json?.data;
    if (!d) return null;
    const changePercent = d.f170 != null ? Number(d.f170) : (d.f60 != null ? Number(d.f60) : null);
    return {
      name: d.f58 != null ? String(d.f58) : code,
      changePercent: changePercent != null ? changePercent : 0
    };
  } catch (e) {
    return null;
  }
}

/** 在 quoted map 中查找港股代表股；约定 key 为 normalizeHkCode(code)，不写多 key 兜底 */
function getHkQuote(quoted, code) {
  const key = normalizeHkCode(code) || String(code).padStart(5, '0');
  return quoted[key] ?? null;
}

/** 港股：用东方财富列表聚合；若列表无涨跌幅则用个股接口补全代表股 */
async function fetchHKSectorByRepresentative() {
  let quoted = await fetchEastMoneyHkStockList();
  const allCodes = HK_INDUSTRY_REPRESENTATIVE.flatMap(ind => ind.codes);
  const missing = allCodes.filter(c => !getHkQuote(quoted, c));
  if (missing.length > 0) {
    const filled = { ...quoted };
    await Promise.all(missing.slice(0, 40).map(async (code) => {
      const one = await fetchEastMoneyHkSingleQuote(code);
      if (one) {
        const n = normalizeHkCode(code);
        const raw5 = String(code).padStart(5, '0');
        filled[n] = one;
        filled[code] = one;
        filled[raw5] = one;
      }
    }));
    quoted = filled;
  }
  return HK_INDUSTRY_REPRESENTATIVE.map((ind, i) => {
    const items = [];
    for (const c of ind.codes) {
      const q = getHkQuote(quoted, c);
      if (q) items.push(q);
    }
    const changePercents = items.map(x => x.changePercent).filter(n => !isNaN(n));
    const avg = changePercents.length ? changePercents.reduce((a, b) => a + b, 0) / changePercents.length : 0;
    const best = items.length ? items.reduce((a, b) => (b.changePercent > a.changePercent ? b : a)) : null;
    return {
      code: 'hk_hy_' + (i + 1),
      name: ind.name,
      changePercent: Math.round(avg * 100) / 100,
      leadingStock: best ? best.name : '-',
      leadingStockChange: best ? best.changePercent : 0,
      volume: '-'
    };
  });
}

// 美股行业 ETF（东方财富）
const US_SECTOR_ETFS = [
  { code: 'XLK', name: '科技' },
  { code: 'XLF', name: '金融' },
  { code: 'XLE', name: '能源' },
  { code: 'XLV', name: '医疗' },
  { code: 'XLI', name: '工业' },
  { code: 'XLP', name: '消费必需' },
  { code: 'XLY', name: '可选消费' },
  { code: 'XLB', name: '材料' },
  { code: 'XLU', name: '公用' }
];

async function fetchUSSectorFromEastMoneyETFs() {
  const fs = 'm:105+t:53,m:106+t:53';
  const url = `https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=3000&po=1&np=1&fltt=2&invt=2&fid=f3&fs=${encodeURIComponent(fs)}&fields=f2,f3,f4,f12,f14,f20`;
  const response = await httpsGet(url);
  const json = JSON.parse(response);
  if (!json?.data?.diff) return [];
  const set = new Set(US_SECTOR_ETFS.map(e => e.code));
  const byCode = {};
  json.data.diff.forEach(item => {
    if (set.has(item.f12)) {
      byCode[item.f12] = {
        changePercent: item.f3 != null ? Number(item.f3) : 0,
        name: item.f14 || item.f12
      };
    }
  });
  return US_SECTOR_ETFS.map(etf => ({
    code: 'us_' + etf.code,
    name: etf.name,
    changePercent: byCode[etf.code] ? byCode[etf.code].changePercent : 0,
    leadingStock: byCode[etf.code] ? byCode[etf.code].name : '-',
    leadingStockChange: 0,
    volume: '-'
  }));
}

/**
 * 新浪美股行业/板块（该接口为 A 股资金流板块列表，美股通常无数据，仅作尝试）
 * 调研结论：新浪/腾讯无公开免费美股板块列表 API；富途需 OpenD 网关。美股采用东方财富行业 ETF。
 */
async function trySinaUSSector() {
  try {
    const url = 'https://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/MoneyFlow.ssl_bkzj_hylist';
    const res = await httpsGet(url, 'https://finance.sina.com.cn');
    const data = JSON.parse(res);
    if (Array.isArray(data) && data.length > 0) {
      return data.slice(0, 30).map((item, i) => ({
        code: 'sina_us_' + (i + 1),
        name: item.name != null ? String(item.name) : String(i + 1),
        changePercent: typeof item.zdp === 'number' ? item.zdp : (parseFloat(item.zdp) || 0),
        leadingStock: item.lz || '-',
        leadingStockChange: 0,
        volume: item.amount ? formatVolume(Number(item.amount)) : '-'
      }));
    }
  } catch (e) {
    console.log('[getSectorData] 新浪美股板块尝试失败', e.message);
  }
  return null;
}

// 东方财富 港股板块尝试（多组 fs）
async function tryEastMoneyHKSector(type) {
  const fsList = type === 'industry' ? ['m:90+t:5', 'm:128+t:1', 'm:156+t:1'] : ['m:90+t:6', 'm:128+t:2'];
  for (const fs of fsList) {
    try {
      const url = `https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=${PZ_FULL}&po=1&np=1&fltt=2&invt=2&fid=f3&fs=${encodeURIComponent(fs)}&fields=f2,f3,f4,f12,f14,f20,f128,f136,f140`;
      const response = await httpsGet(url);
      const json = JSON.parse(response);
      if (!json?.data?.diff || json.data.diff.length === 0) continue;
      const hasChange = json.data.diff.some(item => item.f3 != null && Number(item.f3) !== 0);
      const sectors = json.data.diff.map(item => ({
        code: item.f12 || '',
        name: item.f14 || '',
        changePercent: item.f3 != null ? Number(item.f3) : 0,
        leadingStock: item.f128 || '',
        leadingStockChange: item.f136 || 0,
        volume: formatVolume(item.f20)
      })).filter(s => s.name);
      if (sectors.length > 0 && (hasChange || sectors.length > 5)) {
        return sectors;
      }
    } catch (e) {
      continue;
    }
  }
  return null;
}

exports.main = async (event, context) => {
  try {
    const { type = 'industry', region = 'a_share' } = event;

    if (region === 'a_share') {
      const fs = type === 'industry' ? 'm:90+t:2' : 'm:90+t:3';
      const url = `https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=${PZ_FULL}&po=1&np=1&fltt=2&invt=2&fs=${encodeURIComponent(fs)}&fields=f2,f3,f4,f12,f14,f20,f128,f136,f140`;
      const response = await httpsGet(url);
      const jsonData = JSON.parse(response);
      if (!jsonData?.data?.diff) {
        return { success: false, message: 'API返回数据为空', data: [] };
      }
      const sectors = jsonData.data.diff.map(item => ({
        code: item.f12 || '',
        name: item.f14 || '',
        changePercent: item.f3 || 0,
        leadingStock: item.f128 || '',
        leadingStockChange: item.f136 || 0,
        volume: formatVolume(item.f20)
      })).filter(s => s.name);
      console.log('[getSectorData] A股 type=%s count=%d', type, sectors.length);
      return { success: true, data: sectors, message: '获取板块成功' };
    }

    if (region === 'hong_kong') {
      let fromApi = await tryEastMoneyHKSector(type);
      if (fromApi && fromApi.length > 0) {
        const hasNonZero = fromApi.some(s => s.changePercent !== 0);
        if (hasNonZero) {
          console.log('[getSectorData] 港股 东方财富 type=%s count=%d', type, fromApi.length);
          return { success: true, data: fromApi, message: '获取板块成功' };
        }
      }
      fromApi = null;
      try {
        const byRepresentative = await fetchHKSectorByRepresentative();
        console.log('[getSectorData] 港股 东方财富代表股聚合 type=%s count=%d', type, byRepresentative.length);
        const list = type === 'concept' ? byRepresentative.map((s, i) => ({ ...s, code: 'hk_gn_' + (i + 1) })) : byRepresentative;
        return { success: true, data: list, message: '港股板块（代表股聚合）' };
      } catch (e) {
        console.error('[getSectorData] 港股代表股聚合失败', e);
        const fallback = HK_INDUSTRY_REPRESENTATIVE.map((ind, i) => ({
          code: type === 'industry' ? 'hk_hy_' + (i + 1) : 'hk_gn_' + (i + 1),
          name: ind.name,
          changePercent: 0,
          leadingStock: '-',
          leadingStockChange: 0,
          volume: '-'
        }));
        return { success: true, data: fallback, message: '港股板块（暂无实时）' };
      }
    }

    if (region === 'us') {
      let sectors = await trySinaUSSector();
      if (sectors && sectors.length > 0) {
        console.log('[getSectorData] 美股 新浪 count=%d', sectors.length);
        return { success: true, data: sectors, message: '美股板块（新浪）' };
      }
      sectors = await fetchUSSectorFromEastMoneyETFs();
      console.log('[getSectorData] 美股 东方财富ETF count=%d', sectors.length);
      return { success: true, data: sectors, message: '美股行业（ETF代表）' };
    }

    return { success: true, data: [], message: '未知市场' };
  } catch (error) {
    console.error('[getSectorData] 错误:', error);
    return { success: false, message: error.message || '获取板块数据失败', data: [] };
  }
};
