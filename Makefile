all: run

run:
	docker compose -p "home-server" up -d

pull:
	docker compose -p "home-server" pull astrbot gsuid_core yunzai

update:
	docker compose -p "home-server" pull && docker compose -p "home-server" up -d

down:
	docker compose -p "home-server" down --remove-orphans

build:
	docker compose -p "home-server" -f docker-compose.yml -f docker-compose.build.yml build

build-no-cache:
	docker compose -p "home-server" -f docker-compose.yml -f docker-compose.build.yml build --no-cache

run-local:
	docker compose -p "home-server" -f docker-compose.yml -f docker-compose.build.yml up -d

run-local-napcat:
	docker compose -p "home-server" -f docker-compose-napcat.yml up -d

restart-astrbot:
	docker compose -p "home-server" up -d astrbot

restart-gsuid:
	docker compose -p "home-server" up -d gsuid_core

restart-nonebot:
	docker compose -p "home-server" up -d nonebot

restart-yunzai:
	docker compose -p "home-server" up -d yunzai

restart-zhenxun:
	docker compose -p "home-server" up -d zhenxun_bot

bot-update:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -e TZ=Asia/Shanghai ghcr.io/containrrr/watchtower:latest yunzai gsuid_core astrbot --run-once --cleanup
