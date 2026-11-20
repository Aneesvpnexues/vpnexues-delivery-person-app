package com.vpnexues.partner.common;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.postgresql.util.PGobject;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.sql.Array;
import java.sql.Date;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Thin JDBC access layer used by the services.
 * Rows come back as camelCase maps with JDBC-specific types normalised for JSON.
 */
@Component
public class Db {
    private final JdbcTemplate jdbc;
    private final TransactionTemplate tx;
    private final ObjectMapper mapper;

    public Db(JdbcTemplate jdbc, TransactionTemplate tx, ObjectMapper mapper) {
        this.jdbc = jdbc;
        this.tx = tx;
        this.mapper = mapper;
    }

    public List<Map<String, Object>> query(String sql, Object... args) {
        List<Map<String, Object>> rows = jdbc.queryForList(sql, args);
        List<Map<String, Object>> out = new ArrayList<>(rows.size());
        for (Map<String, Object> row : rows) out.add(normalise(row));
        return out;
    }

    public Map<String, Object> one(String sql, Object... args) {
        List<Map<String, Object>> rows = query(sql, args);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Object scalar(String sql, Object... args) {
        return jdbc.queryForObject(sql, Object.class, args);
    }

    public int update(String sql, Object... args) {
        return jdbc.update(sql, args);
    }

    public <T> T inTx(java.util.function.Supplier<T> work) {
        return tx.execute(status -> work.get());
    }

    public void inTx(Runnable work) {
        tx.executeWithoutResult(status -> work.run());
    }

    /** Recursively convert snake_case keys to camelCase and normalise JDBC values. */
    public Map<String, Object> normalise(Map<String, Object> row) {
        Map<String, Object> out = new LinkedHashMap<>();
        row.forEach((k, v) -> out.put(camel(k), value(v)));
        return out;
    }

    private Object value(Object v) {
        if (v == null) return null;
        if (v instanceof Timestamp ts) return ts.toInstant().toString();
        if (v instanceof Date d) return d.toLocalDate().toString();
        if (v instanceof java.util.Date d) return d.toInstant().toString();
        if (v instanceof Array a) {
            try {
                Object arr = a.getArray();
                if (arr instanceof Object[] objs) {
                    List<Object> list = new ArrayList<>(objs.length);
                    for (Object o : objs) list.add(value(o));
                    return list;
                }
                return arr;
            } catch (Exception e) {
                return null;
            }
        }
        if (v instanceof PGobject pg) {
            String type = pg.getType();
            if (type != null && (type.equals("json") || type.equals("jsonb"))) {
                try {
                    return mapper.readValue(pg.getValue(), new TypeReference<Object>() {});
                } catch (Exception e) {
                    return pg.getValue();
                }
            }
            return pg.getValue();
        }
        if (v instanceof BigDecimal bd) return bd;
        return v;
    }

    public static String camel(String key) {
        if (key == null || key.indexOf('_') < 0) return key;
        StringBuilder sb = new StringBuilder(key.length());
        boolean upper = false;
        for (char c : key.toCharArray()) {
            if (c == '_') { upper = true; continue; }
            sb.append(upper ? Character.toUpperCase(c) : c);
            upper = false;
        }
        return sb.toString();
    }
}
