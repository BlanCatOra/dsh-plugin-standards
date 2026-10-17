#!/bin/sh
# 规范仓库结构自检（本仓库是纯文档仓库，没有 npm 包）。
#
# 检查三件事：
#   1. 三份规范文档都在且非空；
#   2. README 索引里列的每份文档都真实存在；
#   3. 规范文档自身不得含完整敏感字面量（本机路径 / 完整内网 IP / 私人邮箱）。
#
# 用法：sh check.sh

set -e
cd "$(dirname "$0")"

fail=0
say() { printf '%s\n' "$1"; }

say "==> [1/3] 规范文档存在且非空"
for f in docs/UI-STANDARDS.md docs/AGENT-FACING-STANDARDS.md docs/RELEASE-STANDARDS.md; do
  if [ -s "$f" ]; then
    say "✅ $f ($(wc -l < "$f") 行)"
  else
    say "❌ 缺少或为空：$f"
    fail=1
  fi
done

say "==> [2/3] README 索引里引用的文档都真实存在"
# 抽取 README 里指向 docs/ 的相对链接并逐个验证
links=$(grep -oE '\(\./docs/[A-Za-z0-9._-]+\.md\)' README.md | tr -d '()' | sed 's|^\./||' | sort -u)
if [ -z "$links" ]; then
  say "❌ README 里没有任何 docs/ 链接"
  fail=1
else
  for link in $links; do
    if [ -s "$link" ]; then
      say "✅ $link"
    else
      say "❌ README 指向 $link，但文件不存在"
      fail=1
    fi
  done
fi

say "==> [3/3] 规范文档脱敏（不得含完整敏感字面量）"
hits=$(grep -rnE '/home/[a-z][a-zA-Z0-9._-]+|192\.168\.[0-9]+\.[0-9]+|[A-Za-z0-9._%+-]+@qq\.com' \
  README.md AGENTS.md docs/ 2>/dev/null \
  | grep -vE 'blancatora@agent\.qq\.com|<用户>|<用户名>|192\.168\.`|192\.168\. 前缀' || true)
if [ -n "$hits" ]; then
  say "❌ 出现完整敏感字面量："
  printf '%s\n' "$hits"
  fail=1
else
  say "✅ 无本机路径 / 完整内网 IP / 私人邮箱"
fi

if [ "$fail" -ne 0 ]; then
  say ""
  say "❌ 自检未通过"
  exit 1
fi
say ""
say "✅ 规范仓库自检通过"
