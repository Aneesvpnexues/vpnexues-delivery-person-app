package com.vpnexues.partner.service;

import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.common.Crypto;
import com.vpnexues.partner.common.Db;
import com.vpnexues.partner.common.Json;
import com.vpnexues.partner.config.AppProperties;
import com.vpnexues.partner.security.CurrentUser;
import com.vpnexues.partner.web.dto.Dtos;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class MoneyService {
    private static final String METHOD_COLS = "id, type, account_holder_name, account_last4, ifsc, bank_name, branch, account_type, " +
            "upi_vpa, is_primary, is_backup, verification, verified_name, created_at";
    private static final Set<String> RANGES = Set.of("today", "week", "month", "year");
    private static final Set<String> FILTERS = Set.of("all", "earnings", "payouts", "bonuses", "deductions");

    private final Db db;
    private final Crypto crypto;
    private final CurrentUser current;
    private final AppProperties props;

    public MoneyService(Db db, Crypto crypto, CurrentUser current, AppProperties props) {
        this.db = db;
        this.crypto = crypto;
        this.current = current;
        this.props = props;
    }

    // ---------------- payout methods ----------------

    public List<Map<String, Object>> payoutMethods() {
        return db.query("SELECT " + METHOD_COLS + " FROM payout_methods WHERE partner_id = ? AND deleted_at IS NULL " +
                "ORDER BY is_primary DESC, created_at", current.partnerId());
    }

    public Map<String, Object> addPayoutMethod(Dtos.PayoutMethodBody b) {
        if (b.type() == null) throw ApiException.badRequest("TYPE_REQUIRED", "Choose bank account or UPI");
        String pid = current.partnerId();
        return db.inTx(() -> {
            if ("bank_account".equals(b.type())) {
                if (b.accountHolderName() == null || b.accountHolderName().trim().length() < 2) {
                    throw ApiException.badRequest("INVALID_HOLDER", "Enter the account holder name");
                }
                if (b.accountNumber() == null || !b.accountNumber().matches("^\\d{9,18}$")) {
                    throw ApiException.badRequest("INVALID_ACCOUNT", "Account number must be 9–18 digits");
                }
                if (!b.accountNumber().equals(b.confirmAccountNumber())) {
                    throw ApiException.badRequest("ACCOUNT_MISMATCH", "Account numbers do not match");
                }
                if (b.ifsc() == null || !b.ifsc().trim().toUpperCase().matches("^[A-Z]{4}0[A-Z0-9]{6}$")) {
                    throw ApiException.badRequest("INVALID_IFSC", "Enter a valid IFSC");
                }
                String accountType = b.accountType() == null ? "savings" : b.accountType();
                if (!Set.of("savings", "current").contains(accountType)) {
                    throw ApiException.badRequest("INVALID_ACCOUNT_TYPE", "Choose savings or current");
                }
                boolean primary = b.makePrimary() == null || b.makePrimary();
                if (primary) db.update("UPDATE payout_methods SET is_primary = false WHERE partner_id = ? AND is_primary", pid);
                return db.one("INSERT INTO payout_methods (partner_id, type, account_holder_name, account_number_enc, account_last4, ifsc, " +
                                "bank_name, branch, account_type, is_primary) VALUES (?, 'bank_account', ?, ?, ?, ?, ?, ?, ?, ?) RETURNING " + METHOD_COLS,
                        pid, b.accountHolderName().trim(), crypto.encrypt(b.accountNumber()), b.accountNumber().substring(b.accountNumber().length() - 4),
                        b.ifsc().trim().toUpperCase(), b.bankName(), b.branch(), accountType, primary);
            }
            if ("upi".equals(b.type())) {
                String vpa = b.upiVpa() == null ? null : b.upiVpa().trim().toLowerCase();
                if (vpa == null || !vpa.matches("^[\\w.-]{2,256}@[a-z]{2,64}$")) {
                    throw ApiException.badRequest("INVALID_UPI", "Enter a valid UPI ID");
                }
                boolean primary = Boolean.TRUE.equals(b.makePrimary());
                boolean keepBank = b.keepBankAsBackup() == null || b.keepBankAsBackup();
                if (primary) {
                    db.update("UPDATE payout_methods SET is_primary = false WHERE partner_id = ? AND is_primary", pid);
                    if (keepBank) {
                        db.update("UPDATE payout_methods SET is_backup = true WHERE partner_id = ? AND type = 'bank_account' AND deleted_at IS NULL", pid);
                    }
                }
                return db.one("INSERT INTO payout_methods (partner_id, type, upi_vpa, is_primary) VALUES (?, 'upi', ?, ?) RETURNING " + METHOD_COLS,
                        pid, vpa, primary);
            }
            throw ApiException.badRequest("INVALID_TYPE", "Choose bank account or UPI");
        });
    }

    public Map<String, Object> makePrimary(String id) {
        return db.inTx(() -> {
            Map<String, Object> m = db.one("SELECT id FROM payout_methods WHERE id = ? AND partner_id = ? AND deleted_at IS NULL FOR UPDATE",
                    id, current.partnerId());
            if (m == null) throw ApiException.notFound("Payout method");
            db.update("UPDATE payout_methods SET is_primary = false WHERE partner_id = ? AND is_primary", current.partnerId());
            return db.one("UPDATE payout_methods SET is_primary = true WHERE id = ? RETURNING " + METHOD_COLS, id);
        });
    }

    public Map<String, Object> deletePayoutMethod(String id) {
        Map<String, Object> row = db.one("UPDATE payout_methods SET deleted_at = now(), is_primary = false WHERE id = ? AND partner_id = ? " +
                "AND deleted_at IS NULL AND NOT is_primary RETURNING id", id, current.partnerId());
        if (row == null) throw ApiException.badRequest("CANNOT_DELETE", "Pick another primary method before removing this one");
        return Json.map("ok", true);
    }

    // ---------------- earnings ----------------

    public Map<String, Object> earnings(String range) {
        String r = range == null ? "today" : range;
        if (!RANGES.contains(r)) throw ApiException.badRequest("INVALID_RANGE", "Choose today, week, month or year");
        String trunc = switch (r) {
            case "week" -> "week";
            case "month" -> "month";
            case "year" -> "year";
            default -> "day";
        };
        String pid = current.partnerId();
        Map<String, Object> totals = db.one(
                "SELECT COALESCE(sum(amount_paise) FILTER (WHERE type IN ('delivery_base','delivery_distance','tip','bonus','incentive','deduction')), 0) AS net_paise, " +
                        "COALESCE(sum(amount_paise) FILTER (WHERE type = 'delivery_base'), 0) AS base_paise, " +
                        "COALESCE(sum(amount_paise) FILTER (WHERE type = 'delivery_distance'), 0) AS distance_paise, " +
                        "COALESCE(sum(amount_paise) FILTER (WHERE type IN ('tip','bonus','incentive')), 0) AS extras_paise, " +
                        "count(DISTINCT order_id) FILTER (WHERE type = 'delivery_base') AS deliveries " +
                        "FROM wallet_ledger WHERE partner_id = ? AND created_at >= date_trunc(?, now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata'",
                pid, trunc);
        List<Map<String, Object>> byHour = db.query(
                "SELECT extract(hour FROM created_at AT TIME ZONE 'Asia/Kolkata')::int AS hour, sum(amount_paise) AS paise " +
                        "FROM wallet_ledger WHERE partner_id = ? AND type IN ('delivery_base','delivery_distance','tip') " +
                        "AND created_at >= date_trunc('day', now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata' " +
                        "GROUP BY 1 ORDER BY 1", pid);
        Map<String, Object> balance = db.one("SELECT COALESCE(sum(amount_paise), 0) AS paise FROM wallet_ledger WHERE partner_id = ?", pid);
        Map<String, Object> nextPayout = db.one("SELECT (date_trunc('week', now() AT TIME ZONE 'Asia/Kolkata') + interval '7 days 18 hours') AT TIME ZONE 'Asia/Kolkata' AS at");
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("range", r);
        if (totals != null) out.putAll(totals);
        out.put("byHour", byHour);
        out.put("availableBalancePaise", balance == null ? 0 : balance.get("paise"));
        out.put("nextWeeklyPayoutAt", nextPayout == null ? null : nextPayout.get("at"));
        return out;
    }

    public Map<String, Object> transactions(String filter, String search, Long before, int limit) {
        String f = filter == null ? "all" : filter;
        if (!FILTERS.contains(f)) throw ApiException.badRequest("INVALID_FILTER", "Choose a valid filter");
        if (limit < 1 || limit > 100) limit = 30;
        String typesLiteral = switch (f) {
            case "earnings" -> DocumentService.pgTextArray(List.of("delivery_base", "delivery_distance", "tip"));
            case "payouts" -> DocumentService.pgTextArray(List.of("payout", "payout_fee"));
            case "bonuses" -> DocumentService.pgTextArray(List.of("bonus", "incentive"));
            case "deductions" -> DocumentService.pgTextArray(List.of("deduction", "adjustment"));
            default -> null;
        };
        List<Map<String, Object>> rows = db.query(
                "SELECT l.id, l.type, l.amount_paise, l.description, l.created_at, o.order_code, p.utr, p.status AS payout_status " +
                        "FROM wallet_ledger l LEFT JOIN orders o ON o.id = l.order_id LEFT JOIN payouts p ON p.id = l.payout_id " +
                        "WHERE l.partner_id = ? " +
                        "AND (?::ledger_entry_type[] IS NULL OR l.type = ANY(?::ledger_entry_type[])) " +
                        "AND (?::text IS NULL OR o.order_code ILIKE '%' || ? || '%' OR p.utr ILIKE '%' || ? || '%' OR l.description ILIKE '%' || ? || '%') " +
                        "AND (?::bigint IS NULL OR l.id < ?) ORDER BY l.id DESC LIMIT ?",
                current.partnerId(), typesLiteral, typesLiteral, search, search, search, search, before, before, limit);
        Long nextCursor = rows.size() == limit ? ((Number) rows.get(rows.size() - 1).get("id")).longValue() : null;
        return Json.map("items", rows, "nextCursor", nextCursor);
    }

    // ---------------- payouts ----------------

    public List<Map<String, Object>> payouts() {
        return db.query("SELECT p.*, m.type AS method_type, m.account_last4, m.upi_vpa FROM payouts p " +
                        "JOIN payout_methods m ON m.id = p.payout_method_id WHERE p.partner_id = ? ORDER BY p.requested_at DESC LIMIT 50",
                current.partnerId());
    }

    public Map<String, Object> instantPayout(Dtos.InstantPayout b, String idempotencyKey) {
        if (idempotencyKey == null || idempotencyKey.length() < 8) {
            throw ApiException.badRequest("IDEMPOTENCY_KEY_REQUIRED", "Send an Idempotency-Key header (e.g. a UUID)");
        }
        if (b.amountPaise() == null || b.amountPaise() <= 0) {
            throw ApiException.badRequest("INVALID_AMOUNT", "Enter a valid amount");
        }
        if (b.amountPaise() < props.instantPayoutMinPaise()) {
            throw ApiException.badRequest("AMOUNT_TOO_LOW", "Minimum instant payout is ₹" + (props.instantPayoutMinPaise() / 100));
        }
        String pid = current.partnerId();
        Map<String, Object> existing = db.one("SELECT * FROM payouts WHERE idempotency_key = ? AND partner_id = ?", idempotencyKey, pid);
        if (existing != null) return existing;

        return db.inTx(() -> {
            db.query("SELECT 1 FROM partners WHERE id = ? FOR UPDATE", pid);
            Map<String, Object> method = b.payoutMethodId() != null
                    ? db.one("SELECT id FROM payout_methods WHERE id = ? AND partner_id = ? AND deleted_at IS NULL AND verification = 'verified'",
                    b.payoutMethodId(), pid)
                    : db.one("SELECT id FROM payout_methods WHERE partner_id = ? AND is_primary AND deleted_at IS NULL AND verification = 'verified'", pid);
            if (method == null) {
                throw ApiException.badRequest("NO_VERIFIED_METHOD", "Add and verify a bank account or UPI ID first");
            }
            int fee = props.instantPayoutFeePaise();
            Map<String, Object> bal = db.one("SELECT COALESCE(sum(amount_paise), 0) AS paise FROM wallet_ledger WHERE partner_id = ?", pid);
            long balance = ((Number) bal.get("paise")).longValue();
            if (balance < b.amountPaise() + fee) {
                throw ApiException.badRequest("INSUFFICIENT_BALANCE", "Amount plus fee is more than your available balance");
            }
            Map<String, Object> p = db.one(
                    "INSERT INTO payouts (partner_id, payout_method_id, kind, amount_paise, fee_paise, idempotency_key) " +
                            "VALUES (?, ?, 'instant', ?, ?, ?) RETURNING *",
                    pid, method.get("id"), b.amountPaise(), fee, idempotencyKey);
            db.update("INSERT INTO wallet_ledger (partner_id, type, amount_paise, payout_id, description) VALUES " +
                            "(?, 'payout', ?, ?, 'Instant payout'), (?, 'payout_fee', ?, ?, 'Instant payout fee')",
                    pid, -b.amountPaise(), p.get("id"), pid, -fee, p.get("id"));
            return p;
        });
    }
}
