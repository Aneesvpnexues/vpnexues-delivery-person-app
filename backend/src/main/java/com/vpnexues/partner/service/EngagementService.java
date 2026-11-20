package com.vpnexues.partner.service;

import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.common.Json;
import com.vpnexues.partner.security.CurrentUser;
import com.vpnexues.partner.web.dto.Dtos;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class EngagementService {
    private static final Set<String> SOS_KINDS = Set.of("sos", "road_accident", "harassment", "medical",
            "vehicle_breakdown", "other");
    private static final Set<String> RELATIONSHIPS = Set.of("parent", "spouse", "sibling", "friend", "relative", "other");

    private final Db db;
    private final CurrentUser current;

    public EngagementService(Db db, CurrentUser current) {
        this.db = db;
        this.current = current;
    }

    private static String uuid(String id) {
        try {
            return java.util.UUID.fromString(id).toString();
        } catch (Exception e) {
            throw ApiException.notFound("Record");
        }
    }

    // ---------------- notifications ----------------

    public Map<String, Object> notifications(int limit) {
        if (limit < 1 || limit > 100) limit = 50;
        String pid = current.partnerId();
        List<Map<String, Object>> items = db.query(
                "SELECT id, category, title, body, action_url, read_at, created_at FROM notifications " +
                        "WHERE partner_id = ? ORDER BY created_at DESC LIMIT ?", pid, limit);
        Map<String, Object> unread = db.one("SELECT count(*) AS n FROM notifications WHERE partner_id = ? AND read_at IS NULL", pid);
        return Json.map("items", items, "unreadCount", unread == null ? 0 : unread.get("n"));
    }

    public Map<String, Object> readNotification(String id) {
        Map<String, Object> row = db.one("UPDATE notifications SET read_at = now() WHERE id = ? AND partner_id = ? AND read_at IS NULL RETURNING id",
                uuid(id), current.partnerId());
        if (row == null) {
            Map<String, Object> exists = db.one("SELECT id FROM notifications WHERE id = ? AND partner_id = ?", id, current.partnerId());
            if (exists == null) throw ApiException.notFound("Notification");
        }
        return Json.map("ok", true);
    }

    public Map<String, Object> readAllNotifications() {
        int n = db.update("UPDATE notifications SET read_at = now() WHERE partner_id = ? AND read_at IS NULL", current.partnerId());
        return Json.map("ok", true, "updated", n);
    }

    // ---------------- support ----------------

    public List<Map<String, Object>> tickets() {
        return db.query("SELECT t.id, t.topic, t.status, t.order_id, t.created_at, t.updated_at, " +
                "(SELECT body FROM support_messages m WHERE m.ticket_id = t.id ORDER BY m.created_at DESC LIMIT 1) AS last_message, " +
                "(SELECT count(*) FROM support_messages m WHERE m.ticket_id = t.id) AS message_count " +
                "FROM support_tickets t WHERE t.partner_id = ? ORDER BY t.updated_at DESC LIMIT 50", current.partnerId());
    }

    public Map<String, Object> createTicket(Dtos.TicketBody b) {
        String pid = current.partnerId();
        if (b.orderId() != null) {
            Map<String, Object> o = db.one("SELECT id FROM orders WHERE id = ? AND partner_id = ?", uuid(b.orderId()), pid);
            if (o == null) throw ApiException.notFound("Order");
        }
        return db.inTx(() -> {
            Map<String, Object> t = db.one(
                    "INSERT INTO support_tickets (partner_id, order_id, topic) VALUES (?, ?, ?) RETURNING id, topic, status, created_at, updated_at",
                    pid, b.orderId() == null ? null : b.orderId(), b.topic());
            db.update("INSERT INTO support_messages (ticket_id, sender, body) VALUES (?, 'partner', ?)", t.get("id"), b.message());
            return Json.map("ticket", t, "messages", messages(t.get("id").toString()));
        });
    }

    public Map<String, Object> ticket(String id) {
        String pid = current.partnerId();
        Map<String, Object> t = db.one("SELECT id, topic, status, order_id, created_at, updated_at FROM support_tickets " +
                "WHERE id = ? AND partner_id = ?", uuid(id), pid);
        if (t == null) throw ApiException.notFound("Ticket");
        return Json.map("ticket", t, "messages", messages(id));
    }

    private List<Map<String, Object>> messages(String ticketId) {
        return db.query("SELECT id, sender, body, created_at FROM support_messages WHERE ticket_id = ? ORDER BY created_at", ticketId);
    }

    public Map<String, Object> addMessage(String id, Dtos.MessageBody b) {
        String pid = current.partnerId();
        String ticketId = uuid(id);
        Map<String, Object> t = db.one("SELECT id, status FROM support_tickets WHERE id = ? AND partner_id = ? FOR UPDATE", ticketId, pid);
        if (t == null) throw ApiException.notFound("Ticket");
        if ("closed".equals(String.valueOf(t.get("status")))) {
            throw ApiException.badRequest("TICKET_CLOSED", "This ticket is closed. Open a new one if you still need help");
        }
        Map<String, Object> m = db.one("INSERT INTO support_messages (ticket_id, sender, body) VALUES (?, 'partner', ?) " +
                "RETURNING id, sender, body, created_at", ticketId, b.message());
        db.update("UPDATE support_tickets SET status = 'open' WHERE id = ? AND status = 'resolved'", ticketId);
        return m;
    }

    // ---------------- safety ----------------

    public Map<String, Object> sos(Dtos.SosBody b) {
        String kind = b.kind() == null ? "sos" : b.kind();
        if (!SOS_KINDS.contains(kind)) throw ApiException.badRequest("INVALID_KIND", "Choose a valid emergency type");
        String pid = current.partnerId();
        if (b.orderId() != null) {
            Map<String, Object> o = db.one("SELECT id FROM orders WHERE id = ? AND partner_id = ?", uuid(b.orderId()), pid);
            if (o == null) throw ApiException.notFound("Order");
        }
        Map<String, Object> row = db.one(
                "INSERT INTO sos_incidents (partner_id, order_id, kind, lat, lng, details) VALUES (?, ?, ?, ?, ?, ?) " +
                        "RETURNING id, kind, status, created_at",
                pid, b.orderId(), kind, b.lat(), b.lng(), b.details());
        return Json.map("incident", row, "message", "Help is on the way. Stay on this screen and keep your phone unlocked.");
    }

    public List<Map<String, Object>> contacts() {
        return db.query("SELECT id, name, relationship, phone, is_primary, created_at FROM emergency_contacts " +
                "WHERE partner_id = ? ORDER BY is_primary DESC, created_at", current.partnerId());
    }

    public Map<String, Object> addContact(Dtos.ContactBody b) {
        if (!RELATIONSHIPS.contains(b.relationship())) {
            throw ApiException.badRequest("INVALID_RELATIONSHIP", "Choose a valid relationship");
        }
        String phone = b.phone().replaceAll("[^0-9+]", "");
        if (phone.length() < 10) throw ApiException.badRequest("INVALID_PHONE", "Enter a valid phone number");
        String pid = current.partnerId();
        return db.inTx(() -> {
            Map<String, Object> count = db.one("SELECT count(*) AS n FROM emergency_contacts WHERE partner_id = ?", pid);
            boolean primary = Boolean.TRUE.equals(b.isPrimary()) || ((Number) count.get("n")).intValue() == 0;
            if (primary) db.update("UPDATE emergency_contacts SET is_primary = false WHERE partner_id = ? AND is_primary", pid);
            return db.one("INSERT INTO emergency_contacts (partner_id, name, relationship, phone, is_primary) " +
                            "VALUES (?, ?, ?, ?, ?) RETURNING id, name, relationship, phone, is_primary, created_at",
                    pid, b.name().trim(), b.relationship(), phone, primary);
        });
    }

    public Map<String, Object> deleteContact(String id) {
        Map<String, Object> row = db.one("DELETE FROM emergency_contacts WHERE id = ? AND partner_id = ? RETURNING id", uuid(id), current.partnerId());
        if (row == null) throw ApiException.notFound("Contact");
        return Json.map("ok", true);
    }

    // ---------------- app rating ----------------

    public Map<String, Object> rate(Dtos.RatingBody b) {
        if (b.stars() < 1 || b.stars() > 5) throw ApiException.badRequest("INVALID_STARS", "Choose 1 to 5 stars");
        Map<String, Object> row = db.one("INSERT INTO app_ratings (partner_id, stars, comment, app_version) VALUES (?, ?, ?, ?) " +
                "RETURNING id, stars, created_at", current.partnerId(), b.stars(), b.comment(), b.appVersion());
        return Json.map("rating", row);
    }
}
