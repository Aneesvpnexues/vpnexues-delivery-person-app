package com.vpnexues.partner.web;

import com.vpnexues.partner.service.OrderService;
import com.vpnexues.partner.web.dto.Dtos;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/orders")
public class OrderController {
    private final OrderService service;

    public OrderController(OrderService service) {
        this.service = service;
    }

    @GetMapping
    public List<Map<String, Object>> list(@RequestParam(defaultValue = "active") String tab,
                                          @RequestParam(defaultValue = "today") String range,
                                          @RequestParam(defaultValue = "30") int limit) {
        return service.list(tab, range, limit);
    }

    @GetMapping("/{id}")
    public Map<String, Object> detail(@PathVariable String id) {
        return service.detail(id);
    }

    @PostMapping("/{id}/accept")
    public Map<String, Object> accept(@PathVariable String id) {
        return service.accept(id);
    }

    @PostMapping("/{id}/at-pickup")
    public Map<String, Object> atPickup(@PathVariable String id, @RequestBody(required = false) Dtos.LocBody body) {
        return service.atPickup(id, body == null ? new Dtos.LocBody(null, null) : body);
    }

    @PostMapping("/{id}/crates/scan")
    public Map<String, Object> scan(@PathVariable String id, @Valid @RequestBody Dtos.ScanBody body) {
        return service.scanCrate(id, body);
    }

    @PostMapping("/{id}/pickup")
    public Map<String, Object> pickup(@PathVariable String id, @RequestBody(required = false) Dtos.LocBody body) {
        return service.pickup(id, body == null ? new Dtos.LocBody(null, null) : body);
    }

    @PostMapping("/{id}/arrive")
    public Map<String, Object> arrive(@PathVariable String id, @RequestBody(required = false) Dtos.LocBody body) {
        return service.arrive(id, body == null ? new Dtos.LocBody(null, null) : body);
    }

    @PostMapping("/{id}/deliver")
    public Map<String, Object> deliver(@PathVariable String id, @Valid @RequestBody Dtos.DeliverBody body) {
        return service.deliver(id, body);
    }

    @PostMapping("/{id}/feedback")
    public Map<String, Object> feedback(@PathVariable String id, @Valid @RequestBody Dtos.FeedbackBody body) {
        return service.feedback(id, body);
    }
}
