package com.ethanplayz.eaglerauth;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

public class EaglerConfig {
    public final boolean enabled;
    public final String authUrl;
    public final String kickMessage;

    private EaglerConfig(boolean enabled, String authUrl, String kickMessage) {
        this.enabled = enabled;
        this.authUrl = authUrl;
        this.kickMessage = kickMessage;
    }

    public static EaglerConfig load() {
        Properties p = new Properties();
        try (InputStream in = EaglerConfig.class.getResourceAsStream("/eagler-auth.properties")) {
            if (in != null) {
                p.load(in);
            }
        } catch (IOException ignored) {}

        boolean enabled = Boolean.parseBoolean(p.getProperty("enabled", "true"));
        String authUrl = p.getProperty("auth_url", "http://localhost:8080/auth");
        String kickMessage = p.getProperty("kick_message", "You are not authorized to join this server.");
        return new EaglerConfig(enabled, authUrl, kickMessage);
    }
}
