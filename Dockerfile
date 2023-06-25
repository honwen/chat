# builder
FROM --platform=$TARGETPLATFORM golang:1.20 as builder
ARG TARGETARCH
ARG GOPROXY="https://mirrors.tencent.com/go/,direct"

WORKDIR /app

ADD go.mod go.sum ./
RUN go mod download -x

ADD . .
RUN CGO_ENABLED=0 GOARCH=${TARGETARCH} go build -ldflags="-w -s" -x .

# finally
FROM --platform=$TARGETPLATFORM debian:bullseye-slim

ARG MIRRORS=mirrors.tencent.com

RUN set -ex && cd / \
    && sed "s+//.*debian.org+//${MIRRORS}+g; /^#/d" -i /etc/apt/sources.list \
    && apt --allow-releaseinfo-change -y update \
    && apt install -y --no-install-recommends ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/cache/apt/* /root/.cache

COPY --from=builder /app/chat /usr/local/bin

WORKDIR /web

EXPOSE 8080

CMD chat
