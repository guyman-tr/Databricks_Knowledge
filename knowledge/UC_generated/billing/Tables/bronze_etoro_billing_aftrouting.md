---
object_fqn: main.billing.bronze_etoro_billing_aftrouting
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_aftrouting
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-18T10:58:28Z'
upstreams:
- etoro.Billing.AftRouting
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md
  source_database: etoro
  source_schema: Billing
  source_table: AftRouting
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/AftRouting
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 10
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_aftrouting

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.AftRouting`). 10 of 10 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_aftrouting` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Apr 06 12:41:09 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.AftRouting` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md`.

- Lake path: `Bronze/etoro/Billing/AftRouting`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.AftRouting`
- 10 of 10 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Surrogate sequential identifier. NOT the primary key - included for convenience reference (e.g., admin UI row identification). The real routing key is the composite PK (CountryID, CardTypeID, RegulationID, DepotID) (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 1 | CountryID | INT | YES | Country of the customer initiating the AFT transaction. Part of the composite PK. Implicit FK to Dictionary.Country. Combined with CardTypeID and RegulationID to identify the applicable routing set. Used as an optional filter in AftRoutingGet (@CountryID=NULL means all countries) (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 2 | CardTypeID | INT | YES | Credit/debit card network type. Part of the composite PK. All current rows: 1=Visa (82%), 2=MasterCard (18%). FK to Dictionary.CardType. Determines which card network's AFT routing rules apply (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 3 | RegulationID | INT | YES | Regulatory jurisdiction governing the customer's account. Part of the composite PK. Current values: 1=CySEC (69%), 2=FCA (5%), 4=ASIC (5%), 9=FSA Seychelles (3%), 10=ASIC & GAML (5%). FK to Dictionary.Regulation. Determines jurisdiction-specific AFT gateway eligibility (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 4 | DepotID | INT | YES | The payment gateway depot eligible for AFT processing for this country/card/regulation combination. Part of the composite PK. FK to Billing.Depot. Multiple DepotIDs per (CountryID, CardTypeID, RegulationID) tuple represent alternative eligible gateways (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 5 | Trace | STRING | YES | Audit context column, computed at read time. JSON string capturing: HostName (server running the query), AppName (application name), SUserName (SQL login), SPID (session ID), DBName, ObjectName (stored procedure if any). Format: `{"HostName": "...", "AppName": "...", ...}`. Not stored persistently - recalculated every SELECT. Used to identify which application/process is reading routing data (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 6 | ValidFrom | TIMESTAMP | YES | Timestamp when this routing rule became effective. Auto-managed by SQL Server temporal system. Populated on INSERT and each UPDATE. Earliest value: 2023-07-25 (table creation). Read-only - cannot be set by application code (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 7 | ValidTo | TIMESTAMP | YES | Timestamp when this routing rule was superseded. Auto-managed by SQL Server temporal system. Active rows: 9999-12-31 (open-ended). On UPDATE/DELETE, SQL Server sets this to the change timestamp and moves the row to History.BillingAftRouting. Read-only (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 8 | IsWhitelistedProvider | BOOLEAN | YES | Whether this depot is explicitly preferred (forced) for this routing combination: true=whitelisted/forced, NULL=standard eligible. Only 3 rows have true - used for priority routing overrides. No false values currently exist (Tier 1 — inherited from etoro.Billing.AftRouting). |
| 9 | IsBlacklistedProvider | BOOLEAN | YES | Whether this depot is explicitly excluded from this routing combination despite being listed: false=explicitly excluded, NULL=standard eligible. Only 2 rows have false - used for suppression overrides. No true values currently exist (bit semantics: true would mean "is blacklisted") (Tier 1 — inherited from etoro.Billing.AftRouting). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.AftRouting` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.AftRouting
        │
        ▼
main.billing.bronze_etoro_billing_aftrouting   ←── this object
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
| ID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| CountryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| CardTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| RegulationID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| DepotID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| Trace | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| ValidTo | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| IsWhitelistedProvider | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |
| IsBlacklistedProvider | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.AftRouting.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.AftRouting) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
