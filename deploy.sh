#!/bin/bash
set -e

# === 配置 ===
GIT_REMOTE="git@github.com:James99309/Mathmatic.git"
NAS_HOST="admin@ssh.jamesgpone.win"
NAS_DIR="/volume1/docker/mathmatic/html"
LOCAL_DIR="/Users/nijie/Documents/Mathematic"

# 文件映射: 本地文件名 -> NAS 文件名
declare -A FILE_MAP=(
  ["staircase_fractions_test.html"]="index.html"
)

# === 颜色 ===
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

cd "$LOCAL_DIR"

# === 1. Git 推送 ===
echo ""
echo "━━━ Git Push ━━━"

if [ ! -d .git ]; then
  warn "Git 仓库未初始化，正在初始化..."
  git init
  git remote add origin "$GIT_REMOTE"
  info "已初始化并添加 remote origin"
fi

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  info "没有变更需要提交"
else
  git add -A
  MSG="${1:-update: $(date '+%Y-%m-%d %H:%M')}"
  git commit -m "$MSG"
  info "已提交: $MSG"
fi

if git remote | grep -q origin; then
  BRANCH="$(git branch --show-current)"
  git push -u origin "$BRANCH"
  info "已推送到 origin/$BRANCH"
else
  warn "未配置 remote origin，跳过推送"
fi

# === 2. 部署到 NAS ===
echo ""
echo "━━━ Deploy to NAS ━━━"

if ! ssh -o ConnectTimeout=5 "$NAS_HOST" "echo ok" &>/dev/null; then
  error "无法连接 NAS ($NAS_HOST)"
fi

for LOCAL_FILE in "${!FILE_MAP[@]}"; do
  NAS_FILE="${FILE_MAP[$LOCAL_FILE]}"
  if [ -f "$LOCAL_DIR/$LOCAL_FILE" ]; then
    cat "$LOCAL_DIR/$LOCAL_FILE" | ssh "$NAS_HOST" "sudo tee $NAS_DIR/$NAS_FILE > /dev/null"
    info "$LOCAL_FILE → $NAS_DIR/$NAS_FILE"
  else
    warn "文件不存在: $LOCAL_FILE，跳过"
  fi
done

# === 3. 验证 ===
echo ""
echo "━━━ 验证 ━━━"
ssh "$NAS_HOST" "sudo /usr/local/bin/docker ps --filter name=mathmatic-web --format '{{.Status}}'" | while read status; do
  info "容器状态: $status"
done

echo ""
info "部署完成 → https://math.jamesgpone.win"
echo ""
