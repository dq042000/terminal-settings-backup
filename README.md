# terminal-settings-backup

終端機設定備份，可在新機器上一鍵還原。內容包含 GNOME Terminal 與 Guake 的設定、Guake 分頁 session，以及 Meslo Nerd Font 字型。

## 預覽

![終端機風格預覽](screenshots/terminal-style.jpeg)

## 內容

| 檔案 / 資料夾 | 說明 |
| --- | --- |
| `restore.sh` | 一鍵還原腳本（安裝字型 + 載入設定 + 還原分頁 + 重啟 Guake） |
| `export.sh` | 一鍵匯出腳本（重新匯出目前設定到本資料夾） |
| `gnome-terminal.dconf` | GNOME Terminal 設定（`dconf` 匯出） |
| `guake.dconf` | Guake 設定（`dconf` 匯出） |
| `guake-session.json` | Guake 分頁 session（分頁清單與工作目錄） |
| `fonts/` | Meslo Nerd Font 字型檔（`.ttf`） |
| `screenshots/` | 風格預覽截圖 |

## 設定重點

- 配色：深色背景 `#1E1E1E`、前景 `#CCCCCC`（VS Code 風格調色盤）
- 字型：`MesloLGLDZ Nerd Font 12`
- 預設視窗：114 欄 × 24 列，關閉音效提示
- Guake：背景透明度 92%、`F10` 顯示／隱藏、開啟分頁自動儲存

## 還原方式

在本資料夾內執行：

```bash
git pull
./restore.sh
```

腳本會依序執行：

1. 將 `fonts/` 內的字型複製到 `~/.fonts/` 並更新字型快取；若系統缺 U+23F5（`⏵`）符號，會自動安裝 `fonts-symbola`（補齊 Claude Code 模式指示器符號）
2. 以 `dconf load` 還原 GNOME Terminal 設定（未安裝則略過）
3. 以 `dconf load` 還原 Guake 設定，並確保分頁自動儲存開啟（未安裝則略過）
4. 還原 Guake 分頁 session 並重啟 Guake

GNOME Terminal 開新分頁／視窗即可看到新風格。

## 備份方式

更新備份時，在本資料夾內執行：

```bash
./export.sh
git commit -am "chore: 更新終端機設定備份"
git push
```

`export.sh` 會重新匯出 GNOME Terminal 與 Guake 設定、備份 Guake 分頁 session、同步 Meslo 字型到本資料夾，接著以 git 提交推送即完成備份。

本 repo 本身就是備份，不另外產生打包檔：`git clone` 或 `git pull` 取得的內容即可直接還原。若要還原到某個歷史版本，`git checkout <tag>` 後再執行 `./restore.sh`。
