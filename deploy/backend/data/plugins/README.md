Updated: deploy/backend/data/plugins/README.md

Added DiscordSRV notes.

This directory is where backend plugins are placed by deploy/start.sh. The script will attempt to download EssentialsX, Vault, LuckPerms, WorldEdit, WorldGuard, and DiscordSRV jars (if release assets can be resolved) into this directory on invocation.

If downloads fail, provide direct URLs via environment variables (ESSENTIALS_URL, VAULT_URL, LUCKPERMS_URL, WORLDEDIT_URL, WORLDGUARD_URL, DISCORDSRV_URL) or pin with tags (ESSENTIALS_TAG, VAULT_TAG, LUCKPERMS_TAG, WORLDEDIT_TAG, WORLDGUARD_TAG, DISCORDSRV_TAG).

DiscordSRV notes:
- DiscordSRV requires a discord bot token and configuration to link your Minecraft server to a Discord server. After installing the jar and starting the backend, a DiscordSRV folder will be created under deploy/backend/data/plugins/DiscordSRV with config files (config.yml and others).
- Edit deploy/backend/data/plugins/DiscordSRV/config.yml to set the bot token, channel mappings, and other options before starting the server, or edit after the first run and restart the backend.

Example invocation to fetch plugins:

  DISCORDSRV_TAG="v1.23.0" WORLDEDIT_TAG="v8.0.0" WORLDGUARD_TAG="v8.0.0" ./deploy/start.sh

Or supply direct URLs:

  DISCORDSRV_URL="https://.../DiscordSRV.jar" WORLDEDIT_URL="https://.../worldedit.jar" WORLDGUARD_URL="https://.../worldguard.jar" ./deploy/start.sh
