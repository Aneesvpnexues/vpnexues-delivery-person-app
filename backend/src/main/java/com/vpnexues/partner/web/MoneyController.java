package com.vpnexues.partner.web;

import com.vpnexues.partner.service.MoneyService;
import com.vpnexues.partner.web.dto.Dtos;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1")
public class MoneyController {
    private final MoneyService service;

    public MoneyController(MoneyService service) {
        this.service = service;
    }

    @GetMapping("/payout-methods")
    public List<Map<String, Object>> methods() {
        return service.payoutMethods();
    }

    @PostMapping("/payout-methods")
    public ResponseEntity<Map<String, Object>> add(@Valid @RequestBody Dtos.PayoutMethodBody body) {
        return ResponseEntity.status(201).body(service.addPayoutMethod(body));
    }

    @PutMapping("/payout-methods/{id}/primary")
    public Map<String, Object> primary(@PathVariable String id) {
        return service.makePrimary(id);
    }

    @DeleteMapping("/payout-methods/{id}")
    public Map<String, Object> delete(@PathVariable String id) {
        return service.deletePayoutMethod(id);
    }

    @GetMapping("/earnings/summary")
    public Map<String, Object> earnings(@RequestParam(defaultValue = "today") String range) {
        return service.earnings(range);
    }

    @GetMapping("/transactions")
    public Map<String, Object> transactions(@RequestParam(defaultValue = "all") String filter,
                                            @RequestParam(required = false) String search,
                                            @RequestParam(required = false) Long before,
                                            @RequestParam(defaultValue = "30") int limit) {
        return service.transactions(filter, search, before, limit);
    }

    @GetMapping("/payouts")
    public List<Map<String, Object>> payouts() {
        return service.payouts();
    }

    @PostMapping("/payouts/instant")
    public ResponseEntity<Map<String, Object>> instant(@Valid @RequestBody Dtos.InstantPayout body,
                                                       @RequestHeader(value = "Idempotency-Key", required = false) String idem) {
        return ResponseEntity.status(201).body(service.instantPayout(body, idem));
    }
}
