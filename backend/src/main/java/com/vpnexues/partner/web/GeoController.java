package com.vpnexues.partner.web;

import com.vpnexues.partner.service.PartnerService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** Public reference data used by the sign-up city picker and the change-zone screen. */
@RestController
@RequestMapping("/v1")
public class GeoController {
    private final PartnerService service;

    public GeoController(PartnerService service) {
        this.service = service;
    }

    @GetMapping("/cities")
    public List<Map<String, Object>> cities() {
        return service.cities();
    }

    @GetMapping("/cities/{id}/hubs")
    public List<Map<String, Object>> hubs(@PathVariable int id) {
        return service.hubs(id);
    }
}
