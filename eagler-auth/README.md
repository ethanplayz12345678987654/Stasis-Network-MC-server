# EaglerAuth — Velocity plugin to authenticate Eaglercraft users

This plugin verifies incoming Eaglercraft browser connections by calling an external HTTP auth endpoint. It is intended to be used on the proxy (Velocity) so Eagler connections are validated before being forwarded to backend servers.

How it works
- On pre-login, the plugin POSTs JSON {"username":"...","address":"..."} to the configured auth_url.
- The auth service must respond with HTTP 200 and include "\"authorized\":true" in the response body to permit the connection.
- Otherwise the connection is denied with the configured kick message.

Files added
- eagler-auth/ — Maven project (source and pom.xml)
  - src/main/java/.../EaglerAuth.java — main plugin class
  - src/main/java/.../EaglerConfig.java — simple config loader
  - src/main/resources/velocity-plugin.json — Velocity plugin descriptor
  - src/main/resources/eagler-auth.properties — default properties
- deploy/proxy/plugins/eagler-auth.conf — example config you can edit on the host

Build
1. Build with Maven (Java 17):
   cd eagler-auth
   mvn package

2. The shaded jar will be available at target/eagler-auth-1.0.0.jar. Copy it into deploy/proxy/plugins/ alongside EaglerXServer.jar and restart the proxy container.

Configuration
- Edit src/main/resources/eagler-auth.properties before building, or edit deploy/proxy/plugins/eagler-auth.conf on the host and restart the proxy.
- auth_url should point to an endpoint that verifies sessions or tokens (example: your web server that handles login sessions or an OAuth introspection endpoint).

Example auth endpoint contract
- Request: POST JSON {"username": "player123", "address": "/ip:port"}
- Success response (HTTP 200): {"authorized": true}
- Deny response: HTTP 403 or HTTP 200 with {"authorized": false}

Notes & limitations
- The plugin uses a best-effort lightweight JSON check. For production, adapt response parsing to your auth server's exact schema and consider verifying signatures or using JWT.
- You must ensure the auth service is reachable from the proxy container. If you run it on the same host, expose it on the docker network or use containerized service.
- Velocity API versions may vary — if compilation errors occur, adjust velocity-api version in pom.xml to match the proxy's API.

If you want, I can:
- Add a simple example auth microservice (Node.js/Express or Python/Flask) you can run in docker-compose for testing.
- Build the plugin here and add the compiled jar into deploy/proxy/plugins automatically.
- Modify the plugin to validate JWTs or session cookies instead of the simple POST contract.
