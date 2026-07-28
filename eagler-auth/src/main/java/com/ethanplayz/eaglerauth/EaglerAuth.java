package com.ethanplayz.eaglerauth;

import com.google.inject.Inject;
import com.velocitypowered.api.event.Subscribe;
import com.velocitypowered.api.event.connection.PreLoginEvent;
import com.velocitypowered.api.plugin.Plugin;
import com.velocitypowered.api.proxy.ProxyServer;
import com.velocitypowered.api.proxy.server.RegisteredServer;
import net.kyori.adventure.text.Component;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

@Plugin(id = "eagler-auth", name = "EaglerAuth", version = "1.0.0", description = "Authenticates Eaglercraft browser connections against an external auth service.")
public class EaglerAuth {
    private final ProxyServer server;
    private final Logger logger;
    private final HttpClient httpClient;
    private final EaglerConfig config;

    @Inject
    public EaglerAuth(ProxyServer server) {
        this.server = server;
        this.logger = server.getLogger();
        this.httpClient = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        this.config = EaglerConfig.load();
        logger.info("EaglerAuth plugin initialized. Auth URL: " + config.authUrl);
    }

    @Subscribe
    public void onPreLogin(PreLoginEvent event) {
        String username = event.getUsername();
        InetSocketAddress remote = event.getRemoteAddress();
        logger.fine("PreLogin from " + username + " @ " + remote);

        if (!config.enabled) {
            logger.fine("EaglerAuth is disabled in config; allowing login for " + username);
            return;
        }

        try {
            // Build JSON payload
            String payload = String.format("{\"username\":\"%s\",\"address\":\"%s\"}", escapeJson(username), escapeJson(remote.toString()));
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(config.authUrl))
                    .header("Content-Type", "application/json")
                    .timeout(Duration.ofSeconds(5))
                    .POST(HttpRequest.BodyPublishers.ofString(payload))
                    .build();

            HttpResponse<String> resp = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            int code = resp.statusCode();
            String body = resp.body();
            logger.fine("Auth response code=" + code + " body=" + body);

            boolean authorized = false;
            if (code == 200) {
                // very small and tolerant JSON check - expects {"authorized":true}
                authorized = body.toLowerCase().contains("\"authorized\":true");
            }

            if (!authorized) {
                logger.info("Authentication failed for " + username + "; denying connection");
                event.setResult(PreLoginEvent.PreLoginComponentResult.denied(Component.text(config.kickMessage)));
            }

        } catch (IOException | InterruptedException ex) {
            logger.log(Level.WARNING, "Error while contacting auth server; denying login by default", ex);
            event.setResult(PreLoginEvent.PreLoginComponentResult.denied(Component.text("Authentication service error. Try again later.")));
        }
    }

    private static String escapeJson(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
