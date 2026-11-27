# Spring Boot ↔ Supabase schema compatibility (static review)

Status: **repository-only review**. No database was contacted, no migration was applied or baselined, no credentials were read, and no Supabase project identity was verified. This document compares the checked-in SQL only.

The Fastify-era SQL in `backend/migrations/0001_*.sql` … `0011_*.sql` is the historical, owner-applied migration lineage for the isolated Supabase project. The Java/Flyway copies in `backend/src/main/resources/db/migration/V1__*.sql` … `V11__*.sql` are a separate reconstruction for disposable local PostgreSQL. **They are not interchangeable.**

## Safety rule

Never run Flyway `V1`–`V11` against Supabase, and never baseline or repair a Flyway history there. `application.yml` disables Flyway by default. `MigrationSafetyEnvironmentPostProcessor` additionally refuses to initialise Flyway unless both of these are true:

- `app.migration-target=local`
- `spring.datasource.url` resolves to a loopback host (`localhost`, `127.0.0.1`, `::1`)

`application-local.yml` is the only profile that enables the Java migrations, and it is still rejected if the datasource is remote.

## Migration comparison

| Pair | Result | Difference |
|---|---|---|
| `0001` / `V1` | **Semantic difference** | SQL installs `pgcrypto` and `citext`. Flyway relies on built-in `gen_random_uuid()` (PostgreSQL 13+) and does not install either extension. |
| `0002` / `V2` | Equivalent DDL | Comments only. |
| `0003` / `V3` | **Semantic difference** | `partners.email`, `partners.referral_code` change from `citext` to `text`; functional unique indexes `lower(email)` and `upper(referral_code)` are added. Comments changed. |
| `0004` / `V4` | Equivalent DDL | Comments only. |
| `0005` / `V5` | **Semantic difference** | `payout_methods.upi_vpa` changes from `citext` to `text`. Comments changed. |
| `0006` / `V6` | Equivalent DDL | Comments only. |
| `0007` / `V7` | Equivalent DDL | Comments only. |
| `0008` / `V8` | Equivalent DDL | Comments only. |
| `0009` / `V9` | Equivalent DDL | No semantic differences. |
| `0010` / `V10` | **Semantic difference** | Flyway excludes `flyway_schema_history` from the RLS loop; historical SQL enables RLS on every `public` table. Role revocations are otherwise the same. |
| `0011` / `V11` | **Semantic difference** | `admin_users.email` changes from `citext` to `text`; a `lower(email)` unique index is added. Comments changed. |

Because a migration's checksum covers its comments too, even the “comments only” pairs must not be substituted into an already-applied SQL migration history.

## What the Java code assumes when pointed at the deployed Supabase schema

- Plain JDBC SQL against the `public` schema; there is no Hibernate schema generation. Tables, enum types, sequences, columns and constraints from the applied `0001`–`0011` lineage are expected to exist.
- `gen_random_uuid()` is used by both lineages. The Java code does not call PostgreSQL `digest()` or `crypt()`; OTP, refresh-token, delivery-code and password hashing are done in application code. The `pgcrypto` extension from `0001` remains harmless and may be required by other tooling.
- `citext` columns exist in the historical schema (`partners.email`, `partners.referral_code`, `payout_methods.upi_vpa`, `admin_users.email`). The Java Flyway schema uses `text` plus functional indexes instead. Case-sensitive behaviour must therefore be reviewed per query:
  - `AdminService` lower-cases admin e-mail before lookup and insert, so it works with both `citext` and `text`.
  - `AuthService` uses `upper(referral_code) = upper(?)`, so it works with both.
  - `PartnerService.updateMe` writes a trimmed e-mail without lower-casing. On Supabase `citext`, duplicate-case addresses are rejected by the type; on the Java schema, the `lower(email)` index rejects them but may surface as a database unique violation.
  - `DataSeeder` uses `ON CONFLICT (email)` and is local-only; case-only collisions would require `ON CONFLICT (lower(email))` if that seed were ever generalised.
- RLS from `0010` assumes the backend connects as the table owner (or another role that bypasses RLS). Running as an anon/authenticated Supabase role requires explicit policies and is not covered here.
- `order_events` is the timeline source for both the partner API and the trial/admin flows; admin-created and trial-created orders must insert `created`/`assigned` events so the mobile timeline is not empty.
- Money stays in integer paise; timestamps are `timestamptz`; report buckets use `Asia/Kolkata`.

## Still requiring owner verification

This review cannot determine the deployed database's actual state. Before any deployment that touches data, the owner must confirm, using an approved read-only procedure:

1. The Supabase project reference and that it is the intended isolated project (no owner-approved 20-character reference was found in the repository).
2. Applied migration history and checksums for `0001`–`0011`.
3. Installed extensions and column types for the `citext` fields listed above.
4. RLS enablement, roles, grants and policies for the backend connection.
5. Whether any later forward-only migrations exist outside this repository.

If a schema change is needed, add a new forward-only SQL migration after `0011`; never edit a file that has already been applied.
