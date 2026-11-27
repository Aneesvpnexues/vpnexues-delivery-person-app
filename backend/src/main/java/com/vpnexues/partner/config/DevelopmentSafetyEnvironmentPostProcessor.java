package com.vpnexues.partner.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;

import java.util.Arrays;

/**
 * Fail-closed guard for development-only behaviour.
 *
 * Demo seeding, OTP echo, trial/demo orders and bootstrap admin credentials
 * are restricted to the explicit {@code local} profile on a loopback datasource.
 * This runs during Environment preparation, before beans (including AuthService
 * and DataSeeder) exist, so a production-looking configuration cannot silently
 * enable mocked identities, leaked OTP codes or a default admin account.
 */
public class DevelopmentSafetyEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

    public static final String OTP_DEV_ECHO = "app.otp-dev-echo";
    public static final String DEMO_SEED = "app.demo-seed";
    public static final String TRIAL_MODE = "app.trial-mode";
    public static final String BOOTSTRAP_ADMIN_EMAIL = "app.bootstrap-admin-email";
    public static final String BOOTSTRAP_ADMIN_PASSWORD = "app.bootstrap-admin-password";

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 12;
    }

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        boolean local = Arrays.asList(environment.getActiveProfiles()).contains("local")
                && MigrationSafetyEnvironmentPostProcessor.isLoopback(
                        environment.getProperty(MigrationSafetyEnvironmentPostProcessor.DATASOURCE_URL, ""));
        if (local) return;

        rejectIfEnabled(environment, OTP_DEV_ECHO, "OTP dev echo");
        rejectIfEnabled(environment, DEMO_SEED, "Demo seed");
        rejectIfEnabled(environment, TRIAL_MODE, "Trial mode");
        rejectIfPresent(environment, BOOTSTRAP_ADMIN_EMAIL, "Bootstrap admin credentials");
        rejectIfPresent(environment, BOOTSTRAP_ADMIN_PASSWORD, "Bootstrap admin credentials");
    }

    private static void rejectIfEnabled(ConfigurableEnvironment environment, String key, String label) {
        if (environment.getProperty(key, Boolean.class, Boolean.FALSE)) {
            throw new IllegalStateException(
                    label + " requires the local profile and a loopback datasource; refusing to start");
        }
    }

    private static void rejectIfPresent(ConfigurableEnvironment environment, String key, String label) {
        String value = environment.getProperty(key, "");
        if (!value.isBlank()) {
            throw new IllegalStateException(
                    label + " require the local profile and a loopback datasource; refusing to start");
        }
    }
}
