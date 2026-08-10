#!/usr/bin/env bash
# 建立 GitHub Release：打包備份 -> 建立 tag -> 發佈 Release 並上傳附件
# 用法：在本資料夾內執行 ./release.sh [版本號] [額外說明]
#   ./release.sh                              # 依上一版後的 commit 自動決定版本
#                                             #   BREAKING CHANGE→major、feat→minor、其餘→patch
#   ./release.sh "修正 Guake 透明度設定"       # 自動版本 + 額外說明
#   ./release.sh v1.1.0 "修正 Guake 透明度設定" # 手動指定版本
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION="${1:-}"
EXTRA_NOTE="${2:-}"

# 第一參數不是 vX.Y.Z 格式時，視為額外說明，版本號改為自動判斷
if [ -n "$VERSION" ] && ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  EXTRA_NOTE="$VERSION"
  VERSION=""
fi

# 前置檢查
command -v gh >/dev/null 2>&1 || { echo "錯誤：未安裝 gh (GitHub CLI)" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "錯誤：gh 未登入，請先執行 gh auth login" >&2; exit 1; }

# 同步遠端 tag，否則版本判斷只看得到本機 tag，會算出遠端已存在的版本號
git -C "$DIR" fetch --tags --prune origin

if [ -z "$VERSION" ]; then
  LAST_TAG="$(git -C "$DIR" tag --sort=-v:refname | head -1)"
  [ -n "$LAST_TAG" ] || { echo "錯誤：找不到既有 tag，請手動指定版本，例如 ./release.sh v1.0.0" >&2; exit 1; }
  COMMITS="$(git -C "$DIR" log "$LAST_TAG"..HEAD --pretty='%s%n%b')"
  [ -n "$COMMITS" ] || { echo "錯誤：$LAST_TAG 之後沒有新 commit，無需發佈" >&2; exit 1; }
  IFS=. read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
  if echo "$COMMITS" | grep -qE '^[a-z]+(\([^)]*\))?!:|^BREAKING CHANGE'; then
    VERSION="v$((MAJOR + 1)).0.0"
  elif echo "$COMMITS" | grep -qE '^feat(\([^)]*\))?:'; then
    VERSION="v$MAJOR.$((MINOR + 1)).0"
  else
    VERSION="v$MAJOR.$MINOR.$((PATCH + 1))"
  fi
  echo "==> 自動判斷版本：$LAST_TAG -> $VERSION"
fi

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
# 打包前就掛上清理，任何一步失敗中止時才不會把 tar.gz 留在家目錄
trap 'rm -f "$HOME"/terminal-settings-*.tar.gz; echo "==> 已清理本機打包檔"' EXIT
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
