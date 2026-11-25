package com.vpnexues.partner.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {
    private final JwtService jwt;

    public JwtAuthFilter(JwtService jwt) {
        this.jwt = jwt;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ") && SecurityContextHolder.getContext().getAuthentication() == null) {
            String token = header.substring(7).trim();
            try {
                Claims claims = jwt.parse(token);
                String type = claims.get("typ", String.class);
                String role = claims.get("role", String.class);
                AuthPrincipal principal = new AuthPrincipal(claims.getSubject(), type, role);
                List<SimpleGrantedAuthority> authorities = new ArrayList<>();
                if ("admin".equals(type)) {
                    authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
                    if (role != null) authorities.add(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()));
                } else if ("access".equals(type)) {
                    authorities.add(new SimpleGrantedAuthority("ROLE_PARTNER"));
                } else {
                    authorities = List.of();
                }
                if (!authorities.isEmpty()) {
                    UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            } catch (Exception ignored) {
                // Invalid/expired token: leave the context empty; protected routes return 401.
            }
        }
        chain.doFilter(request, response);
    }
}
