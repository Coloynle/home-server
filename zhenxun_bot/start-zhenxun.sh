#!/bin/sh
set -e

repo_url="${ZHENXUN_REPO_URL:-https://github.com/zhenxun-org/zhenxun_bot.git}"
auto_update="${AUTO_UPDATE_ZHENXUN:-false}"
auto_upgrade="${AUTO_UPGRADE_ZHENXUN:-false}"

export ENVIRONMENT="${ENVIRONMENT:-dev}"
export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-19211}"
export DB_URL="${DB_URL:-sqlite:data/db/zhenxun.db}"
export CACHE_MODE="${CACHE_MODE:-NONE}"
export ZHENXUN_WEBUI_USERNAME="${ZHENXUN_WEBUI_USERNAME:-admin}"
export ZHENXUN_WEBUI_PASSWORD="${ZHENXUN_WEBUI_PASSWORD:-admin}"
export ZHENXUN_SYNC_WEBUI_CREDENTIALS="${ZHENXUN_SYNC_WEBUI_CREDENTIALS:-false}"

escape_sed() {
  printf '%s' "$1" | sed 's/[|&\\]/\\&/g'
}

if [ ! -f /zhenxun/pyproject.toml ]; then
  if [ -z "$(ls -A /zhenxun)" ]; then
    git clone --depth 1 --single-branch "$repo_url" /zhenxun
  else
    git clone --depth 1 --single-branch "$repo_url" /tmp/zhenxun-src
    cp -an /tmp/zhenxun-src/. /zhenxun/
    rm -rf /tmp/zhenxun-src
  fi
elif [ "$auto_update" = "true" ] && [ -d /zhenxun/.git ]; then
  git -C /zhenxun pull --ff-only
fi

if [ ! -f /zhenxun/.env.dev ]; then
  cp /opt/zhenxun-scaffold/.env.dev /zhenxun/.env.dev
fi

if [ ! -f /zhenxun/.env ]; then
  cp /opt/zhenxun-scaffold/.env /zhenxun/.env
fi

mkdir -p /zhenxun/data/db

if [ ! -f /zhenxun/data/config.yaml ]; then
  cp /opt/zhenxun-scaffold/data/config.yaml /zhenxun/data/config.yaml
  webui_username="$(escape_sed "$ZHENXUN_WEBUI_USERNAME")"
  webui_password="$(escape_sed "$ZHENXUN_WEBUI_PASSWORD")"
  sed -i "s|__ZHENXUN_WEBUI_USERNAME__|$webui_username|g" /zhenxun/data/config.yaml
  sed -i "s|__ZHENXUN_WEBUI_PASSWORD__|$webui_password|g" /zhenxun/data/config.yaml
elif [ "$ZHENXUN_SYNC_WEBUI_CREDENTIALS" = "true" ]; then
  python - <<'PY'
from pathlib import Path
import os
import re

path = Path("/zhenxun/data/config.yaml")
lines = path.read_text(encoding="utf-8").splitlines()
username = os.environ["ZHENXUN_WEBUI_USERNAME"]
password = os.environ["ZHENXUN_WEBUI_PASSWORD"]

in_webui = False
seen_username = False
seen_password = False
out = []

for line in lines:
    if re.match(r"^web-ui:\s*$", line):
        in_webui = True
        out.append(line)
        continue
    if in_webui and line and not line.startswith((" ", "\t", "#")):
        if not seen_username:
            out.append(f"  USERNAME: {username}")
        if not seen_password:
            out.append(f"  PASSWORD: {password}")
        in_webui = False

    if in_webui and re.match(r"^\s*USERNAME\s*:", line):
        out.append(f"  USERNAME: {username}")
        seen_username = True
        continue
    if in_webui and re.match(r"^\s*PASSWORD\s*:", line):
        out.append(f"  PASSWORD: {password}")
        seen_password = True
        continue

    out.append(line)

if in_webui:
    if not seen_username:
        out.append(f"  USERNAME: {username}")
    if not seen_password:
        out.append(f"  PASSWORD: {password}")

path.write_text("\n".join(out) + "\n", encoding="utf-8")
PY
fi

if [ "$auto_upgrade" = "true" ]; then
  uv sync --upgrade --no-dev
else
  uv sync --no-dev
fi

uv run playwright install chromium

exec uv run zx
