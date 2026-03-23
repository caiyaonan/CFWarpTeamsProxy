# CFWarpTeamsProxy

一个基于官方 `cloudflare-warp` 客户端的 Cloudflare WARP Teams Docker 代理容器。

容器启动后会连接 WARP Teams，并同时对外提供：

- HTTP 代理：`40001`
- SOCKS5 代理：`40008`

---

## 项目特点

适合需要稳定接入 WARP Teams，并同时给不同应用提供 HTTP 和 SOCKS5 两种代理入口的场景。

工作方式：

1. 使用官方 `cloudflare-warp` 完成注册和连接
2. 使用 `socat` 转发 HTTP 代理
3. 使用 `gost` 将 HTTP 代理转换为 SOCKS5

---

## 快速开始

### 1. 修改 `docker-compose.yml`

以下三个环境变量是必填项，不能留空，也不能保留占位值：

```yaml
environment:
  TEAM_NAME: "REPLACE_WITH_TEAM_NAME"
  PROXY_PORT: "REPLACE_WITH_PROXY_PORT"
  CF_REGISTRATION_TOKEN: "REPLACE_WITH_TOKEN"
```

示例：

```yaml
environment:
  TEAM_NAME: "example-team"
  PROXY_PORT: "40000"
  CF_REGISTRATION_TOKEN: "xxxxxxxxxxxxxxxx"
```

### 2. 启动

```bash
docker compose up -d --build
```

### 3. 使用代理

```text
HTTP   : http://127.0.0.1:40001
SOCKS5 : socks5://127.0.0.1:40008
```

---

## 必填环境变量

### `TEAM_NAME`

必填。Cloudflare Teams 组织名。

### `PROXY_PORT`

必填。WARP 在容器内监听的本地 HTTP 代理端口。

要求：

- 必须填写
- 必须是数字
- 必须在 `1-65535` 之间

### `CF_REGISTRATION_TOKEN`

必填。Cloudflare WARP Teams 注册 token。

---

## 启动校验

容器启动时会强制校验以下条件：

- `TEAM_NAME` 不能为空
- `PROXY_PORT` 不能为空
- `CF_REGISTRATION_TOKEN` 不能为空
- 不能继续使用 `team-name`、`your-token`、`REPLACE_WITH_*`、`CHANGEME` 这类占位值
- `PROXY_PORT` 必须是有效端口号

如果未通过校验，容器会直接报错退出。

---

## 默认端口

| 端口 | 类型 | 说明 |
| :--- | :--- | :--- |
| `40001` | HTTP | 对外提供 HTTP 代理 |
| `40008` | SOCKS5 | 对外提供 SOCKS5 代理 |
| `PROXY_PORT` | 内部端口 | WARP 本地 HTTP 代理端口 |

---

## 注意事项

### 1. 需要 `NET_ADMIN`

```yaml
cap_add:
  - NET_ADMIN
```

### 2. 当前 `gost` 下载的是 `amd64`

`Dockerfile` 当前使用的是：

```text
gost-linux-amd64
```

如果你要运行在 `arm64`，需要自行调整。

### 3. 注册数据会持久化

数据卷路径：

```text
/var/lib/cloudflare-warp
```

删除数据卷后，通常需要重新注册。

---

## 许可证

本项目使用 [MIT License](./LICENSE)。

你可以自由地使用、修改、分发和私有化部署本项目，但必须保留原始版权声明和许可证文本。

---

## 无责声明

本项目仅供学习、研究与合法授权的网络环境接入测试使用。

使用者应自行确认其使用行为符合所在国家或地区的法律法规、服务条款以及所属组织的安全规范。因使用本项目而导致的任何直接或间接后果，包括但不限于账号风险、服务中断、数据泄露、合规问题或其他损失，项目作者及贡献者不承担任何责任。
