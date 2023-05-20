const axios = require('axios');
const qs = require('qs');

// 获取Waka数据并构造变量
async function getWakaData() {
  const range = 'Yesterday';
  const wakaSummariesResponse = await axios.get(`https://wakatime.com/api/v1/users/${process.env.WAKA_USER_ID}/summaries`, {
    headers: {
      Authorization: `Bearer ${process.env.WAKA_ACCESS_TOKEN}`,
    },
    params: {
      range,
    },
  });
  const { date } = wakaSummariesResponse.data.data[0].range;
  const totalCodeTime = `all project | ${wakaSummariesResponse.data.cumulative_total.text}`;
  const projects = wakaSummariesResponse.data.data[0].projects;
  const contextMsgArr = [];
  for (const project of projects) {
    const { name } = project;
    const spendTime = project.text;
    const timePercent = project.percent;
    contextMsgArr.push(`${name} | ${spendTime} | ${timePercent}%`);
  }
  const contextMsg = contextMsgArr.join('\n');
  return {
    date,
    totalCodeTime,
    contextMsg,
  };
}

// 发送飞书消息
async function sendFeishuMessage(date, totalCodeTime, contextMsg) {
  const feishuApiData = {
    msg_type: 'interactive',
    card: {
      config: {
        wide_screen_mode: true,
      },
      elements: [
        {
          alt: {
            content: '',
            tag: 'plain_text',
          },
          img_key: 'img_v2_927db8cf-d788-4a9b-a6ed-3f04bbde9cbg',
          tag: 'img',
        },
        {
          tag: 'div',
          text: {
            content: `${totalCodeTime}`,
            tag: 'lark_md'
          }
        },
        {
          tag: 'hr'
        },
        {
          tag: 'div',
          text: {
            content: `${contextMsg}`,
            tag: 'lark_md'
          }
        },
        {
          actions: [
            {
              tag: 'button',
              text: {
                content: '查看 waka time dashboard',
                tag: 'plain_text',
              },
              type: 'primary',
              url: 'https://wakatime.com/dashboard',
            },
          ],
          tag: 'action',
        },
      ],
      header: {
        template: 'wathet',
        title: {
          content: `${date} 编程时间回顾`,
          tag: 'plain_text',
        },
      },
    },
  };

  const feishuResponse = await axios.post(`https://open.feishu.cn/open-apis/bot/v2/hook/${process.env.FEISHU_BOT_TOKEN}`,
    feishuApiData, {
      headers: {
        'Content-Type': 'application/json',
      },
    });
  console.log(`${date} Feishu message sent.`);
}

// 发送企业微信消息
async function sendQywxMessage(date, totalCodeTime, contextMsg) {
  const qywxMessage = {
    msgtype: 'markdown',
    markdown: {
      content: `## ${date} 编程时间回顾\n\n${totalCodeTime}\n${contextMsg}\n> [查看 waka time dashboard](https://wakatime.com/dashboard)`,
    },
  };
  const qywxResponse = await axios.post(`https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=${process.env.QYWX_BOT_TOKEN}`,
    qs.stringify(qywxMessage), {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });
  console.log(`${date} Qywx message sent.`);
}

// 调用函数发送消息
(async () => {
  const {
    date,
    totalCodeTime,
    contextMsg,
  } = await getWakaData();
  await sendFeishuMessage(date, totalCodeTime, contextMsg);
  // await sendQywxMessage(date, totalCodeTime, contextMsg);
})();
