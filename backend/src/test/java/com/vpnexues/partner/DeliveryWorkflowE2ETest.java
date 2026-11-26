package com.vpnexues.partner;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Full delivery lifecycle against a disposable embedded PostgreSQL database.
 *
 * Every state-changing request is local-only: the datasource is replaced by an EmbeddedPostgres
 * instance and is torn down after the test. No remote Supabase data is read or written.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
                "spring.flyway.enabled=true",
                "app.migration-target=local",
                "app.demo-seed=true",
                "app.trial-mode=true",
                "app.otp-dev-echo=true",
                "app.bootstrap-admin-email=owner@vpnexues.local",
                "app.bootstrap-admin-password=Owner@12345"
        })
@ActiveProfiles("local")
class DeliveryWorkflowE2ETest {

    static EmbeddedPostgres pg;
    static final StringBuilder REPORT = new StringBuilder();

    static {
        try {
            System.setProperty("ot.epg.working-dir",
                    java.nio.file.Paths.get("target", "pgbin").toAbsolutePath().toString());
            pg = EmbeddedPostgres.builder().start();
        } catch (Exception e) {
            throw new RuntimeException("Could not start embedded PostgreSQL", e);
        }
    }

    @AfterAll
    static void stopPostgres() throws Exception {
        if (pg != null) pg.close();
    }

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", () -> pg.getJdbcUrl("postgres", "postgres"));
        r.add("spring.datasource.username", () -> "postgres");
        r.add("spring.datasource.password", () -> "");
    }

    @Autowired TestRestTemplate rest;
    @Autowired JdbcTemplate jdbc;
    @Autowired com.vpnexues.partner.security.JwtService jwtService;

    private void record(String label, String method, String path, int expected,
                        ResponseEntity<?> response, String detail) {
        int actual = response.getStatusCode().value();
        REPORT.append(label).append('|')
                .append(method).append(' ').append(path).append('|')
                .append("expected=").append(expected).append('|')
                .append("actual=").append(actual).append('|')
                .append(actual == expected ? "PASS" : "FAIL").append('|')
                .append(detail == null ? "" : detail.replace('\n', ' ').replace('|', '/'))
                .append('\n');
        assertEquals(expected, actual, label);
    }

    private void check(String label, boolean condition, String detail) {
        REPORT.append(label).append('|')
                .append("ASSERT|expected=true|actual=").append(condition).append('|')
                .append(condition ? "PASS" : "FAIL").append('|')
                .append(detail == null ? "" : detail.replace('\n', ' ').replace('|', '/'))
                .append('\n');
        assertTrue(condition, label);
    }

    private HttpHeaders headers(String token) {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        if (token != null) h.setBearerAuth(token);
        return h;
    }

    private ResponseEntity<Map> get(String path, String token) {
        return rest.exchange(path, HttpMethod.GET, new HttpEntity<>(headers(token)), Map.class);
    }

    @SuppressWarnings("rawtypes")
    private ResponseEntity<List> getList(String path, String token) {
        return rest.exchange(path, HttpMethod.GET, new HttpEntity<>(headers(token)), List.class);
    }

    private ResponseEntity<Map> post(String path, Object body, String token) {
        return rest.exchange(path, HttpMethod.POST, new HttpEntity<>(body, headers(token)), Map.class);
    }

    private ResponseEntity<Map> patch(String path, Object body, String token) {
        return rest.exchange(path, HttpMethod.PATCH, new HttpEntity<>(body, headers(token)), Map.class);
    }

    @SuppressWarnings("unchecked")
    private static String errorCode(ResponseEntity<?> r) {
        Object body = r.getBody();
        if (body instanceof Map<?, ?> map) {
            Object error = map.get("error");
            if (error instanceof Map<?, ?> em) return String.valueOf(em.get("code"));
        }
        return "<none>";
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> map(Object value) {
        return value instanceof Map<?, ?> m ? (Map<String, Object>) m : Map.of();
    }

    private static long num(Object value) {
        return value instanceof Number n ? n.longValue() : -1L;
    }

    private static String token(Map<String, Object> body) {
        Object value = body.get("accessToken");
        return value == null ? null : String.valueOf(value);
    }

    @Test
    void fullDeliveryWorkflow() throws Exception {
        REPORT.setLength(0);
        REPORT.append("LOCAL_DELIVERY_WORKFLOW_REPORT\n");
        try {
            // Local Flyway verification on the embedded disposable database.
            int applied = jdbc.queryForObject("SELECT count(*) FROM flyway_schema_history WHERE success = true", Integer.class);
            REPORT.append("LOCAL_FLYWAY_V1_V11|ASSERT|expected=11|actual=").append(applied)
                    .append('|').append(applied == 11 ? "PASS" : "FAIL")
                    .append("|appliedSuccessRows=").append(applied).append('\n');
            check("LOCAL_FLYWAY_VERSIONS", applied == 11, "V1-V11 applied successfully to embedded DB");

            // Health and authentication.
            ResponseEntity<Map> ready = get("/health/ready", null);
            record("HEALTH_READY", "GET", "/health/ready", 200, ready,
                    "status=" + ready.getBody().get("status") + ",database=" + ready.getBody().get("database")
                            + ",trial=" + ready.getBody().get("trial"));
            check("HEALTH_STATUS", "ready".equals(String.valueOf(ready.getBody().get("status"))), "local status ready");
            check("HEALTH_DATABASE", "up".equals(String.valueOf(ready.getBody().get("database"))), "local database up");

            ResponseEntity<Map> adminLogin = post("/v1/admin/auth/login",
                    Map.of("email", "owner@vpnexues.local", "password", "Owner@12345"), null);
            record("ADMIN_LOGIN", "POST", "/v1/admin/auth/login", 200, adminLogin, "accessTokenPresent=" + (token(adminLogin.getBody()) != null));
            String adminToken = token(adminLogin.getBody());
            assertNotNull(adminToken, "admin token");
            check("ADMIN_ROLE_OWNER", "owner".equals(String.valueOf(map(adminLogin.getBody().get("admin")).get("role"))), "owner role issued");

            ResponseEntity<Map> adminMe = get("/v1/admin/me", adminToken);
            record("ADMIN_ME", "GET", "/v1/admin/me", 200, adminMe, "email=owner@vpnexues.local");

            ResponseEntity<Map> partnerLogin = post("/v1/auth/login",
                    Map.of("phone", "9876543210", "password", "Demo@12345"), null);
            record("PARTNER_LOGIN", "POST", "/v1/auth/login", 200, partnerLogin, "accessTokenPresent=" + (token(partnerLogin.getBody()) != null));
            String partnerToken = token(partnerLogin.getBody());
            assertNotNull(partnerToken, "partner token");

            ResponseEntity<Map> me = get("/v1/me", partnerToken);
            record("PARTNER_ME", "GET", "/v1/me", 200, me, "phone=" + me.getBody().get("phone"));
            check("PARTNER_IDENTITY", "+919876543210".equals(String.valueOf(me.getBody().get("phone"))), "demo partner phone");

            // Setup data created by Flyway V2/V9 and the guarded local DataSeeder.
            ResponseEntity<Map> lookups = get("/v1/admin/lookups", adminToken);
            record("ADMIN_LOOKUPS", "GET", "/v1/admin/lookups", 200, lookups, "hubLookupLoaded");
            List<Map<String, Object>> hubs = (List<Map<String, Object>>) lookups.getBody().get("hubs");
            assertNotNull(hubs, "hubs lookup");
            assertFalse(hubs.isEmpty(), "at least one hub");
            String hubId = String.valueOf(hubs.get(0).get("id"));

            ResponseEntity<List> partnersResponse = getList("/v1/admin/partners", adminToken);
            record("ADMIN_PARTNERS", "GET", "/v1/admin/partners", 200, partnersResponse, "partnerLookupLoaded");
            List<Map<String, Object>> partners = (List<Map<String, Object>>) (List<?>) partnersResponse.getBody();
            assertNotNull(partners, "partners list");
            assertFalse(partners.isEmpty(), "at least one partner");
            String partnerId = null;
            for (Map<String, Object> p : partners) {
                if ("Demo Partner".equals(String.valueOf(p.get("fullName")))) {
                    partnerId = String.valueOf(p.get("id"));
                    break;
                }
            }
            if (partnerId == null) partnerId = String.valueOf(partners.get(0).get("id"));
            check("DEMO_PARTNER_FOUND", partnerId != null && !partnerId.isBlank(), "partnerIdResolved");

            ResponseEntity<List> cities = getList("/v1/cities", null);
            record("PUBLIC_CITIES", "GET", "/v1/cities", 200, cities, "publicLookup");

            // Admin creates an unassigned order with two crates and a generated delivery code.
            Map<String, Object> orderBody = new HashMap<>();
            orderBody.put("hubId", hubId);
            orderBody.put("customerName", "Anjith E2E Customer");
            orderBody.put("customerPhone", "+919000000001");
            orderBody.put("dropAddress", "12 Verification Street");
            orderBody.put("dropLat", 13.05);
            orderBody.put("dropLng", 80.25);
            orderBody.put("dropInstructions", "Ring the bell");
            orderBody.put("leaveAtDoor", false);
            orderBody.put("distanceKm", 2.5);
            orderBody.put("etaMinutes", 30);
            orderBody.put("payBasePaise", 4000L);
            orderBody.put("payDistancePaise", 1000L);
            orderBody.put("tipPaise", 500L);
            orderBody.put("crates", List.of(
                    Map.of("label", "E2E Crate A", "weightGrams", 800),
                    Map.of("label", "E2E Crate B", "weightGrams", 1200)));

            ResponseEntity<Map> created = post("/v1/admin/orders", orderBody, adminToken);
            record("ADMIN_CREATE_ORDER", "POST", "/v1/admin/orders", 201, created,
                    "orderCode=" + created.getBody().get("orderCode") + ",deliveryCode=<redacted>");
            String orderId = String.valueOf(created.getBody().get("id"));
            String deliveryCode = String.valueOf(created.getBody().get("deliveryCode"));
            check("DELIVERY_CODE_GENERATED", deliveryCode.matches("^\\d{4}$"), "4-digit code generated (value redacted)");
            check("ORDER_INITIAL_STATUS", "created".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "status=created in DB");

            // Assign to the seeded demo partner.
            ResponseEntity<Map> assigned = post("/v1/admin/orders/" + orderId + "/assign",
                    Map.of("partnerId", partnerId), adminToken);
            record("ADMIN_ASSIGN_ORDER", "POST", "/v1/admin/orders/{id}/assign", 200, assigned,
                    "status=" + assigned.getBody().get("status"));
            check("ASSIGN_STATUS_PERSISTED", "assigned".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "status=assigned in DB");
            check("ASSIGNED_AT_PERSISTED", jdbc.queryForObject("SELECT assigned_at IS NOT NULL FROM orders WHERE id = ?", Boolean.class, orderId),
                    "assigned_at set");

            // Partner sees the assigned order and its timeline.
            ResponseEntity<Map> detailAssigned = get("/v1/orders/" + orderId, partnerToken);
            record("PARTNER_VIEW_ASSIGNED", "GET", "/v1/orders/{id}", 200, detailAssigned,
                    "status=" + detailAssigned.getBody().get("status"));
            check("ASSIGNED_DETAIL_STATUS", "assigned".equals(String.valueOf(detailAssigned.getBody().get("status"))), "status assigned");
            List<Map<String, Object>> crates = (List<Map<String, Object>>) detailAssigned.getBody().get("crates");
            check("ASSIGNED_DETAIL_CRATES", crates != null && crates.size() == 2, "two crates returned");

            ResponseEntity<List> activeList = getList("/v1/orders?tab=active", partnerToken);
            record("PARTNER_ACTIVE_LIST", "GET", "/v1/orders?tab=active", 200, activeList, "activeTabLoaded");
            boolean visibleInActive = ((List<?>) activeList.getBody()).stream()
                    .anyMatch(o -> orderId.equals(String.valueOf(map(o).get("id"))));
            check("ORDER_IN_ACTIVE_TAB", visibleInActive, "order visible to assigned partner");

            // Accept and verify duplicate-transition protection.
            ResponseEntity<Map> accepted = post("/v1/orders/" + orderId + "/accept", Map.of(), partnerToken);
            record("PARTNER_ACCEPT", "POST", "/v1/orders/{id}/accept", 200, accepted, "status=" + accepted.getBody().get("status"));
            check("ACCEPT_PERSISTED", "accepted".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "status=accepted in DB");

            ResponseEntity<Map> duplicateAccept = post("/v1/orders/" + orderId + "/accept", Map.of(), partnerToken);
            record("NEGATIVE_DUPLICATE_ACCEPT", "POST", "/v1/orders/{id}/accept", 409, duplicateAccept,
                    "error=" + errorCode(duplicateAccept));
            check("DUPLICATE_ACCEPT_CODE", "BAD_ORDER_STATE".equals(errorCode(duplicateAccept)), "BAD_ORDER_STATE");

            // Missing crate scans must block pickup.
            ResponseEntity<Map> earlyPickup = post("/v1/orders/" + orderId + "/pickup",
                    Map.of("lat", 13.08, "lng", 80.21), partnerToken);
            record("NEGATIVE_MISSING_SCANS", "POST", "/v1/orders/{id}/pickup", 400, earlyPickup,
                    "error=" + errorCode(earlyPickup));
            check("MISSING_SCANS_CODE", "CRATES_NOT_SCANNED".equals(errorCode(earlyPickup)), "CRATES_NOT_SCANNED");
            check("STATUS_UNCHANGED_AFTER_EARLY_PICKUP",
                    "accepted".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "still accepted");

            // Scan all required crates; an unknown QR must be rejected.
            ResponseEntity<Map> badScan = post("/v1/orders/" + orderId + "/crates/scan",
                    Map.of("qrCode", "NOT-A-REAL-CRATE"), partnerToken);
            record("NEGATIVE_INVALID_QR", "POST", "/v1/orders/{id}/crates/scan", 400, badScan,
                    "error=" + errorCode(badScan));
            check("INVALID_QR_CODE", "QR_MISMATCH".equals(errorCode(badScan)), "QR_MISMATCH");

            int scanCount = 0;
            for (Map<String, Object> crate : crates) {
                String qr = String.valueOf(crate.get("trialQr"));
                ResponseEntity<Map> scan = post("/v1/orders/" + orderId + "/crates/scan",
                        Map.of("qrCode", qr), partnerToken);
                record("PARTNER_SCAN_CRATE_" + (++scanCount), "POST", "/v1/orders/{id}/crates/scan", 200, scan,
                        "scanned=" + scan.getBody().get("scanned") + ",total=" + scan.getBody().get("total")
                                + ",complete=" + scan.getBody().get("complete"));
                check("SCAN_COUNT_" + scanCount, num(scan.getBody().get("scanned")) == scanCount, "scanned=" + scanCount);
            }
            check("ALL_CRATES_SCANNED_DB",
                    jdbc.queryForObject("SELECT count(*) FROM order_crates WHERE order_id = ? AND scanned_at IS NOT NULL", Integer.class, orderId) == 2,
                    "both scanned_at set");

            // Pickup arrival and pickup confirmation.
            ResponseEntity<Map> atPickup = post("/v1/orders/" + orderId + "/at-pickup",
                    Map.of("lat", 13.08, "lng", 80.21), partnerToken);
            record("PARTNER_AT_PICKUP", "POST", "/v1/orders/{id}/at-pickup", 200, atPickup,
                    "status=" + atPickup.getBody().get("status"));
            check("AT_PICKUP_PERSISTED", "at_pickup".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "status=at_pickup in DB");

            ResponseEntity<Map> pickedUp = post("/v1/orders/" + orderId + "/pickup",
                    Map.of("lat", 13.08, "lng", 80.21), partnerToken);
            record("PARTNER_CONFIRM_PICKUP", "POST", "/v1/orders/{id}/pickup", 200, pickedUp,
                    "status=" + pickedUp.getBody().get("status"));
            check("PICKUP_PERSISTED", "picked_up".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "status=picked_up in DB");
            check("PICKED_UP_AT_PERSISTED", jdbc.queryForObject("SELECT picked_up_at IS NOT NULL FROM orders WHERE id = ?", Boolean.class, orderId),
                    "picked_up_at set");

            // Arrive at the delivery location.
            ResponseEntity<Map> arrived = post("/v1/orders/" + orderId + "/arrive",
                    Map.of("lat", 13.07, "lng", 80.27), partnerToken);
            record("PARTNER_ARRIVE_DELIVERY", "POST", "/v1/orders/{id}/arrive", 200, arrived,
                    "status=" + arrived.getBody().get("status"));
            check("ARRIVED_PERSISTED", "arrived".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "status=arrived in DB");

            // Wrong code must be rejected and counted, without changing state or paying.
            ResponseEntity<Map> wrongCode = post("/v1/orders/" + orderId + "/deliver",
                    Map.of("code", "0000"), partnerToken);
            record("NEGATIVE_WRONG_CODE", "POST", "/v1/orders/{id}/deliver", 400, wrongCode,
                    "error=" + errorCode(wrongCode));
            check("WRONG_CODE_ERROR", "CODE_INVALID".equals(errorCode(wrongCode)), "CODE_INVALID");
            check("WRONG_CODE_ATTEMPT_COUNTED",
                    jdbc.queryForObject("SELECT delivery_attempts FROM orders WHERE id = ?", Integer.class, orderId) == 1,
                    "delivery_attempts=1");
            check("NO_LEDGER_BEFORE_DELIVERY",
                    jdbc.queryForObject("SELECT count(*) FROM wallet_ledger WHERE order_id = ?", Integer.class, orderId) == 0,
                    "no wallet rows yet");

            // Correct generated code completes delivery and pays the order.
            ResponseEntity<Map> delivered = post("/v1/orders/" + orderId + "/deliver",
                    Map.of("code", deliveryCode, "lat", 13.07, "lng", 80.27), partnerToken);
            record("PARTNER_DELIVER", "POST", "/v1/orders/{id}/deliver", 200, delivered,
                    "status=" + delivered.getBody().get("status") + ",earnedPaise=" + delivered.getBody().get("earnedPaise"));
            check("DELIVERED_PERSISTED", "delivered".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "status=delivered in DB");
            check("DELIVERED_AT_PERSISTED", jdbc.queryForObject("SELECT delivered_at IS NOT NULL FROM orders WHERE id = ?", Boolean.class, orderId),
                    "delivered_at set");
            check("EARNED_PAISE_RESPONSE", num(delivered.getBody().get("earnedPaise")) == 5500L, "4000+1000+500=5500");

            List<Map<String, Object>> ledger = jdbc.queryForList(
                    "SELECT type, amount_paise FROM wallet_ledger WHERE order_id = ? ORDER BY id", orderId);
            check("LEDGER_ROW_COUNT", ledger.size() == 3, "3 ledger rows for order");
            long base = ledger.stream().filter(r -> "delivery_base".equals(String.valueOf(r.get("type"))))
                    .mapToLong(r -> num(r.get("amount_paise"))).sum();
            long distance = ledger.stream().filter(r -> "delivery_distance".equals(String.valueOf(r.get("type"))))
                    .mapToLong(r -> num(r.get("amount_paise"))).sum();
            long tip = ledger.stream().filter(r -> "tip".equals(String.valueOf(r.get("type"))))
                    .mapToLong(r -> num(r.get("amount_paise"))).sum();
            check("LEDGER_BASE", base == 4000L, "delivery_base=4000");
            check("LEDGER_DISTANCE", distance == 1000L, "delivery_distance=1000");
            check("LEDGER_TIP", tip == 500L, "tip=500");

            ResponseEntity<Map> earnings = get("/v1/earnings/summary?range=today", partnerToken);
            record("EARNINGS_SUMMARY", "GET", "/v1/earnings/summary?range=today", 200, earnings,
                    "basePaise=" + earnings.getBody().get("basePaise") + ",distancePaise=" + earnings.getBody().get("distancePaise"));
            check("EARNINGS_BASE", num(earnings.getBody().get("basePaise")) == 4000L, "base=4000");
            check("EARNINGS_DISTANCE", num(earnings.getBody().get("distancePaise")) == 1000L, "distance=1000");
            check("EARNINGS_DELIVERIES", num(earnings.getBody().get("deliveries")) == 1L, "deliveries=1");
            check("EARNINGS_BALANCE", num(earnings.getBody().get("availableBalancePaise")) == 30500L,
                    "25000 welcome bonus + 5500 delivery");

            ResponseEntity<Map> transactions = get("/v1/transactions?filter=earnings", partnerToken);
            record("TRANSACTIONS_EARNINGS", "GET", "/v1/transactions?filter=earnings", 200, transactions,
                    "items=" + ((List<?>) transactions.getBody().get("items")).size());
            check("TRANSACTIONS_CONTAIN_ORDER", ((List<?>) transactions.getBody().get("items")).stream()
                    .anyMatch(i -> orderId.equals(String.valueOf(map(i).get("orderId")))
                            || orderId.equals(String.valueOf(map(i).get("id")))
                            || String.valueOf(map(i).get("description")).contains(String.valueOf(created.getBody().get("orderCode")))),
                    "order present in earnings transactions");

            // Duplicate delivery and invalid feedback.
            ResponseEntity<Map> duplicateDeliver = post("/v1/orders/" + orderId + "/deliver",
                    Map.of("code", deliveryCode), partnerToken);
            record("NEGATIVE_DUPLICATE_DELIVER", "POST", "/v1/orders/{id}/deliver", 409, duplicateDeliver,
                    "error=" + errorCode(duplicateDeliver));
            check("DUPLICATE_DELIVER_CODE", "BAD_ORDER_STATE".equals(errorCode(duplicateDeliver)), "BAD_ORDER_STATE");

            ResponseEntity<Map> invalidFeedback = post("/v1/orders/" + orderId + "/feedback",
                    Map.of("dropOffEase", "unknown"), partnerToken);
            record("NEGATIVE_INVALID_FEEDBACK", "POST", "/v1/orders/{id}/feedback", 400, invalidFeedback,
                    "error=" + errorCode(invalidFeedback));
            check("INVALID_FEEDBACK_CODE", "INVALID_FEEDBACK".equals(errorCode(invalidFeedback)), "INVALID_FEEDBACK");

            ResponseEntity<Map> feedback = post("/v1/orders/" + orderId + "/feedback",
                    Map.of("dropOffEase", "smooth"), partnerToken);
            record("PARTNER_FEEDBACK", "POST", "/v1/orders/{id}/feedback", 200, feedback,
                    "dropOffEase=smooth");
            check("FEEDBACK_PERSISTED", "smooth".equals(jdbc.queryForObject("SELECT drop_off_ease FROM orders WHERE id = ?", String.class, orderId)),
                    "drop_off_ease=smooth in DB");

            // Timeline and persistence verification.
            ResponseEntity<Map> finalDetail = get("/v1/orders/" + orderId, partnerToken);
            record("PARTNER_FINAL_DETAIL", "GET", "/v1/orders/{id}", 200, finalDetail,
                    "status=" + finalDetail.getBody().get("status"));
            List<String> timeline = ((List<Map<String, Object>>) finalDetail.getBody().get("timeline")).stream()
                    .map(e -> String.valueOf(e.get("status"))).toList();
            List<String> expectedTimeline = List.of("created", "assigned", "accepted", "at_pickup", "picked_up", "arrived", "delivered");
            check("TIMELINE_SEQUENCE", timeline.equals(expectedTimeline), "timeline=" + timeline);
            check("EVENT_COUNT", jdbc.queryForObject("SELECT count(*) FROM order_events WHERE order_id = ?", Integer.class, orderId) == 7,
                    "7 lifecycle events");

            // Negative security and identifier scenarios.
            ResponseEntity<Map> unauth = get("/v1/orders/" + orderId, null);
            record("NEGATIVE_UNAUTHENTICATED", "GET", "/v1/orders/{id}", 401, unauth,
                    "error=" + errorCode(unauth));
            check("UNAUTH_CODE", "UNAUTHENTICATED".equals(errorCode(unauth)), "UNAUTHENTICATED");

            ResponseEntity<Map> partnerToAdmin = get("/v1/admin/orders", partnerToken);
            record("NEGATIVE_PARTNER_TO_ADMIN", "GET", "/v1/admin/orders", 403, partnerToAdmin,
                    "error=" + errorCode(partnerToAdmin));
            check("FORBIDDEN_CODE", "FORBIDDEN".equals(errorCode(partnerToAdmin)), "FORBIDDEN");

            ResponseEntity<Map> adminToPartner = get("/v1/orders/" + orderId, adminToken);
            record("NEGATIVE_ADMIN_TOKEN_ON_PARTNER_ROUTE", "GET", "/v1/orders/{id}", 401, adminToPartner,
                    "error=" + errorCode(adminToPartner));
            check("WRONG_TOKEN_TYPE_REJECTED", adminToPartner.getStatusCode().value() == 401, "admin token cannot act as partner");

            ResponseEntity<Map> badToken = get("/v1/orders/" + orderId, "not-a-jwt");
            record("NEGATIVE_INVALID_TOKEN", "GET", "/v1/orders/{id}", 401, badToken,
                    "error=" + errorCode(badToken));

            ResponseEntity<Map> invalidUuid = get("/v1/orders/not-a-uuid", partnerToken);
            record("NEGATIVE_INVALID_UUID", "GET", "/v1/orders/not-a-uuid", 404, invalidUuid,
                    "error=" + errorCode(invalidUuid));
            check("INVALID_UUID_CODE", "NOT_FOUND".equals(errorCode(invalidUuid)), "NOT_FOUND");

            ResponseEntity<Map> randomUuid = get("/v1/orders/00000000-0000-0000-0000-000000000000", partnerToken);
            record("NEGATIVE_UNKNOWN_UUID", "GET", "/v1/orders/{id}", 404, randomUuid,
                    "error=" + errorCode(randomUuid));

            // Cross-partner access must be invisible and non-mutating.
            Integer cityId = jdbc.queryForObject("SELECT id FROM cities ORDER BY id LIMIT 1", Integer.class);
            String otherId = UUID.randomUUID().toString();
            jdbc.update("INSERT INTO partners (id, partner_code, full_name, phone, city_id, vehicle_type, "
                            + "status, kyc_status, referral_code, password_hash) VALUES (?, ?, ?, ?, ?, 'motorbike', "
                            + "'active', 'verified', ?, 'unused')",
                    otherId, "TST-" + UUID.randomUUID(), "Other Partner",
                    "+919" + UUID.randomUUID().toString().replace("-", "").substring(0, 9),
                    cityId, "REF-" + UUID.randomUUID());
            String otherToken = jwtService.issueAccess(otherId);

            ResponseEntity<Map> crossDetail = get("/v1/orders/" + orderId, otherToken);
            record("NEGATIVE_CROSS_PARTNER_DETAIL", "GET", "/v1/orders/{id}", 404, crossDetail,
                    "error=" + errorCode(crossDetail));
            check("CROSS_PARTNER_DETAIL_CODE", "NOT_FOUND".equals(errorCode(crossDetail)), "NOT_FOUND");

            ResponseEntity<Map> crossAccept = post("/v1/orders/" + orderId + "/accept", Map.of(), otherToken);
            record("NEGATIVE_CROSS_PARTNER_ACCEPT", "POST", "/v1/orders/{id}/accept", 404, crossAccept,
                    "error=" + errorCode(crossAccept));

            ResponseEntity<Map> crossDeliver = post("/v1/orders/" + orderId + "/deliver",
                    Map.of("code", deliveryCode), otherToken);
            record("NEGATIVE_CROSS_PARTNER_DELIVER", "POST", "/v1/orders/{id}/deliver", 404, crossDeliver,
                    "error=" + errorCode(crossDeliver));
            check("CROSS_PARTNER_STATE_UNCHANGED",
                    "delivered".equals(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)),
                    "status still delivered");

            ResponseEntity<List> otherCompleted = getList("/v1/orders?tab=completed", otherToken);
            record("NEGATIVE_CROSS_PARTNER_LIST", "GET", "/v1/orders?tab=completed", 200, otherCompleted,
                    "other partner list loaded");
            check("CROSS_PARTNER_LIST_ISOLATED", ((List<?>) otherCompleted.getBody()).stream()
                    .noneMatch(o -> orderId.equals(String.valueOf(map(o).get("id")))), "order not leaked");

            // Local schema inventory for comparison with the verified remote Supabase schema.
            REPORT.append("===== LOCAL SCHEMA INVENTORY =====\n");
            List<Map<String, Object>> tableRows = jdbc.queryForList(
                    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' "
                            + "AND table_type = 'BASE TABLE' ORDER BY table_name");
            for (Map<String, Object> row : tableRows) {
                REPORT.append("TABLE|public|").append(row.get("table_name")).append('\n');
            }
            List<Map<String, Object>> columnRows = jdbc.queryForList(
                    "SELECT table_name, column_name, udt_name FROM information_schema.columns "
                            + "WHERE table_schema = 'public' ORDER BY table_name, ordinal_position");
            for (Map<String, Object> row : columnRows) {
                REPORT.append("COLUMN|").append(row.get("table_name")).append('|')
                        .append(row.get("column_name")).append('|').append(row.get("udt_name")).append('\n');
            }
            List<String> localTables = tableRows.stream()
                    .map(r -> String.valueOf(r.get("table_name"))).toList();
            List<String> localAppTables = localTables.stream()
                    .filter(t -> !"flyway_schema_history".equals(t)).toList();
            List<String> localEnums = jdbc.queryForList(
                    "SELECT t.typname AS typname FROM pg_type t JOIN pg_enum e ON e.enumtypid = t.oid "
                            + "GROUP BY t.typname ORDER BY t.typname").stream()
                    .map(r -> String.valueOf(r.get("typname"))).toList();
            for (String type : localEnums) {
                REPORT.append("ENUM|public|").append(type).append('\n');
            }
            int rlsCount = jdbc.queryForObject(
                    "SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
                            + "WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity", Integer.class);
            int policyCount = jdbc.queryForObject(
                    "SELECT count(*) FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid "
                            + "JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public'", Integer.class);
            REPORT.append("RLS_TABLES|").append(rlsCount).append('\n');
            REPORT.append("RLS_POLICIES|").append(policyCount).append('\n');

            // These expectations come from the completed READ-ONLY Supabase inspection of the approved project.
            Set<String> expectedRemoteAppTables = Set.of(
                    "admin_audit_log", "admin_users", "app_ratings", "cities", "device_tokens",
                    "document_events", "emergency_contacts", "hub_change_requests", "hubs", "notifications",
                    "order_crates", "order_events", "orders", "otp_codes", "partner_documents",
                    "partner_settings", "partners", "payout_methods", "payouts", "sessions",
                    "sos_incidents", "support_messages", "support_tickets", "vehicles", "wallet_ledger");
            Set<String> expectedRemoteEnums = Set.of(
                    "app_language", "document_status", "document_type", "kyc_status", "ledger_entry_type",
                    "notification_category", "order_status", "otp_purpose", "partner_status", "payout_kind",
                    "payout_method_type", "payout_status", "sos_status", "ticket_status", "vehicle_type",
                    "verification_status");
            check("LOCAL_APP_TABLE_COUNT", localAppTables.size() == 25, "25 local app tables");
            check("LOCAL_ENUM_COUNT", localEnums.size() == 16, "16 local enum types");
            check("SCHEMA_COMPARE_TABLES", expectedRemoteAppTables.equals(new HashSet<>(localAppTables)),
                    "local app tables match verified remote public app tables");
            check("SCHEMA_COMPARE_ENUMS", expectedRemoteEnums.equals(new HashSet<>(localEnums)),
                    "local enum types match verified remote public enums");
            check("LOCAL_RLS_TABLES", rlsCount == localAppTables.size(),
                    "all 25 local app tables RLS-enabled");
            check("LOCAL_RLS_POLICIES", policyCount == 0, "no local public RLS policies");
            REPORT.append("EXPECTED_DIFFERENCE|remote public.schema_migrations vs local public.flyway_schema_history|"
                    + "both migration-history tables are outside the 25 app tables\n");
            REPORT.append("EXPECTED_DIFFERENCE|remote public citext email/referral_code/upi_vpa vs local text|"
                    + "documented Spring/Supabase compatibility difference, API access is through JDBC\n");

            REPORT.append("LOCAL_WORKFLOW=PASS\n");
        } finally {
            try {
                Path out = Path.of("target", "delivery-workflow-report.txt");
                Files.createDirectories(out.getParent());
                Files.writeString(out, REPORT.toString(), StandardCharsets.UTF_8);
            } catch (Exception ignored) {
                // Reporting failure must not mask the actual test result.
            }
        }
    }
}
