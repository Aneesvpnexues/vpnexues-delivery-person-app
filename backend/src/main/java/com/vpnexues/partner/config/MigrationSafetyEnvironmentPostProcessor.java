package com.vpnexues.partner.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;

import java.util.Locale;

/**
 * Fail-closed guard that runs while the Environment is being prepared, before
 * Flyway auto-configuration or any application bean is created.
 *
 * The Java V1-V11 Flyway scripts are not equivalent to the SQL 0001-0011
 * migrations already applied in the isolated Supabase project. They must never
 * be run, baselined, or repaired against a remote database. Flyway is disabled
 * by default; this guard additionally refuses to let it initialise unless the
 * target is explicitly local and the datasource URL is loopback.
 */
public class MigrationSafetyEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

    public static final String FLYWAY_ENABLED = "spring.flyway.enabled";
    public static final String MIGRATION_TARGET = "app.migration-target";
    public static final String DATASOURCE_URL = "spring.datasource.url";

    @Override
    public int getOrder() {
        // ConfigDataEnvironmentPostProcessor uses HIGHEST_PRECEDENCE + 10; run
        // just after it so application.yml/profile values are visible, but
        // still before Flyway auto-configuration creates any bean.
        return Ordered.HIGHEST_PRECEDENCE + 11;
    }

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        boolean flywayEnabled = environment.getProperty(FLYWAY_ENABLED, Boolean.class, Boolean.FALSE);
        if (!flywayEnabled) {
            return;
        }
        String target = environment.getProperty(MIGRATION_TARGET, "");
        if (!"local".equalsIgnoreCase(target.trim())) {
            throw new IllegalStateException(
                    "Flyway may only run with app.migration-target=local; refusing to initialise migrations");
        }
        if (!isLoopback(environment.getProperty(DATASOURCE_URL, ""))) {
            throw new IllegalStateException(
                    "Flyway may only run against a loopback database; refusing to initialise migrations for a remote target");
        }
    }

    /** Returns true only for localhost/127.0.0.1/::1 JDBC URLs. Never logs the URL itself. */
    public static boolean isLoopback(String jdbcUrl) {
        if (jdbcUrl == null || jdbcUrl.isBlank()) return false;
        String url = jdbcUrl.trim();
        int authorityStart = url.indexOf("://");
        if (authorityStart < 0) return false;
        authorityStart += 3;

        int authorityEnd = url.length();
        for (char delimiter : new char[]{'/', '?', '#'}) {
            int at = url.indexOf(delimiter, authorityStart);
            if (at >= 0) authorityEnd = Math.min(authorityEnd, at);
        }
        String authority = url.substring(authorityStart, authorityEnd);
        int at = authority.lastIndexOf('@');
        if (at >= 0) authority = authority.substring(at + 1);

        String host;
        if (authority.startsWith("[")) {
            int close = authority.indexOf(']');
            if (close < 0) return false;
            host = authority.substring(1, close);
        } else {
            int colon = authority.indexOf(':');
            host = colon < 0 ? authority : authority.substring(0, colon);
        }
        if (host.isBlank()) return false;
        String h = host.toLowerCase(Locale.ROOT);
        return h.equals("localhost") || h.equals("127.0.0.1")
                || h.equals("::1") || h.equals("0:0:0:0:0:0:0:1");
    }
}
