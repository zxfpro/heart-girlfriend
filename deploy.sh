#!/usr/bin/env bash
# =====================================================================
#  heart-girlfriend 一键部署 —— 把「有心跳的角色」装配到当前 Hermes 实例
#
#  用法：
#    ./deploy.sh                         交互式部署示例角色 xiaolu
#    ./deploy.sh --character xiaolu      指定角色（characters/ 下）
#    ./deploy.sh --no-start              只配置不启动（先看配置）
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")"

CHARACTER="xiaolu"
DO_START=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--character) CHARACTER="$2"; shift 2 ;;
    --no-start) DO_START=0; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

ROOT="$(pwd)"
CHAR_DIR="$ROOT/characters/$CHARACTER"
[[ -f "$CHAR_DIR/AGENTS.md" ]] || {
  echo "✗ 角色不存在: $CHAR_DIR（缺 AGENTS.md）" >&2
  echo "  可用角色:"; ls characters/ 2>/dev/null || true
  exit 1
}

HERMES_HOME="${HERMES_HOME:-/opt/data}"
SCRIPTS_DIR="$HERMES_HOME/scripts"
HAVE_HERMES=0; command -v hermes >/dev/null && HAVE_HERMES=1

# 0. 依赖检查
for cmd in git python3; do command -v "$cmd" >/dev/null || { echo "✗ 缺 $cmd" >&2; exit 1; }; done
[[ "$HAVE_HERMES" == "1" ]] || echo "⚠ 未找到 hermes CLI（桥 cron 需要它；心跳可先跑）"

# 1. 拉 heart submodule
echo "❤️  拉取 heart 子模块..."
git submodule update --init --recursive

# 2. heart 引擎：venv + 依赖
echo ""
echo "🧠 装配 heart 引擎（venv + rich）..."
( cd heart && python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt )

# 3. 生成 heart/.env（「想」LLM + 「做」执行端，交互式）
echo ""
echo "🔑 配置 heart 的 LLM 端点..."
( cd heart && bash install.sh --persona "$CHAR_DIR" --no-start )

# 4. 配置桥：探测投递目标 + 会话
echo ""
echo "🌉 配置对话通道桥..."
CHAT_ID=""
if [[ "$HAVE_HERMES" == "1" ]]; then
  CHAT_ID=$(hermes send --list 2>/dev/null | grep -oE '[a-z]+:[A-Za-z0-9_-]+' | head -1 || true)
fi
if [[ -n "$CHAT_ID" ]]; then
  echo "  投递目标（自动探测）: $CHAT_ID"
else
  read -r -p "  投递目标（如 feishu:oc_xxx，见 hermes send --list）: " CHAT_ID
fi
read -r -p "  会话 session-id（先给机器人发条消息生成会话，用 hermes sessions list 查）: " SESSION_ID

mkdir -p "$SCRIPTS_DIR"
cat > "$CHAR_DIR/bridge.json" <<EOF
{
  "persona": "$CHAR_DIR",
  "session_id": "$SESSION_ID"
}
EOF

# 5. 桥 wrapper + cron（no_agent，纯脚本，每 3 分钟双向同步）
cat > "$SCRIPTS_DIR/bridge_$CHARACTER.sh" <<EOF
#!/usr/bin/env bash
exec "$ROOT/heart/.venv/bin/python" "$ROOT/heart/bridge.py" --config "$CHAR_DIR/bridge.json"
EOF
chmod +x "$SCRIPTS_DIR/bridge_$CHARACTER.sh"

if [[ "$HAVE_HERMES" == "1" ]]; then
  hermes cron create --name "${CHARACTER}对话通道桥" --no-agent \
    --script "bridge_$CHARACTER.sh" --deliver "$CHAT_ID" "every 3m" \
    || echo "⚠ cron 创建失败，请手动：hermes cron create ..."
fi

# 6. 启动心跳（后台常驻：mind 想 + hermes 做）
if [[ "$DO_START" == "1" ]]; then
  echo ""
  echo "❤️  启动心跳（mind + hermes 后台常驻）..."
  ( cd heart
    setsid nohup .venv/bin/python mind.py "$CHAR_DIR" > /tmp/mind.log 2>&1 &
    setsid nohup .venv/bin/python hermes.py "$CHAR_DIR" > /tmp/hermes.log 2>&1 &
  )
  echo "  mind.py / hermes.py 已后台启动（日志 /tmp/mind.log、/tmp/hermes.log）"
fi

echo ""
echo "✅ 部署完成！角色=$CHARACTER"
echo "   - 心跳：按 heart/config.yaml 的 interval 冒想法（支持白天/晚上动态频率 active_hours）"
echo "   - 桥：每 3 分钟同步（感知用户消息 + 投递角色的话）"
echo "   - 调粘人程度：改 heart/config.yaml 的 clinginess（0-1，越小越不主动）"
echo "   - 捏新角色：cp -r characters/xiaolu characters/<你的角色>，改里面的 .md 文件"
