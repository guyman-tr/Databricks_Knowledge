---
object_fqn: main.bi_db.bronze_etoro_billing_currencysettings
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_billing_currencysettings
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:12:42Z'
upstreams:
- etoro.Billing.CurrencySettings
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md
  source_database: etoro
  source_schema: Billing
  source_table: CurrencySettings
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/CurrencySettings
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 6
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_currencysettings

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Billing.CurrencySettings`). 6 of 6 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_billing_currencysettings` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 6 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Dec 09 07:26:21 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.CurrencySettings` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md`.

- Lake path: `Bronze/etoro/Billing/CurrencySettings`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.CurrencySettings`
- 6 of 6 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Surrogate primary key. No business significance - internal row identifier (Tier 1 — inherited from etoro.Billing.CurrencySettings). |
| 1 | CurrencyID | INT | YES | Currency being configured. Implicit FK to Dictionary.Currency. The lookup key used by PIP calculation functions: `JOIN Billing.CurrencySettings ON CurrencyID = BD.CurrencyID`. Covers 31 currencies including EUR (2), GBP (3), JPY (4), AUD (5), CHF (6), CAD (7), and others (Tier 1 — inherited from etoro.Billing.CurrencySettings). |
| 2 | InstrumentID | INT | YES | Trading instrument that provides the exchange rate for this currency. Implicit FK to the Trade instrument table. For major currencies, typically the standard forex pair (e.g., EUR->InstrumentID=1 is EUR/USD). For some currencies, CurrencyID=InstrumentID (e.g., 79, 80, 81 where currency and instrument share the same ID - likely non-USD instruments referenced directly) (Tier 2 — inherited from etoro.Billing.CurrencySettings). |
| 3 | IsReciprocal | INT | YES | Rate direction flag: 0=direct quote (currency is base, e.g., EUR/USD), 1=reciprocal quote (USD is base, e.g., USD/JPY, must invert rate). Used by PIP formula to determine whether to apply rate directly or as 1/rate. 0 for 9 currencies (EUR, GBP, AUD, CAD, and some crypto), 1 for 22 currencies (most others including JPY, CHF, CNY) (Tier 1 — inherited from etoro.Billing.CurrencySettings). |
| 4 | Precision | INT | YES | Decimal places used for this currency in PIP calculations. Determines rounding precision in the PIP formula. Values: 0=JPY-class (no decimal), 2=most standard currencies, 4=major FX pairs (EUR, GBP, AUD, CAD), 5=crypto/exotic instruments (Tier 1 — inherited from etoro.Billing.CurrencySettings). |
| 5 | ModificationDate | TIMESTAMP | YES | Timestamp of last configuration update. All 31 rows show 2024-05-06 - a bulk update/refresh event. Used for change tracking by the admin tool (Tier 1 — inherited from etoro.Billing.CurrencySettings). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.CurrencySettings` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.CurrencySettings
        │
        ▼
main.bi_db.bronze_etoro_billing_currencysettings   ←── this object
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
| ID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CurrencySettings) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CurrencySettings) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CurrencySettings) |
| IsReciprocal | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CurrencySettings) |
| Precision | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CurrencySettings) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CurrencySettings) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 6 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: bronze_tier1_inheritance*
