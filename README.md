# tailscale-containers

這個專案是 tailscale 自行編譯的 container,因為 base image 同時包含多個 binary
所以獨立成一個 compose 來當成 base image

## How to use

```sh
mv env.sample .env

# following value to your preference
vim .env
```

## tailscale-userspace

這個 container 可以在沒有權限的環境之下，創建 userspace proxy(sock5, http proxy)，
同時也可以宣告這個 service 是 subnet router 或是 exit node。

```shell
# (Required) Tailscale auth
TAILSCALE_AUTH_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TAILSCALE_HOSTNAME=derp

# (Optional) Custom login server (e.g. Headscale)
TAILSCALE_LOGIN_SERVER=https://xxxxxxxxx.net

# (Optional) State storage: "mem:" (ephemeral) or "/app/states" (persistent)
TAILSCALED_STATE_ARG="mem:"

# (Optional) SOCKS5 and HTTP proxy listen addresses
TAILSCALED_SOCKS5_SERVER=0.0.0.0:1055
TAILSCALED_HTTP_PROXY=0.0.0.0:1056
```

## tailscale-derp

```shell
# (Required) Tailscale auth
TAILSCALE_AUTH_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TAILSCALE_HOSTNAME=derp

# (Optional) Custom login server (e.g. Headscale)
TAILSCALE_LOGIN_SERVER=https://xxxxxxxxx.net

# (Required, tailscale-derp) DERP server config
DERP_DOMAIN=xxxxxxxxx.net
DERP_VERIFY_CLIENTS=true
```
