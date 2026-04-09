#!/bin/bash
set -euo pipefail

# Claude Managed Agents の Session を起動し、Issue の実装を指示する
#
# 環境変数:
#   ANTHROPIC_API_KEY, AGENT_ID, ENVIRONMENT_ID
#   ISSUE_NUMBER, ISSUE_TITLE, ISSUE_BODY
#   GITHUB_TOKEN, GITHUB_REPO
#   SLACK_BOT_TOKEN, SLACK_CHANNEL_ID

: "${ANTHROPIC_API_KEY:?required}"
: "${AGENT_ID:?required}"
: "${ENVIRONMENT_ID:?required}"
: "${ISSUE_NUMBER:?required}"

API_BASE="https://api.anthropic.com/v1"
HEADERS=(
  -H "x-api-key: ${ANTHROPIC_API_KEY}"
  -H "anthropic-version: 2023-06-01"
  -H "anthropic-beta: managed-agents-2026-04-01"
  -H "content-type: application/json"
)

# -----------------------------------------------------------
# 1. Slack に着手通知
# -----------------------------------------------------------
echo ">> Posting to Slack..."

slack_response=$(curl -sS -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg channel "$SLACK_CHANNEL_ID" \
    --arg text "🤖 *Issue #${ISSUE_NUMBER}* に着手します\n\n*${ISSUE_TITLE}*\nhttps://github.com/${GITHUB_REPO}/issues/${ISSUE_NUMBER}" \
    '{channel: $channel, text: $text}'
  )")

SLACK_THREAD_TS=$(echo "$slack_response" | jq -r '.ts')
echo "   Slack thread: ${SLACK_THREAD_TS}"

# -----------------------------------------------------------
# 2. ask-human.sh を生成（エージェント内で Slack 質問に使う）
# -----------------------------------------------------------
# セッション内のコンテナにファイルとして渡すため、
# エージェントへの指示メッセージ内にインラインで含める
ASK_HUMAN_SCRIPT=$(cat <<'ASKEOF'
#!/bin/bash
# Slack で人間に質問し、返答を待つスクリプト
QUESTION="$1"
if [ -z "$QUESTION" ]; then
  echo "Usage: bash /tmp/ask-human.sh \"質問内容\""
  exit 1
fi

# 質問を投稿
curl -sS -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg channel "$SLACK_CHANNEL_ID" \
    --arg thread_ts "$SLACK_THREAD_TS" \
    --arg text "💬 *質問があります:*\n\n${QUESTION}\n\n_スレッドで返信してください_" \
    '{channel: $channel, thread_ts: $thread_ts, text: $text}'
  )" > /dev/null

echo "Slack に質問を投稿しました。返答を待っています..." >&2

# ポーリングで返答を待つ（最大60分）
LAST_COUNT=0
for i in $(seq 1 360); do
  sleep 10
  replies=$(curl -sS "https://slack.com/api/conversations.replies?channel=${SLACK_CHANNEL_ID}&ts=${SLACK_THREAD_TS}" \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}")

  CURRENT_COUNT=$(echo "$replies" | jq '.messages | length')

  if [ "$CURRENT_COUNT" -gt "$LAST_COUNT" ] && [ "$LAST_COUNT" -gt 0 ]; then
    # 新しいメッセージを取得（bot以外）
    LATEST=$(echo "$replies" | jq -r '.messages[-1]')
    IS_BOT=$(echo "$LATEST" | jq -r '.bot_id // empty')

    if [ -z "$IS_BOT" ]; then
      echo "$LATEST" | jq -r '.text'
      exit 0
    fi
  fi

  [ "$LAST_COUNT" -eq 0 ] && LAST_COUNT=$CURRENT_COUNT
done

echo "ERROR: 60分以内に返答がありませんでした"
exit 1
ASKEOF
)

# -----------------------------------------------------------
# 3. Session 作成
# -----------------------------------------------------------
echo ">> Creating session..."

session_response=$(curl -sS --fail-with-body "${API_BASE}/sessions" \
  "${HEADERS[@]}" \
  -d "$(jq -n \
    --arg agent "$AGENT_ID" \
    --arg env "$ENVIRONMENT_ID" \
    --arg title "Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}" \
    '{agent: $agent, environment_id: $env, title: $title}'
  )")

SESSION_ID=$(echo "$session_response" | jq -r '.id')

if [ "$SESSION_ID" = "null" ] || [ -z "$SESSION_ID" ]; then
  echo "ERROR: Failed to create session"
  echo "$session_response" | jq .
  exit 1
fi

echo "   Session ID: ${SESSION_ID}"

# -----------------------------------------------------------
# 4. ユーザーメッセージ送信（Issue の内容 + 作業指示）
# -----------------------------------------------------------
echo ">> Sending issue context to agent..."

USER_MESSAGE=$(cat <<MSGEOF
以下の GitHub Issue を実装してください。

## Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}

${ISSUE_BODY}

---

## 作業環境の準備

まず以下を実行してください:

1. ask-human スクリプトを作成:
\`\`\`bash
cat > /tmp/ask-human.sh << 'SCRIPT'
${ASK_HUMAN_SCRIPT}
SCRIPT
chmod +x /tmp/ask-human.sh
\`\`\`

2. 環境変数を設定:
\`\`\`bash
export GITHUB_TOKEN="${GITHUB_TOKEN}"
export GITHUB_REPO="${GITHUB_REPO}"
export ISSUE_NUMBER="${ISSUE_NUMBER}"
export ISSUE_TITLE="${ISSUE_TITLE}"
export SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN}"
export SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID}"
export SLACK_THREAD_TS="${SLACK_THREAD_TS}"
\`\`\`

3. リポジトリをクローンしてブランチ作成:
\`\`\`bash
git clone https://x-access-token:\${GITHUB_TOKEN}@github.com/\${GITHUB_REPO}.git /workspace
cd /workspace
git config user.name "Claude Agent"
git config user.email "claude-agent@formx.co.jp"
BRANCH_NAME="feature/issue-\${ISSUE_NUMBER}"
git checkout -b "\${BRANCH_NAME}"
\`\`\`

4. CLAUDE.md があれば読んでプロジェクトの文脈を把握

5. Issue の内容を理解し、実装 → テスト → commit → push → PR作成

不明点があれば \`bash /tmp/ask-human.sh "質問"\` で Slack に質問できます。
MSGEOF
)

# メッセージを JSON-safe にエスケープして送信
MESSAGE_JSON=$(jq -n --arg text "$USER_MESSAGE" \
  '{events: [{type: "user.message", content: [{type: "text", text: $text}]}]}')

curl -sS --fail-with-body \
  "${API_BASE}/sessions/${SESSION_ID}/events" \
  "${HEADERS[@]}" \
  -d "$MESSAGE_JSON" > /dev/null

echo "   Message sent."

# -----------------------------------------------------------
# 5. SSE ストリームを監視
# -----------------------------------------------------------
echo ">> Monitoring agent (Session: ${SESSION_ID})..."
echo "=========================================="

# SSE ストリームを受信して進捗を表示
curl -sS -N --fail-with-body \
  "${API_BASE}/sessions/${SESSION_ID}/events/stream" \
  "${HEADERS[@]}" | while IFS= read -r line; do

  # SSE の data: 行だけ処理
  [[ "$line" == data:* ]] || continue
  json="${line#data: }"

  event_type=$(echo "$json" | jq -r '.type // empty')

  case "$event_type" in
    agent.message)
      # エージェントのテキスト出力
      echo "$json" | jq -j '.content[]? | select(.type == "text") | .text'
      ;;
    agent.tool_use)
      tool_name=$(echo "$json" | jq -r '.name // "unknown"')
      printf '\n📦 [Tool: %s]\n' "$tool_name"
      ;;
    agent.error)
      error_msg=$(echo "$json" | jq -r '.error.message // "unknown error"')
      printf '\n❌ Error: %s\n' "$error_msg"
      ;;
    session.status_idle)
      printf '\n\n✅ Agent finished.\n'

      # 完了通知を Slack に投稿
      curl -sS -X POST https://slack.com/api/chat.postMessage \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
          --arg channel "$SLACK_CHANNEL_ID" \
          --arg thread_ts "$SLACK_THREAD_TS" \
          --arg text "✅ Issue #${ISSUE_NUMBER} の作業が完了しました。PRを確認してください。" \
          '{channel: $channel, thread_ts: $thread_ts, text: $text}'
        )" > /dev/null

      break
      ;;
  esac
done

echo "=========================================="
echo "Session ${SESSION_ID} completed."
