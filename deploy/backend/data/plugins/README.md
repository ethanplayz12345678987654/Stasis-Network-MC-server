Added WorldEdit and WorldGuard to the backend plugins README and notes.

This folder is where backend plugins are placed by deploy/start.sh. The script will attempt to download WorldEdit and WorldGuard jars (if release assets can be resolved) into this directory on invocation.

If downloads fail, provide direct URLs via WORLDEDIT_URL and WORLDGUARD_URL environment variables, or pin with WORLDEDIT_TAG and WORLDGUARD_TAG.

Example invocation:

  WORLDEDIT_TAG="v8.0.0" WORLDGUARD_TAG="v8.0.0" ./deploy/start.sh

Or supply direct URLs:

  WORLDEDIT_URL="https://.../worldedit.jar" WORLDGUARD_URL="https://.../worldguard.jar" ./deploy/start.sh
