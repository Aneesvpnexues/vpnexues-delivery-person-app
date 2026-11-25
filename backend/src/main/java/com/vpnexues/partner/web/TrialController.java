package com.vpnexues.partner.web;

import com.vpnexues.partner.service.TrialService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/v1")
public class TrialController {
    private final TrialService service;

    public TrialController(TrialService service) {
        this.service = service;
    }

    @PostMapping("/demo-order")
    public ResponseEntity<Map<String, Object>> demoOrder() {
        return ResponseEntity.status(201).body(service.createDemoOrder());
    }
}
