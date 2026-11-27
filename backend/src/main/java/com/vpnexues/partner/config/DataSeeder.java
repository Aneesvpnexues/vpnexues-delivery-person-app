package com.vpnexues.partner.config;

import com.vpnexues.partner.common.Db;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.Map;

/** Creates the first ops-console owner and an optional demo partner for local testing. */
@Component
public class DataSeeder implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final Db db;
    private final PasswordEncoder encoder;
    private final Environment environment;

    @Value("${app.bootstrap-admin-email:}")
    private String adminEmail;
    @Value("${app.bootstrap-admin-password:}")
    private String adminPassword;
    @Value("${app.bootstrap-admin-name:Ops Owner}")
    private String adminName;
    @Value("${app.demo-seed:false}")
    private boolean demoSeed;

    public DataSeeder(Db db, PasswordEncoder encoder, Environment environment) {
        this.db = db;
        this.encoder = encoder;
        this.environment = environment;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            bootstrapAdmin();
            if (demoSeed && isLoopbackDevProfile()) seedDemoPartner();
        } catch (Exception e) {
            log.warn("Seeding skipped: {}", e.getMessage());
        }
    }

    /** Demo identities are only allowed in the explicit local profile on a loopback database. */
    private boolean isLoopbackDevProfile() {
        boolean local = Arrays.asList(environment.getActiveProfiles()).contains("local");
        String url = environment.getProperty(MigrationSafetyEnvironmentPostProcessor.DATASOURCE_URL, "");
        return local && MigrationSafetyEnvironmentPostProcessor.isLoopback(url);
    }

    private void bootstrapAdmin() {
        if (adminEmail == null || adminEmail.isBlank() || adminPassword == null || adminPassword.isBlank()) return;
        Map<String, Object> owner = db.one("SELECT id FROM admin_users WHERE role = 'owner' LIMIT 1");
        if (owner != null) return;
        db.update("INSERT INTO admin_users (email, full_name, password_hash, role) VALUES (?, ?, ?, 'owner') ON CONFLICT (email) DO NOTHING",
                adminEmail.trim().toLowerCase(), adminName, encoder.encode(adminPassword));
        log.info("Created ops owner account {}", adminEmail);
    }

    private void seedDemoPartner() {
        if (db.one("SELECT id FROM partners WHERE phone = '+919876543210'") != null) return;
        Map<String, Object> city = db.one("SELECT id FROM cities WHERE name = 'Chennai'");
        if (city == null) return;
        Map<String, Object> hub = db.one("SELECT id FROM hubs WHERE city_id = ? ORDER BY name LIMIT 1", city.get("id"));
        Map<String, Object> p = db.one(
                "INSERT INTO partners (partner_code, full_name, phone, phone_verified_at, email, password_hash, city_id, hub_id, " +
                        "vehicle_type, status, kyc_status, referral_code) VALUES " +
                        "('VPN-' || lpad(nextval('partner_code_seq')::text, 5, '0'), 'Demo Partner', '+919876543210', now(), " +
                        "'demo@vpnexues.test', ?, ?, ?, 'motorbike', 'active', 'verified', 'DEMO2026') RETURNING id",
                encoder.encode("Demo@12345"), city.get("id"), hub == null ? null : hub.get("id"));
        String pid = p.get("id").toString();
        db.update("INSERT INTO partner_settings (partner_id) VALUES (?) ON CONFLICT DO NOTHING", pid);
        db.update("INSERT INTO wallet_ledger (partner_id, type, amount_paise, description) VALUES (?, 'bonus', 25000, 'Welcome bonus (demo)')", pid);
        db.update("INSERT INTO payout_methods (partner_id, type, upi_vpa, is_primary, verification, verified_name) " +
                "VALUES (?, 'upi', 'demo@upi', true, 'verified', 'Demo Partner')", pid);
        db.update("INSERT INTO notifications (partner_id, category, title, body) VALUES (?, 'account', 'Welcome to VpnExues', " +
                "'Your partner account is ready. Complete a demo delivery to explore the app.')", pid);
        log.info("Seeded local demo partner with phone {}", "+919876543210");
    }
}
