---
object_fqn: main.etoro_kpi_prep.v_revenue_conversionfee
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_conversionfee
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 17
row_count: null
generated_at: '2026-05-19T12:26:36Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee.sql
concept_count: 1
formula_count: 17
tier_breakdown:
  tier1_columns: 13
  tier2_columns: 4
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_conversionfee

> View in `main.etoro_kpi_prep`. 1 business concept(s) in §2; 17 of 17 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_conversionfee` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 17 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:01 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_conversionfee` is a view in `main.etoro_kpi_prep` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md`. Additional upstreams: 4 object(s), listed in §5 Lineage.

Of its 17 columns: 13 inherit byte-for-byte from upstream wikis (Tier 1), 4 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID     AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee.sql` L28
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
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID     AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID` | Lookup via alias `dr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Internal customer id (**RealCID**) from deposit or cashout state. (Tier 2 -SP_DepositWithdrawFee, Fact_Deposit_State.CID / Fact_Cashout_State.CID) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 1 | GCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 2 | DateID | INT | YES | Business date as **YYYYMMDD** for the load (**@StartDateID**). (Tier 2 -SP_DepositWithdrawFee, @StartDateID) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 3 | ConversionFee | DECIMAL | YES | **ABS(PIPsInUSD)** at insert; adjusted by direction rules and post-join **UPDATE**s (rollbacks, chargeback reversals, **Fact_CustomerAction** tie-break). (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.PIPsInUSD) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 4 | TransactionType | STRING | YES | Type string from state (**Deposit**, **Withdraw**, chargebacks, refunds, rollbacks, etc.). (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.TransactionType) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 5 | IsIBANTrade | INT | YES | **1** when deposit **FlowID** = 1 or withdraw **FlowID** = 2 on billing fact. (Tier 2 -SP_DepositWithdrawFee, Fact_BillingDeposit.FlowID / Fact_BillingWithdraw.FlowID) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 6 | TransactionID | INT | YES | Cast of upstream column. Formula: `CAST(LEFT(TransactionID, LENGTH(TransactionID) - 1) AS INT)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`) |
| 7 | PaymentMethod | STRING | YES | Funding type name (**Dim_FundingType.Name**). (Tier 2 -SP_DepositWithdrawFee, Dim_FundingType.Name) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 8 | Amount | DECIMAL | YES | Transaction amount in original currency; **ABS** at insert then signed via **#amountDirections** (and edge-case **UPDATE**). (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.Amount) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 9 | Currency | STRING | YES | Currency code (**Dim_Currency.Abbreviation**). (Tier 2 -SP_DepositWithdrawFee, Dim_Currency.Abbreviation) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 10 | AmountUSD | DECIMAL | YES | USD amount; **ABS** at insert then signed like **Amount**. (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.AmountInUSD) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 11 | ExchangeRate | DECIMAL | YES | FX rate on the state row. (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.ExchangeRate) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 12 | BaseExchangeRate | DECIMAL | YES | Base FX rate from state. (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.BaseExchangeRate) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 13 | Depot | STRING | YES | Billing depot name (**Dim_BillingDepot**). (Tier 2 -SP_DepositWithdrawFee, Dim_BillingDepot.Name) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 14 | MIDValue | STRING | YES | Merchant id value on the state row (**MID**). (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.MID) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee). |
| 15 | IsRecurring | INT | YES | Direct passthrough from upstream. Formula: `IsRecurring`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`) |
| 16 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
... (2 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_revenue_conversionfee   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=17 runtime=17 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md`)
- **JOIN/UNION upstreams**: 4 additional object(s)
- **Wiki coverage**: 4/4 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 17 | Tiers: 13 T1, 4 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 17/17 | Source: view_definition*
