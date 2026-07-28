# Eaglercraft + Minecraft 1.21 (Paper) - Docker Compose Template

This repository section contains a template to run an Eaglercraft (EaglercraftX / EaglerXServer) compatible proxy (Velocity) in front of a Java Minecraft 1.21 backend (Paper), using Docker Compose.

What this provides:
- A Docker Compose template that starts a Paper 1.21 backend and a generic Java-based proxy container (you place the Velocity jar + EaglerXServer plugin in the proxy folder).
- Example Velocity config and an example EaglerXServer plugin config.
- Instructions and commands to download the latest Velocity and EaglerXServer jars.

Notes / disclaimers:
- For stability, you should pin Velocity and EaglerXServer to specific versions. The example commands use placeholders you must replace with the desired release versions or use the projects' releases pages.
- The EaglerXServer plugin must be the version compatible with the Velocity/Bungee plugin API you choose.
- This template does not bundle any third-party jars. You must download the server jar(s) yourself (automated curl examples are provided).

Structure added:
- docker-compose.yml
- backend/ (data volume will be created at runtime)
- proxy/
  - server.jar (placeholder path - you must download the Velocity jar here)
  - plugins/ (place EaglerXServer.jar here)
  - velocity.toml (example)
  - eaglerx.yml (example plugin config)
- README.eagler_setup.md (this file)
- start.sh (helper script to download jars and start the stack)

Quick start (summary):
1. Edit docker-compose.yml if you need custom memory or ports.
2. Download a Velocity jar into ./proxy/server.jar and EaglerXServer.jar into ./proxy/plugins/
3. Run: docker compose up -d
4. Browser clients connect to the host on port 25565 (by default), and the proxy will forward players to the backend Paper server.

For more detail, read the README.eagler_setup.md in this folder.
