package com.vpnexues.partner.web;

import com.vpnexues.partner.service.AuthService;
import com.vpnexues.partner.web.dto.Dtos;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/auth")
public class AuthController {
    private final AuthService service;

    public AuthController(AuthService service) {
        this.service = service;
    }

    @PostMapping("/signup/start")
    public Map<String, Object> signupStart(@Valid @RequestBody Dtos.SignupStart body) {
        return service.signupStart(body);
    }

    @PostMapping("/signup/verify")
    public ResponseEntity<Map<String, Object>> signupVerify(@Valid @RequestBody Dtos.SignupVerify body) {
        return ResponseEntity.status(201).body(service.signupVerify(body));
    }

    @PostMapping("/password")
    public Map<String, Object> setPassword(@Valid @RequestBody Dtos.PasswordBody body) {
        return service.setPassword(body);
    }

    @PostMapping("/login")
    public Map<String, Object> login(@Valid @RequestBody Dtos.LoginBody body) {
        return service.login(body);
    }

    @PostMapping("/login/otp/start")
    public Map<String, Object> loginOtpStart(@Valid @RequestBody Dtos.PhoneBody body) {
        return service.loginOtpStart(body);
    }

    @PostMapping("/login/otp/verify")
    public Map<String, Object> loginOtpVerify(@Valid @RequestBody Dtos.SignupVerify body) {
        return service.loginOtpVerify(body);
    }

    @PostMapping("/password/reset/start")
    public Map<String, Object> passwordResetStart(@Valid @RequestBody Dtos.PhoneBody body) {
        return service.passwordResetStart(body);
    }

    @PostMapping("/password/reset/verify")
    public Map<String, Object> passwordResetVerify(@Valid @RequestBody Dtos.ResetVerify body) {
        return service.passwordResetVerify(body);
    }

    @PostMapping("/refresh")
    public Map<String, Object> refresh(@Valid @RequestBody Dtos.RefreshBody body) {
        return service.refresh(body);
    }

    @PostMapping("/logout")
    public Map<String, Object> logout(@Valid @RequestBody Dtos.RefreshBody body) {
        return service.logout(body);
    }
}
