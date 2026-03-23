FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ARG GOST_VERSION=3.2.6
ARG TARGETARCH

RUN apt-get update && apt-get install -y \
    ca-certificates curl gnupg iproute2 iptables procps tini socat wget tar \
 && mkdir -p /usr/share/keyrings \
 && curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
    | gpg --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bookworm main" \
    > /etc/apt/sources.list.d/cloudflare-client.list \
 && apt-get update \
 && apt-get install -y cloudflare-warp \
 && arch="${TARGETARCH:-$(dpkg --print-architecture)}" \
 && case "$arch" in \
      amd64) gost_arch="amd64" ;; \
      arm64) gost_arch="arm64" ;; \
      *) echo "Unsupported architecture for gost: $arch" >&2; exit 1 ;; \
    esac \
 && wget -O /tmp/gost.tar.gz "https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${gost_arch}.tar.gz" \
 && tar -xzf /tmp/gost.tar.gz -C /tmp \
 && install -m 0755 /tmp/gost /usr/local/bin/gost \
 && /usr/local/bin/gost -V \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/gost.tar.gz /tmp/gost

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
