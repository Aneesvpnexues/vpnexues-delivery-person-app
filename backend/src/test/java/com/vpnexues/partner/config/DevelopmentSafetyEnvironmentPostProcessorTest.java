package com.vpnexues.partner.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.SpringApplication;
import org.springframework.mock.env.MockEnvironment;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DevelopmentSafetyEnvironmentPostProcessorTest {

    private final DevelopmentSafetyEnvironmentPostProcessor guard =
            new DevelopmentSafetyEnvironmentPostProcessor();

    private static MockEnvironment env(String profile, String url) {
        MockEnvironment environment = new MockEnvironment()
                .withProperty(MigrationSafetyEnvironmentPostProcessor.DATASOURCE_URL, url);
        if (profile != null) environment.setActiveProfiles(profile);
        return environment;
    }

    @Test
    void devFlagsAreAllowedOnlyOnExplicitLocalLoopback() {
        MockEnvironment environment = env("local", "jdbc:postgresql://localhost:5432/vpnexues")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.OTP_DEV_ECHO, "true")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.DEMO_SEED, "true")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.TRIAL_MODE, "true")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.BOOTSTRAP_ADMIN_EMAIL, "owner@vpnexues.local")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.BOOTSTRAP_ADMIN_PASSWORD, "Owner@12345");
        assertDoesNotThrow(() -> guard.postProcessEnvironment(environment, (SpringApplication) null));
    }

    @Test
    void devFlagsFailClosedWithoutLocalProfile() {
        MockEnvironment environment = env(null, "jdbc:postgresql://localhost:5432/vpnexues")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.TRIAL_MODE, "true");
        IllegalStateException error = assertThrows(IllegalStateException.class,
                () -> guard.postProcessEnvironment(environment, (SpringApplication) null));
        assertTrue(error.getMessage().contains("Trial mode"));
    }

    @Test
    void devFlagsFailClosedOnARemoteDatasourceEvenWithLocalProfile() {
        MockEnvironment environment = env("local", "jdbc:postgresql://db.example.supabase.co:5432/postgres")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.DEMO_SEED, "true");
        IllegalStateException error = assertThrows(IllegalStateException.class,
                () -> guard.postProcessEnvironment(environment, (SpringApplication) null));
        assertTrue(error.getMessage().contains("Demo seed"));
    }

    @Test
    void bootstrapAdminCredentialsFailClosedOutsideLocalLoopback() {
        MockEnvironment environment = env(null, "jdbc:postgresql://localhost:5432/vpnexues")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.BOOTSTRAP_ADMIN_EMAIL, "owner@example.com")
                .withProperty(DevelopmentSafetyEnvironmentPostProcessor.BOOTSTRAP_ADMIN_PASSWORD, "Example@12345");
        IllegalStateException error = assertThrows(IllegalStateException.class,
                () -> guard.postProcessEnvironment(environment, (SpringApplication) null));
        assertTrue(error.getMessage().contains("Bootstrap admin credentials"));
    }

    @Test
    void disabledDefaultsAllowStartupAnywhere() {
        MockEnvironment environment = env(null, "jdbc:postgresql://db.example.supabase.co:5432/postgres");
        assertDoesNotThrow(() -> guard.postProcessEnvironment(environment, (SpringApplication) null));
    }
}
