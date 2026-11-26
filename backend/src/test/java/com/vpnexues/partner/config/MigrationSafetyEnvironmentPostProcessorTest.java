package com.vpnexues.partner.config;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.junit.jupiter.api.Test;
import org.springframework.boot.SpringApplication;
import org.springframework.mock.env.MockEnvironment;

import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class MigrationSafetyEnvironmentPostProcessorTest {

    private final MigrationSafetyEnvironmentPostProcessor guard = new MigrationSafetyEnvironmentPostProcessor();

    private static MockEnvironment env(String flyway, String target, String url) {
        return new MockEnvironment()
                .withProperty(MigrationSafetyEnvironmentPostProcessor.FLYWAY_ENABLED, flyway)
                .withProperty(MigrationSafetyEnvironmentPostProcessor.MIGRATION_TARGET, target)
                .withProperty(MigrationSafetyEnvironmentPostProcessor.DATASOURCE_URL, url);
    }

    @Test
    void flywayDisabledByDefaultAllowsAnyUrl() {
        MockEnvironment environment = env("false", "none",
                "jdbc:postgresql://db.abcdefghijklmnopqrst.supabase.co:5432/postgres");
        assertDoesNotThrow(() -> guard.postProcessEnvironment(environment, (SpringApplication) null));
    }

    @Test
    void remoteFlywayInitialisationFailsClosedBeforeBeansAreCreated() {
        MockEnvironment environment = env("true", "local",
                "jdbc:postgresql://db.abcdefghijklmnopqrst.supabase.co:5432/postgres");
        IllegalStateException error = assertThrows(IllegalStateException.class,
                () -> guard.postProcessEnvironment(environment, (SpringApplication) null));
        assertTrue(error.getMessage().contains("loopback"));
        assertFalse(error.getMessage().contains("supabase"));
    }

    @Test
    void flywayRequiresExplicitLocalTarget() {
        MockEnvironment environment = env("true", "none", "jdbc:postgresql://localhost:5432/vpnexues");
        IllegalStateException error = assertThrows(IllegalStateException.class,
                () -> guard.postProcessEnvironment(environment, (SpringApplication) null));
        assertTrue(error.getMessage().contains("app.migration-target=local"));
    }

    @Test
    void loopbackUrlsAreRecognisedAndRemoteUrlsAreRejected() {
        assertTrue(MigrationSafetyEnvironmentPostProcessor.isLoopback("jdbc:postgresql://localhost:5432/vpnexues"));
        assertTrue(MigrationSafetyEnvironmentPostProcessor.isLoopback("jdbc:postgresql://127.0.0.1:5432/vpnexues"));
        assertTrue(MigrationSafetyEnvironmentPostProcessor.isLoopback("jdbc:postgresql://[::1]:5432/vpnexues"));
        assertFalse(MigrationSafetyEnvironmentPostProcessor.isLoopback(
                "jdbc:postgresql://aws-0-ap-south-1.pooler.supabase.com:6543/postgres"));
        assertFalse(MigrationSafetyEnvironmentPostProcessor.isLoopback(null));
    }

    @Test
    void remotePostgresUrlWithCredentialsIsRejectedWithoutLeakingHost() {
        MockEnvironment environment = env("true", "local",
                "jdbc:postgresql://postgres:synthetic@db.example.invalid:5432/postgres");
        IllegalStateException error = assertThrows(IllegalStateException.class,
                () -> guard.postProcessEnvironment(environment, (SpringApplication) null));
        assertTrue(error.getMessage().contains("loopback"));
        assertFalse(error.getMessage().contains("example.invalid"));
        assertFalse(error.getMessage().contains("synthetic"));
    }

    @Test
    void realEmbeddedPostgresUrlIsAcceptedByTheGuard() throws Exception {
        System.setProperty("ot.epg.working-dir",
                Paths.get("target", "pgbin").toAbsolutePath().toString());
        EmbeddedPostgres pg = EmbeddedPostgres.builder().start();
        try {
            String url = pg.getJdbcUrl("postgres", "postgres");
            assertTrue(MigrationSafetyEnvironmentPostProcessor.isLoopback(url));
            MockEnvironment environment = env("true", "local", url);
            assertDoesNotThrow(() -> guard.postProcessEnvironment(environment, (SpringApplication) null));
        } finally {
            pg.close();
        }
    }
}
