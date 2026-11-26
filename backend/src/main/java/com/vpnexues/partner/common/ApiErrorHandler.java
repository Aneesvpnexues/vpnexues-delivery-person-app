package com.vpnexues.partner.common;

import jakarta.validation.ConstraintViolationException;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestControllerAdvice
public class ApiErrorHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<Map<String, Object>> api(ApiException e) {
        Map<String, Object> error = new LinkedHashMap<>();
        error.put("code", e.code());
        error.put("message", e.getMessage());
        if (e.details() != null) error.put("details", e.details());
        return ResponseEntity.status(e.status()).body(Map.of("error", error));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> validation(MethodArgumentNotValidException e) {
        List<Map<String, String>> details = e.getBindingResult().getFieldErrors().stream()
                .map(f -> Map.of("field", f.getField(), "message", f.getDefaultMessage() == null ? "Invalid value" : f.getDefaultMessage()))
                .toList();
        return ResponseEntity.badRequest().body(Map.of("error", Map.of(
                "code", "VALIDATION_FAILED",
                "message", "Some fields are invalid",
                "details", details)));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, Object>> constraint(ConstraintViolationException e) {
        return ResponseEntity.badRequest().body(Map.of("error", Map.of(
                "code", "VALIDATION_FAILED",
                "message", "Some fields are invalid")));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> unreadable(HttpMessageNotReadableException e) {
        return ResponseEntity.badRequest().body(Map.of("error", Map.of(
                "code", "INVALID_BODY",
                "message", "Request body is not valid JSON")));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, Object>> integrity(DataIntegrityViolationException e) {
        String msg = String.valueOf(e.getMostSpecificCause().getMessage());
        if (msg.contains("23505") || msg.toLowerCase().contains("duplicate key")) {
            return ResponseEntity.status(409).body(Map.of("error", Map.of(
                    "code", "ALREADY_EXISTS",
                    "message", "A record with these details already exists")));
        }
        return ResponseEntity.badRequest().body(Map.of("error", Map.of(
                "code", "INVALID_DATA",
                "message", "The request conflicts with existing data")));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<Map<String, Object>> notFound(NoResourceFoundException e) {
        return ResponseEntity.status(404).body(Map.of("error", Map.of(
                "code", "ROUTE_NOT_FOUND",
                "message", "This endpoint does not exist")));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String, Object>> typeMismatch(MethodArgumentTypeMismatchException e) {
        return ResponseEntity.badRequest().body(Map.of("error", Map.of(
                "code", "INVALID_PARAMETER",
                "message", "A request parameter has an invalid value")));
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, Object>> missingParameter(MissingServletRequestParameterException e) {
        return ResponseEntity.badRequest().body(Map.of("error", Map.of(
                "code", "MISSING_PARAMETER",
                "message", "A required request parameter is missing")));
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<Map<String, Object>> unsupportedMediaType(HttpMediaTypeNotSupportedException e) {
        return ResponseEntity.status(415).body(Map.of("error", Map.of(
                "code", "UNSUPPORTED_MEDIA_TYPE",
                "message", "Send a JSON request body")));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<Map<String, Object>> methodNotAllowed(HttpRequestMethodNotSupportedException e) {
        return ResponseEntity.status(405).body(Map.of("error", Map.of(
                "code", "METHOD_NOT_ALLOWED",
                "message", "This method is not allowed here")));
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, Object>> database(DataAccessException e) {
        return ResponseEntity.status(503).body(Map.of("error", Map.of(
                "code", "DATABASE_UNAVAILABLE",
                "message", "The service is temporarily unavailable")));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> generic(Exception e) {
        return ResponseEntity.status(500).body(Map.of("error", Map.of(
                "code", "INTERNAL",
                "message", "Something went wrong")));
    }
}
