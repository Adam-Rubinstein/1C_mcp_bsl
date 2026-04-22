#!/usr/bin/env bash
# Собирает .cursor/mcp.json для MCP 1c-platform (Java, JAR, --platform-path).
# Запуск: из корня репозитория: bash scripts/install-mcp.sh
# Зависимости: curl, java в PATH или JAVA_HOME; для JSON удобно python3.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CURSOR_DIR="$REPO_ROOT/.cursor"
OUT="$CURSOR_DIR/mcp.json"
EXAMPLE="$CURSOR_DIR/mcp.json.example"

if [[ ! -f "$EXAMPLE" ]]; then
  echo "Не найден $EXAMPLE — запускайте из клона репозитория 1C_mcp_bsl." >&2
  exit 1
fi

if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]]; then
  JAVA_CMD="$JAVA_HOME/bin/java"
else
  JAVA_CMD="$(command -v java)" || true
fi
if [[ -z "${JAVA_CMD:-}" ]]; then
  echo "Не найден java. Установите JDK 17+ и PATH или JAVA_HOME." >&2
  exit 1
fi

JAR_IN_REPO="$REPO_ROOT/dist/1C_mcp_bsl.jar"
if [[ -f "$JAR_IN_REPO" ]]; then
  JAR_PATH="$(cd "$(dirname "$JAR_IN_REPO")" && pwd)/$(basename "$JAR_IN_REPO")"
else
  CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/1C_mcp_bsl"
  mkdir -p "$CACHE"
  JAR_PATH="$CACHE/1C_mcp_bsl.jar"
  URL="$(curl -fsSL -H "User-Agent: 1C_mcp_bsl-install" \
    https://api.github.com/repos/Adam-Rubinstein/1C_mcp_bsl/releases/latest \
    | python3 -c "import sys,json; r=json.load(sys.stdin); a=[x for x in r.get('assets',[]) if x.get('name')=='1C_mcp_bsl.jar']; print(a[0]['browser_download_url'] if a else '')")"
  if [[ -z "$URL" ]]; then
    echo "Не удалось получить URL JAR из GitHub API (нужен python3 для разбора JSON)." >&2
    exit 1
  fi
  echo "Скачивание JAR в $JAR_PATH ..."
  curl -fSL "$URL" -o "$JAR_PATH"
fi

PLATFORM_PATH=""
shopt -s nullglob
candidates=()
for base in /opt/1cv8/x86_64 /opt/1cv8/aarch64; do
  [[ -d "$base" ]] || continue
  for d in "$base"/8.3.*/; do
    [[ -d "${d}bin" ]] || continue
    candidates+=("$(cd "$d" && pwd)")
  done
done
shopt -u nullglob
if ((${#candidates[@]})); then
  PLATFORM_PATH="$(printf '%s\n' "${candidates[@]}" | sort -V | tail -1)"
fi

if [[ -z "$PLATFORM_PATH" ]]; then
  echo "Не найдена платформа 1С под /opt/1cv8/*/8.3.* (нужен каталог с bin). Укажите путь вручную — см. documentation/INSTALL.md." >&2
  exit 1
fi

mkdir -p "$CURSOR_DIR"
export INSTALL_MCP_OUT="$OUT"
export INSTALL_MCP_JAVA="$JAVA_CMD"
export INSTALL_MCP_JAR="$JAR_PATH"
export INSTALL_MCP_PLATFORM="$PLATFORM_PATH"
python3 <<'PY'
import json
import os
from pathlib import Path
out = Path(os.environ["INSTALL_MCP_OUT"])
cfg = {
    "mcpServers": {
        "1c-platform": {
            "type": "stdio",
            "command": os.environ["INSTALL_MCP_JAVA"],
            "args": [
                "-Dfile.encoding=UTF-8",
                "-jar",
                os.environ["INSTALL_MCP_JAR"],
                "--platform-path",
                os.environ["INSTALL_MCP_PLATFORM"],
            ],
        }
    }
}
out.write_text(json.dumps(cfg, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

echo "Java:          $JAVA_CMD"
echo "JAR:           $JAR_PATH"
echo "platform-path: $PLATFORM_PATH"
echo "Записано:      $OUT"
echo "В Cursor: Reload Window, проверьте MCP 1c-platform."
