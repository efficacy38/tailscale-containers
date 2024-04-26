# tailscale-containers

這個專案是 tailscale 自行編譯的 container,因為 base image 同時包含多個 binary
所以獨立成一個 compose 來當成 base image

## tailscale-userspace

這個 container 可以在沒有權限的環境之下，創建 userspace proxy(sock5, http proxy)，
同時也可以宣告這個 service 是 subnet router 或是 exit node。

```shell
# (Required, both of tailscale-derp and tailscale-userspace) tailscaled config
TAILSCALE_AUTH_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TAILSCALE_HOSTNAME=derp
TAILSCALE_OPT=--login-server https://xxxxxxxxx.net

# (Optional) if you want's tailscale to be as userspace proxy
TAILSCALED_STATE_ARG="mem:"
TAILSCALED_OPT=--socks5-server=0.0.0.0:1055 --outbound-http-proxy-listen=0.0.0.0:1056
```

## tailscale-derp

```shell
# (Required, both of tailscale-derp and tailscale-userspace) tailscaled config
TAILSCALE_AUTH_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TAILSCALE_HOSTNAME=derp
TAILSCALE_OPT=--login-server https://xxxxxxxxx.net

# (Required, tailscale-derp) derp configs
DERP_DOMAIN=xxxxxxxxx.net
DERP_VERIFY_CLIENTS=true
```
