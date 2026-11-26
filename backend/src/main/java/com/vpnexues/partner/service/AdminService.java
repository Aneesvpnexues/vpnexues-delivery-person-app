package com.vpnexues.partner.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Crypto;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.common.Json;
import com.vpnexues.partner.security.AuthPrincipal;
import com.vpnexues.partner.security.CurrentUser;
import com.vpnexues.partner.security.JwtService;
import com.vpnexues.partner.web.dto.Dtos;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class AdminService {
    private static final Set<String> PARTNER_STATUS = Set.of("onboarding", "active", "suspended", "deactivated");
    private static final Set<String> KYC_STATUS = Set.of("not_started", "in_review", "verified", "rejected");
    private static final Set<String> PAYOUT_STATUS = Set.of("requested", "processing", "paid", "failed");
    private static final Set<String> TICKET_STATUS = Set.of("open", "waiting_on_partner", "resolved", "closed");
    private static final Set<String> SOS_STATUS = Set.of("open", "acknowledged", "resolved");
    private static final Set<String> ROLES = Set.of("owner", "ops", "support");
    private static final SecureRandom RANDOM = new SecureRandom();

    private final Db db;
    private final CurrentUser current;
    private final JwtService jwt;
    private final PasswordEncoder encoder;
    private final ObjectMapper mapper;

    public AdminService(Db db, CurrentUser current, JwtService jwt, PasswordEncoder encoder, ObjectMapper mapper) {
        this.db = db;
        this.current = current;
        this.jwt = jwt;
        this.encoder = encoder;
        this.mapper = mapper;
    }

    private static String uuid(String id) {
        try {
            return java.util.UUID.fromString(id).toString();
        } catch (Exception e) {
            throw ApiException.notFound("Record");
        }
    }

    private void audit(String action, String entity, Object entityId, Map<String, Object> details) {
        String json;
        try {
            json = mapper.writeValueAsString(details == null ? Map.of() : details);
        } catch (Exception e) {
            json = "{}";
        }
        db.update("INSERT INTO admin_audit_log (admin_id, action, entity, entity_id, details) VALUES (?, ?, ?, ?, ?::jsonb)",
                current.admin().id(), action, entity, String.valueOf(entityId), json);
    }

    // ---------------- auth ----------------

    public Map<String, Object> login(Dtos.AdminLogin b) {
        Map<String, Object> a = db.one("SELECT id, email, full_name, password_hash, role, is_active FROM admin_users WHERE email = ?",
                b.email().trim().toLowerCase());
        if (a == null || !encoder.matches(b.password(), String.valueOf(a.get("passwordHash")))) {
            throw ApiException.unauthorized("Email or password is incorrect");
        }
        if (!Boolean.TRUE.equals(a.get("isActive"))) throw ApiException.forbidden("ACCOUNT_DISABLED", "This account is disabled");
        db.update("UPDATE admin_users SET last_login_at = now() WHERE id = ?", a.get("id"));
        String token = jwt.issueAdmin(a.get("id").toString(), String.valueOf(a.get("role")));
        return Json.map("accessToken", token, "tokenType", "Bearer", "expiresIn", 8 * 3600,
                "admin", Json.map("id", a.get("id"), "email", a.get("email"), "fullName", a.get("fullName"), "role", a.get("role")));
    }

    public Map<String, Object> me() {
        AuthPrincipal p = current.admin();
        Map<String, Object> a = db.one("SELECT id, email, full_name, role, last_login_at, created_at FROM admin_users WHERE id = ?", p.id());
        if (a == null) throw ApiException.unauthorized("Account no longer exists");
        return a;
    }

    public Map<String, Object> changePassword(Dtos.AdminPassword b) {
        AuthPrincipal p = current.admin();
        Map<String, Object> a = db.one("SELECT password_hash FROM admin_users WHERE id = ?", p.id());
        if (a == null || !encoder.matches(b.currentPassword(), String.valueOf(a.get("passwordHash")))) {
            throw ApiException.badRequest("WRONG_PASSWORD", "Current password is incorrect");
        }
        if (b.newPassword().length() < 10) throw ApiException.badRequest("WEAK_PASSWORD", "Use at least 10 characters");
        db.update("UPDATE admin_users SET password_hash = ? WHERE id = ?", encoder.encode(b.newPassword()), p.id());
        return Json.map("ok", true);
    }

    // ---------------- lookups & overview ----------------

    public Map<String, Object> lookups() {
        return Json.map(
                "cities", db.query("SELECT id, name, state, is_active FROM cities ORDER BY name"),
                "hubs", db.query("SELECT id, city_id, name, address, allowed_radii_km, recommended_radius_km, is_active FROM hubs ORDER BY name"),
                "partnerStatuses", PARTNER_STATUS,
                "kycStatuses", KYC_STATUS,
                "roles", ROLES);
    }

    public Map<String, Object> overview() {
        String today = "date_trunc('day', now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata'";
        return db.one(
                "SELECT " +
                        "(SELECT count(*) FROM partners WHERE status = 'active') AS active_partners, " +
                        "(SELECT count(*) FROM partners WHERE is_online AND status = 'active') AS online_partners, " +
                        "(SELECT count(*) FROM partners WHERE status = 'onboarding') AS onboarding_partners, " +
                        "(SELECT count(*) FROM partners WHERE kyc_status = 'in_review') AS kyc_pending, " +
                        "(SELECT count(*) FROM orders WHERE created_at >= " + today + ") AS orders_today, " +
                        "(SELECT count(*) FROM orders WHERE status IN ('created','assigned','accepted','at_pickup','picked_up','arrived')) AS open_orders, " +
                        "(SELECT count(*) FROM orders WHERE status = 'delivered' AND delivered_at >= " + today + ") AS delivered_today, " +
                        "(SELECT COALESCE(sum(amount_paise),0) FROM wallet_ledger WHERE type IN ('delivery_base','delivery_distance','tip') AND created_at >= " + today + ") AS earnings_today_paise, " +
                        "(SELECT count(*) FROM payouts WHERE status IN ('requested','processing')) AS pending_payouts, " +
                        "(SELECT COALESCE(sum(amount_paise),0) FROM payouts WHERE status IN ('requested','processing')) AS pending_payout_paise, " +
                        "(SELECT count(*) FROM support_tickets WHERE status IN ('open','waiting_on_partner')) AS open_tickets, " +
                        "(SELECT count(*) FROM sos_incidents WHERE status <> 'resolved') AS open_sos, " +
                        "(SELECT count(*) FROM hub_change_requests WHERE status = 'pending') AS pending_zone_requests");
    }

    // ---------------- partners ----------------

    public List<Map<String, Object>> partners(String search, String status, String kycStatus, Integer cityId, int limit) {
        if (limit < 1 || limit > 200) limit = 50;
        return db.query(
                "SELECT p.id, p.partner_code, p.full_name, p.phone, p.status, p.kyc_status, p.is_online, p.rating, p.created_at, " +
                        "c.name AS city_name, h.name AS hub_name FROM partners p JOIN cities c ON c.id = p.city_id " +
                        "LEFT JOIN hubs h ON h.id = p.hub_id WHERE " +
                        "(?::text IS NULL OR p.full_name ILIKE '%' || ? || '%' OR p.phone LIKE '%' || ? || '%' OR p.partner_code ILIKE '%' || ? || '%') " +
                        "AND (?::text IS NULL OR p.status = ?::partner_status) " +
                        "AND (?::text IS NULL OR p.kyc_status = ?::kyc_status) " +
                        "AND (?::int IS NULL OR p.city_id = ?) ORDER BY p.created_at DESC LIMIT ?",
                search, search, search, search, status, status, kycStatus, kycStatus, cityId, cityId, limit);
    }

    public Map<String, Object> partner(String id) {
        String pid = uuid(id);
        Map<String, Object> p = db.one(
                "SELECT p.id, p.partner_code, p.full_name, p.phone, p.email, p.status, p.kyc_status, p.is_online, p.last_online_at, " +
                        "p.vehicle_type, p.delivery_radius_km, p.language, p.date_of_birth, p.blood_group, p.address, p.rating, " +
                        "p.referral_code, p.created_at, c.id AS city_id, c.name AS city_name, h.id AS hub_id, h.name AS hub_name " +
                        "FROM partners p JOIN cities c ON c.id = p.city_id LEFT JOIN hubs h ON h.id = p.hub_id WHERE p.id = ?", pid);
        if (p == null) throw ApiException.notFound("Partner");
        return Json.map(
                "partner", p,
                "documents", db.query("SELECT id, type, status, number_masked, s3_keys, source, valid_until, rejection_reason, submitted_at, reviewed_at FROM partner_documents WHERE partner_id = ? ORDER BY type", pid),
                "vehicle", db.one("SELECT * FROM vehicles WHERE partner_id = ?", pid),
                "payoutMethods", db.query("SELECT id, type, account_holder_name, account_last4, ifsc, bank_name, upi_vpa, is_primary, is_backup, verification, verified_name, created_at FROM payout_methods WHERE partner_id = ? AND deleted_at IS NULL ORDER BY is_primary DESC", pid),
                "balancePaise", db.one("SELECT COALESCE(sum(amount_paise),0) AS paise FROM wallet_ledger WHERE partner_id = ?", pid),
                "recentOrders", db.query("SELECT id, order_code, status, customer_name, distance_km, delivered_at, created_at FROM orders WHERE partner_id = ? ORDER BY created_at DESC LIMIT 10", pid));
    }

    public Map<String, Object> patchPartner(String id, Dtos.PartnerPatch b) {
        String pid = uuid(id);
        Map<String, Object> p = db.one("SELECT id, status, kyc_status, hub_id, delivery_radius_km FROM partners WHERE id = ?", pid);
        if (p == null) throw ApiException.notFound("Partner");
        if (b.status() != null && !PARTNER_STATUS.contains(b.status())) {
            throw ApiException.badRequest("INVALID_STATUS", "Choose a valid partner status");
        }
        if (b.kycStatus() != null && !KYC_STATUS.contains(b.kycStatus())) {
            throw ApiException.badRequest("INVALID_KYC_STATUS", "Choose a valid KYC status");
        }
        if (b.deliveryRadiusKm() != null && (b.deliveryRadiusKm() < 1 || b.deliveryRadiusKm() > 20)) {
            throw ApiException.badRequest("INVALID_RADIUS", "Radius must be 1–20 km");
        }
        List<String> sets = new ArrayList<>();
        List<Object> args = new ArrayList<>();
        if (b.status() != null) { sets.add("status = ?::partner_status"); args.add(b.status()); }
        if (b.kycStatus() != null) { sets.add("kyc_status = ?::kyc_status"); args.add(b.kycStatus()); }
        if (b.hubId() != null) { sets.add("hub_id = ?"); args.add(uuid(b.hubId())); }
        if (b.deliveryRadiusKm() != null) { sets.add("delivery_radius_km = ?"); args.add(b.deliveryRadiusKm()); }
        if (sets.isEmpty()) throw ApiException.badRequest("NOTHING_TO_UPDATE", "Send at least one field to change");
        args.add(pid);
        db.update("UPDATE partners SET " + String.join(", ", sets) + " WHERE id = ?", args.toArray());
        audit("partner.update", "partner", pid, Json.map(
                "status", b.status(), "kycStatus", b.kycStatus(), "hubId", b.hubId(),
                "deliveryRadiusKm", b.deliveryRadiusKm(), "reason", b.reason()));
        return partner(pid);
    }

    // ---------------- documents ----------------

    public List<Map<String, Object>> documentQueue(String status) {
        String s = status == null ? "in_review" : status;
        return db.query(
                "SELECT d.id, d.type, d.status, d.number_masked, d.s3_keys, d.valid_until, d.submitted_at, d.rejection_reason, " +
                        "p.id AS partner_id, p.full_name, p.partner_code, p.phone FROM partner_documents d " +
                        "JOIN partners p ON p.id = d.partner_id WHERE d.status = ?::document_status ORDER BY d.submitted_at NULLS LAST LIMIT 100", s);
    }

    public Map<String, Object> reviewDocument(String id, Dtos.DocReview b) {
        String did = uuid(id);
        Map<String, Object> d = db.one("SELECT id, partner_id, type, status FROM partner_documents WHERE id = ? FOR UPDATE", did);
        if (d == null) throw ApiException.notFound("Document");
        if (!Set.of("in_review", "pending_upload", "rejected").contains(String.valueOf(d.get("status")))) {
            throw ApiException.conflict("ALREADY_REVIEWED", "This document has already been reviewed");
        }
        boolean approve = "approve".equalsIgnoreCase(b.decision()) || "verified".equalsIgnoreCase(b.decision());
        if (!approve && !"reject".equalsIgnoreCase(b.decision())) {
            throw ApiException.badRequest("INVALID_DECISION", "Decision must be approve or reject");
        }
        LocalDate validUntil = null;
        if (b.validUntil() != null && !b.validUntil().isBlank()) {
            try {
                validUntil = LocalDate.parse(b.validUntil());
            } catch (Exception e) {
                throw ApiException.badRequest("INVALID_DATE", "Use YYYY-MM-DD");
            }
        }
        String status = approve ? "verified" : "rejected";
        LocalDate valid = validUntil;
        String pid = d.get("partner_id").toString();
        String adminId = current.admin().id();
        db.inTx(() -> {
            db.update("UPDATE partner_documents SET status = ?::document_status, rejection_reason = ?, valid_until = COALESCE(?, valid_until), " +
                            "reviewed_at = now(), reviewed_by = ? WHERE id = ?",
                    status, approve ? null : b.reason(), valid, adminId, did);
            db.update("INSERT INTO document_events (document_id, status, note) VALUES (?, ?::document_status, ?)",
                    did, status, approve ? null : b.reason());
            if (approve) {
                db.update("UPDATE partners SET kyc_status = 'verified' WHERE id = ? AND NOT EXISTS (" +
                        "SELECT 1 FROM partner_documents WHERE partner_id = ? AND type = ANY(?::document_type[]) AND status <> 'verified')",
                        pid, pid, DocumentService.pgTextArray(DocumentService.REQUIRED_DOCS));
            }
        });
        audit(approve ? "document.approve" : "document.reject", "document", did,
                Json.map("partnerId", pid, "type", d.get("type"), "reason", b.reason()));
        return Json.map("id", did, "status", status);
    }

    // ---------------- orders ----------------

    public List<Map<String, Object>> orders(String status, String search, int limit) {
        if (limit < 1 || limit > 200) limit = 50;
        return db.query(
                "SELECT o.id, o.order_code, o.status, o.customer_name, o.drop_address, o.distance_km, " +
                        "(o.pay_base_paise + o.pay_distance_paise + o.tip_paise) AS earning_paise, o.created_at, o.delivered_at, " +
                        "h.name AS hub_name, p.full_name AS partner_name, p.partner_code FROM orders o " +
                        "JOIN hubs h ON h.id = o.hub_id LEFT JOIN partners p ON p.id = o.partner_id WHERE " +
                        "(?::text IS NULL OR o.status = ?::order_status) " +
                        "AND (?::text IS NULL OR o.order_code ILIKE '%' || ? || '%' OR o.customer_name ILIKE '%' || ? || '%') " +
                        "ORDER BY o.created_at DESC LIMIT ?",
                status, status, search, search, search, limit);
    }

    public Map<String, Object> createOrder(Dtos.OrderCreate b) {
        String hubId = uuid(b.hubId());
        Map<String, Object> hub = db.one("SELECT id FROM hubs WHERE id = ? AND is_active", hubId);
        if (hub == null) throw ApiException.badRequest("INVALID_HUB", "Choose an active hub");
        if (b.customerName() == null || b.customerPhone() == null || b.dropAddress() == null) {
            throw ApiException.badRequest("MISSING_FIELDS", "Customer name, phone and drop address are required");
        }
        long base = paise(b.payBasePaise(), "payBasePaise");
        long distancePay = paise(b.payDistancePaise(), "payDistancePaise");
        long tip = paise(b.tipPaise(), "tipPaise");
        Object scheduled = scheduledFor(b.scheduledFor());
        if (b.crates() != null) {
            for (Dtos.OrderCreate.Crate c : b.crates()) {
                if (c == null || c.label() == null || c.label().isBlank()
                        || c.weightGrams() == null || c.weightGrams() <= 0) {
                    throw ApiException.badRequest("INVALID_CRATE", "Every crate needs a label and a positive weight");
                }
            }
        }
        String partnerId = b.partnerId() == null ? null : uuid(b.partnerId());
        if (partnerId != null) {
            Map<String, Object> p = db.one("SELECT id, status FROM partners WHERE id = ?", partnerId);
            if (p == null) throw ApiException.notFound("Partner");
            if (!"active".equals(String.valueOf(p.get("status")))) {
                throw ApiException.badRequest("PARTNER_INACTIVE", "That partner is not active");
            }
        }
        String code = String.format("%04d", RANDOM.nextInt(10000));
        return db.inTx(() -> {
            Map<String, Object> o = db.one(
                    "INSERT INTO orders (order_code, hub_id, partner_id, status, customer_name, customer_phone, drop_address, drop_lat, drop_lng, " +
                            "drop_instructions, leave_at_door, delivery_code_hash, distance_km, eta_minutes, scheduled_for, " +
                            "pay_base_paise, pay_distance_paise, tip_paise, assigned_at) " +
                            "VALUES ('VPN-' || lpad(nextval('order_number_seq')::text, 5, '0'), ?, ?, " +
                            "CASE WHEN ?::uuid IS NULL THEN 'created'::order_status ELSE 'assigned'::order_status END, ?, ?, ?, " +
                            "COALESCE(?::double precision, 0), COALESCE(?::double precision, 0), ?, COALESCE(?::boolean, false), '', " +
                            "COALESCE(?::numeric, 0), ?::smallint, ?::timestamptz, ?, ?, ?, " +
                            "CASE WHEN ?::uuid IS NULL THEN NULL ELSE now() END) RETURNING id, order_code",
                    hubId, partnerId, partnerId, b.customerName(), b.customerPhone(), b.dropAddress(),
                    b.dropLat(), b.dropLng(), b.dropInstructions(), b.leaveAtDoor(), b.distanceKm(), b.etaMinutes(),
                    scheduled, base, distancePay, tip, partnerId);
            String oid = o.get("id").toString();
            db.update("UPDATE orders SET delivery_code_hash = ? WHERE id = ?", Crypto.sha256(oid + ":" + code), oid);
            if (b.crates() != null) {
                int pos = 1;
                for (Dtos.OrderCreate.Crate c : b.crates()) {
                    db.update("INSERT INTO order_crates (order_id, position, label, weight_grams, qr_code) VALUES (?, ?, ?, ?, ?)",
                            oid, pos, c.label(), c.weightGrams(), "VPN-CRATE-" + oid.substring(0, 8).toUpperCase() + "-" + pos);
                    pos++;
                }
            }
            String actor = "admin:" + current.admin().id();
            db.update("INSERT INTO order_events (order_id, status, actor, note) VALUES (?, 'created', ?, 'Created in ops console')",
                    oid, actor);
            if (partnerId != null) {
                db.update("INSERT INTO order_events (order_id, status, actor, note) VALUES (?, 'assigned', ?, 'Assigned in ops console')",
                        oid, actor);
            }
            audit("order.create", "order", oid, Json.map("hubId", hubId, "partnerId", partnerId));
            return Json.map("id", oid, "orderCode", o.get("orderCode"), "deliveryCode", code);
        });
    }

    private static long paise(Long value, String field) {
        long amount = value == null ? 0L : value;
        if (amount < 0 || amount > Integer.MAX_VALUE) {
            throw ApiException.badRequest("INVALID_AMOUNT", field + " must be between 0 and 2147483647 paise");
        }
        return amount;
    }

    private static Object scheduledFor(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return Timestamp.from(OffsetDateTime.parse(value).toInstant());
        } catch (Exception e) {
            throw ApiException.badRequest("INVALID_SCHEDULE", "Use an ISO date-time with an offset");
        }
    }

    public Map<String, Object> assignOrder(String id, Dtos.AssignBody b) {
        String oid = uuid(id);
        String partnerId = uuid(b.partnerId());
        return db.inTx(() -> {
            Map<String, Object> o = db.one("SELECT id, status FROM orders WHERE id = ? FOR UPDATE", oid);
            if (o == null) throw ApiException.notFound("Order");
            if (!Set.of("created", "assigned").contains(String.valueOf(o.get("status")))) {
                throw ApiException.conflict("BAD_ORDER_STATE", "Only unaccepted orders can be (re)assigned");
            }
            Map<String, Object> p = db.one("SELECT id, status, hub_id FROM partners WHERE id = ?", partnerId);
            if (p == null) throw ApiException.notFound("Partner");
            if (!"active".equals(String.valueOf(p.get("status")))) {
                throw ApiException.badRequest("PARTNER_INACTIVE", "That partner is not active");
            }
            db.update("UPDATE orders SET partner_id = ?, status = 'assigned', assigned_at = now() WHERE id = ?", partnerId, oid);
            db.update("INSERT INTO order_events (order_id, status, actor, note) VALUES (?, 'assigned', ?, 'Assigned in ops console')",
                    oid, "admin:" + current.admin().id());
            audit("order.assign", "order", oid, Json.map("partnerId", partnerId));
            return Json.map("id", oid, "status", "assigned", "partnerId", partnerId);
        });
    }

    public Map<String, Object> cancelOrder(String id, Dtos.CancelBody b) {
        String oid = uuid(id);
        return db.inTx(() -> {
            Map<String, Object> o = db.one("SELECT id, status FROM orders WHERE id = ? FOR UPDATE", oid);
            if (o == null) throw ApiException.notFound("Order");
            if (Set.of("delivered", "cancelled").contains(String.valueOf(o.get("status")))) {
                throw ApiException.conflict("BAD_ORDER_STATE", "Order is already " + o.get("status"));
            }
            db.update("UPDATE orders SET status = 'cancelled', cancel_reason = ?, cancelled_at = now() WHERE id = ?", b.reason(), oid);
            db.update("INSERT INTO order_events (order_id, status, actor, note) VALUES (?, 'cancelled', ?, ?)",
                    oid, "admin:" + current.admin().id(), b.reason());
            audit("order.cancel", "order", oid, Json.map("reason", b.reason()));
            return Json.map("id", oid, "status", "cancelled");
        });
    }

    // ---------------- money ----------------

    public List<Map<String, Object>> payouts(String status) {
        return db.query(
                "SELECT p.id, p.kind, p.amount_paise, p.fee_paise, p.status, p.utr, p.failure_reason, p.requested_at, p.processed_at, " +
                        "pt.id AS partner_id, pt.full_name, pt.partner_code, pt.phone, m.type AS method_type, m.account_last4, m.upi_vpa " +
                        "FROM payouts p JOIN partners pt ON pt.id = p.partner_id JOIN payout_methods m ON m.id = p.payout_method_id " +
                        "WHERE (?::text IS NULL OR p.status = ?::payout_status) ORDER BY p.requested_at DESC LIMIT 100",
                status, status);
    }

    public Map<String, Object> payoutStatus(String id, Dtos.PayoutStatusBody b) {
        if (!PAYOUT_STATUS.contains(b.status())) throw ApiException.badRequest("INVALID_STATUS", "Choose a valid payout status");
        String pid = uuid(id);
        Map<String, Object> p = db.one("SELECT id, status, partner_id FROM payouts WHERE id = ? FOR UPDATE", pid);
        if (p == null) throw ApiException.notFound("Payout");
        if ("paid".equals(b.status()) && (b.utr() == null || b.utr().isBlank())) {
            throw ApiException.badRequest("UTR_REQUIRED", "Enter the bank UTR before marking as paid");
        }
        db.update("UPDATE payouts SET status = ?::payout_status, utr = COALESCE(?, utr), failure_reason = ?, " +
                        "processed_at = CASE WHEN ? IN ('paid','failed') THEN now() ELSE processed_at END WHERE id = ?",
                b.status(), b.utr(), b.failureReason(), b.status(), pid);
        audit("payout.status", "payout", pid, Json.map("status", b.status(), "utr", b.utr()));
        return Json.map("id", pid, "status", b.status());
    }

    public List<Map<String, Object>> payoutMethodQueue(String verification) {
        String v = verification == null ? "pending" : verification;
        return db.query(
                "SELECT m.id, m.type, m.account_holder_name, m.account_last4, m.ifsc, m.bank_name, m.upi_vpa, m.verification, " +
                        "m.created_at, p.id AS partner_id, p.full_name, p.partner_code, p.phone FROM payout_methods m " +
                        "JOIN partners p ON p.id = m.partner_id WHERE m.verification = ?::verification_status AND m.deleted_at IS NULL " +
                        "ORDER BY m.created_at LIMIT 100", v);
    }

    public Map<String, Object> verifyPayoutMethod(String id, Dtos.VerificationBody b) {
        if (!Set.of("verified", "failed", "pending").contains(b.verification())) {
            throw ApiException.badRequest("INVALID_STATUS", "Choose verified, failed or pending");
        }
        String mid = uuid(id);
        Map<String, Object> m = db.one("SELECT id FROM payout_methods WHERE id = ? AND deleted_at IS NULL", mid);
        if (m == null) throw ApiException.notFound("Payout method");
        db.update("UPDATE payout_methods SET verification = ?::verification_status, verified_name = ? WHERE id = ?",
                b.verification(), b.verifiedName(), mid);
        audit("payout_method.verify", "payout_method", mid, Json.map("verification", b.verification(), "verifiedName", b.verifiedName()));
        return Json.map("id", mid, "verification", b.verification());
    }

    // ---------------- support & safety ----------------

    public List<Map<String, Object>> tickets(String status) {
        return db.query(
                "SELECT t.id, t.topic, t.status, t.created_at, t.updated_at, o.order_code, p.id AS partner_id, p.full_name, " +
                        "p.partner_code, p.phone, (SELECT count(*) FROM support_messages m WHERE m.ticket_id = t.id) AS message_count " +
                        "FROM support_tickets t JOIN partners p ON p.id = t.partner_id LEFT JOIN orders o ON o.id = t.order_id " +
                        "WHERE (?::text IS NULL OR t.status = ?::ticket_status) ORDER BY t.updated_at DESC LIMIT 100",
                status, status);
    }

    public Map<String, Object> ticket(String id) {
        String tid = uuid(id);
        Map<String, Object> t = db.one(
                "SELECT t.id, t.topic, t.status, t.created_at, t.updated_at, o.order_code, p.id AS partner_id, p.full_name, " +
                        "p.partner_code, p.phone FROM support_tickets t JOIN partners p ON p.id = t.partner_id " +
                        "LEFT JOIN orders o ON o.id = t.order_id WHERE t.id = ?", tid);
        if (t == null) throw ApiException.notFound("Ticket");
        return Json.map("ticket", t,
                "messages", db.query("SELECT id, sender, body, created_at FROM support_messages WHERE ticket_id = ? ORDER BY created_at", tid));
    }

    public Map<String, Object> ticketStatus(String id, Dtos.TicketStatusBody b) {
        if (!TICKET_STATUS.contains(b.status())) throw ApiException.badRequest("INVALID_STATUS", "Choose a valid ticket status");
        String tid = uuid(id);
        int n = db.update("UPDATE support_tickets SET status = ?::ticket_status WHERE id = ?", b.status(), tid);
        if (n == 0) throw ApiException.notFound("Ticket");
        audit("ticket.status", "ticket", tid, Json.map("status", b.status()));
        return Json.map("id", tid, "status", b.status());
    }

    public Map<String, Object> replyTicket(String id, Dtos.MessageBody b) {
        String tid = uuid(id);
        Map<String, Object> t = db.one("SELECT id, status FROM support_tickets WHERE id = ? FOR UPDATE", tid);
        if (t == null) throw ApiException.notFound("Ticket");
        Map<String, Object> m = db.one("INSERT INTO support_messages (ticket_id, sender, body) VALUES (?, 'agent', ?) " +
                "RETURNING id, sender, body, created_at", tid, b.message());
        if (!"closed".equals(String.valueOf(t.get("status")))) {
            db.update("UPDATE support_tickets SET status = 'waiting_on_partner' WHERE id = ?", tid);
        }
        return m;
    }

    public List<Map<String, Object>> sos(String status) {
        return db.query(
                "SELECT s.id, s.kind, s.status, s.lat, s.lng, s.details, s.created_at, s.acknowledged_at, s.resolved_at, " +
                        "p.id AS partner_id, p.full_name, p.partner_code, p.phone, o.order_code FROM sos_incidents s " +
                        "JOIN partners p ON p.id = s.partner_id LEFT JOIN orders o ON o.id = s.order_id " +
                        "WHERE (?::text IS NULL OR s.status = ?::sos_status) ORDER BY s.created_at DESC LIMIT 100",
                status, status);
    }

    public Map<String, Object> sosStatus(String id, Dtos.SosStatusBody b) {
        if (!SOS_STATUS.contains(b.status())) throw ApiException.badRequest("INVALID_STATUS", "Choose open, acknowledged or resolved");
        String sid = uuid(id);
        int n = db.update("UPDATE sos_incidents SET status = ?::sos_status, " +
                        "acknowledged_at = CASE WHEN ? = 'acknowledged' THEN COALESCE(acknowledged_at, now()) ELSE acknowledged_at END, " +
                        "resolved_at = CASE WHEN ? = 'resolved' THEN now() ELSE resolved_at END, " +
                        "details = COALESCE(?, details) WHERE id = ?",
                b.status(), b.status(), b.status(), b.note(), sid);
        if (n == 0) throw ApiException.notFound("SOS incident");
        audit("sos.status", "sos", sid, Json.map("status", b.status(), "note", b.note()));
        return Json.map("id", sid, "status", b.status());
    }

    // ---------------- zone change requests ----------------

    public List<Map<String, Object>> zoneRequests(String status) {
        String s = status == null ? "pending" : status;
        return db.query(
                "SELECT r.id, r.status, r.created_at, r.resolved_at, p.id AS partner_id, p.full_name, p.partner_code, " +
                        "c.id AS to_city_id, c.name AS to_city_name, h.id AS to_hub_id, h.name AS to_hub_name " +
                        "FROM hub_change_requests r JOIN partners p ON p.id = r.partner_id JOIN cities c ON c.id = r.to_city_id " +
                        "LEFT JOIN hubs h ON h.id = r.to_hub_id WHERE r.status = ? ORDER BY r.created_at", s);
    }

    public Map<String, Object> decideZoneRequest(String id, Dtos.ZoneDecision b) {
        boolean approve = "approve".equalsIgnoreCase(b.decision());
        if (!approve && !"reject".equalsIgnoreCase(b.decision())) {
            throw ApiException.badRequest("INVALID_DECISION", "Decision must be approve or reject");
        }
        String rid = uuid(id);
        Map<String, Object> r = db.one("SELECT id, partner_id, to_city_id, to_hub_id, status FROM hub_change_requests WHERE id = ? FOR UPDATE", rid);
        if (r == null) throw ApiException.notFound("Zone request");
        if (!"pending".equals(String.valueOf(r.get("status")))) {
            throw ApiException.conflict("ALREADY_RESOLVED", "This request has already been handled");
        }
        String hubId = b.hubId() != null ? uuid(b.hubId()) : (r.get("to_hub_id") == null ? null : r.get("to_hub_id").toString());
        if (approve && hubId == null) {
            throw ApiException.badRequest("HUB_REQUIRED", "Pick a hub before approving");
        }
        db.inTx(() -> {
            db.update("UPDATE hub_change_requests SET status = ?, resolved_at = now(), to_hub_id = ? WHERE id = ?",
                    approve ? "approved" : "rejected", hubId, rid);
            if (approve) {
                db.update("UPDATE partners SET city_id = ?, hub_id = ? WHERE id = ?", r.get("to_city_id"), hubId, r.get("partner_id"));
            }
        });
        audit("zone." + (approve ? "approve" : "reject"), "zone_request", rid, Json.map("hubId", hubId, "note", b.note()));
        return Json.map("id", rid, "status", approve ? "approved" : "rejected");
    }

    // ---------------- audit & staff ----------------

    public List<Map<String, Object>> auditLog(String entity, String entityId, int limit) {
        if (limit < 1 || limit > 500) limit = 100;
        return db.query(
                "SELECT a.id, a.action, a.entity, a.entity_id, a.details, a.created_at, u.email AS admin_email, u.full_name AS admin_name " +
                        "FROM admin_audit_log a LEFT JOIN admin_users u ON u.id = a.admin_id WHERE " +
                        "(?::text IS NULL OR a.entity = ?) AND (?::text IS NULL OR a.entity_id = ?) ORDER BY a.id DESC LIMIT ?",
                entity, entity, entityId, entityId, limit);
    }

    public List<Map<String, Object>> staff() {
        return db.query("SELECT id, email, full_name, role, is_active, last_login_at, created_at FROM admin_users ORDER BY created_at");
    }

    public Map<String, Object> createStaff(Dtos.StaffCreate b) {
        if (!ROLES.contains(b.role())) throw ApiException.badRequest("INVALID_ROLE", "Choose owner, ops or support");
        if (b.password().length() < 10) throw ApiException.badRequest("WEAK_PASSWORD", "Use at least 10 characters");
        String email = b.email().trim().toLowerCase();
        if (db.one("SELECT id FROM admin_users WHERE email = ?", email) != null) {
            throw ApiException.conflict("EMAIL_IN_USE", "An account with this email already exists");
        }
        Map<String, Object> a = db.one("INSERT INTO admin_users (email, full_name, password_hash, role) VALUES (?, ?, ?, ?) " +
                        "RETURNING id, email, full_name, role, is_active, created_at",
                email, b.fullName().trim(), encoder.encode(b.password()), b.role());
        audit("staff.create", "admin_user", a.get("id"), Json.map("email", email, "role", b.role()));
        return a;
    }

    public Map<String, Object> patchStaff(String id, Dtos.StaffPatch b) {
        String uid = uuid(id);
        if (b.role() != null && !ROLES.contains(b.role())) {
            throw ApiException.badRequest("INVALID_ROLE", "Choose owner, ops or support");
        }
        if (Boolean.FALSE.equals(b.isActive()) && uid.equals(current.admin().id())) {
            throw ApiException.badRequest("CANNOT_DISABLE_SELF", "You cannot disable your own account");
        }
        Map<String, Object> a = db.one("UPDATE admin_users SET role = COALESCE(?, role), is_active = COALESCE(?, is_active) " +
                "WHERE id = ? RETURNING id, email, full_name, role, is_active", b.role(), b.isActive(), uid);
        if (a == null) throw ApiException.notFound("Staff account");
        audit("staff.update", "admin_user", uid, Json.map("role", b.role(), "isActive", b.isActive()));
        return a;
    }
}
