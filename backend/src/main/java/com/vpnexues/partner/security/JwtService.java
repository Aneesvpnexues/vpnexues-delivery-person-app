package com.vpnexues.partner.security;

import com.vpnexues.partner.config.AppProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Date;

@Service
public class JwtService {
    private final SecretKey key;
    private final long accessTtlSeconds;

    public JwtService(AppProperties props) {
        byte[] raw = props.jwtSecret().getBytes(StandardCharsets.UTF_8);
        if (raw.length < 32) {
            try {
                raw = MessageDigest.getInstance("SHA-256").digest(raw);
            } catch (Exception e) {
                throw new IllegalStateException(e);
            }
        }
        this.key = Keys.hmacShaKeyFor(raw);
        this.accessTtlSeconds = props.accessTokenTtlSeconds();
    }

    public String issueAccess(String partnerId) {
        Date now = new Date();
        return Jwts.builder()
                .subject(partnerId)
                .claim("typ", "access")
                .issuedAt(now)
                .expiration(new Date(now.getTime() + accessTtlSeconds * 1000))
                .signWith(key)
                .compact();
    }

    public String issueAdmin(String adminId, String role) {
        Date now = new Date();
        return Jwts.builder()
                .subject(adminId)
                .claim("typ", "admin")
                .claim("role", role)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + 8 * 3600 * 1000))
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }

    public long accessTtlSeconds() {
        return accessTtlSeconds;
    }
}
