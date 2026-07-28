# Backend plugins directory (managed by start.sh)

This directory is where backend plugins (Paper/PaperMC) should be placed so the mc_backend container can load them.

The helper script deploy/start.sh will attempt to download EssentialsX, Vault, and LuckPerms into this directory automatically if their releases can be resolved from GitHub. If you prefer to manage plugins manually, place plugin jars here and restart the backend container.

Example:
- deploy/backend/data/plugins/EssentialsX.jar
- deploy/backend/data/plugins/Vault.jar
- deploy/backend/data/plugins/LuckPerms.jar

To force-download plugins via the helper script, run:

  ./deploy/start.sh

You can also pin versions by setting environment variables before running start.sh:

  VELOCITY_TAG="vX.Y.Z" EAGLER_TAG="vA.B.C" ESSENTIALS_TAG="v1.5.0" VAULT_TAG="v1.7.0" LUCKPERMS_TAG="vX.Y.Z" ./deploy/start.sh

Or supply direct download URLs:

  VELOCITY_URL="https://.../velocity.jar" EAGLER_URL="https://.../EaglerXServer.jar" ESSENTIALS_URL="https://.../EssentialsX.jar" VAULT_URL="https://.../Vault.jar" LUCKPERMS_URL="https://.../LuckPerms.jar" ./deploy/start.sh
