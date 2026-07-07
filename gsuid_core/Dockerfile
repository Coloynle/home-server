FROM docker.cnb.cool/gscore-mirror/gsuid_core:latest

USER root

# Keep the default Debian mirror for GitHub Actions. Playwright installs its
# browser runtime dependencies in the later step.
RUN export http_proxy="" https_proxy="" no_proxy="*" && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 第二步：安装 Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm --registry "https://registry.npmmirror.com" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /root/.npm

# 第三步：安装 playwright 和 浏览器
RUN . /venv/bin/activate && \
    uv pip install playwright && \
    uv run playwright install chromium --with-deps

WORKDIR /gsuid_core
