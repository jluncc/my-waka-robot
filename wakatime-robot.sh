#!/bin/bash

range='Yesterday'

waka_summaries_response=$(curl --location \
  --request GET "https://wakatime.com/api/v1/users/${waka_user_id}/summaries?range=${range}" \
  --header "Authorization: Bearer ${waka_access_token}")

date=`echo "$waka_summaries_response" | jq '.data[0].range.date' | sed  's:":'':g'`
echo $date

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
feishu_api_data=${feishu_api_data/'==context_msg=='/${context_msg}}
# echo $feishu_api_data


curl --location --request POST "https://open.feishu.cn/open-apis/bot/v2/hook/${feishu_bot_token}" \
--header 'Content-Type: application/json' \
--data-raw "${feishu_api_data}"