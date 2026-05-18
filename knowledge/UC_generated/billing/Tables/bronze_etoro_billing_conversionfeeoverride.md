---
object_fqn: main.billing.bronze_etoro_billing_conversionfeeoverride
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_conversionfeeoverride
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-18T10:58:30Z'
upstreams:
- etoro.Billing.ConversionFeeOverride
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md
  source_database: etoro
  source_schema: Billing
  source_table: ConversionFeeOverride
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/ConversionFeeOverride
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

# bronze_etoro_billing_conversionfeeoverride

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.ConversionFeeOverride`). 10 of 10 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_conversionfeeoverride` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-18 |
| **Created** | Wed May 15 05:47:15 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.ConversionFeeOverride` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md`.

- Lake path: `Bronze/etoro/Billing/ConversionFeeOverride`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.ConversionFeeOverride`
- 10 of 10 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerLevelID | INT | YES | eToro Club loyalty tier for which this override applies. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Value 0 means "all tiers" (global override). Implicit FK to Dictionary.PlayerLevel. See [Player Level](_glossary.md#player-level) (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 1 | FundingTypeID | INT | YES | Payment method for which this override applies. Active values in this table: 1=CreditCard, 2=WireTransfer, 33=eToroMoney, 35=Trustly, 43=GCCInstantBankTransfer. Implicit FK to Dictionary.FundingType (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 2 | CurrencyID | INT | YES | Account denomination currency for which this override applies. References Dictionary.Currency (which is the universal instrument registry; in billing context, CurrencyID refers to actual ISO currencies like EUR=2, GBP=3, AUD=5, CHF=6, NOK=39, SEK=40, PLN=44, HUF=45, DKK=46, CZK=82, RON=521, AEDUSD=349). Value 0 means "any currency". Explicit FK to Dictionary.Currency (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 3 | DepositFee | INT | YES | Flat minimum deposit conversion fee in minor currency units (e.g., cents). Used for flat-fee payment methods (CreditCard, WireTransfer). For eToroMoney rows this is 0, meaning no flat minimum - the percentage (DepositFeePercentage) is the operative charge (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 4 | CashoutFee | INT | YES | Flat minimum cashout (withdrawal) conversion fee in minor currency units. Same model as DepositFee: used for flat-fee methods; 0 for percentage-based methods. Diamond tier rows show CashoutFee=0 (flat minimum waived as loyalty benefit) (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 5 | ModifictionDate | TIMESTAMP | YES | UTC timestamp of the last INSERT or UPDATE on this row. Note: column name is intentionally misspelled in DDL ("Modification" -> "Modifiction"). DEFAULT is GETUTCDATE() so new rows auto-populate. The trigger archives the old value to History.ConversionFeeOverride on UPDATE/DELETE (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 6 | CountryID | INT | YES | Optional country scope for this override. NULL=applies globally to all countries. Non-NULL values: 12=Australia (AUD/eToroMoney rows with higher rates), 218=United Kingdom (GBP/Trustly flat fee rows). Passed to Billing.ExchangeRatesByPlayerLevelGet as @CountryID for country-aware fee lookup. Implicit FK to Dictionary.Country (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 7 | DepositFeePercentage | DECIMAL | YES | Percentage-based deposit conversion fee rate (e.g., 0.75 = 0.75%). Used for newer payment methods (eToroMoney=0.75% globally, Trustly). NULL for flat-fee methods (CreditCard, WireTransfer, GCCInstantBankTransfer). Added in PAYIL-8694 (Aug 2024) to support percentage-based fee model (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 8 | CashoutFeePercentage | DECIMAL | YES | Percentage-based cashout conversion fee rate. Mirrors DepositFeePercentage for withdrawal direction. Same values as DepositFeePercentage for symmetric pricing; NULL for flat-fee payment methods (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |
| 9 | ConversionFeeID | INT | YES | Auto-incrementing surrogate identity column. NOT declared as PRIMARY KEY in DDL - uniqueness is enforced via IX_Conv_1 unique index on (PlayerLevelID, FundingTypeID, CurrencyID, CountryID). Used as a stable row reference (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.ConversionFeeOverride` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.ConversionFeeOverride
        │
        ▼
main.billing.bronze_etoro_billing_conversionfeeoverride   ←── this object
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
| PlayerLevelID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| FundingTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| DepositFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| CashoutFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| ModifictionDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| CountryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| DepositFeePercentage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| CashoutFeePercentage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |
| ConversionFeeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFeeOverride.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ConversionFeeOverride) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
