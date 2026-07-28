# AutoOp — Paper/Spigot plugin

This plugin grants operator status to a configured username when they join the server.

Build

Requirements:
- Java 17
- Maven

Build steps:

  cd auto-op
  mvn package

The shaded jar will be created at target/auto-op-1.0.0.jar. Copy this jar into deploy/backend/plugins/ on the host (create the directory if it doesn't exist):

  mkdir -p deploy/backend/plugins
  cp auto-op/target/auto-op-1.0.0.jar deploy/backend/plugins/

Restart the backend container:

  docker compose -f deploy/docker-compose.yml restart mc_backend

Configuration

The plugin uses a single config option `target` (case-insensitive) which defaults to `EthanPLAYZ`. To change it, edit the config.yml inside the plugin jar before building or create a directory deploy/backend/plugins/AutoOp and place a config.yml there.

Notes

- This plugin sets player.setOp(true) on join. If you require more granular permission control, consider using a permissions plugin (LuckPerms) and assigning a permissions group instead.
- Setting op on join is a convenience; be sure to secure operator commands and consider giving permanent ops via ops.json for persistence if needed.
