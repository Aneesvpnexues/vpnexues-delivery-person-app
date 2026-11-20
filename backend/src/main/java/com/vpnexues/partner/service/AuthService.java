package com.vpnexues.partner.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Crypto;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.common.Json;
import com.vpnexues.partner.config.AppProperties;
import com.vpnexues.partner.security.CurrentUser;
import com.vpnexues.partner.security.JwtService;
import com.vpnexues.partner.web.dto.Dtos;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Function;

@Service
public class AuthService {
    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
    private static final Set<String> VEHICLES = Set.of("motorbike", "scooter", "electric_scooter", "bicycle");

    private final Db db;
    private final JwtService jwt;
    private final CurrentUser current;
    private final AppProperties props;
    private final PasswordEncoder encoder;
    private final ObjectMapper mapper;
    private final String dummyHash;

    public AuthService(Db db, JwtService jwt, CurrentUser current, AppProperties props, PasswordEncoder encoder, ObjectMapper mapper) {
        this.db = db;
        this.jwt = jwt;
        this.current = current;
        this.props = props;
        this.encoder = encoder;
        this.mapper = mapper;
        this.dummyHash = encoder.encode("timing-equaliser");
    }

    // ---------------- helpers ----------------

    public static String normalizePhone(String raw) {
        if (raw == null) throw ApiException.badRequest("INVALID_PHONE", "Enter a valid 10-digit Indian mobile number");
        String s = raw.replaceAll("[\\s-]", "");
        s = s.replaceFirst("^(\\+91|91|0)(?=\\d{10}$)", "");
        if (!s.matches("^[6-9]\\d{9}$")) {
            throw ApiException.badRequest("INVALID_PHONE", "Enter a valid 10-digit Indian mobile number");
        }
        return "+91" + s;
    }

    public static void validatePassword(String pw) {
        if (pw == null || pw.length() < 8 || pw.length() > 72) {
            throw ApiException.badRequest("WEAK_PASSWORD", "Password must be 8–72 characters");
        }
        if (!(pw.matches(".*[A-Z].*") && pw.matches(".*\\d.*") && pw.matches(".*[^A-Za-z0-9].*"))) {
            throw ApiException.badRequest("WEAK_PASSWORD", "Needs an uppercase letter, a number and a symbol");
        }
    }

    private String payload(Object value) {
        try {
            return mapper.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private Map<String, Object> issueOtp(String phone, String purpose, Object payload) {
        Map<String, Object> recent = db.one(
                "SELECT 1 FROM otp_codes WHERE phone = ? AND purpose = ?::otp_purpose AND created_at > now() - interval '30 seconds'",
                phone, purpose);
        if (recent != null) {
            throw new ApiException(429, "OTP_TOO_SOON", "Please wait 30 seconds before requesting another code");
        }
        String code = Crypto.numericCode(6);
        db.update("INSERT INTO otp_codes (phone, purpose, code_hash, payload, expires_at) VALUES (?, ?::otp_purpose, ?, ?::jsonb, now() + make_interval(secs => ?))",
                phone, purpose, Crypto.sha256(phone + ":" + code), payload == null ? null : payload(payload), props.otpTtlSeconds());
        log.info("[sms:log] {} is your VP Nexues verification code. It expires in {} minutes.",
                phone.substring(0, phone.length() - 4).replaceAll("\\d", "•") + phone.substring(phone.length() - 4),
                Math.round(props.otpTtlSeconds() / 60.0));
        return Json.map(
                "sent", true,
                "expiresIn", props.otpTtlSeconds(),
                "devCode", props.otpDevEcho() ? code : null);
    }

    private String consumeOtp(String phone, String purpose, String code) {
        Map<String, Object> row = db.one(
                "SELECT id, code_hash, attempts, expires_at < now() AS expired, payload::text AS payload FROM otp_codes " +
                        "WHERE phone = ? AND purpose = ?::otp_purpose AND consumed_at IS NULL ORDER BY created_at DESC LIMIT 1 FOR UPDATE",
                phone, purpose);
        if (row == null) throw ApiException.badRequest("OTP_NOT_FOUND", "Request a new code first");
        if (Boolean.TRUE.equals(row.get("expired"))) throw ApiException.badRequest("OTP_EXPIRED", "This code has expired. Request a new one");
        int attempts = ((Number) row.get("attempts")).intValue();
        if (attempts >= props.otpMaxAttempts()) {
            throw new ApiException(429, "OTP_LOCKED", "Too many wrong attempts. Request a new code");
        }
        if (!Crypto.sameHash(String.valueOf(row.get("codeHash")), Crypto.sha256(phone + ":" + code))) {
            db.update("UPDATE otp_codes SET attempts = attempts + 1 WHERE id = ?", row.get("id"));
            throw ApiException.badRequest("OTP_INVALID", "That code is not correct");
        }
        db.update("UPDATE otp_codes SET consumed_at = now() WHERE id = ?", row.get("id"));
        return (String) row.get("payload");
    }

    private <T> T withOtp(String rawPhone, String purpose, String code, Function<String, T> fn) {
        String phone = normalizePhone(rawPhone);
        if (code == null || !code.matches("^\\d{6}$")) {
            throw ApiException.badRequest("INVALID_CODE", "Enter the 6-digit code");
        }
        AtomicReference<ApiException> deferred = new AtomicReference<>();
        T out = db.inTx(() -> {
            try {
                return fn.apply(consumeOtp(phone, purpose, code));
            } catch (ApiException e) {
                if ("OTP_INVALID".equals(e.code())) {
                    deferred.set(e);
                    return null;
                }
                throw e;
            }
        });
        if (deferred.get() != null) throw deferred.get();
        return out;
    }

    public Map<String, Object> issueTokens(String partnerId) {
        String refreshToken = Crypto.opaqueToken();
        db.update("INSERT INTO sessions (partner_id, refresh_token_hash, expires_at) VALUES (?, ?, now() + make_interval(days => ?))",
                partnerId, Crypto.sha256(refreshToken), props.refreshTokenTtlDays());
        String accessToken = jwt.issueAccess(partnerId);
        return Json.map(
                "accessToken", accessToken,
                "refreshToken", refreshToken,
                "tokenType", "Bearer",
                "expiresIn", props.accessTokenTtlSeconds());
    }

    // ---------------- sign-up ----------------

    public Map<String, Object> signupStart(Dtos.SignupStart b) {
        String fullName = b.fullName().trim();
        if (fullName.length() < 2 || fullName.length() > 80) {
            throw ApiException.badRequest("INVALID_NAME", "Enter your full name");
        }
        if (!VEHICLES.contains(b.vehicleType())) {
            throw ApiException.badRequest("INVALID_VEHICLE", "Choose a valid vehicle type");
        }
        if (!Boolean.TRUE.equals(b.acceptedTerms())) {
            throw ApiException.badRequest("TERMS_REQUIRED", "You must accept the partner terms");
        }
        String phone = normalizePhone(b.phone());
        if (db.one("SELECT 1 FROM partners WHERE phone = ?", phone) != null) {
            throw ApiException.conflict("PHONE_TAKEN", "This number already has an account. Log in instead");
        }
        if (db.one("SELECT 1 FROM cities WHERE id = ? AND is_active", b.cityId()) == null) {
            throw ApiException.badRequest("CITY_UNAVAILABLE", "We are not in this city yet");
        }
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("fullName", fullName);
        payload.put("phone", phone);
        payload.put("cityId", b.cityId());
        payload.put("vehicleType", b.vehicleType());
        payload.put("referralCode", b.referralCode() == null ? null : b.referralCode().trim());
        return issueOtp(phone, "signup", payload);
    }

    public Map<String, Object> signupVerify(Dtos.SignupVerify b) {
        return withOtp(b.phone(), "signup", b.code(), payloadJson -> {
            JsonNode p;
            try {
                p = mapper.readTree(payloadJson);
            } catch (Exception e) {
                throw new IllegalStateException(e);
            }
            String fullName = p.path("fullName").asText();
            String phone = p.path("phone").asText();
            int cityId = p.path("cityId").asInt();
            String vehicleType = p.path("vehicleType").asText();
            String referralCode = p.hasNonNull("referralCode") ? p.get("referralCode").asText() : null;

            String referredById = null;
            if (referralCode != null && !referralCode.isBlank()) {
                Map<String, Object> referrer = db.one("SELECT id FROM partners WHERE upper(referral_code) = upper(?)", referralCode);
                if (referrer != null) referredById = String.valueOf(referrer.get("id"));
            }
            Map<String, Object> hub = db.one("SELECT id FROM hubs WHERE city_id = ? AND is_active ORDER BY created_at LIMIT 1", cityId);
            String hubId = hub == null ? null : String.valueOf(hub.get("id"));

            String letters = fullName.replaceAll("[^A-Za-z]", "");
            if (letters.length() < 2) letters = "VPNP";
            String ref = letters.substring(0, Math.min(4, letters.length())).toUpperCase()
                    + "-" + UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase();

            Map<String, Object> partner = db.one(
                    "INSERT INTO partners (partner_code, full_name, phone, phone_verified_at, city_id, hub_id, vehicle_type, referral_code, referred_by_id) " +
                            "VALUES ('VPN-P-' || nextval('partner_code_seq'), ?, ?, now(), ?, ?, ?::vehicle_type, ?, ?) RETURNING id, partner_code",
                    fullName, phone, cityId, hubId, vehicleType, ref, referredById);
            db.update("INSERT INTO partner_settings (partner_id) VALUES (?)", partner.get("id"));

            Map<String, Object> out = new LinkedHashMap<>();
            out.put("partnerId", partner.get("id"));
            out.put("partnerCode", partner.get("partnerCode"));
            out.putAll(issueTokens(String.valueOf(partner.get("id"))));
            out.put("next", "set_password");
            return out;
        });
    }

    public Map<String, Object> setPassword(Dtos.PasswordBody b) {
        validatePassword(b.password());
        db.update("UPDATE partners SET password_hash = ? WHERE id = ?",
                encoder.encode(b.password()), current.partnerId());
        return Json.map("ok", true);
    }

    // ---------------- login ----------------

    public Map<String, Object> login(Dtos.LoginBody b) {
        String phone = normalizePhone(b.phone());
        Map<String, Object> p = db.one("SELECT id, password_hash, status FROM partners WHERE phone = ?", phone);
        String hash = p == null || p.get("passwordHash") == null ? dummyHash : String.valueOf(p.get("passwordHash"));
        boolean ok = encoder.matches(b.password(), hash);
        if (p == null || !ok) {
            throw new ApiException(401, "BAD_CREDENTIALS", "Phone number or password is incorrect");
        }
        String status = String.valueOf(p.get("status"));
        if ("suspended".equals(status) || "deactivated".equals(status)) {
            throw ApiException.forbidden("ACCOUNT_BLOCKED", "Your account is not active. Contact support");
        }
        return issueTokens(String.valueOf(p.get("id")));
    }

    public Map<String, Object> loginOtpStart(Dtos.PhoneBody b) {
        String phone = normalizePhone(b.phone());
        if (db.one("SELECT 1 FROM partners WHERE phone = ?", phone) == null) {
            throw ApiException.notFound("Account");
        }
        return issueOtp(phone, "login", null);
    }

    public Map<String, Object> loginOtpVerify(Dtos.SignupVerify b) {
        return withOtp(b.phone(), "login", b.code(), payload -> {
            Map<String, Object> p = db.one("SELECT id FROM partners WHERE phone = ?", normalizePhone(b.phone()));
            if (p == null) throw ApiException.notFound("Account");
            return issueTokens(String.valueOf(p.get("id")));
        });
    }

    // ---------------- password reset ----------------

    public Map<String, Object> passwordResetStart(Dtos.PhoneBody b) {
        String phone = normalizePhone(b.phone());
        if (db.one("SELECT 1 FROM partners WHERE phone = ?", phone) != null) {
            return issueOtp(phone, "password_reset", null);
        }
        return Json.map("sent", true, "expiresIn", props.otpTtlSeconds());
    }

    public Map<String, Object> passwordResetVerify(Dtos.ResetVerify b) {
        validatePassword(b.password());
        String hash = encoder.encode(b.password());
        withOtp(b.phone(), "password_reset", b.code(), payload -> {
            Map<String, Object> p = db.one("UPDATE partners SET password_hash = ? WHERE phone = ? RETURNING id", hash, normalizePhone(b.phone()));
            if (p != null) {
                db.update("UPDATE sessions SET revoked_at = now() WHERE partner_id = ? AND revoked_at IS NULL", p.get("id"));
            }
            return true;
        });
        return Json.map("ok", true);
    }

    // ---------------- session ----------------

    public Map<String, Object> refresh(Dtos.RefreshBody b) {
        Map<String, Object> out = db.inTx(() -> {
            Map<String, Object> s = db.one(
                    "SELECT id, partner_id, revoked_at IS NOT NULL AS revoked, expires_at < now() AS expired FROM sessions " +
                            "WHERE refresh_token_hash = ? FOR UPDATE",
                    Crypto.sha256(b.refreshToken()));
            if (s == null) throw ApiException.unauthorized("Sign in again to continue");
            if (Boolean.TRUE.equals(s.get("revoked"))) {
                db.update("UPDATE sessions SET revoked_at = now() WHERE partner_id = ? AND revoked_at IS NULL", s.get("partnerId"));
                return null;
            }
            if (Boolean.TRUE.equals(s.get("expired"))) throw ApiException.unauthorized("Session expired. Sign in again");
            db.update("UPDATE sessions SET revoked_at = now(), last_used_at = now() WHERE id = ?", s.get("id"));
            return issueTokens(String.valueOf(s.get("partnerId")));
        });
        if (out == null) throw ApiException.unauthorized("Sign in again to continue");
        return out;
    }

    public Map<String, Object> logout(Dtos.RefreshBody b) {
        db.update("UPDATE sessions SET revoked_at = now() WHERE refresh_token_hash = ? AND revoked_at IS NULL",
                Crypto.sha256(b.refreshToken()));
        return Json.map("ok", true);
    }
}
