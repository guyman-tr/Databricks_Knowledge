---
object_fqn: main.bi_db.bronze_etoro_billing_depositamount
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_billing_depositamount
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 12
row_count: null
generated_at: '2026-05-19T12:12:43Z'
upstreams:
- etoro.Billing.DepositAmount
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md
  source_database: etoro
  source_schema: Billing
  source_table: DepositAmount
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/DepositAmount
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 12
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_depositamount

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Billing.DepositAmount`). 12 of 12 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_billing_depositamount` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 12 |
| **Generated** | 2026-05-19 |
| **Created** | Fri Oct 17 04:16:26 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.DepositAmount` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md`.

- Lake path: `Bronze/etoro/Billing/DepositAmount`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.DepositAmount`
- 12 of 12 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | INT | YES | Country for which these deposit limits apply. Implicit FK to Dictionary.Country(CountryID). CountryID=0 is the global fallback used when no country-specific row exists (via ISNULL(@CountryID, 0) in GetDepositAmountsForUser) (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 1 | MinAmount | DECIMAL | YES | Minimum deposit amount in USD. The smallest amount a customer in this country can deposit (or globally, $50 for the fallback). Enforced at the deposit validation layer (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 2 | Package1Amount | DECIMAL | YES | First suggested deposit amount shown as a quick-select button. NULL if not applicable. Default value is $200.00 across most rows. Only displayed when IsPackageVisible=1 (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 3 | Package2Amount | DECIMAL | YES | Second suggested deposit amount. NULL if not applicable. Default value is $400.00. Only displayed when IsPackageVisible=1 (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 4 | Package3Amount | DECIMAL | YES | Third suggested deposit amount. NULL if not applicable. Default value is $1,000.00. Only displayed when IsPackageVisible=1 (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 5 | FTD | BOOLEAN | YES | First Time Deposit flag. 1=this row applies to customers making their FIRST approved deposit (no prior PaymentStatusID=2 in Billing.Deposit). 0=this row applies to returning depositors. GetDepositAmountsForUser dynamically determines FTD status and selects the appropriate row. DEFAULT 0 (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 6 | Id | INT | YES | Surrogate PK. Auto-incremented row identifier. Not the natural business key - lookups are by (CountryID, FTD) (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 7 | IsPackageVisible | BOOLEAN | YES | Whether the Package1/2/3 suggested amounts should be displayed in the deposit UI. 1=show package buttons (8 rows, all FTD=true), 0=hide packages, customer enters amount manually (493 rows). DEFAULT 0 (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 8 | Trace | STRING | YES | Non-persisted JSON audit string (HostName, AppName, SUserName, SPID, DBName, ObjectName). Computed at query time for diagnostic purposes. Same pattern as CurrencyPerFundingTypeOverrides (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 9 | ValidFrom | TIMESTAMP | YES | System-time start: row became current at this timestamp. GENERATED ALWAYS AS ROW START (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 10 | ValidTo | TIMESTAMP | YES | System-time end: row was superseded at this timestamp (9999-12-31 for current rows). GENERATED ALWAYS AS ROW END (Tier 1 — inherited from etoro.Billing.DepositAmount). |
| 11 | MaxAmount | DECIMAL | YES | Maximum deposit amount in USD. NULL means no upper limit. When set (e.g., MaxAmount=50 for CountryID=1), enforces a cap on deposit size for that country/depositor type (Tier 1 — inherited from etoro.Billing.DepositAmount). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.DepositAmount` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.DepositAmount
        │
        ▼
main.bi_db.bronze_etoro_billing_depositamount   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| CountryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| MinAmount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| Package1Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| Package2Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| Package3Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| FTD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| Id | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| IsPackageVisible | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| Trace | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| ValidTo | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |
| MaxAmount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositAmount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositAmount) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 12 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 12/12 | Source: bronze_tier1_inheritance*
