FROM soulter/astrbot:latest

ARG HTTP_PROXY
ARG HTTPS_PROXY
# 使用 root 权限进行系统级安装
USER root

# 设置环境变量，确保 Playwright 路径固定
ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright

# 使用清华大学镜像源加速 Python 依赖安装
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --no-cache-dir \
    playwright \
    Pillow \
    chinese-calendar \
    lunarcalendar \
    jmcomic \
    pymupdf \
    croniter \
    ping3 && \
    playwright install --with-deps chromium && \
    rm -rf /root/.cache/pip

# 构建完成后取消环境变量，防止干扰容器启动后的正常直连
ENV http_proxy=
ENV https_proxy=

# 维持原镜像启动逻辑
CMD ["python3", "main.py"]
