#!/usr/bin/env bash
# 終端機設定還原腳本（GNOME Terminal + Guake + Meslo 字型）
# 用法：在本資料夾內執行 ./restore.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 1/4 安裝 Meslo Nerd Font"
mkdir -p "$HOME/.fonts"
cp -f "$DIR/fonts/"* "$HOME/.fonts/"
fc-cache -f "$HOME/.fonts" >/dev/null
echo "    字型安裝完成"

echo "==> 2/4 還原 GNOME Terminal 設定"
if command -v gnome-terminal >/dev/null 2>&1; then
  dconf load /org/gnome/terminal/ < "$DIR/gnome-terminal.dconf"
  echo "    完成（開新視窗即生效）"
else
  echo "    略過：未安裝 gnome-terminal"
fi

echo "==> 3/4 還原 Guake 設定"
if command -v guake >/dev/null 2>&1; then
  dconf load /org/guake/ < "$DIR/guake.dconf"
  gsettings set guake.general save-tabs-when-changed true
  echo "    完成（已確保分頁自動儲存開啟）"
else
  echo "    略過：未安裝 guake"
fi

echo "==> 4/4 還原 Guake 分頁 session 並重啟"
if command -v guake >/dev/null 2>&1; then
  if [ -f "$DIR/guake-session.json" ]; then
    mkdir -p "$HOME/.config/guake"
    cp -f "$DIR/guake-session.json" "$HOME/.config/guake/session.json"
    echo "    已還原 session.json（分頁清單）"
  fi
  guake --quit >/dev/null 2>&1 || true
  (setsid guake >/dev/null 2>&1 &) || true
  echo "    Guake 已重啟"
fi

echo ""
echo "全部完成。GNOME Terminal 請開新分頁／視窗即可看到新風格。"
