package com.vpnexues.partner.common;

import java.util.LinkedHashMap;
import java.util.Map;

/** Tiny helpers for building JSON-friendly maps without Map.of's null restrictions. */
public final class Json {
    private Json() {}

    public static Map<String, Object> map(Object... kv) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i + 1 < kv.length; i += 2) m.put(String.valueOf(kv[i]), kv[i + 1]);
        return m;
    }
}
