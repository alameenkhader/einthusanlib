:81 {
  encode zstd gzip

  # Serve precompiled assets directly (optional)
  handle_path /assets/* {
    root * /var/www/myapp/current/public
    file_server
  }

  # ActionCable (WebSockets)
  @cable path /cable*
  reverse_proxy @cable 127.0.0.1:3000 {
    transport http {
      versions 1.1
      read_timeout  0s
      idle_timeout  0s
    }
    header_up Host {host}
    header_up X-Forwarded-Proto {scheme}
    header_up X-Forwarded-For {remote}
  }

  # Everything else → Rails (Puma)
  reverse_proxy 127.0.0.1:3000
}


config.force_ssl = false   # IMPORTANT: you are serving HTTP
config.action_cable.mount_path = '/cable'
config.action_cable.url = 'ws://YOUR_IP:81/cable'
config.action_cable.allowed_request_origins = [
  "http://YOUR_IP:81"
]
