/**
 * 获取热门股票排行榜云函数（全量、多市场）
 * 代理东方财富 API：A股/港股/美股 涨幅榜、跌幅榜、活跃榜
 *
 * @param {Object} event - 云函数事件参数
 * @param {string} event.type - 榜单类型: 'gainers' | 'losers' | 'active'
 * @param {string} event.region - 市场: 'a_share' | 'hong_kong' | 'us'
 * @returns {Object} - 返回标准化股票列表，与 App WatchlistItem 对齐
 */
const https = require('https');

const PZ_FULL = 100; // 全量条数，东方财富风格

function httpsGet(url) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://quote.eastmoney.com/'
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
      res.on('error', reject);
    }).on('error', reject);
  });
}

/**
 * 东方财富 fs 参数：按市场与类型
 * A股: m:0+t:6,m:0+t:80
 * 港股: m:128+t:3,m:128+t:4,m:128+t:1,m:128+t:2
 * 美股: m:105+t:53,m:106+t:53 (纽交所+纳斯达克)
 */
function getFs(region) {
  switch (region) {
    case 'hong_kong':
      return 'm:128+t:3,m:128+t:4,m:128+t:1,m:128+t:2';
    case 'us':
      return 'm:105+t:53,m:106+t:53';
    case 'a_share':
    default:
      return 'm:0+t:6,m:0+t:80';
  }
}

/** 生成 App 使用的 code：A股 sh/sz，港股 hk，美股 us */
function toMarketCode(region, f12, f13) {
  const code = String(f12 || '').trim();
  if (!code) return '';
  if (region === 'hong_kong') return 'hk' + code;
  if (region === 'us') return 'us' + code;
  if (f13 === 1) return 'sh' + code;
  if (f13 === 0) return 'sz' + code;
  return code.startsWith('6') ? 'sh' + code : 'sz' + code;
}

exports.main = async (event, context) => {
  try {
    const { type = 'gainers', region = 'a_share' } = event;
    const fs = getFs(region);

    let fid = 'f3';
    let po = 1;
    if (type === 'gainers') { fid = 'f3'; po = 1; }
    else if (type === 'losers') { fid = 'f3'; po = 0; }
    else if (type === 'active') { fid = 'f20'; po = 1; }

    const url = `https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=${PZ_FULL}&po=${po}&np=1&fltt=2&invt=2&fid=${fid}&fs=${encodeURIComponent(fs)}&fields=f2,f3,f4,f12,f13,f14,f20`;
    console.log('[getHotStocks] type=%s region=%s', type, region);

    const response = await httpsGet(url);
    const jsonData = JSON.parse(response);

    if (!jsonData || !jsonData.data || !Array.isArray(jsonData.data.diff)) {
      return { success: false, message: 'API 返回数据为空', data: [] };
    }

    const list = jsonData.data.diff
      .filter(item => item.f14)
      .map(item => {
        const code = toMarketCode(region, item.f12, item.f13);
        const changePercent = item.f3 != null ? Number(item.f3) : 0;
        const volume = item.f20 != null ? Math.round(Number(item.f20)) : 0;
        return {
          code,
          name: String(item.f14 || '').trim(),
          price: item.f2 != null ? Number(item.f2) : null,
          changePercent,
          volume: volume > 0 ? volume : null
        };
      });

    console.log('[getHotStocks] 成功 type=%s region=%s count=%d', type, region, list.length);
    return {
      success: true,
      data: list,
      message: `获取排行榜成功`
    };
  } catch (error) {
    console.error('[getHotStocks] 错误:', error);
    return {
      success: false,
      message: error.message || '获取排行榜失败',
      data: []
    };
  }
};
