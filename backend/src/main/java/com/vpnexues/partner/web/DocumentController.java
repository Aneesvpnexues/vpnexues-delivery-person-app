package com.vpnexues.partner.web;

import com.vpnexues.partner.service.DocumentService;
import com.vpnexues.partner.web.dto.Dtos;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1")
public class DocumentController {
    private final DocumentService service;

    public DocumentController(DocumentService service) {
        this.service = service;
    }

    @GetMapping("/documents")
    public Map<String, Object> list() {
        return service.list();
    }

    @PostMapping("/documents/{type}/upload-url")
    public Map<String, Object> uploadUrl(@PathVariable String type, @Valid @RequestBody Dtos.UploadUrlBody body) {
        return service.uploadUrl(type, body);
    }

    @PutMapping("/documents/upload")
    public Map<String, Object> upload(@RequestParam String key, @RequestBody byte[] body) {
        return service.storeUpload(key, body);
    }

    @PostMapping("/documents/{type}/submit")
    public ResponseEntity<Map<String, Object>> submit(@PathVariable String type, @Valid @RequestBody Dtos.SubmitDoc body) {
        return ResponseEntity.status(201).body(service.submit(type, body));
    }

    @GetMapping("/vehicle")
    public Map<String, Object> vehicle() {
        return service.vehicle();
    }

    @PutMapping("/vehicle")
    public Map<String, Object> saveVehicle(@Valid @RequestBody Dtos.VehicleBody body) {
        return service.saveVehicle(body);
    }
}
