package com.vpnexues.partner.common;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

class ApiErrorHandlerTest {

    private final ApiErrorHandler handler = new ApiErrorHandler();

    @SuppressWarnings("unchecked")
    private static Map<String, Object> error(ResponseEntity<Map<String, Object>> response) {
        return (Map<String, Object>) response.getBody().get("error");
    }

    @Test
    void genericErrorsNeverExposeExceptionText() {
        ResponseEntity<Map<String, Object>> response = handler.generic(new RuntimeException("secret db password"));
        assertEquals(500, response.getStatusCode().value());
        assertEquals("INTERNAL", error(response).get("code"));
        assertFalse(String.valueOf(response.getBody()).contains("secret"));
    }

    @Test
    void databaseFailuresReturnSafeServiceUnavailable() {
        ResponseEntity<Map<String, Object>> response = handler.database(
                new DataAccessResourceFailureException("select password from users"));
        assertEquals(503, response.getStatusCode().value());
        assertEquals("DATABASE_UNAVAILABLE", error(response).get("code"));
        assertFalse(String.valueOf(response.getBody()).contains("password"));
    }

    @Test
    void integrityFailuresDoNotLeakConstraintNames() {
        ResponseEntity<Map<String, Object>> response = handler.integrity(
                new DataIntegrityViolationException("duplicate key value violates unique constraint users_email_key"));
        assertEquals(409, response.getStatusCode().value());
        assertEquals("ALREADY_EXISTS", error(response).get("code"));
        assertFalse(String.valueOf(response.getBody()).contains("users_email_key"));
    }

    @Test
    void malformedRequestsReturnClientErrors() {
        ResponseEntity<Map<String, Object>> body = handler.unreadable(
                new HttpMessageNotReadableException("broken json", (HttpInputMessage) null));
        assertEquals(400, body.getStatusCode().value());
        assertEquals("INVALID_BODY", error(body).get("code"));

        ResponseEntity<Map<String, Object>> parameter = handler.typeMismatch(
                new MethodArgumentTypeMismatchException("x", Integer.class, "limit", null,
                        new IllegalArgumentException("nope")));
        assertEquals(400, parameter.getStatusCode().value());
        assertEquals("INVALID_PARAMETER", error(parameter).get("code"));
        assertFalse(String.valueOf(parameter.getBody()).contains("nope"));
    }
}
