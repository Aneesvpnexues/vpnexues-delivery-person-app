package com.vpnexues.partner.web;

import com.vpnexues.partner.config.AppProperties;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {
    private final JdbcTemplate jdbc;
    private final AppProperties props;
    private final long startedAt = System.currentTimeMillis();

    public HealthController(JdbcTemplate jdbc, AppProperties props) {
        this.jdbc = jdbc;
        this.props = props;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of("status", "ok", "uptimeSeconds", Math.round((System.currentTimeMillis() - startedAt) / 1000.0));
    }

    @GetMapping("/health/ready")
    public Map<String, Object> ready() {
        String database;
        boolean up;
        try {
            jdbc.queryForObject("SELECT 1", Integer.class);
            database = "up";
            up = true;
        } catch (Exception e) {
            database = "down";
            up = false;
        }
        return Map.of(
                "status", up ? "ready" : "degraded",
                "database", database,
                "trial", props.trialMode());
    }
}
