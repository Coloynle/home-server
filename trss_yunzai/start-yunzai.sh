#!/bin/sh
set -e

repo_url="${YUNZAI_REPO_URL:-https://gitee.com/TimeRainStarSky/Yunzai}"
auto_update="${AUTO_UPDATE_YUNZAI:-false}"
pnpm_install_args="--force --dangerously-allow-all-builds"

if [ ! -d .git ]; then
  git clone --depth 1 --single-branch "$repo_url" .
elif [ "$auto_update" = "true" ]; then
  git pull --ff-only
fi

pnpm install $pnpm_install_args
pnpm add axios --dangerously-allow-all-builds

exec node . start
