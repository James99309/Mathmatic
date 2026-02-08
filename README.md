# Mathematic - 数学练习网页项目

## 项目概述

独立的数学练习网页集合，部署在新加坡 NAS 上，通过 Cloudflare Tunnel 提供外网访问。

## 已部署页面

| 页面 | 文件 | 说明 |
|------|------|------|
| Staircase Fractions Practice Retest | `staircase_fractions_test.html` | 阶梯分数练习测试，支持手写作答和 PDF 导出 |

## 部署架构

```
用户 → https://math.jamesgpone.win → Cloudflare Tunnel (nas-sg) → 192.168.1.2:8088 → mathmatic-web (nginx:alpine)
```

## 新加坡 NAS 部署信息

- **NAS IP**: `192.168.1.2`（SSH 免密登录已配置）
- **Docker 命令**: 使用 `sudo /usr/local/bin/docker-compose`（旧版独立二进制，非 docker compose 子命令）
- **项目目录**: `/volume1/docker/mathmatic/`
- **容器名称**: `mathmatic-web`
- **镜像**: `nginx:alpine`
- **端口映射**: `8088:80`
- **外网域名**: `https://math.jamesgpone.win`

### NAS 目录结构

```
/volume1/docker/mathmatic/
├── html/
│   └── index.html          # 网页文件（从源文件重命名）
└── docker-compose.yml      # Docker Compose 配置
```

### docker-compose.yml 内容

```yaml
version: '3'
services:
  mathmatic:
    image: nginx:alpine
    container_name: mathmatic-web
    restart: unless-stopped
    ports:
      - "8088:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
```

## 常用运维命令

```bash
# 查看容器状态
ssh admin@192.168.1.2 "sudo /usr/local/bin/docker ps --filter name=mathmatic-web"

# 重启容器
ssh admin@192.168.1.2 "cd /volume1/docker/mathmatic && sudo /usr/local/bin/docker-compose restart"

# 停止容器
ssh admin@192.168.1.2 "cd /volume1/docker/mathmatic && sudo /usr/local/bin/docker-compose down"

# 启动容器
ssh admin@192.168.1.2 "cd /volume1/docker/mathmatic && sudo /usr/local/bin/docker-compose up -d"

# 查看日志
ssh admin@192.168.1.2 "sudo /usr/local/bin/docker logs mathmatic-web --tail 50"
```

## 更新页面内容

由于 NAS 的 scp 存在权限限制，需要通过 cat 管道方式传输文件：

```bash
# 更新现有页面
cat /Users/nijie/Documents/Mathematic/staircase_fractions_test.html | \
  ssh admin@192.168.1.2 "sudo tee /volume1/docker/mathmatic/html/index.html > /dev/null"

# 添加新页面（例如 new_page.html）
cat /Users/nijie/Documents/Mathematic/new_page.html | \
  ssh admin@192.168.1.2 "sudo tee /volume1/docker/mathmatic/html/new_page.html > /dev/null"
```

> **注意**: `scp` 直接传输会报 "Permission denied"，必须使用 `cat | ssh sudo tee` 方式。

## Cloudflare Tunnel 配置

外网访问通过 Cloudflare Tunnel `nas-sg` 隧道提供：

- **Subdomain**: `math`
- **Domain**: `jamesgpone.win`
- **Service Type**: HTTP
- **URL**: `192.168.1.2:8088`

如需修改，登录 [Cloudflare Dashboard](https://dash.cloudflare.com) → Zero Trust → Networks → Tunnels → `nas-sg`。

## 部署日期

- **2026-02-08**: 初次部署 Staircase Fractions Practice Retest 页面
