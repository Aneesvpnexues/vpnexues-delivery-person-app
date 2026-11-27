package com.vpnexues.partner.service;

import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Crypto;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.common.Json;
import com.vpnexues.partner.config.AppProperties;
import com.vpnexues.partner.security.CurrentUser;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Trial-mode demo order so a new partner can walk the full delivery flow. */
@Service
public class TrialService {
    public static final String DEMO_CODE = "7391";

    private final Db db;
    private final CurrentUser current;
    private final AppProperties props;

    public TrialService(Db db, CurrentUser current, AppProperties props) {
        this.db = db;
        this.current = current;
        this.props = props;
    }

    public Map<String, Object> createDemoOrder() {
        if (!props.trialMode()) throw ApiException.notFound("Demo order");
        String pid = current.partnerId();
        return db.inTx(() -> {
            Map<String, Object> open = db.one(
                    "SELECT count(*) AS n FROM orders WHERE partner_id = ? AND customer_phone = '+919000000000' " +
                            "AND status IN ('assigned','accepted','at_pickup','picked_up','arrived')", pid);
            if (open != null && ((Number) open.get("n")).longValue() >= 3) {
                throw ApiException.conflict("DEMO_LIMIT", "Finish your open demo orders before creating another");
            }
            Map<String, Object> p = db.one("SELECT hub_id, city_id FROM partners WHERE id = ? FOR UPDATE", pid);
            if (p == null) throw ApiException.notFound("Partner");
            Object hubId = p.get("hubId");
            if (hubId == null) {
                Map<String, Object> hub = db.one("SELECT id FROM hubs WHERE city_id = ? AND is_active ORDER BY name LIMIT 1", p.get("cityId"));
                if (hub == null) throw ApiException.conflict("NO_HUB", "No delivery hub is configured for your city yet");
                hubId = hub.get("id");
            }
            Map<String, Object> o = db.one(
                    "INSERT INTO orders (order_code, hub_id, partner_id, status, customer_name, customer_phone, drop_address, " +
                            "drop_lat, drop_lng, drop_instructions, leave_at_door, delivery_code_hash, distance_km, eta_minutes, " +
                            "pay_base_paise, pay_distance_paise, tip_paise, assigned_at) VALUES " +
                            "('VPN-' || lpad(nextval('order_number_seq')::text, 5, '0'), ?, ?, 'assigned', 'Trial Customer', '+919000000000', " +
                            "'12, Demo Street, Near Clock Tower (trial order)', 13.0827, 80.2707, 'Ring the bell twice. This is a trial order.', " +
                            "false, '', 3.2, 14, 4500, 1800, 2000, now()) RETURNING id, order_code",
                    hubId, pid);
            String id = o.get("id").toString();
            db.update("UPDATE orders SET delivery_code_hash = ? WHERE id = ?", Crypto.sha256(id + ":" + DEMO_CODE), id);

            List<Map<String, Object>> crates = new ArrayList<>();
            String[][] spec = {{"Crate 1 · Groceries", "1200"}, {"Crate 2 · Dairy", "800"}};
            for (int i = 0; i < spec.length; i++) {
                String qr = "TRIAL-" + id.substring(0, 8).toUpperCase() + "-" + (i + 1);
                Map<String, Object> c = db.one("INSERT INTO order_crates (order_id, position, label, weight_grams, qr_code) " +
                                "VALUES (?, ?, ?, ?, ?) RETURNING position, label, weight_grams, qr_code",
                        id, i + 1, spec[i][0], Integer.parseInt(spec[i][1]), qr);
                crates.add(c);
            }
            db.update("INSERT INTO order_events (order_id, status, actor, note) VALUES (?, 'created', 'system', 'Trial order created')", id);
            db.update("INSERT INTO order_events (order_id, status, actor, note) VALUES (?, 'assigned', 'system', 'Trial order assigned')", id);
            db.update("INSERT INTO notifications (partner_id, category, title, body) VALUES (?, 'order', " +
                    "'Trial order ready', 'A demo delivery is waiting for you. Accept it to explore the delivery flow.')", pid);
            return Json.map("orderId", id, "orderCode", o.get("orderCode"), "demoCode", DEMO_CODE, "crates", crates);
        });
    }
}
