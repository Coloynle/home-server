# Home Server

Docker Compose based home-server stack. Most services use upstream images directly; the bot images are built by GitHub Actions and published to Docker Hub.

## Services

- `astrbot`: AstrBot bot platform, with Playwright Chromium installed in the image.
- `gsuid_core`: GSUID Core game-query service, with Playwright Chromium installed in the image.
- `nonebot`: Blank NoneBot2 project with OneBot v11 adapter and a web plugin-management panel.
- `yunzai`: TRSS-Yunzai bot runtime, with system Chromium installed in the image.
- `zhenxun_bot`: Complete NoneBot2-based bot distribution with its own plugin/config ecosystem and WebUI.
- `napcat`: QQ protocol/client side service used by the bot stack.
- `nginx-proxy-manager`, `cloudflared`, `adguardhome`, `reader`, `v2raya`, `cloudsaver`.

## Docker Hub Images

The default compose file pulls these images:

```text
coloynle/astrbot:latest
coloynle/gsuid_core:latest
coloynle/nonebot:latest
coloynle/yunzai:latest
coloynle/zhenxun_bot:latest
```

Override the namespace with `DOCKERHUB_NAMESPACE` in `.env` if needed.

## GitHub Actions Setup

Create a Docker Hub access token, then add these repository secrets:

```text
DOCKERHUB_USERNAME=coloynle
DOCKERHUB_TOKEN=<docker-hub-access-token>
```

The workflow builds on pushes to `main` when one of these paths changes:

```text
astrbot/**
gsuid_core/**
nonebot/**
trss_yunzai/**
zhenxun_bot/**
.github/workflows/docker-build.yml
```

It pushes `latest`, a short git SHA tag, and registry-backed build cache for each image.

The workflow also runs every day at 04:00 Asia/Shanghai. This scheduled rebuild is intentional:

- `astrbot` is rebuilt when `soulter/astrbot:latest` changes.
- `gsuid_core` is rebuilt when `docker.cnb.cool/gscore-mirror/gsuid_core:latest` changes.
- `nonebot` is rebuilt when its Python base image or scaffold changes.
- `yunzai` is rebuilt when the Node base image or apt packages such as Chromium change.
- `zhenxun_bot` is rebuilt when its Python base image or Playwright runtime changes.

GitHub Actions does not need to store previous digests. Buildx pulls the current base-image metadata, reuses cache when nothing changed, and pushes fresh bot images when rebuild output changes.

## Deploy

Create `.env`:

```env
CLOUDFLARE_TUNNEL_TOKEN=your-token
DOCKERHUB_NAMESPACE=coloynle
AUTO_UPDATE_YUNZAI=false
WATCHTOWER_INTERVAL=3600
AUTO_UPGRADE_NONEBOT=false
AUTO_UPDATE_ZHENXUN=false
AUTO_UPGRADE_ZHENXUN=false
```

Start or update the stack:

```bash
make run
make update
```

Stop the stack:

```bash
make down
```

## Automatic Updates

`watchtower` is included in `docker-compose.yml` and is scoped to these containers only:

```text
astrbot
gsuid_core
nonebot
Yunzai
zhenxun_bot
```

It checks Docker Hub every `WATCHTOWER_INTERVAL` seconds, pulls changed images, recreates only those containers, and cleans old image layers. It does not update infrastructure containers such as `nginx-proxy-manager`, `adguardhome`, `cloudflared`, or `v2raya`.

TRSS-Yunzai code lives in the mounted `trss_yunzai/data` directory. Image rebuilds update the runtime environment, but not an existing checked-out Yunzai repository. To update Yunzai code on container start, set:

```env
AUTO_UPDATE_YUNZAI=true
```

The startup script then runs `git pull --ff-only` before `pnpm install`. Keep it `false` if you make local changes inside `trss_yunzai/data`.

Zhenxun Bot code lives in the mounted `zhenxun_bot/data` directory. To pull upstream code on container start, set:

```env
AUTO_UPDATE_ZHENXUN=true
```

To upgrade Python dependencies with `uv sync --upgrade --no-dev`, set:

```env
AUTO_UPGRADE_ZHENXUN=true
```

Leave both `false` if you prefer stable runtime behavior after the first successful startup.

## NoneBot

The `nonebot` image initializes a blank NoneBot2 project into `nonebot/data` on first start. The mounted data directory contains the project files, local plugins, and Python virtual environment:

```text
nonebot/data
├── .venv
├── bot.py
├── pyproject.toml
├── requirements.txt
└── plugins
```

The image includes:

```text
nonebot2[fastapi]
nonebot-adapter-onebot
nb-cli
nonebot-plugin-manageweb
```

By default, the container installs missing dependencies but does not force-upgrade already installed packages in `nonebot/data/.venv`. To upgrade NoneBot dependencies on container start, set:

```env
AUTO_UPGRADE_NONEBOT=true
```

Leave it `false` if you prefer stable dependency versions after the first successful startup.

The web plugin-management panel comes from the third-party `nonebot-plugin-manageweb` package. NoneBot's official plugin workflow is still `nb-cli`, so treat the web panel as a convenience layer rather than the core package manager.

Default runtime:

```text
HOST=0.0.0.0
PORT=19210
MW_CDN=https://unpkg.com
```

To connect NapCat to NoneBot, configure a OneBot v11 reverse WebSocket target in NapCat. With host networking, the target is usually:

```text
ws://127.0.0.1:19210/onebot/v11/ws
```

If you already have files in `nonebot/data`, the container will not overwrite them on restart.

Use the same container path when sharing local files with NapCat:

```text
NoneBot: ./nonebot/data -> /nonebot
NapCat:  ./nonebot/data -> /nonebot
```

Do not mount it to `/app` in NapCat, because NapCat uses `/app` for its own program files.

If the manageweb login page reports `amisRequire is not defined`, the browser did not load the AMis SDK from `MW_CDN`. Change `nonebot/data/.env` to another npm CDN, for example:

```env
MW_CDN=https://cdn.jsdelivr.net/npm
```

Do not add a trailing slash to `MW_CDN`; the plugin appends paths such as `/amis@latest/sdk/sdk.js` itself.

## Zhenxun Bot

`zhenxun_bot` is a complete NoneBot2-based bot distribution. It is separate from the blank `nonebot` service:

```text
nonebot      -> blank NoneBot2 environment for testing general plugins
zhenxun_bot  -> ready-made bot with its own WebUI, config system, and plugin ecosystem
```

The container initializes upstream Zhenxun Bot into `zhenxun_bot/data` on first start:

```text
zhenxun_bot/data -> /zhenxun
```

Default runtime:

```text
HOST=0.0.0.0
PORT=19211
DB_URL=sqlite:data/db/zhenxun.db
ZHENXUN_WEBUI_USERNAME=admin
ZHENXUN_WEBUI_PASSWORD=admin
ZHENXUN_SYNC_WEBUI_CREDENTIALS=false
```

Zhenxun's upstream docs use `.env.dev`, so the image writes both `.env.dev` and `.env` templates and also exports these values as container environment variables. This prevents the upstream default `127.0.0.1:8080` from being used when another service already occupies port 8080.

The image also writes `data/config.yaml` on first start with default WebUI credentials:

```text
username: admin
password: admin
```

Change them in `zhenxun_bot/data/data/config.yaml` after the first start. If you want CasaOS environment variables to overwrite an existing `config.yaml` on container start, set:

```env
ZHENXUN_SYNC_WEBUI_CREDENTIALS=true
```

To connect NapCat to Zhenxun Bot, configure another OneBot v11 reverse WebSocket target:

```text
ws://127.0.0.1:19211/onebot/v11/ws
```

NapCat also mounts the same directory to `/zhenxun`, so local files generated by Zhenxun plugins can be sent through NapCat without path mismatch.

## Local Image Builds

Default deployment does not build images locally. If you need to rebuild the bot images on the home server, use the build override file:

```bash
make build
make run-local
```

Optional local build proxy:

```env
BUILD_HTTP_PROXY=http://172.17.0.1:20172
BUILD_HTTPS_PROXY=http://172.17.0.1:20172
```

No-cache rebuild:

```bash
make build-no-cache
```

## Data

Runtime data is mounted from local directories and is not part of the Docker build context:

```text
astrbot/data
gsuid_core/data
gsuid_core/plugins
nonebot/data
trss_yunzai/data
zhenxun_bot/data
```
