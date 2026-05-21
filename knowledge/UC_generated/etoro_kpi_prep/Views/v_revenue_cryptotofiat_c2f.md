---
object_fqn: main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 16
row_count: null
generated_at: '2026-05-19T12:26:37Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_cryptotofiat_c2f.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_cryptotofiat_c2f.sql
concept_count: 1
formula_count: 16
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 11
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_cryptotofiat_c2f

> View in `main.etoro_kpi_prep`. 1 business concept(s) in §2; 16 of 16 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 16 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:03 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_cryptotofiat_c2f` is a view in `main.etoro_kpi_prep` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\EXW_dbo\Tables\EXW_C2F_E2E.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 16 columns: 5 inherit byte-for-byte from upstream wikis (Tier 1), 11 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID     AND CAST(DATE_FORMAT(CAST(GREATEST(ecfee.eMoneyLastStatusTime, ecfee.ConversionDateTime, ecfee.ConversionStatusDateTime, ecfee.CryptoTransactionDateTime`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_cryptotofiat_c2f.sql` L27
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID     AND CAST(DATE_FORMAT(CAST(GREATEST(ecfee.eMoneyLastStatusTime, ecfee.ConversionDate` | Lookup via alias `dr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Internal CID after deduplication mapping. Sourced from EXW_dbo.EXW_DimUser.RealCID; maps GCID to the canonical customer record. (Tier 2 — SP_EXW_C2F_E2E) |
| 1 | GCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 2 | LastModificationDate | TIMESTAMP | YES | Function call computed in source. Formula: `GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e`) |
| 3 | LastModificationDateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) AS DATE), 'yyyyMMdd') AS INT) AS LastModificationD…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e`) |
| 4 | TotalFeePercentage | DECIMAL | YES | Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. Zero fee observed for some EtoroPosition conversions. (Tier 1 — C2F.Conversions) |
| 5 | TotalFeeUSD | DECIMAL | YES | Fee amount in USD. Computed by SP: CAST(CryptoAmount AS FLOAT) * CAST(CryptoToUsdRate AS FLOAT) / 100 * TotalFeePercentage. Approximation subject to float precision. (Tier 2 — SP_EXW_C2F_E2E) |
| 6 | FiatAmount | DECIMAL | YES | Actual fiat amount credited to the customer in the target currency. This is the post-fee amount the customer receives. (Tier 1 — C2F.FiatTransactions) |
| 7 | CryptoAmount | DECIMAL | YES | Quantity of cryptocurrency being converted. High precision (18 decimals) to handle fractional crypto amounts. This is the gross amount before fees. (Tier 1 — C2F.Conversions) |
| 8 | FiatCurrency | STRING | YES | Display name for FiatCurrencyID. Lookup from EXW_Wallet.FiatTypes. Values observed: GBP (50%), EUR (40%), USD (7.5%), AUD (2%). (Tier 2 — SP_EXW_C2F_E2E) |
| 9 | UsdAmount | DECIMAL | YES | USD equivalent of the fiat amount. Used for regulatory limit calculations. Preferred over EstimatedFiatTransactions.UsdAmount when available. (Tier 1 — C2F.FiatTransactions) |
| 10 | Crypto | STRING | YES | Display name for CryptoID. Lookup from EXW_Wallet.CryptoTypes. Values observed: BTC, ETH, XRP, USDC, SOL, DOGE, ADA, TRX, LTC, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 11 | TargetPlatformID | INT | YES | Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target). Determines the downstream routing of fiat proceeds. (Tier 1 — C2F.Conversions) |
| 12 | TargetPlatform | STRING | YES | Display name for TargetPlatformID. Values: IbanAccount, EtoroPlatform, EtoroPosition. Lookup from WalletConversionDB Dictionary.FiatConversionTargets. (Tier 2 — SP_EXW_C2F_E2E) |
| 13 | DepositID | INT | YES | Billing deposit ID from DWH_dbo.Fact_BillingDeposit. Populated only for EtoroPosition conversions (TargetPlatformID=3) where the fiat proceeds fund a trading deposit (FundingTypeID=27). NULL (13,555 rows, 93%) for IbanAccount and EtoroPlatform paths. (Tier 2 — SP_EXW_C2F_E2E) |
| 14 | eMoneyTransactionID | INT | YES | FiatDwhDB transaction ID for the eToro Money fiat settlement event. Matched by C2FCorrelationID = FiatDwhDB.MoneyCorrelationID. NULL (1,567 rows, 10.8%) for EtoroPosition-path conversions. (Tier 2 — SP_EXW_C2F_E2E) |
| 15 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | Primary | `knowledge\synapse\Wiki\EXW_dbo\Tables\EXW_C2F_E2E.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
        │
        ▼
main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f   ←── this object
        │
        ▼
main.etoro_kpi_prep.v_ddr_revenues
main.etoro_kpi_prep_stg.v_ddr_revenues
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=16 runtime=16 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` (wiki: `knowledge\synapse\Wiki\EXW_dbo\Tables\EXW_C2F_E2E.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep.v_ddr_revenues`
- `main.etoro_kpi_prep_stg.v_ddr_revenues`

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 16 | Tiers: 5 T1, 11 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 16/16 | Source: view_definition*
