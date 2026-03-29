/**
 * aiChat — AI 追问对话（增强版）
 *
 * 参数：{ userId, message, conversationId? }
 * 流程：加载用户上下文（打卡+发帖+报告） → 组装 System Prompt → DeepSeek 生成 → 存储对话
 */
const tcb = require('@cloudbase/node-sdk');

const app = tcb.init({ env: 'prod-1-3g3ukjzod3d5e3a1' });
const db = app.database();
const _ = db.command;

const MAX_HISTORY_TURNS = 10;

const MAGNITUDE_LABELS = {
  big_win: '大赚',
  small_win: '小赚',
  neutral: '持平',
  small_loss: '小亏',
  big_loss: '大亏',
};

// ─── 用户上下文 ───

async function loadUserContext(userId) {
  const now = new Date();
  const dates = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    dates.push(
      `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    );
  }

  // 并行拉取：打卡记录 + 用户发帖 + 今日报告
  const today = dates[0];
  const reportId = `report_${today.replace(/-/g, '')}`;

  const [checkInsResult, postsResult, reportResult] = await Promise.all([
    db
      .collection('check_ins')
      .where({ _openid: userId, date: _.in(dates) })
      .orderBy('date', 'desc')
      .get()
      .catch(() => ({ data: [] })),
    db
      .collection('user_posts')
      .where({ userId, isDeleted: _.neq(true) })
      .orderBy('createdAt', 'desc')
      .limit(5)
      .get()
      .catch(() => ({ data: [] })),
    db.collection('ai_reports').doc(reportId).get().catch(() => ({ data: null })),
  ]);

  const checkIns = checkInsResult.data;
  const userPosts = postsResult.data;
  const report = reportResult.data;

  // 打卡记录（含幅度）
  const recentResults = dates.map((date) => {
    const found = checkIns.find((c) => c.date === date);
    if (!found) return '未打卡';
    const magnitudeLabel = found.magnitude ? MAGNITUDE_LABELS[found.magnitude] : null;
    if (magnitudeLabel) return magnitudeLabel;
    return found.result === 'yes' ? '赚了' : found.result === 'neutral' ? '持平' : '亏了';
  });

  // 情绪趋势描述
  const checkedResults = recentResults.filter((r) => r !== '未打卡');
  let emotionTrend = '数据不足';
  if (checkedResults.length >= 3) {
    const lossLabels = new Set(['亏了', '小亏', '大亏']);
    const winLabels = new Set(['赚了', '小赚', '大赚']);
    const lastThree = checkedResults.slice(0, 3);
    const losses = lastThree.filter((r) => lossLabels.has(r)).length;
    const wins = lastThree.filter((r) => winLabels.has(r)).length;
    if (losses === 3) emotionTrend = '连续亏损';
    else if (wins === 3) emotionTrend = '连续盈利';
    else if (losses >= 2) emotionTrend = '近期偏亏';
    else if (wins >= 2) emotionTrend = '近期偏赚';
    else emotionTrend = '盈亏交替';

    if (checkedResults.some((r) => r === '大亏')) emotionTrend += '，有大亏经历';
  }

  // 连续打卡天数
  let streakDays = 0;
  for (const r of recentResults) {
    if (r === '未打卡') break;
    streakDays++;
  }

  // 今日报告摘要
  const todaySummary = report?.aiContent?.summary || report?.aiContent?.oneLiner || '暂无今日报告';

  // 用户最近发帖（带日期）
  const recentPosts = userPosts.map((p) => {
    const d = new Date(p.createdAt);
    const dateLabel = `${d.getMonth() + 1}/${d.getDate()}`;
    const content = p.content.length > 80 ? p.content.slice(0, 80) + '…' : p.content;
    return `[${dateLabel}] "${content}"`;
  });

  return { recentResults, emotionTrend, streakDays, todaySummary, recentPosts };
}

function buildSystemPrompt(ctx) {
  let prompt = `你是"赚了吗"App 的 AI 投资教练"赚哥"。

关于你：
- 你是一个懂投资、更懂散户心理的朋友
- 你说人话，有观点，不打官腔
- 你的第一反应是关注用户的情绪状态，其次才是给分析
- 你绝对不荐股，不给具体买卖建议，但会帮用户理清思路
- 回复控制在 200 字以内，简洁有力
- 当用户情绪激动时，先共情再分析
- 你的回复要体现出你"认识"这位用户——引用他的打卡记录、发帖内容来证明你了解他

关于这位用户：
- 近 7 天打卡: ${ctx.recentResults.join(' → ')}
- 情绪趋势: ${ctx.emotionTrend}
- 已连续打卡 ${ctx.streakDays} 天
- 今日市场概况: ${ctx.todaySummary}`;

  if (ctx.recentPosts.length > 0) {
    prompt += `\n- 最近发帖：\n${ctx.recentPosts.map((p, i) => `  ${i + 1}. ${p}`).join('\n')}`;
  }

  prompt += `

重要：
1. 不要问"你今天做了什么操作"这种你已经知道答案的问题。
2. 回复时自然地融入你对用户的了解（打卡记录、发帖内容），让用户感觉"你真的懂我"。
3. 如果用户情绪低落（连续亏损、大亏），优先共情安慰，不要急着分析。
4. 如果用户问与投资无关的问题，友善地引导回投资复盘话题。`;

  return prompt;
}

// ─── 对话管理 ───

async function loadConversation(conversationId) {
  if (!conversationId) return null;
  const { data } = await db
    .collection('ai_conversations')
    .doc(conversationId)
    .get()
    .catch(() => ({ data: null }));
  return data;
}

// ─── 主函数 ───

exports.main = async (event) => {
  const { userId, message, conversationId } = event;

  if (!userId || !message) {
    return { success: false, message: '缺少 userId 或 message' };
  }

  try {
    // 1. 加载用户上下文（打卡+发帖+报告，并行查询）
    const ctx = await loadUserContext(userId);

    // 2. 加载或创建对话
    const conv = await loadConversation(conversationId);
    const history = conv?.messages || [];

    // 3. 组装消息（System + 历史 + 新消息）
    const systemMsg = { role: 'system', content: buildSystemPrompt(ctx) };
    const truncatedHistory = history.slice(-MAX_HISTORY_TURNS * 2);
    const newUserMsg = { role: 'user', content: message };

    const messages = [systemMsg, ...truncatedHistory.map((m) => ({ role: m.role, content: m.content })), newUserMsg];

    // 4. 调 DeepSeek
    const ai = app.ai();
    const model = ai.createModel('deepseek');

    const result = await model.generateText({
      model: 'deepseek-v3.2',
      messages,
    });

    const reply = result.text;

    // 5. 存储对话
    const now = Date.now();
    const userMsgRecord = { role: 'user', content: message, timestamp: now };
    const assistantMsgRecord = { role: 'assistant', content: reply, timestamp: now + 1 };

    let savedConvId = conversationId;

    if (conv) {
      await db
        .collection('ai_conversations')
        .doc(conversationId)
        .update({
          messages: _.push([userMsgRecord, assistantMsgRecord]),
          updatedAt: now,
          context: {
            recentCheckIns: ctx.recentResults,
            emotionTrend: ctx.emotionTrend,
            streakDays: ctx.streakDays,
            recentPosts: ctx.recentPosts,
          },
        });
    } else {
      const title = message.length > 20 ? message.substring(0, 20) + '...' : message;
      const addResult = await db.collection('ai_conversations').add({
        userId,
        title,
        messages: [userMsgRecord, assistantMsgRecord],
        context: {
          recentCheckIns: ctx.recentResults,
          emotionTrend: ctx.emotionTrend,
          streakDays: ctx.streakDays,
          recentPosts: ctx.recentPosts,
        },
        createdAt: now,
        updatedAt: now,
      });
      savedConvId = addResult.id;
    }

    return {
      success: true,
      data: {
        reply,
        conversationId: savedConvId,
        usage: result.usage,
      },
    };
  } catch (error) {
    console.error('[aiChat] 错误:', error);
    return { success: false, message: error.message };
  }
};
