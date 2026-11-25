package com.vpnexues.partner.web;

import com.vpnexues.partner.service.PartnerService;
import com.vpnexues.partner.web.dto.Dtos;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/me")
public class PartnerController {
    private final PartnerService service;

    public PartnerController(PartnerService service) {
        this.service = service;
    }

    @GetMapping
    public Map<String, Object> me() {
        return service.me();
    }

    @PatchMapping
    public Map<String, Object> update(@Valid @RequestBody Dtos.UpdateMe body) {
        return service.updateMe(body);
    }

    @PutMapping("/online")
    public Map<String, Object> online(@Valid @RequestBody Dtos.OnlineBody body) {
        return service.setOnline(body);
    }

    @GetMapping("/settings")
    public Map<String, Object> settings() {
        return service.settings();
    }

    @PatchMapping("/settings")
    public Map<String, Object> patchSettings(@Valid @RequestBody Dtos.SettingsBody body) {
        return service.patchSettings(body);
    }

    @GetMapping("/zone")
    public Map<String, Object> zone() {
        return service.zone();
    }

    @PutMapping("/zone/radius")
    public Map<String, Object> radius(@Valid @RequestBody Dtos.RadiusBody body) {
        return service.setRadius(body);
    }

    @PostMapping("/zone/change-request")
    public ResponseEntity<Map<String, Object>> changeRequest(@Valid @RequestBody Dtos.ChangeRequest body) {
        return ResponseEntity.status(201).body(service.changeRequest(body));
    }

    @PostMapping("/devices")
    public Map<String, Object> device(@Valid @RequestBody Dtos.DeviceBody body) {
        return service.registerDevice(body);
    }
}
