package com.vpnexues.partner.security;

import com.vpnexues.partner.common.ApiException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Arrays;

@Component
public class CurrentUser {

    public AuthPrincipal principal() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof AuthPrincipal p)) {
            throw ApiException.unauthorized("Sign in again to continue");
        }
        return p;
    }

    public String partnerId() {
        AuthPrincipal p = principal();
        if (!"access".equals(p.type())) throw ApiException.unauthorized("Wrong token type");
        return p.id();
    }

    public AuthPrincipal admin() {
        AuthPrincipal p = principal();
        if (!"admin".equals(p.type())) throw ApiException.unauthorized("Wrong token type");
        return p;
    }

    /** owner is always allowed; otherwise the role must be one of {@code roles}. */
    public void requireRole(AuthPrincipal admin, String... roles) {
        if ("owner".equals(admin.role())) return;
        if (admin.role() == null || Arrays.stream(roles).noneMatch(r -> r.equals(admin.role()))) {
            throw ApiException.forbidden("FORBIDDEN", "Your role cannot do this");
        }
    }
}
