#!/usr/bin/env bash
# 重新匯出目前的終端機設定（GNOME Terminal + Guake）
# 用法：在本資料夾內執行 ./export.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 匯出 GNOME Terminal 設定"
dconf dump /org/gnome/terminal/ > "$DIR/gnome-terminal.dconf"

echo "==> 匯出 Guake 設定"
dconf dump /org/guake/ > "$DIR/guake.dconf"

echo "==> 匯出 Guake 分頁 session"
if [ -f "$HOME/.config/guake/session.json" ]; then
  cp -f "$HOME/.config/guake/session.json" "$DIR/guake-session.json"
  echo "    已備份 session.json"
else
  echo "    略過：找不到 session.json"
fi

echo "==> 同步 Meslo 字型"
mkdir -p "$DIR/fonts"
cp -f "$HOME"/.fonts/Meslo* "$DIR/fonts/" 2>/dev/null || true

echo "==> 重新打包"
TS=$(date +%Y%m%d)
tar czf "$HOME/terminal-settings-${TS}.tar.gz" -C "$HOME" terminal-settings-backup

echo ""
echo "完成：$HOME/terminal-settings-${TS}.tar.gz"
