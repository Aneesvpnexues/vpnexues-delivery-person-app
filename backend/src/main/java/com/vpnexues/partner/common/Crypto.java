package com.vpnexues.partner.common;

import com.vpnexues.partner.config.AppProperties;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/** Hashing, one-time codes, opaque tokens and AES-256-GCM for bank account numbers. */
@Component
public class Crypto {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int GCM_TAG_BITS = 128;
    private final SecretKeySpec dataKey;

    public Crypto(AppProperties props) {
        try {
            this.dataKey = new SecretKeySpec(
                    MessageDigest.getInstance("SHA-256").digest(props.jwtSecret().getBytes(StandardCharsets.UTF_8)),
                    "AES");
        } catch (Exception e) {
            throw new IllegalStateException("Unable to initialise encryption key", e);
        }
    }

    public static String sha256(String s) {
        try {
            byte[] d = MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(d.length * 2);
            for (byte b : d) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    public static boolean sameHash(String a, String b) {
        if (a == null || b == null) return false;
        return MessageDigest.isEqual(a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8));
    }

    public static String numericCode(int digits) {
        StringBuilder sb = new StringBuilder(digits);
        for (int i = 0; i < digits; i++) sb.append(RANDOM.nextInt(10));
        return sb.toString();
    }

    public static String opaqueToken() {
        byte[] b = new byte[32];
        RANDOM.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    /** Output: base64(iv | tag | ciphertext). */
    public String encrypt(String plain) {
        try {
            byte[] iv = new byte[12];
            RANDOM.nextBytes(iv);
            Cipher c = Cipher.getInstance("AES/GCM/NoPadding");
            c.init(Cipher.ENCRYPT_MODE, dataKey, new GCMParameterSpec(GCM_TAG_BITS, iv));
            byte[] enc = c.doFinal(plain.getBytes(StandardCharsets.UTF_8));
            byte[] out = new byte[iv.length + 16 + enc.length];
            System.arraycopy(iv, 0, out, 0, 12);
            byte[] tag = java.util.Arrays.copyOfRange(enc, enc.length - 16, enc.length);
            byte[] body = java.util.Arrays.copyOfRange(enc, 0, enc.length - 16);
            System.arraycopy(tag, 0, out, 12, 16);
            System.arraycopy(body, 0, out, 28, body.length);
            return Base64.getEncoder().encodeToString(out);
        } catch (Exception e) {
            throw new IllegalStateException("encrypt failed", e);
        }
    }

    public String decrypt(String blob) {
        try {
            byte[] b = Base64.getDecoder().decode(blob);
            byte[] iv = java.util.Arrays.copyOfRange(b, 0, 12);
            byte[] tag = java.util.Arrays.copyOfRange(b, 12, 28);
            byte[] body = java.util.Arrays.copyOfRange(b, 28, b.length);
            Cipher c = Cipher.getInstance("AES/GCM/NoPadding");
            c.init(Cipher.DECRYPT_MODE, dataKey, new GCMParameterSpec(GCM_TAG_BITS, iv));
            byte[] joined = new byte[body.length + tag.length];
            System.arraycopy(body, 0, joined, 0, body.length);
            System.arraycopy(tag, 0, joined, body.length, tag.length);
            return new String(c.doFinal(joined), StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("decrypt failed", e);
        }
    }
}
