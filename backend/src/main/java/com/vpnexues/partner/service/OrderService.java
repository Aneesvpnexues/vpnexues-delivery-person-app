package com.vpnexues.partner.service;

import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Crypto;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.common.Json;
import com.vpnexues.partner.config.AppProperties;
import com.vpnexues.partner.security.CurrentUser;
import com.vpnexues.partner.web.dto.Dtos;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class OrderService {
    private static final String LIST_COLS = "o.id, o.order_code, o.status, o.customer_name, o.drop_address, o.distance_km, " +
            "o.eta_minutes, o.scheduled_for, (o.pay_base_paise + o.pay_distance_paise + o.tip_paise) AS earning_paise, " +
            "o.created_at, o.delivered_at, h.name AS hub_name, " +
            "(SELECT count(*) FROM order_crates c WHERE c.order_id = o.id) AS crate_count";
    private static final Set<String> TABS = Set.of("active", "upcoming", "completed");
    private static final Set<String> RANGES = Set.of("today", "week", "month", "all");

    private final Db db;
    private final CurrentUser current;
    private final AppProperties props;

    public OrderService(Db db, CurrentUser current, AppProperties props) {
        this.db = db;
        this.current = current;
        this.props = props;
    }

    private static String uuid(String id) {
        try {
            return java.util.UUID.fromString(id).toString();
        } catch (Exception e) {
            throw ApiException.notFound("Order");
        }
    }

    public List<Map<String, Object>> list(String tab, String range, int limit) {
        String t = tab == null ? "active" : tab;
        String r = range == null ? "today" : range;
        if (!TABS.contains(t)) throw ApiException.badRequest("INVALID_TAB", "Choose active, upcoming or completed");
        if (!RANGES.contains(r)) throw ApiException.badRequest("INVALID_RANGE", "Choose today, week, month or all");
        if (limit < 1 || limit > 100) limit = 30;

        String where;
        String order;
        List<Object> args = new ArrayList<>();
        args.add(current.partnerId());
        switch (t) {
            case "upcoming" -> {
                where = "o.status IN ('assigned','accepted') AND o.scheduled_for > now() + interval '30 minutes'";
                order = "COALESCE(o.scheduled_for, o.created_at)";
            }
            case "completed" -> {
                where = "o.status IN ('delivered','cancelled')";
                if (!"all".equals(r)) {
                    String unit = "today".equals(r) ? "day" : r;
                    where += " AND COALESCE(o.delivered_at, o.cancelled_at) >= date_trunc('" + unit + "', now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata'";
                }
                order = "COALESCE(o.delivered_at, o.cancelled_at) DESC";
            }
            default -> {
                where = "o.status IN ('assigned','accepted','at_pickup','picked_up','arrived') " +
                        "AND (o.scheduled_for IS NULL OR o.scheduled_for <= now() + interval '30 minutes')";
                order = "COALESCE(o.scheduled_for, o.created_at)";
            }
        }
        args.add(limit);
        return db.query("SELECT " + LIST_COLS + " FROM orders o JOIN hubs h ON h.id = o.hub_id " +
                "WHERE o.partner_id = ? AND " + where + " ORDER BY " + order + " LIMIT ?", args.toArray());
    }

    public Map<String, Object> detail(String id) {
        Map<String, Object> o = db.one(
                "SELECT o.id, o.order_code, o.status, o.customer_name, o.drop_address, o.drop_lat, o.drop_lng, o.drop_instructions, " +
                        "o.leave_at_door, o.distance_km, o.eta_minutes, o.scheduled_for, o.pay_base_paise, o.pay_distance_paise, o.tip_paise, " +
                        "'+91 ••••• ' || right(o.customer_phone, 5) AS customer_phone_masked, " +
                        "json_build_object('id', h.id, 'name', h.name, 'address', h.address, 'lat', h.lat, 'lng', h.lng) AS pickup, " +
                        "COALESCE((SELECT json_agg(json_build_object('id', c.id, 'position', c.position, 'label', c.label, 'weightGrams', c.weight_grams, " +
                        "'scanned', c.scanned_at IS NOT NULL, 'trialQr', CASE WHEN ? THEN c.qr_code END) ORDER BY c.position) " +
                        "FROM order_crates c WHERE c.order_id = o.id), '[]') AS crates, " +
                        "COALESCE((SELECT json_agg(json_build_object('status', e.status, 'at', e.created_at) ORDER BY e.created_at) " +
                        "FROM order_events e WHERE e.order_id = o.id), '[]') AS timeline " +
                        "FROM orders o JOIN hubs h ON h.id = o.hub_id WHERE o.id = ? AND o.partner_id = ?",
                props.trialMode(), uuid(id), current.partnerId());
        if (o == null) throw ApiException.notFound("Order");
        return o;
    }

    private Map<String, Object> myOrder(String id, String pid) {
        Map<String, Object> o = db.one("SELECT * FROM orders WHERE id = ? AND partner_id = ? FOR UPDATE", id, pid);
        if (o == null) throw ApiException.notFound("Order");
        return o;
    }

    private void transition(Map<String, Object> order, String to, Set<String> from, String pid,
                            String col, Double lat, Double lng, String note) {
        String status = String.valueOf(order.get("status"));
        if (!from.contains(status)) {
            throw ApiException.conflict("BAD_ORDER_STATE", "Order is " + status + "; cannot move to " + to);
        }
        String sql = "UPDATE orders SET status = ?::order_status" + (col == null ? "" : ", " + col + " = now()") + " WHERE id = ?";
        db.update(sql, to, order.get("id"));
        db.update("INSERT INTO order_events (order_id, status, actor, lat, lng, note) VALUES (?, ?::order_status, ?, ?, ?, ?)",
                order.get("id"), to, "partner:" + pid, lat, lng, note);
    }

    public Map<String, Object> accept(String id) {
        String pid = current.partnerId();
        db.inTx(() -> transition(myOrder(uuid(id), pid), "accepted", Set.of("assigned"), pid, "accepted_at", null, null, null));
        return Json.map("status", "accepted");
    }

    public Map<String, Object> atPickup(String id, Dtos.LocBody loc) {
        String pid = current.partnerId();
        db.inTx(() -> transition(myOrder(uuid(id), pid), "at_pickup", Set.of("accepted"), pid, null, loc.lat(), loc.lng(), null));
        return Json.map("status", "at_pickup");
    }

    public Map<String, Object> scanCrate(String id, Dtos.ScanBody b) {
        String pid = current.partnerId();
        String orderId = uuid(id);
        return db.inTx(() -> {
            Map<String, Object> o = myOrder(orderId, pid);
            String status = String.valueOf(o.get("status"));
            if (!Set.of("accepted", "at_pickup").contains(status)) {
                throw ApiException.conflict("BAD_ORDER_STATE", "Crates can only be scanned before pickup");
            }
            boolean damaged = Boolean.TRUE.equals(b.damaged());
            Map<String, Object> crate = db.one(
                    "UPDATE order_crates SET scanned_at = COALESCE(scanned_at, now()), damaged = ? " +
                            "WHERE order_id = ? AND qr_code = ? RETURNING position, label",
                    damaged, orderId, b.qrCode());
            if (crate == null) throw ApiException.badRequest("QR_MISMATCH", "This crate does not belong to this order");
            Map<String, Object> p = db.one("SELECT count(*) FILTER (WHERE scanned_at IS NOT NULL) AS scanned, count(*) AS total " +
                    "FROM order_crates WHERE order_id = ?", orderId);
            long scanned = ((Number) p.get("scanned")).longValue();
            long total = ((Number) p.get("total")).longValue();
            return Json.map("crate", crate, "scanned", scanned, "total", total, "complete", scanned == total);
        });
    }

    public Map<String, Object> pickup(String id, Dtos.LocBody loc) {
        String pid = current.partnerId();
        String orderId = uuid(id);
        db.inTx(() -> {
            Map<String, Object> o = myOrder(orderId, pid);
            Map<String, Object> p = db.one("SELECT count(*) FILTER (WHERE scanned_at IS NULL) AS missing, " +
                    "count(*) FILTER (WHERE damaged) AS damaged FROM order_crates WHERE order_id = ?", orderId);
            long missing = ((Number) p.get("missing")).longValue();
            long damaged = ((Number) p.get("damaged")).longValue();
            if (missing > 0) throw ApiException.badRequest("CRATES_NOT_SCANNED", missing + " crate(s) still need scanning");
            if (damaged > 0) throw ApiException.badRequest("CRATE_DAMAGED", "A crate is damaged — report it to the hub before picking up");
            transition(o, "picked_up", Set.of("accepted", "at_pickup"), pid, "picked_up_at", loc.lat(), loc.lng(), null);
            return null;
        });
        return Json.map("status", "picked_up");
    }

    public Map<String, Object> arrive(String id, Dtos.LocBody loc) {
        String pid = current.partnerId();
        db.inTx(() -> transition(myOrder(uuid(id), pid), "arrived", Set.of("picked_up"), pid, "arrived_at", loc.lat(), loc.lng(), null));
        return Json.map("status", "arrived");
    }

    public Map<String, Object> deliver(String id, Dtos.DeliverBody b) {
        if (b.code() == null || !b.code().matches("^\\d{4}$")) {
            throw ApiException.badRequest("INVALID_CODE", "Enter the 4-digit delivery code");
        }
        String pid = current.partnerId();
        String orderId = uuid(id);
        Map<String, Object> result = db.inTx(() -> {
            Map<String, Object> o = myOrder(orderId, pid);
            if (!"arrived".equals(String.valueOf(o.get("status")))) {
                throw ApiException.conflict("BAD_ORDER_STATE", "Mark the order as arrived first");
            }
            int attempts = ((Number) o.get("deliveryAttempts")).intValue();
            if (attempts >= 5) throw new ApiException(429, "CODE_LOCKED", "Too many wrong codes. Contact support");
            String expected = String.valueOf(o.get("deliveryCodeHash"));
            if (!Crypto.sameHash(expected, Crypto.sha256(orderId + ":" + b.code()))) {
                db.update("UPDATE orders SET delivery_attempts = delivery_attempts + 1 WHERE id = ?", orderId);
                return Json.map("ok", false);
            }
            transition(o, "delivered", Set.of("arrived"), pid, "delivered_at", b.lat(), b.lng(), null);
            long base = ((Number) o.get("payBasePaise")).longValue();
            long dist = ((Number) o.get("payDistancePaise")).longValue();
            long tip = ((Number) o.get("tipPaise")).longValue();
            Object[][] credits = {
                    {"delivery_base", base, "Delivery · " + o.get("orderCode")},
                    {"delivery_distance", dist, "Distance pay · " + o.get("distanceKm") + " km"},
                    {"tip", tip, "Customer tip · " + o.get("orderCode")},
            };
            for (Object[] c : credits) {
                long amt = ((Number) c[1]).longValue();
                if (amt <= 0) continue;
                db.update("INSERT INTO wallet_ledger (partner_id, type, amount_paise, order_id, description) " +
                        "VALUES (?, ?::ledger_entry_type, ?, ?, ?) ON CONFLICT DO NOTHING", pid, c[0], amt, orderId, c[2]);
            }
            return Json.map("ok", true, "earnedPaise", base + dist + tip);
        });
        if (!Boolean.TRUE.equals(result.get("ok"))) {
            throw ApiException.badRequest("CODE_INVALID", "That code is not correct. Ask the customer to check their app");
        }
        return Json.map("status", "delivered", "earnedPaise", result.get("earnedPaise"));
    }

    public Map<String, Object> feedback(String id, Dtos.FeedbackBody b) {
        if (!Set.of("smooth", "hard_to_find", "long_wait").contains(b.dropOffEase())) {
            throw ApiException.badRequest("INVALID_FEEDBACK", "Choose a valid option");
        }
        Map<String, Object> row = db.one("UPDATE orders SET drop_off_ease = ? WHERE id = ? AND partner_id = ? AND status = 'delivered' RETURNING id",
                b.dropOffEase(), uuid(id), current.partnerId());
        if (row == null) throw ApiException.notFound("Delivered order");
        return Json.map("ok", true);
    }
}
