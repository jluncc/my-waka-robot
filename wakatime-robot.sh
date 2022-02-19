#!/bin/bash

range='Yesterday'

# 1.获取waka数据
waka_summaries_response=$(curl --location \
  --request GET "https://wakatime.com/api/v1/users/${waka_user_id}/summaries?range=${range}" \
  --header "Authorization: Bearer ${waka_access_token}")

# 2.构造变量
date=`echo "$waka_summaries_response" | jq '.data[0].range.date' | sed  's:":'':g'`
echo $date

total_code_time="all project | "`echo "$waka_summaries_response" | jq '.cummulative_total.text' | sed  's:":'':g'`
echo $total_code_time

projects=`echo "$waka_summaries_response" | jq '.data[0].projects'`
project_num=`echo "$projects" | jq 'length'`
# echo $project_num

context_msg=''
for((i=0; i<=$project_num-1; i=i+1))
do 
  project_name=`echo "$projects" | jq '.['${i}'].name' | sed  's:":'':g'`
  spend_time=`echo "$projects" | jq '.['${i}'].text' | sed  's:":'':g'`
  time_percent=`echo "$projects" | jq '.['${i}'].percent' | sed  's:":'':g'`
  context_msg=$context_msg\\n`echo $project_name \| $spend_time \| $time_percent%`
done
# echo $context_msg

# 3.构造飞书curl数据体
feishu_api_data='{
    "msg_type": "interactive",
    "card": {
        "config": {
            "wide_screen_mode": true
        },
        "elements": [
            {
                "alt": {
                    "content": "",
                    "tag": "plain_text"
                },
                "img_key": "img_v2_927db8cf-d788-4a9b-a6ed-3f04bbde9cbg",
                "tag": "img"
            },
            {
                "tag": "div",
                "text": {
                    "content": "===total_code_time===",
                    "tag": "lark_md"
                }
            },
            {
                "tag": "hr"
            },
            {
                "tag": "div",
                "text": {
                    "content": "==context_msg==",
                    "tag": "lark_md"
                }
            },
            {
                "actions": [
                    {
                        "tag": "button",
                        "text": {
                            "content": "查看 waka time dashboard",
                            "tag": "plain_text"
                        },
                        "type": "default",
                        "url": "https://wakatime.com/dashboard"
                    }
                ],
                "tag": "action"
            }
        ],
        "header": {
            "template": "turquoise",
            "title": {
                "content": "===date=== 编程时间回顾",
                "tag": "plain_text"
            }
        }
    }
}'
feishu_api_data=${feishu_api_data/'===date==='/${date}}
feishu_api_data=${feishu_api_data/'===total_code_time==='/${total_code_time}}
feishu_api_data=${feishu_api_data/'==context_msg=='/${context_msg}}
# echo $feishu_api_data

# 4.发送飞书消息
curl --location --request POST "https://open.feishu.cn/open-apis/bot/v2/hook/${feishu_bot_token}" \
--header 'Content-Type: application/json' \
--data-raw "${feishu_api_data}"


# 5.构造企业微信消息结构体
qywxMessage='{
    "msgtype": "markdown",
    "markdown": {
        "content": "
            ## ===date=== 编程时间回顾\n 
            ### 总耗时\n\n
===total_code_time===\n\n
            ### 各项目耗时\n
            ==context_msg==\n
            > [查看 waka time dashboard](https://wakatime.com/dashboard)"
    }
}'
qywxMessage=${qywxMessage/'===date==='/${date}}
qywxMessage=${qywxMessage/'===total_code_time==='/${total_code_time}}
qywxMessage=${qywxMessage/'==context_msg=='/${context_msg}}
# echo $qywxMessage

# 6.发送企业微信消息
curl --location --request POST "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=${qywx_bot_token}" \
--header 'Content-Type: application/json' \
--data-raw "${qywxMessage}"
