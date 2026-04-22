#!/usr/bin/env bash
# Smoke: install-mcp.sh с подставными JAR и platform-path (без 1С и без скачивания JAR).
# Запуск из корня репозитория: bash scripts/test/smoke-install-mcp.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ ! -f "$ROOT/.cursor/mcp.json.example" ]]; then
  echo "Запускайте из корня репозитория 1C_mcp_bsl (нет .cursor/mcp.json.example)." >&2
  exit 1
fi

WS=$(mktemp -d)
FAKE_PLAT=$(mktemp -d)
mkdir -p "$FAKE_PLAT/bin"
touch "$FAKE_PLAT/bin/.keep"

FAKE_JAR=$(mktemp)
# не обязан быть валидным JAR — проверяем только структуру mcp.json
printf 'x' > "$FAKE_JAR"

export INSTALL_MCP_SOURCE_ROOT="$ROOT"
export INSTALL_MCP_WORKSPACE_ROOT="$WS"
export INSTALL_MCP_PLATFORM_PATH="$FAKE_PLAT"
export INSTALL_MCP_JAR_PATH="$FAKE_JAR"
unset INSTALL_MCP_GITHUB_URL
unset INSTALL_MCP_DRY_RUN

bash "$ROOT/scripts/install-mcp.sh"

test -f "$WS/.cursor/mcp.json"
test -f "$WS/.cursor/rules/use-1c-platform-mcp.mdc"
test -f "$WS/.cursor/mcp.json.example"

export WS_ROOT="$WS"
python3 <<'PY'
import json, os, sys
ws = os.environ["WS_ROOT"]
with open(os.path.join(ws, ".cursor", "mcp.json"), encoding="utf-8") as f:
    j = json.load(f)
srv = j["mcpServers"]["1c-platform"]
assert srv["type"] == "stdio"
args = srv["args"]
assert "-Dfile.encoding=UTF-8" in args
assert "--platform-path" in args
i = args.index("--platform-path")
assert i + 1 < len(args)
assert os.path.isdir(args[i + 1])
print("smoke-install-mcp: OK")
PY

rm -rf "$WS" "$FAKE_PLAT" "$FAKE_JAR"
