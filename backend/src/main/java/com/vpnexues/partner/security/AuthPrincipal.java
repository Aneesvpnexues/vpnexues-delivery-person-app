package com.vpnexues.partner.security;

/** Authenticated caller. type is "access" (partner) or "admin" (ops console). */
public record AuthPrincipal(String id, String type, String role) {
    public boolean isAdmin() {
        return "admin".equals(type);
    }
}
