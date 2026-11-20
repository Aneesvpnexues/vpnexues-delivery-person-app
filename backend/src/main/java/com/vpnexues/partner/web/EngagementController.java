package com.vpnexues.partner.web;

import com.vpnexues.partner.service.EngagementService;
import com.vpnexues.partner.web.dto.Dtos;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1")
public class EngagementController {
    private final EngagementService service;

    public EngagementController(EngagementService service) {
        this.service = service;
    }

    @GetMapping("/notifications")
    public Map<String, Object> notifications(@RequestParam(defaultValue = "50") int limit) {
        return service.notifications(limit);
    }

    @PostMapping("/notifications/read")
    public Map<String, Object> readAll() {
        return service.readAllNotifications();
    }

    @PostMapping("/notifications/{id}/read")
    public Map<String, Object> read(@PathVariable String id) {
        return service.readNotification(id);
    }

    @GetMapping("/support/tickets")
    public List<Map<String, Object>> tickets() {
        return service.tickets();
    }

    @PostMapping("/support/tickets")
    public ResponseEntity<Map<String, Object>> create(@Valid @RequestBody Dtos.TicketBody body) {
        return ResponseEntity.status(201).body(service.createTicket(body));
    }

    @GetMapping("/support/tickets/{id}")
    public Map<String, Object> ticket(@PathVariable String id) {
        return service.ticket(id);
    }

    @PostMapping("/support/tickets/{id}/messages")
    public ResponseEntity<Map<String, Object>> message(@PathVariable String id, @Valid @RequestBody Dtos.MessageBody body) {
        return ResponseEntity.status(201).body(service.addMessage(id, body));
    }

    @PostMapping("/sos")
    public ResponseEntity<Map<String, Object>> sos(@Valid @RequestBody Dtos.SosBody body) {
        return ResponseEntity.status(201).body(service.sos(body));
    }

    @GetMapping("/emergency-contacts")
    public List<Map<String, Object>> contacts() {
        return service.contacts();
    }

    @PostMapping("/emergency-contacts")
    public ResponseEntity<Map<String, Object>> addContact(@Valid @RequestBody Dtos.ContactBody body) {
        return ResponseEntity.status(201).body(service.addContact(body));
    }

    @DeleteMapping("/emergency-contacts/{id}")
    public Map<String, Object> deleteContact(@PathVariable String id) {
        return service.deleteContact(id);
    }

    @PostMapping("/app-ratings")
    public ResponseEntity<Map<String, Object>> rate(@Valid @RequestBody Dtos.RatingBody body) {
        return ResponseEntity.status(201).body(service.rate(body));
    }
}
