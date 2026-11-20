package com.vpnexues.partner.common;

/**
 * Application error with an HTTP status and a stable machine-readable code.
 * Serialized as {@code {"error":{"code","message","details"}}}.
 */
public class ApiException extends RuntimeException {
    private final int status;
    private final String code;
    private final Object details;

    public ApiException(int status, String code, String message) {
        this(status, code, message, null);
    }

    public ApiException(int status, String code, String message, Object details) {
        super(message);
        this.status = status;
        this.code = code;
        this.details = details;
    }

    public int status() { return status; }
    public String code() { return code; }
    public Object details() { return details; }

    public static ApiException notFound(String what) {
        return new ApiException(404, "NOT_FOUND", what + " not found");
    }

    public static ApiException badRequest(String code, String message) {
        return new ApiException(400, code, message);
    }

    public static ApiException conflict(String code, String message) {
        return new ApiException(409, code, message);
    }

    public static ApiException unauthorized(String message) {
        return new ApiException(401, "UNAUTHENTICATED", message);
    }

    public static ApiException forbidden(String code, String message) {
        return new ApiException(403, code, message);
    }
}
