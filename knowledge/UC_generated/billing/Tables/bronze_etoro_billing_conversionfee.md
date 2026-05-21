---
object_fqn: main.billing.bronze_etoro_billing_conversionfee
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_conversionfee
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 11
row_count: null
generated_at: '2026-05-18T10:58:30Z'
upstreams:
- etoro.Billing.ConversionFee
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md
  source_database: etoro
  source_schema: Billing
  source_table: ConversionFee
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/ConversionFee
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_conversionfee

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.ConversionFee`). 11 of 11 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_conversionfee` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 11 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Apr 20 15:50:58 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.ConversionFee` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md`.

- Lake path: `Bronze/etoro/Billing/ConversionFee`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.ConversionFee`
- 11 of 11 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyID | INT | YES | Primary key. The currency for which this fee applies. FK to `Dictionary.Currency` implicitly. CurrencyID=1 (USD) has no entry - USD is eToro's base currency requiring no conversion (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 1 | InstrumentID | INT | YES | The forex trading instrument for this currency pair (e.g., EUR/USD=1, GBP/USD=2, AUD/USD=7). References `Trade.Instrument` implicitly. Used by the exchange rate SP to retrieve current bid/ask rates for the conversion (Tier 2 — inherited from etoro.Billing.ConversionFee). |
| 2 | DepositFee | INT | YES | Flat deposit conversion fee in the local currency's smallest unit (cents, pence, subunits, etc.). Applied when a customer makes a deposit in this currency and eToro converts to USD (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 3 | CashoutFee | INT | YES | Flat cashout conversion fee in the local currency's smallest unit. Applied when a customer withdraws in this currency and eToro converts from USD. CHF has asymmetric fees (DepositFee=140, CashoutFee=150) (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 4 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the last modification to this fee row. Defaults to GETUTCDATE() on insert. All rows = 2024-05-02 (bulk fee update). Distinct from temporal ValidFrom (which is system-managed) (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 5 | Trace | STRING | YES | Auto-captured session context at DML time: `{"HostName":"...","AppName":"...","SUserName":"...","SPID":"...","DBName":"...","ObjectName":"..."}`. Provides lightweight audit trail of who changed the fee (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 6 | ValidFrom | TIMESTAMP | YES | System-managed temporal column. UTC timestamp when this row version became current. Automatically set by SQL Server on INSERT/UPDATE (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 7 | ValidTo | TIMESTAMP | YES | System-managed temporal column. UTC timestamp when this row version was superseded. Current rows: 9999-12-31. Set to NOW when updated or deleted; historical row moved to History.ConversionFee (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 8 | DepositFeePercentage | DECIMAL | YES | Percentage-based deposit fee (e.g., 1.50 = 1.5%). Currently NULL for all rows - reserved for future percentage-based fee model. Already queried by GetExchangeRatesForCustomerFunding_v4 (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 9 | CashoutFeePercentage | DECIMAL | YES | Percentage-based cashout fee. Currently NULL for all rows - future use (Tier 1 — inherited from etoro.Billing.ConversionFee). |
| 10 | ConversionFeeID | INT | YES | Secondary identity column (NOT the PK). Auto-generated starting at 100,000. Provides a stable row identifier separate from the CurrencyID PK, used in override and audit references (Tier 1 — inherited from etoro.Billing.ConversionFee). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.ConversionFee` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.ConversionFee
        │
        ▼
main.billing.bronze_etoro_billing_conversionfee   ←── this object
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
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| DepositFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| CashoutFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| Trace | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| ValidTo | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| DepositFeePercentage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| CashoutFeePercentage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |
| ConversionFeeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFee) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 11 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 11/11 | Source: bronze_tier1_inheritance*
