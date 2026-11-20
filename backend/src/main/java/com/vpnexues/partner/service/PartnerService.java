package com.vpnexues.partner.service;

import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.common.Json;
import com.vpnexues.partner.security.CurrentUser;
import com.vpnexues.partner.web.dto.Dtos;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class PartnerService {
    private static final Set<String> LANGUAGES = Set.of("en", "ta", "hi", "ml", "te", "kn");
    private static final Set<String> BLOOD_GROUPS = Set.of("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-");
    private static final Set<String> NAV_APPS = Set.of("google_maps", "in_app");

    private final Db db;
    private final CurrentUser current;

    public PartnerService(Db db, CurrentUser current) {
        this.db = db;
        this.current = current;
    }

    public Map<String, Object> me() {
        Map<String, Object> p = db.one(
                "SELECT p.id, p.partner_code, p.full_name, p.phone, p.email, p.status, p.kyc_status, p.is_online, p.language, " +
                        "p.date_of_birth, p.blood_group, p.address, p.rating, p.referral_code, p.vehicle_type, p.delivery_radius_km, " +
                        "p.created_at AS partner_since, " +
                        "json_build_object('id', c.id, 'name', c.name) AS city, " +
                        "CASE WHEN h.id IS NULL THEN NULL ELSE json_build_object('id', h.id, 'name', h.name) END AS hub, " +
                        "(SELECT count(*) FROM orders o WHERE o.partner_id = p.id AND o.status = 'delivered') AS deliveries " +
                        "FROM partners p JOIN cities c ON c.id = p.city_id LEFT JOIN hubs h ON h.id = p.hub_id WHERE p.id = ?",
                current.partnerId());
        if (p == null) throw ApiException.notFound("Partner");
        return p;
    }

    public Map<String, Object> updateMe(Dtos.UpdateMe b) {
        List<String> sets = new ArrayList<>();
        List<Object> args = new ArrayList<>();
        if (b.email() != null) {
            String email = b.email().trim();
            if (!email.isEmpty() && !email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
                throw ApiException.badRequest("INVALID_EMAIL", "Enter a valid email address");
            }
            sets.add("email = ?");
            args.add(email.isEmpty() ? null : email);
        }
        if (b.dateOfBirth() != null) {
            sets.add("date_of_birth = ?");
            args.add(b.dateOfBirth().isBlank() ? null : java.time.LocalDate.parse(b.dateOfBirth()));
        }
        if (b.bloodGroup() != null) {
            if (!b.bloodGroup().isBlank() && !BLOOD_GROUPS.contains(b.bloodGroup())) {
                throw ApiException.badRequest("INVALID_BLOOD_GROUP", "Choose a valid blood group");
            }
            sets.add("blood_group = ?");
            args.add(b.bloodGroup().isBlank() ? null : b.bloodGroup());
        }
        if (b.address() != null) {
            if (b.address().length() > 300) throw ApiException.badRequest("ADDRESS_TOO_LONG", "Address is too long");
            sets.add("address = ?");
            args.add(b.address().isBlank() ? null : b.address());
        }
        if (b.language() != null) {
            if (!LANGUAGES.contains(b.language())) throw ApiException.badRequest("INVALID_LANGUAGE", "Unsupported language");
            sets.add("language = ?::app_language");
            args.add(b.language());
        }
        if (sets.isEmpty()) return Json.map("ok", true);
        args.add(current.partnerId());
        db.update("UPDATE partners SET " + String.join(", ", sets) + " WHERE id = ?", args.toArray());
        return Json.map("ok", true);
    }

    public Map<String, Object> setOnline(Dtos.OnlineBody b) {
        boolean online = Boolean.TRUE.equals(b.online());
        Map<String, Object> p = db.one("SELECT status FROM partners WHERE id = ?", current.partnerId());
        if (p == null) throw ApiException.notFound("Partner");
        if (online && !"active".equals(String.valueOf(p.get("status")))) {
            throw ApiException.forbidden("NOT_ACTIVE", "Finish verification before going online");
        }
        db.update("UPDATE partners SET is_online = ?, last_online_at = CASE WHEN ? THEN now() ELSE last_online_at END WHERE id = ?",
                online, online, current.partnerId());
        return Json.map("online", online);
    }

    public Map<String, Object> settings() {
        Map<String, Object> s = db.one("SELECT * FROM partner_settings WHERE partner_id = ?", current.partnerId());
        return s == null ? Map.of() : s;
    }

    public Map<String, Object> patchSettings(Dtos.SettingsBody b) {
        List<String> sets = new ArrayList<>();
        List<Object> args = new ArrayList<>();
        if (b.autoAcceptNearby() != null) { sets.add("auto_accept_nearby = ?"); args.add(b.autoAcceptNearby()); }
        if (b.navigationApp() != null) {
            if (!NAV_APPS.contains(b.navigationApp())) throw ApiException.badRequest("INVALID_NAV_APP", "Choose a valid navigation app");
            sets.add("navigation_app = ?");
            args.add(b.navigationApp());
        }
        if (b.newOrderSound() != null) { sets.add("new_order_sound = ?"); args.add(b.newOrderSound()); }
        if (b.payoutAlerts() != null) { sets.add("payout_alerts = ?"); args.add(b.payoutAlerts()); }
        if (b.offersCampaigns() != null) { sets.add("offers_campaigns = ?"); args.add(b.offersCampaigns()); }
        if (b.darkModeAtNight() != null) { sets.add("dark_mode_at_night = ?"); args.add(b.darkModeAtNight()); }
        if (b.dataSaver() != null) { sets.add("data_saver = ?"); args.add(b.dataSaver()); }
        if (b.voiceNavigation() != null) { sets.add("voice_navigation = ?"); args.add(b.voiceNavigation()); }
        if (b.fingerprintUnlock() != null) { sets.add("fingerprint_unlock = ?"); args.add(b.fingerprintUnlock()); }
        if (!sets.isEmpty()) {
            args.add(current.partnerId());
            db.update("UPDATE partner_settings SET " + String.join(", ", sets) + " WHERE partner_id = ?", args.toArray());
        }
        return settings();
    }

    public Map<String, Object> zone() {
        Map<String, Object> z = db.one(
                "SELECT p.delivery_radius_km, h.id AS hub_id, h.name AS hub_name, h.lat, h.lng, h.allowed_radii_km, " +
                        "h.recommended_radius_km, h.areas_by_radius, c.name AS city " +
                        "FROM partners p JOIN cities c ON c.id = p.city_id LEFT JOIN hubs h ON h.id = p.hub_id WHERE p.id = ?",
                current.partnerId());
        if (z == null) throw ApiException.notFound("Partner");
        return z;
    }

    public Map<String, Object> setRadius(Dtos.RadiusBody b) {
        if (b.radiusKm() == null || b.radiusKm() <= 0) {
            throw ApiException.badRequest("INVALID_RADIUS", "Choose a valid delivery radius");
        }
        int n = db.update(
                "UPDATE partners p SET delivery_radius_km = ? FROM hubs h " +
                        "WHERE p.id = ? AND h.id = p.hub_id AND ?::int = ANY(h.allowed_radii_km) RETURNING p.delivery_radius_km",
                b.radiusKm(), current.partnerId(), b.radiusKm());
        if (n == 0) throw ApiException.badRequest("RADIUS_NOT_ALLOWED", "This radius is not available for your hub");
        return Json.map("radiusKm", b.radiusKm());
    }

    public Map<String, Object> changeRequest(Dtos.ChangeRequest b) {
        if (db.one("SELECT 1 FROM cities WHERE id = ? AND is_active", b.cityId()) == null) {
            throw ApiException.badRequest("CITY_UNAVAILABLE", "We are not in this city yet");
        }
        if (b.hubId() != null && db.one("SELECT 1 FROM hubs WHERE id = ? AND city_id = ? AND is_active", b.hubId(), b.cityId()) == null) {
            throw ApiException.badRequest("HUB_UNAVAILABLE", "That hub is not available in this city");
        }
        return db.inTx(() -> {
            db.update("UPDATE hub_change_requests SET status = 'cancelled', resolved_at = now() WHERE partner_id = ? AND status = 'pending'",
                    current.partnerId());
            return db.one("INSERT INTO hub_change_requests (partner_id, to_city_id, to_hub_id) VALUES (?, ?, ?) RETURNING id, status, created_at",
                    current.partnerId(), b.cityId(), b.hubId());
        });
    }

    public Map<String, Object> registerDevice(Dtos.DeviceBody b) {
        if (!Set.of("android", "ios", "web").contains(b.platform())) {
            throw ApiException.badRequest("INVALID_PLATFORM", "Unsupported platform");
        }
        db.update("INSERT INTO device_tokens (partner_id, platform, token) VALUES (?, ?, ?) " +
                        "ON CONFLICT (token) DO UPDATE SET partner_id = EXCLUDED.partner_id, platform = EXCLUDED.platform",
                current.partnerId(), b.platform(), b.token());
        return Json.map("ok", true);
    }

    public List<Map<String, Object>> cities() {
        return db.query("SELECT id, name, state FROM cities WHERE is_active ORDER BY name");
    }

    public List<Map<String, Object>> hubs(int cityId) {
        return db.query("SELECT id, name, address, lat, lng, allowed_radii_km FROM hubs WHERE city_id = ? AND is_active ORDER BY name", cityId);
    }
}
