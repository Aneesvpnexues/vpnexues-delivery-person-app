package com.vpnexues.partner;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/** End-to-end smoke test: real PostgreSQL, real migrations, real HTTP. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
                "app.demo-seed=true",
                "app.trial-mode=true",
                "app.otp-dev-echo=true",
                "app.bootstrap-admin-email=owner@vpnexues.local",
                "app.bootstrap-admin-password=Owner@12345"
        })
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class PartnerApiTest {
    static EmbeddedPostgres pg;
    static String partnerToken;
    static String adminToken;
    static String orderId;

    static {
        try {
            System.setProperty("ot.epg.working-dir",
                    java.nio.file.Paths.get("target", "pgbin").toAbsolutePath().toString());
            pg = EmbeddedPostgres.builder().start();
        } catch (Exception e) {
            throw new RuntimeException("Could not start embedded PostgreSQL", e);
        }
    }

    @org.junit.jupiter.api.AfterAll
    static void stopPostgres() throws Exception {
        if (pg != null) pg.close();
    }

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", () -> pg.getJdbcUrl("postgres", "postgres"));
        r.add("spring.datasource.username", () -> "postgres");
        r.add("spring.datasource.password", () -> "");
    }

    @Autowired
    TestRestTemplate rest;

    @SuppressWarnings("rawtypes")
    private ResponseEntity<Map> get(String path, String token) {
        HttpHeaders h = new HttpHeaders();
        if (token != null) h.setBearerAuth(token);
        return rest.exchange(path, HttpMethod.GET, new HttpEntity<>(h), Map.class);
    }

    @SuppressWarnings("rawtypes")
    private ResponseEntity<List> getList(String path, String token) {
        HttpHeaders h = new HttpHeaders();
        if (token != null) h.setBearerAuth(token);
        return rest.exchange(path, HttpMethod.GET, new HttpEntity<>(h), List.class);
    }

    @SuppressWarnings("rawtypes")
    private ResponseEntity<Map> post(String path, Object body, String token, String idem) {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        if (token != null) h.setBearerAuth(token);
        if (idem != null) h.set("Idempotency-Key", idem);
        return rest.exchange(path, HttpMethod.POST, new HttpEntity<>(body, h), Map.class);
    }

    @SuppressWarnings("rawtypes")
    private ResponseEntity<Map> patch(String path, Object body, String token) {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        if (token != null) h.setBearerAuth(token);
        return rest.exchange(path, HttpMethod.PATCH, new HttpEntity<>(body, h), Map.class);
    }

    private static void ok(ResponseEntity<?> r, int status) {
        assertEquals(status, r.getStatusCode().value(), "unexpected status, body=" + r.getBody());
    }

    @Test
    @Order(1)
    void healthIsPublic() {
        ok(get("/health", null), 200);
        ok(get("/health/ready", null), 200);
    }

    @Test
    @Order(2)
    void adminCanLoginAndSeeOverview() {
        ResponseEntity<Map> login = post("/v1/admin/auth/login",
                Map.of("email", "owner@vpnexues.local", "password", "Owner@12345"), null, null);
        ok(login, 200);
        adminToken = (String) login.getBody().get("accessToken");
        assertNotNull(adminToken);
        ok(get("/v1/admin/me", adminToken), 200);
        ResponseEntity<Map> overview = get("/v1/admin/overview", adminToken);
        ok(overview, 200);
        assertNotNull(overview.getBody().get("activePartners"));
    }

    @Test
    @Order(3)
    void partnerCanLogin() {
        ResponseEntity<Map> login = post("/v1/auth/login",
                Map.of("phone", "9876543210", "password", "Demo@12345"), null, null);
        ok(login, 200);
        partnerToken = (String) login.getBody().get("accessToken");
        assertNotNull(partnerToken);
        ResponseEntity<Map> me = get("/v1/me", partnerToken);
        ok(me, 200);
        assertEquals("+919876543210", me.getBody().get("phone"));
    }

    @Test
    @Order(4)
    void citiesArePublic() {
        ok(getList("/v1/cities", null), 200);
    }

    @Test
    @Order(5)
    void demoOrderFullLifecycle() {
        ResponseEntity<Map> demo = post("/v1/demo-order", Map.of(), partnerToken, null);
        ok(demo, 201);
        orderId = (String) demo.getBody().get("orderId");
        assertEquals("7391", demo.getBody().get("demoCode"));
        List<Map<String, Object>> crates = (List<Map<String, Object>>) demo.getBody().get("crates");
        assertEquals(2, crates.size());

        ok(post("/v1/orders/" + orderId + "/accept", Map.of(), partnerToken, null), 200);
        ok(post("/v1/orders/" + orderId + "/at-pickup", Map.of("lat", 13.08, "lng", 80.21), partnerToken, null), 200);
        int scanned = 0;
        for (Map<String, Object> crate : crates) {
            ResponseEntity<Map> scan = post("/v1/orders/" + orderId + "/crates/scan",
                    Map.of("qrCode", crate.get("qrCode")), partnerToken, null);
            ok(scan, 200);
            assertEquals(++scanned, ((Number) scan.getBody().get("scanned")).intValue());
        }
        ok(post("/v1/orders/" + orderId + "/pickup", Map.of("lat", 13.08, "lng", 80.21), partnerToken, null), 200);
        ok(post("/v1/orders/" + orderId + "/arrive", Map.of("lat", 13.07, "lng", 80.27), partnerToken, null), 200);

        ResponseEntity<Map> wrong = post("/v1/orders/" + orderId + "/deliver", Map.of("code", "0000"), partnerToken, null);
        ok(wrong, 400);
        assertEquals("CODE_INVALID", ((Map<?, ?>) wrong.getBody().get("error")).get("code"));

        ResponseEntity<Map> done = post("/v1/orders/" + orderId + "/deliver", Map.of("code", "7391"), partnerToken, null);
        ok(done, 200);
        assertEquals("delivered", done.getBody().get("status"));
        assertEquals(8300, ((Number) done.getBody().get("earnedPaise")).intValue());

        ResponseEntity<Map> detail = get("/v1/orders/" + orderId, partnerToken);
        ok(detail, 200);
        assertEquals("delivered", detail.getBody().get("status"));
    }

    @Test
    @Order(6)
    void earningsAndLedgerReflectDelivery() {
        ResponseEntity<Map> summary = get("/v1/earnings/summary?range=today", partnerToken);
        ok(summary, 200);
        assertEquals(33300, ((Number) summary.getBody().get("availableBalancePaise")).intValue());

        ResponseEntity<Map> tx = get("/v1/transactions", partnerToken);
        ok(tx, 200);
        assertFalse(((List<?>) tx.getBody().get("items")).isEmpty());
    }

    @Test
    @Order(7)
    void notificationsAndSupport() {
        ResponseEntity<Map> notes = get("/v1/notifications", partnerToken);
        ok(notes, 200);
        assertTrue(((Number) notes.getBody().get("unreadCount")).intValue() >= 1);

        ResponseEntity<Map> ticket = post("/v1/support/tickets",
                Map.of("topic", "Order issue", "message", "Customer was not reachable", "orderId", orderId), partnerToken, null);
        ok(ticket, 201);
        String ticketId = (String) ((Map<?, ?>) ticket.getBody().get("ticket")).get("id");
        ok(get("/v1/support/tickets/" + ticketId, partnerToken), 200);
        ok(post("/v1/support/tickets/" + ticketId + "/messages", Map.of("message", "Any update?"), partnerToken, null), 201);

        ok(post("/v1/sos", Map.of("kind", "sos", "lat", 13.07, "lng", 80.27), partnerToken, null), 201);

        ResponseEntity<Map> contact = post("/v1/emergency-contacts",
                Map.of("name", "Amma", "relationship", "parent", "phone", "9876500000"), partnerToken, null);
        ok(contact, 201);
        String contactId = (String) contact.getBody().get("id");
        HttpHeaders h = new HttpHeaders();
        h.setBearerAuth(partnerToken);
        ok(rest.exchange("/v1/emergency-contacts/" + contactId, HttpMethod.DELETE, new HttpEntity<>(h), Map.class), 200);
    }

    @Test
    @Order(8)
    void instantPayoutIsIdempotent() {
        ResponseEntity<Map> first = post("/v1/payouts/instant", Map.of("amountPaise", 10000), partnerToken, "test-idem-key-1");
        ok(first, 201);
        String id = (String) first.getBody().get("id");
        ResponseEntity<Map> again = post("/v1/payouts/instant", Map.of("amountPaise", 10000), partnerToken, "test-idem-key-1");
        ok(again, 201);
        assertEquals(id, again.getBody().get("id"));
        ok(getList("/v1/payouts", partnerToken), 200);
    }

    @Test
    @Order(9)
    void adminConsoleReadsWork() {
        ok(getList("/v1/admin/partners", adminToken), 200);
        ok(getList("/v1/admin/orders", adminToken), 200);
        ok(getList("/v1/admin/documents", adminToken), 200);
        ok(getList("/v1/admin/payouts", adminToken), 200);
        ok(getList("/v1/admin/tickets", adminToken), 200);
        ok(getList("/v1/admin/sos", adminToken), 200);
        ok(getList("/v1/admin/zone-requests", adminToken), 200);
        ok(getList("/v1/admin/audit", adminToken), 200);
        ok(getList("/v1/admin/staff", adminToken), 200);
        ok(get("/v1/admin/lookups", adminToken), 200);
    }

    @Test
    @Order(10)
    void adminCreatesAndAssignsOrder() {
        ResponseEntity<Map> lookups = get("/v1/admin/lookups", adminToken);
        List<Map<String, Object>> hubs = (List<Map<String, Object>>) lookups.getBody().get("hubs");
        String hubId = (String) hubs.get(0).get("id");
        List<Map<String, Object>> partners = (List<Map<String, Object>>) getList("/v1/admin/partners", adminToken).getBody();
        String partnerId = (String) partners.get(0).get("id");

        Map<String, Object> newOrder = new java.util.HashMap<>();
        newOrder.put("hubId", hubId);
        newOrder.put("customerName", "Ops Customer");
        newOrder.put("customerPhone", "9000000001");
        newOrder.put("dropAddress", "5 Test Street");
        newOrder.put("dropLat", 13.05);
        newOrder.put("dropLng", 80.25);
        newOrder.put("distanceKm", 2.5);
        newOrder.put("payBasePaise", 4000);
        newOrder.put("payDistancePaise", 1000);
        newOrder.put("tipPaise", 0);
        newOrder.put("crates", List.of(Map.of("label", "Crate A", "weightGrams", 900)));
        ResponseEntity<Map> created = post("/v1/admin/orders", newOrder, adminToken, null);
        ok(created, 201);
        String newId = (String) created.getBody().get("id");
        ok(post("/v1/admin/orders/" + newId + "/assign", Map.of("partnerId", partnerId), adminToken, null), 200);

        ok(patch("/v1/admin/partners/" + partnerId, Map.of("deliveryRadiusKm", 7, "reason", "Smoke test"), adminToken), 200);
        ok(getList("/v1/admin/audit?entity=partner&entityId=" + partnerId, adminToken), 200);
    }
}
