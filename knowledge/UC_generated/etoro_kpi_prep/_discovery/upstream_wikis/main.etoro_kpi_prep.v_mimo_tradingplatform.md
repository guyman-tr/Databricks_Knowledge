---
object_fqn: main.etoro_kpi_prep.v_mimo_tradingplatform
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_mimo_tradingplatform
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 19
row_count: null
generated_at: '2026-05-19T12:04:42Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql
concept_count: 9
formula_count: 19
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 17
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_mimo_tradingplatform

> View in `main.etoro_kpi_prep`. 9 business concept(s) in §2; 19 of 19 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_tradingplatform` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 19 |
| **Concepts** | 9 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 24 12:39:32 UTC 2026 |

---

## 1. Business Meaning

`v_mimo_tradingplatform` is a view in `main.etoro_kpi_prep` that composes 6 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 5 object(s), listed in §5 Lineage.

Of its 19 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 17 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsFTD` computed flag
**What**: Computed flag on `IsFTD` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsFTD`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` etoro_kpi_prep.sql L18-L18
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.2 `IsInternalTransfer` discriminator: `FundingTypeID = 33` → set to 1 else 0
**What**: Computed flag on `IsInternalTransfer` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsInternalTransfer`
**Rules**:
- `FundingTypeID = 33`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` etoro_kpi_prep.sql L19-L19
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`

### 2.3 `IsIBANTrade` discriminator: `ActionTypeID = 44` → set to 1 else 0
**What**: Computed flag on `IsIBANTrade` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsIBANTrade`
**Rules**:
- `ActionTypeID = 44`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` etoro_kpi_prep.sql L22-L22
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.4 `IsIBANQuickTransfer` discriminator: `MoveMoneyReasonID = 6` → set to 1 else 0
**What**: Computed flag on `IsIBANQuickTransfer` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsIBANQuickTransfer`
**Rules**:
- `MoveMoneyReasonID = 6`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` etoro_kpi_prep.sql L23-L23
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.5 `IsInternalTransfer` discriminator: `FundingTypeID_Funding = 33` → set to 1 else 0
**What**: Computed flag on `IsInternalTransfer` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsInternalTransfer`
**Rules**:
- `FundingTypeID_Funding = 33`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` etoro_kpi_prep.sql L49-L49
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw`

### 2.6 `IsIBANTrade` discriminator: `ActionTypeID = 45` → set to 1 else 0
**What**: Computed flag on `IsIBANTrade` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsIBANTrade`
**Rules**:
- `ActionTypeID = 45`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` etoro_kpi_prep.sql L52-L52
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.7 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_currency`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_currency` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fbd.CurrencyID = dc.CurrencyID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` L27,L57
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`

### 2.8 Dim lookup via alias `dc1` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fca.RealCID = dc1.RealCID     AND dc1.FTDPlatformID = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` L29
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.9 Filter on scope `mimo_deduped`: `rn = 1`
**What**: `WHERE` clause at the top of scope `mimo_deduped` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `rn`
**Rules**:
- `rn = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_tradingplatform.sql` L88

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
| Filter on discriminator flags | Use `IsFTD = 1`-style filters on the precomputed flag columns (`IsFTD`, `IsIBANQuickTransfer`, `IsIBANTrade`, `IsInternalTransfer`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_currency`, `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | `fbd.CurrencyID = dc.CurrencyID` | Lookup via alias `dc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `fca.RealCID = dc1.RealCID     AND dc1.FTDPlatformID = 1` | Lookup via alias `dc1` |

### 3.4 Gotchas

- Scope `mimo_deduped` applies `rn = 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 1 | Date | DATE | YES | Function call computed in source. Formula: `to_date(CAST(DateID AS STRING), 'yyyyMMdd')`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 2 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 3 | MIMOAction | STRING | NO | Computed in source (transform kind not classified). Formula: `'Deposit' AS MIMOAction, 'DepositID' AS OrigIdentifier, DepositID`. (Tier 2 — literal) |
| 4 | OrigIdentifier | STRING | NO | Computed in source (transform kind not classified). Formula: `'Deposit' AS MIMOAction, 'DepositID' AS OrigIdentifier, DepositID`. (Tier 2 — literal) |
| 5 | TransactionID | INT | YES | Computed in source (transform kind not classified). Formula: `'Deposit' AS MIMOAction, 'DepositID' AS OrigIdentifier, DepositID`. (Tier 2 — literal) |
| 6 | AmountUSD | DECIMAL | YES | Direct passthrough from upstream. Formula: `Amount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 7 | AmountOrigCurrency | DECIMAL | YES | Direct passthrough from upstream. Formula: `Amount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`) |
| 8 | FundingTypeID | INT | YES | Ledger funding / wallet channel identifier (deposits & cash-outs). Nullable upstream coerced with `ISNULL(...,0)` sentinel row **`0`** (`Dim_FundingType.md`). **Value 27 pairs with redeem flag derivation on cash-outs.** References `Dim_FundingType`. (Tier 1 — History.Credit) |
| 9 | CurrencyID | INT | YES | Direct passthrough from upstream. Formula: `ProcessCurrencyID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw`) |
| 10 | Currency | STRING | YES | Direct passthrough from upstream. Formula: `Abbreviation`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`) |
| 11 | IsFTD | INT | NO | `IsFTD` computed flag. Formula: `CASE WHEN FTDTransactionID = DepositID THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 12 | IsInternalTransfer | INT | NO | `IsInternalTransfer` discriminator: `FundingTypeID = 33` → set to 1 else 0. Formula: `CASE WHEN FundingTypeID = 33 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`) |
| 13 | IsRedeem | INT | NO | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 14 | IsRecurring | INT | NO | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 15 | IsIBANTrade | INT | NO | `IsIBANTrade` discriminator: `ActionTypeID = 44` → set to 1 else 0. Formula: `CASE WHEN ActionTypeID = 44 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 16 | IsCryptoToFiat | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 17 | IsIBANQuickTransfer | INT | NO | `IsIBANQuickTransfer` discriminator: `MoveMoneyReasonID = 6` → set to 1 else 0. Formula: `CASE WHEN MoveMoneyReasonID = 6 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 18 | UpdateDate | TIMESTAMP | NO | Literal constant set in this object. Formula: `CURRENT_TIMESTAMP()`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
... (3 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_mimo_tradingplatform   ←── this object
        │
        ▼
main.etoro_kpi_prep.v_mimo_allplatforms
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=19 runtime=19 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 5 additional object(s)
- **Wiki coverage**: 5/5 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep.v_mimo_allplatforms`

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

*Generated: 2026-05-19 | Concepts: 9 | Formulas: 19 | Tiers: 2 T1, 17 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 19/19 | Source: view_definition*
