# Backend plugins directory

Place any backend (Paper/Spigot) plugin jars here so they are available to the backend server when the container starts.

Example:
- deploy/backend/plugins/auto-op-1.0.0.jar

If you add new plugin jars, restart the backend container:
  docker compose -f deploy/docker-compose.yml restart mc_backend
