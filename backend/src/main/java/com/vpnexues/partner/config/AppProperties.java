package com.vpnexues.partner.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app")
public record AppProperties(
        String jwtSecret,
        long accessTokenTtlSeconds,
        int refreshTokenTtlDays,
        int otpTtlSeconds,
        int otpMaxAttempts,
        boolean otpDevEcho,
        boolean trialMode,
        String corsOrigins,
        String uploadDir,
        String publicBaseUrl,
        int instantPayoutFeePaise,
        int instantPayoutMinPaise
) {
    public String[] corsOriginList() {
        return corsOrigins.split(",");
    }
}
