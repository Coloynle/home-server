FROM node:trixie-slim
RUN sed -i "s|deb.debian.org|mirrors.ustc.edu.cn|g" /etc/apt/sources.list.d/debian.sources\
 && apt update\
 && apt install -y ca-certificates\
 && sed -i "s|http://mirrors.ustc.edu.cn|https://mirrors.ustc.edu.cn|" /etc/apt/sources.list.d/debian.sources\
 && apt update\
 && apt full-upgrade -y\
 && apt install -y curl git valkey-server chromium fonts-lxgw-wenkai fonts-noto-color-emoji\
 && apt autoremove --purge\
 && apt clean\
 && ln -vsf valkey-server /bin/redis-server\
 && git config --global --add safe.directory "*"\
 && npm install -g pnpm --registry "https://registry.npmmirror.com"\
 && rm -rf /var/cache/* /var/log/* /var/lib/apt /root/.npm

COPY start-yunzai.sh /start

HEALTHCHECK CMD curl -s http://localhost:2536/status||exit 1
WORKDIR /root/Yunzai
ENTRYPOINT []
CMD ["sh","/start"]
EXPOSE 2536
