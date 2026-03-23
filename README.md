# CFWarpTeamsProxy

一个基于官方 `cloudflare-warp` 客户端的 Cloudflare WARP Teams Docker 代理容器。

容器启动后会连接 WARP Teams，并同时对外提供：

- HTTP 代理：`40001`
- SOCKS5 代理：`40008`

默认发布镜像：

```bash
docker pull magotcai/cfwarpteamsproxy:latest
```

---

## 快速开始

### 1. 准备 `docker-compose.yml`

当前仓库内的 [docker-compose.yml](d:\Project\CFWarpTeamsProxy\docker-compose.yml) 已经改成直接拉取镜像的方式：

```yaml
version: "3.9"

services:
  warp:
    image: magotcai/cfwarpteamsproxy:latest
    container_name: warp-teams-proxy
    restart: unless-stopped

    cap_add:
      - NET_ADMIN

    ports:
      - "127.0.0.1:40001:40001"
      - "127.0.0.1:40008:40008"

    environment:
      TEAM_NAME: "REPLACE_WITH_TEAM_NAME"
      PROXY_PORT: "REPLACE_WITH_PROXY_PORT"
      CF_REGISTRATION_TOKEN: "REPLACE_WITH_TOKEN"

    volumes:
      - warp-data:/var/lib/cloudflare-warp

volumes:
  warp-data:
```

### 2. 填写必填环境变量

以下三个变量必须填写，不能留空，也不能保留占位值：

```yaml
environment:
  TEAM_NAME: "你的团队名"
  PROXY_PORT: "40000"
  CF_REGISTRATION_TOKEN: "你的真实token"
```

说明：

- `TEAM_NAME`：Cloudflare Teams 组织名
- `PROXY_PORT`：容器内 WARP 本地 HTTP 代理端口，必须是 `1-65535` 的数字
- `CF_REGISTRATION_TOKEN`：Cloudflare WARP Teams 注册 token

### 3. 启动

```bash
docker compose up -d
```

### 4. 测试代理

HTTP：

```bash
curl -x http://127.0.0.1:40001 ifconfig.me
```

SOCKS5：

```bash
curl --socks5-hostname 127.0.0.1:40008 https://ifconfig.me
```

---

## 代理地址

默认可直接使用：

```text
HTTP   : http://127.0.0.1:40001
SOCKS5 : socks5://127.0.0.1:40008
```

---

## 运行要求

### 1. 需要 `NET_ADMIN`

```yaml
cap_add:
  - NET_ADMIN
```

### 2. 当前支持 `amd64` 和 `arm64`

镜像会根据构建架构自动下载对应的 `gost` 二进制：

- `amd64`
- `arm64`

### 3. 注册数据会持久化

数据卷路径：

```text
/var/lib/cloudflare-warp
```

删除数据卷后，通常需要重新注册。

---

## 本地构建

如果你想自己在本地构建镜像：

```bash
docker build -t magotcai/cfwarpteamsproxy:latest .
```

构建完成后可直接运行：

```bash
docker run -d \
  --name warp-teams-proxy \
  --restart unless-stopped \
  --cap-add NET_ADMIN \
  -e TEAM_NAME=你的团队名 \
  -e PROXY_PORT=40000 \
  -e CF_REGISTRATION_TOKEN=你的真实token \
  -p 127.0.0.1:40001:40001 \
  -p 127.0.0.1:40008:40008 \
  -v warp-data:/var/lib/cloudflare-warp \
  magotcai/cfwarpteamsproxy:latest
```

---

## 许可证

本项目使用 [MIT License](./LICENSE)。

你可以自由地使用、修改、分发和私有化部署本项目，但必须保留原始版权声明和许可证文本。

---

## 无责声明

本项目仅供学习、研究与合法授权的网络环境接入测试使用。

使用者应自行确认其使用行为符合所在国家或地区的法律法规、服务条款以及所属组织的安全规范。因使用本项目而导致的任何直接或间接后果，包括但不限于账号风险、服务中断、数据泄露、合规问题或其他损失，项目作者及贡献者不承担任何责任。
