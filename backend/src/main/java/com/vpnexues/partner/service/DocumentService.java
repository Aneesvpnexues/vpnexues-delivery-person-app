package com.vpnexues.partner.service;

import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.common.Json;
import com.vpnexues.partner.security.CurrentUser;
import com.vpnexues.partner.web.dto.Dtos;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class DocumentService {
    public static final Set<String> DOC_TYPES = Set.of("aadhaar", "pan", "driving_licence", "vehicle_rc",
            "vehicle_insurance", "pucc", "police_verification", "selfie");
    public static final List<String> REQUIRED_DOCS = List.of("aadhaar", "pan", "driving_licence",
            "vehicle_rc", "vehicle_insurance", "selfie");
    private static final Set<String> CONTENT_TYPES = Set.of("image/jpeg", "image/png", "application/pdf");
    private static final Set<String> SIDES = Set.of("front", "back", "single");
    private static final Set<String> VEHICLES = Set.of("motorbike", "scooter", "electric_scooter", "bicycle");
    private static final Set<String> FUELS = Set.of("petrol", "electric", "cng", "none");

    private final Db db;
    private final CurrentUser current;
    private final StorageService storage;

    public DocumentService(Db db, CurrentUser current, StorageService storage) {
        this.db = db;
        this.current = current;
        this.storage = storage;
    }

    private static String mask(String n) {
        String s = n.replaceAll("\\s", "");
        String masked = "X".repeat(Math.max(0, s.length() - 4)) + s.substring(Math.max(0, s.length() - 4));
        return masked.replaceAll("(.{4})(?=.)", "$1 ");
    }

    public Map<String, Object> list() {
        String pid = current.partnerId();
        List<Map<String, Object>> docs = db.query(
                "SELECT id, type, status, number_masked, source, valid_until, rejection_reason, submitted_at, reviewed_at, " +
                        "(valid_until IS NOT NULL AND valid_until < current_date + 30) AS expiring_soon " +
                        "FROM partner_documents WHERE partner_id = ? ORDER BY type", pid);
        long verified = docs.stream().filter(d -> "verified".equals(String.valueOf(d.get("status")))).count();
        Set<String> present = docs.stream().map(d -> String.valueOf(d.get("type"))).collect(Collectors.toSet());
        List<String> missing = REQUIRED_DOCS.stream().filter(t -> !present.contains(t)).toList();
        return Json.map(
                "documents", docs,
                "verifiedCount", verified,
                "requiredCount", REQUIRED_DOCS.size(),
                "missing", missing);
    }

    public Map<String, Object> uploadUrl(String type, Dtos.UploadUrlBody b) {
        validateType(type);
        if (!CONTENT_TYPES.contains(b.contentType())) {
            throw ApiException.badRequest("INVALID_FILE_TYPE", "Upload a JPG, PNG or PDF");
        }
        String side = b.side() == null ? "single" : b.side();
        if (!SIDES.contains(side)) throw ApiException.badRequest("INVALID_SIDE", "Choose front, back or single");
        String ext = switch (b.contentType()) {
            case "image/jpeg" -> "jpg";
            case "image/png" -> "png";
            default -> "pdf";
        };
        String key = "partners/" + current.partnerId() + "/documents/" + type + "/" + side + "-" + UUID.randomUUID() + "." + ext;
        return storage.presignUpload(key, b.contentType());
    }

    public Map<String, Object> storeUpload(String key, byte[] bytes) {
        if (bytes == null || bytes.length == 0) throw ApiException.badRequest("EMPTY_FILE", "The uploaded file is empty");
        storage.store(current.partnerId(), key, bytes);
        return Json.map("ok", true);
    }

    public Map<String, Object> submit(String type, Dtos.SubmitDoc b) {
        validateType(type);
        if (b.s3Keys() == null || b.s3Keys().isEmpty() || b.s3Keys().size() > 2) {
            throw ApiException.badRequest("FILES_REQUIRED", "Upload 1 or 2 files first");
        }
        String pid = current.partnerId();
        String prefix = "partners/" + pid + "/documents/" + type + "/";
        if (b.s3Keys().stream().anyMatch(k -> k == null || !k.startsWith(prefix))) {
            throw ApiException.badRequest("BAD_S3_KEY", "Upload the file with an upload URL first");
        }
        if (("aadhaar".equals(type) || "pan".equals(type)) && !Boolean.TRUE.equals(b.consent())) {
            throw ApiException.badRequest("CONSENT_REQUIRED", "Consent is required for e-KYC");
        }
        LocalDate validUntil = null;
        if (b.validUntil() != null && !b.validUntil().isBlank()) {
            try {
                validUntil = LocalDate.parse(b.validUntil());
            } catch (Exception e) {
                throw ApiException.badRequest("INVALID_DATE", "Use YYYY-MM-DD for the expiry date");
            }
        }
        String masked = b.number() == null || b.number().isBlank() ? null : mask(b.number());
        String keysLiteral = pgTextArray(b.s3Keys());
        LocalDate valid = validUntil;
        return db.inTx(() -> {
            Map<String, Object> d = db.one(
                    "INSERT INTO partner_documents (partner_id, type, status, number_masked, s3_keys, valid_until, submitted_at, rejection_reason) " +
                            "VALUES (?, ?::document_type, 'in_review', ?, ?::text[], ?, now(), NULL) " +
                            "ON CONFLICT (partner_id, type) DO UPDATE SET status = 'in_review', number_masked = EXCLUDED.number_masked, " +
                            "s3_keys = EXCLUDED.s3_keys, valid_until = EXCLUDED.valid_until, submitted_at = now(), rejection_reason = NULL, reviewed_at = NULL " +
                            "RETURNING id, type, status, number_masked, valid_until, submitted_at",
                    pid, type, masked, keysLiteral, valid);
            db.update("INSERT INTO document_events (document_id, status) VALUES (?, 'in_review')", d.get("id"));
            db.update("UPDATE partners SET kyc_status = 'in_review' WHERE id = ? AND kyc_status = 'not_started'", pid);
            return d;
        });
    }

    public Map<String, Object> vehicle() {
        return db.one("SELECT * FROM vehicles WHERE partner_id = ?", current.partnerId());
    }

    public Map<String, Object> saveVehicle(Dtos.VehicleBody b) {
        if (!VEHICLES.contains(b.type())) throw ApiException.badRequest("INVALID_VEHICLE", "Choose a valid vehicle type");
        String reg = b.registrationNumber().trim().toUpperCase();
        if (!reg.matches("^[A-Z]{2}\\s?\\d{1,2}\\s?[A-Z]{0,3}\\s?\\d{1,4}$")) {
            throw ApiException.badRequest("INVALID_REGISTRATION", "Enter a valid registration number");
        }
        if (b.fuel() != null && !FUELS.contains(b.fuel())) {
            throw ApiException.badRequest("INVALID_FUEL", "Choose a valid fuel type");
        }
        if (b.year() != null && (b.year() < 1990 || b.year() > 2100)) {
            throw ApiException.badRequest("INVALID_YEAR", "Enter a valid year");
        }
        return db.one(
                "INSERT INTO vehicles (partner_id, type, registration_number, make_model, year, colour, fuel) " +
                        "VALUES (?, ?::vehicle_type, ?, ?, ?, ?, ?) " +
                        "ON CONFLICT (partner_id) DO UPDATE SET type = EXCLUDED.type, registration_number = EXCLUDED.registration_number, " +
                        "make_model = EXCLUDED.make_model, year = EXCLUDED.year, colour = EXCLUDED.colour, fuel = EXCLUDED.fuel RETURNING *",
                current.partnerId(), b.type(), reg, b.makeModel(), b.year(), b.colour(), b.fuel());
    }

    private void validateType(String type) {
        if (!DOC_TYPES.contains(type)) throw ApiException.badRequest("INVALID_DOC_TYPE", "Unknown document type");
    }

    public static String pgTextArray(List<String> values) {
        return "{" + values.stream()
                .map(v -> "\"" + v.replace("\\", "\\\\").replace("\"", "\\\"") + "\"")
                .collect(Collectors.joining(",")) + "}";
    }
}
