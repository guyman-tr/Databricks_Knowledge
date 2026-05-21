---
object_fqn: main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 27
row_count: null
generated_at: '2026-05-19T12:26:36Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
- main.dwh.dim_position
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban
  / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee_withpositiondata.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee_withpositiondata.sql
concept_count: 4
formula_count: 27
tier_breakdown:
  tier1_columns: 13
  tier2_columns: 14
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_conversionfee_withpositiondata

> View in `main.etoro_kpi_prep`. 4 business concept(s) in §2; 27 of 27 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 27 |
| **Concepts** | 4 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:02 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_conversionfee_withpositiondata` is a view in `main.etoro_kpi_prep` that composes 2 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md`. Additional upstreams: 10 object(s), listed in §5 Lineage.

Of its 27 columns: 13 inherit byte-for-byte from upstream wikis (Tier 1), 14 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `ExecutionIBANTradeSuccess` discriminator: `IsIBANTrade = 1` → set to 0 else 1
**What**: Computed flag on `ExecutionIBANTradeSuccess` set to `0` when the predicates below hold, else `1`.
**Columns Involved**: `ExecutionIBANTradeSuccess`
**Rules**:
- `IsIBANTrade = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee_withpositiondata.sql` etoro_kpi_prep.sql L29-L29
**Source(s)**: `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban`

### 2.2 `IsCopy` discriminator: `MirrorID > 0` → set to 1 else 0
**What**: Computed flag on `IsCopy` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopy`
**Rules**:
- `MirrorID > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee_withpositiondata.sql` etoro_kpi_prep.sql L33-L33
**Source(s)**: `main.dwh.dim_position`

### 2.3 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID     AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee_withpositiondata.sql` L38
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.4 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dp.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_conversionfee_withpositiondata.sql` L53
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

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
| Filter on discriminator flags | Use `ExecutionIBANTradeSuccess = 1`-style filters on the precomputed flag columns (`ExecutionIBANTradeSuccess`, `IsCopy`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`, `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID     AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `dp.InstrumentID = di.InstrumentID` | Lookup via alias `di` |

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
| 16 | PositionID | LONG | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(PositionID, PositionID)`. (Tier 2 — from `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban`) |
| 17 | IsSettled | INT | YES | Direct passthrough from upstream. Formula: `IsSettled`. (Tier 5 — from `main.dwh.dim_position`) |
| 18 | IsBuy | BOOLEAN | YES | Direct passthrough from upstream. Formula: `IsBuy`. (Tier 2 — from `main.dwh.dim_position`) |
| 19 | Leverage | INT | YES | Direct passthrough from upstream. Formula: `Leverage`. (Tier 2 — from `main.dwh.dim_position`) |
| 20 | IsAirDrop | INT | YES | Direct passthrough from upstream. Formula: `IsAirDrop`. (Tier 2 — from `main.dwh.dim_position`) |
| 21 | ExecutionIBANTradeSuccess | INT | NO | `ExecutionIBANTradeSuccess` discriminator: `IsIBANTrade = 1` → set to 0 else 1. Formula: `CASE WHEN COALESCE(PositionID, PositionID) IS NULL AND IsIBANTrade = 1 THEN 0 ELSE 1 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban`) |
| 22 | InstrumentID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 23 | InstrumentTypeID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 24 | InstrumentType | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentType`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 25 | IsCopy | INT | NO | `IsCopy` discriminator: `MirrorID > 0` → set to 1 else 0. Formula: `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.dim_position`) |
| 26 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Positions_Opened_From_IBAN.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Positions_Closed_To_IBAN.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
... (8 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=27 runtime=27 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md`)
- **JOIN/UNION upstreams**: 10 additional object(s)
- **Wiki coverage**: 7/10 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 4 | Formulas: 27 | Tiers: 13 T1, 14 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 27/27 | Source: view_definition*
