#!/usr/bin/env bash
# Создаёт .cursor/mcp.json для MCP 1c-platform.
#
# Запуск из клона (рядом dist/ и .cursor/mcp.json.example):
#   bash scripts/install-mcp.sh
#
# Чужой проект + репозиторий GitHub (нужны git, curl, python3):
#   export INSTALL_MCP_WORKSPACE_ROOT="/abs/path/to/your/project"
#   export INSTALL_MCP_GITHUB_URL="https://github.com/Adam-Rubinstein/1C_mcp_bsl"
#   curl -fsSL "https://raw.githubusercontent.com/Adam-Rubinstein/1C_mcp_bsl/main/scripts/install-mcp.sh" | bash
#
# Или только клон у себя, затем:
#   INSTALL_MCP_WORKSPACE_ROOT=/path/to/erp bash scripts/install-mcp.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_ROOT="${INSTALL_MCP_SOURCE_ROOT:-}"
WORKSPACE_ROOT="${INSTALL_MCP_WORKSPACE_ROOT:-}"
GITHUB_URL="${INSTALL_MCP_GITHUB_URL:-}"
DRY="${INSTALL_MCP_DRY_RUN:-}"

parse_github() {
  local s="$1"
  if [[ "$s" =~ github\.com/([^/]+)/([^/?#]+) ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
  elif [[ "$s" =~ ^([^/]+)/([^/]+)$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
  else
    return 1
  fi
}

JAR_OWNER="Adam-Rubinstein"
JAR_REPO="1C_mcp_bsl"

if [[ -n "$GITHUB_URL" ]]; then
  SPEC="$(parse_github "$GITHUB_URL")" || { echo "Не разобрать URL: $GITHUB_URL" >&2; exit 1; }
  OWNER="${SPEC%%/*}"
  REPO="${SPEC##*/}"
  JAR_OWNER="$OWNER"
  JAR_REPO="$REPO"
  case "$(uname -s)" in
    Linux*)  BASE="${XDG_CACHE_HOME:-$HOME/.cache}/1C_mcp_bsl/checkout" ;;
    Darwin*) BASE="$HOME/Library/Caches/1C_mcp_bsl/checkout" ;;
    *)       BASE="${LOCALAPPDATA:-$HOME/.local/share}/1C_mcp_bsl/checkout" ;;
  esac
  DEST="$BASE/${OWNER}_${REPO}"
  if [[ -d "$DEST/.git" ]]; then
    echo "Обновление клона: $DEST"
    if [[ "$DRY" != "1" ]]; then
      git -C "$DEST" pull --ff-only 2>/dev/null || { git -C "$DEST" fetch --depth 1 origin && git -C "$DEST" merge FETCH_HEAD --ff-only; }
    fi
  else
    echo "Клонирование в $DEST ..."
    if [[ "$DRY" != "1" ]]; then
      mkdir -p "$BASE"
      git clone --depth 1 "https://github.com/${OWNER}/${REPO}.git" "$DEST"
    fi
  fi
  SOURCE_ROOT="$DEST"
elif [[ -n "$SOURCE_ROOT" ]]; then
  SOURCE_ROOT="$(cd "$SOURCE_ROOT" && pwd)"
else
  if [[ -f "$DEFAULT_REPO/.cursor/mcp.json.example" ]]; then
    SOURCE_ROOT="$DEFAULT_REPO"
  else
    echo "Задайте INSTALL_MCP_GITHUB_URL или запускайте из клона репозитория." >&2
    exit 1
  fi
fi

SOURCE_ROOT="$(cd "$SOURCE_ROOT" && pwd)"
EXAMPLE="$SOURCE_ROOT/.cursor/mcp.json.example"
if [[ ! -f "$EXAMPLE" ]]; then
  echo "Не найден $EXAMPLE" >&2
  exit 1
fi

if [[ -z "$WORKSPACE_ROOT" ]]; then
  if [[ -n "$GITHUB_URL" ]]; then
    WORKSPACE_ROOT="$(pwd)"
  else
    WORKSPACE_ROOT="$SOURCE_ROOT"
  fi
fi
WORKSPACE_ROOT="$(cd "$WORKSPACE_ROOT" && pwd)"

CURSOR_DIR="$WORKSPACE_ROOT/.cursor"
OUT="$CURSOR_DIR/mcp.json"

if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]]; then
  JAVA_CMD="$JAVA_HOME/bin/java"
else
  JAVA_CMD="$(command -v java)" || true
fi
if [[ -z "${JAVA_CMD:-}" ]]; then
  echo "Не найден java." >&2
  exit 1
fi

JAR_IN_REPO="$SOURCE_ROOT/dist/1C_mcp_bsl.jar"
if [[ -f "$JAR_IN_REPO" ]]; then
  JAR_PATH="$(cd "$(dirname "$JAR_IN_REPO")" && pwd)/$(basename "$JAR_IN_REPO")"
else
  case "$(uname -s)" in
    Linux*)  CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/1C_mcp_bsl" ;;
    Darwin*) CACHE="$HOME/Library/Caches/1C_mcp_bsl" ;;
    *)       CACHE="${LOCALAPPDATA:-$HOME/.local/share}/1C_mcp_bsl" ;;
  esac
  mkdir -p "$CACHE"
  JAR_PATH="$CACHE/1C_mcp_bsl.jar"
  if [[ "$DRY" != "1" ]]; then
    URL="$(curl -fsSL -H "User-Agent: 1C_mcp_bsl-install" \
      "https://api.github.com/repos/${JAR_OWNER}/${JAR_REPO}/releases/latest" \
      | python3 -c "import sys,json; r=json.load(sys.stdin); a=[x for x in r.get('assets',[]) if x.get('name')=='1C_mcp_bsl.jar']; print(a[0]['browser_download_url'] if a else '')")"
    [[ -n "$URL" ]] || { echo "Нет JAR в releases $JAR_OWNER/$JAR_REPO" >&2; exit 1; }
    echo "Скачивание JAR..."
    curl -fSL "$URL" -o "$JAR_PATH"
  fi
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
  echo "Не найдена платформа 1С под /opt/1cv8/..." >&2
  exit 1
fi

mkdir -p "$CURSOR_DIR"
export INSTALL_MCP_OUT="$OUT"
export INSTALL_MCP_JAVA="$JAVA_CMD"
export INSTALL_MCP_JAR="$JAR_PATH"
export INSTALL_MCP_PLATFORM="$PLATFORM_PATH"
if [[ "$DRY" != "1" ]]; then
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
fi

RULE_SRC="$SOURCE_ROOT/.cursor/rules/use-1c-platform-mcp.mdc"
EX_SRC="$SOURCE_ROOT/.cursor/mcp.json.example"
RULE_DST="$CURSOR_DIR/rules"
if [[ "$DRY" != "1" ]]; then
  mkdir -p "$RULE_DST"
  [[ -f "$RULE_SRC" ]] && cp -f "$RULE_SRC" "$RULE_DST/"
  [[ -f "$EX_SRC" ]] && cp -f "$EX_SRC" "$CURSOR_DIR/"
fi

echo "Источник: $SOURCE_ROOT"
echo "Проект:   $WORKSPACE_ROOT"
echo "Записано: $OUT"
echo "В Cursor: Reload Window."
