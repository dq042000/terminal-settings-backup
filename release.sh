#!/usr/bin/env bash
# 建立 GitHub Release：打包備份 -> 建立 tag -> 發佈 Release 並上傳附件
# 用法：在本資料夾內執行 ./release.sh <版本號>
#   ./release.sh v1.0.0
#   ./release.sh v1.1.0 "修正 Guake 透明度設定"   # 第二參數為額外說明（可省略）
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION="${1:-}"
EXTRA_NOTE="${2:-}"

if [ -z "$VERSION" ]; then
  echo "錯誤：請提供版本號，例如 ./release.sh v1.0.0" >&2
  exit 1
fi

# 前置檢查
command -v gh >/dev/null 2>&1 || { echo "錯誤：未安裝 gh (GitHub CLI)" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "錯誤：gh 未登入，請先執行 gh auth login" >&2; exit 1; }

if git -C "$DIR" rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "錯誤：tag $VERSION 已存在" >&2
  exit 1
fi

echo "==> 1/3 確認工作區已提交並推送"
if [ -n "$(git -C "$DIR" status --porcelain)" ]; then
  echo "錯誤：尚有未提交的變更，請先 commit 再發佈" >&2
  git -C "$DIR" status --short
  exit 1
fi
git -C "$DIR" push origin HEAD

echo "==> 2/3 打包備份"
"$DIR/export.sh"
ASSET="$(ls -t "$HOME"/terminal-settings-*.tar.gz 2>/dev/null | head -1)"
[ -n "$ASSET" ] || { echo "錯誤：找不到打包檔 terminal-settings-*.tar.gz" >&2; exit 1; }
echo "    附件：$ASSET"

echo "==> 3/3 建立 Release $VERSION"
NOTES="終端機設定備份 $VERSION

GNOME Terminal + Guake 設定、Guake 分頁 session、Meslo Nerd Font 字型與一鍵還原腳本。
下載 tar.gz 解壓後執行 ./restore.sh 即可還原。"
[ -n "$EXTRA_NOTE" ] && NOTES="$NOTES

本版變更：$EXTRA_NOTE"

gh release create "$VERSION" "$ASSET" \
  --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" \
  --title "終端機設定備份 $VERSION" \
  --notes "$NOTES" \
  --generate-notes

echo ""
echo "完成：Release $VERSION 已發佈"
gh release view "$VERSION" --web >/dev/null 2>&1 || true
