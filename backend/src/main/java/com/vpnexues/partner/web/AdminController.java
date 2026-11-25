package com.vpnexues.partner.web;

import com.vpnexues.partner.security.CurrentUser;
import com.vpnexues.partner.service.AdminService;
import com.vpnexues.partner.web.dto.Dtos;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin")
public class AdminController {
    private final AdminService service;
    private final CurrentUser current;

    public AdminController(AdminService service, CurrentUser current) {
        this.service = service;
        this.current = current;
    }

    @PostMapping("/auth/login")
    public Map<String, Object> login(@Valid @RequestBody Dtos.AdminLogin body) {
        return service.login(body);
    }

    @GetMapping("/me")
    public Map<String, Object> me() {
        return service.me();
    }

    @PostMapping("/auth/password")
    public Map<String, Object> changePassword(@Valid @RequestBody Dtos.AdminPassword body) {
        return service.changePassword(body);
    }

    @GetMapping("/lookups")
    public Map<String, Object> lookups() {
        return service.lookups();
    }

    @GetMapping("/overview")
    public Map<String, Object> overview() {
        return service.overview();
    }

    @GetMapping("/partners")
    public List<Map<String, Object>> partners(@RequestParam(required = false) String search,
                                              @RequestParam(required = false) String status,
                                              @RequestParam(required = false) String kycStatus,
                                              @RequestParam(required = false) Integer cityId,
                                              @RequestParam(defaultValue = "50") int limit) {
        return service.partners(search, status, kycStatus, cityId, limit);
    }

    @GetMapping("/partners/{id}")
    public Map<String, Object> partner(@PathVariable String id) {
        return service.partner(id);
    }

    @PatchMapping("/partners/{id}")
    public Map<String, Object> patchPartner(@PathVariable String id, @RequestBody Dtos.PartnerPatch body) {
        current.requireRole(current.admin(), "ops");
        return service.patchPartner(id, body);
    }

    @GetMapping("/documents")
    public List<Map<String, Object>> documents(@RequestParam(defaultValue = "in_review") String status) {
        return service.documentQueue(status);
    }

    @PostMapping("/documents/{id}/review")
    public Map<String, Object> review(@PathVariable String id, @Valid @RequestBody Dtos.DocReview body) {
        current.requireRole(current.admin(), "ops");
        return service.reviewDocument(id, body);
    }

    @GetMapping("/orders")
    public List<Map<String, Object>> orders(@RequestParam(required = false) String status,
                                            @RequestParam(required = false) String search,
                                            @RequestParam(defaultValue = "50") int limit) {
        return service.orders(status, search, limit);
    }

    @PostMapping("/orders")
    public ResponseEntity<Map<String, Object>> createOrder(@RequestBody Dtos.OrderCreate body) {
        current.requireRole(current.admin(), "ops");
        return ResponseEntity.status(201).body(service.createOrder(body));
    }

    @PostMapping("/orders/{id}/assign")
    public Map<String, Object> assign(@PathVariable String id, @Valid @RequestBody Dtos.AssignBody body) {
        current.requireRole(current.admin(), "ops");
        return service.assignOrder(id, body);
    }

    @PostMapping("/orders/{id}/cancel")
    public Map<String, Object> cancel(@PathVariable String id, @Valid @RequestBody Dtos.CancelBody body) {
        current.requireRole(current.admin(), "ops");
        return service.cancelOrder(id, body);
    }

    @GetMapping("/payouts")
    public List<Map<String, Object>> payouts(@RequestParam(required = false) String status) {
        return service.payouts(status);
    }

    @PostMapping("/payouts/{id}/status")
    public Map<String, Object> payoutStatus(@PathVariable String id, @Valid @RequestBody Dtos.PayoutStatusBody body) {
        current.requireRole(current.admin(), "ops");
        return service.payoutStatus(id, body);
    }

    @GetMapping("/payout-methods")
    public List<Map<String, Object>> payoutMethods(@RequestParam(defaultValue = "pending") String verification) {
        return service.payoutMethodQueue(verification);
    }

    @PostMapping("/payout-methods/{id}/verify")
    public Map<String, Object> verifyPayoutMethod(@PathVariable String id, @Valid @RequestBody Dtos.VerificationBody body) {
        current.requireRole(current.admin(), "ops");
        return service.verifyPayoutMethod(id, body);
    }

    @GetMapping("/tickets")
    public List<Map<String, Object>> tickets(@RequestParam(required = false) String status) {
        return service.tickets(status);
    }

    @GetMapping("/tickets/{id}")
    public Map<String, Object> ticket(@PathVariable String id) {
        return service.ticket(id);
    }

    @PostMapping("/tickets/{id}/status")
    public Map<String, Object> ticketStatus(@PathVariable String id, @Valid @RequestBody Dtos.TicketStatusBody body) {
        return service.ticketStatus(id, body);
    }

    @PostMapping("/tickets/{id}/messages")
    public ResponseEntity<Map<String, Object>> reply(@PathVariable String id, @Valid @RequestBody Dtos.MessageBody body) {
        return ResponseEntity.status(201).body(service.replyTicket(id, body));
    }

    @GetMapping("/sos")
    public List<Map<String, Object>> sos(@RequestParam(required = false) String status) {
        return service.sos(status);
    }

    @PostMapping("/sos/{id}/status")
    public Map<String, Object> sosStatus(@PathVariable String id, @Valid @RequestBody Dtos.SosStatusBody body) {
        return service.sosStatus(id, body);
    }

    @GetMapping("/zone-requests")
    public List<Map<String, Object>> zoneRequests(@RequestParam(defaultValue = "pending") String status) {
        return service.zoneRequests(status);
    }

    @PostMapping("/zone-requests/{id}/decide")
    public Map<String, Object> decideZone(@PathVariable String id, @Valid @RequestBody Dtos.ZoneDecision body) {
        current.requireRole(current.admin(), "ops");
        return service.decideZoneRequest(id, body);
    }

    @GetMapping("/audit")
    public List<Map<String, Object>> audit(@RequestParam(required = false) String entity,
                                           @RequestParam(required = false) String entityId,
                                           @RequestParam(defaultValue = "100") int limit) {
        return service.auditLog(entity, entityId, limit);
    }

    @GetMapping("/staff")
    public List<Map<String, Object>> staff() {
        current.requireRole(current.admin());
        return service.staff();
    }

    @PostMapping("/staff")
    public ResponseEntity<Map<String, Object>> createStaff(@Valid @RequestBody Dtos.StaffCreate body) {
        current.requireRole(current.admin());
        return ResponseEntity.status(201).body(service.createStaff(body));
    }

    @PatchMapping("/staff/{id}")
    public Map<String, Object> patchStaff(@PathVariable String id, @RequestBody Dtos.StaffPatch body) {
        current.requireRole(current.admin());
        return service.patchStaff(id, body);
    }
}
