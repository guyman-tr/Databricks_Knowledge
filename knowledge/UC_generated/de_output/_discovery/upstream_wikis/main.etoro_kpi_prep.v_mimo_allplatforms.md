---
object_fqn: main.etoro_kpi_prep.v_mimo_allplatforms
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_mimo_allplatforms
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 21
row_count: null
generated_at: '2026-05-19T12:26:25Z'
upstreams:
- main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
- main.etoro_kpi_prep.v_mimo_tradingplatform
- main.etoro_kpi_prep.v_mimo_emoneyplatform
- main.etoro_kpi_prep.v_mimo_optionsplatform
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_allplatforms.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_allplatforms.sql
concept_count: 2
formula_count: 21
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 21
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_mimo_allplatforms

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 21 of 21 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_allplatforms` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 3 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Mon Apr 27 12:40:37 UTC 2026 |

---

## 1. Business Meaning

`v_mimo_allplatforms` is a view in `main.etoro_kpi_prep` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` → this object. Canonical upstream documentation: `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_first_deposit_all_platforms.md`. Additional upstreams: 4 object(s), listed in §5 Lineage.

Of its 21 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 21 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsGlobalFTD` computed flag
**What**: Computed flag on `IsGlobalFTD` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsGlobalFTD`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_allplatforms.sql` etoro_kpi_prep.sql L77-L77
**Source(s)**: `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms`

### 2.2 Filter on scope `moneyfarm_ftds`: `FTDPlatform = '         '`
**What**: `WHERE` clause at the top of scope `moneyfarm_ftds` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `FTDPlatform`
**Rules**:
- `FTDPlatform = '         '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_allplatforms.sql` L60

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
| Filter on discriminator flags | Use `IsGlobalFTD = 1`-style filters on the precomputed flag columns (`IsGlobalFTD`) instead of recomputing the underlying CASE predicates downstream. |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `moneyfarm_ftds` applies `FTDPlatform = '         '` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(FirstDepositDate, 'yyyyMMdd') AS INT)`. (Tier 2 — computed in source) |
| 1 | Date | DATE | YES | Cast of upstream column. Formula: `CAST(FirstDepositDate AS DATE)`. (Tier 2 — computed in source) |
| 2 | RealCID | INT | YES | Computed in source (transform kind not classified). Formula: `DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_tradingplatform`) |
| 3 | MIMOAction | STRING | YES | Computed in source (transform kind not classified). Formula: `'Deposit' AS MIMOAction, 'DepositID'`. (Tier 2 — literal) |
| 4 | OrigIdentifier | STRING | YES | Computed in source (transform kind not classified). Formula: `OfficeCode AS OrigIdentifier, TransactionID`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_optionsplatform`) |
| 5 | TransactionID | STRING | YES | Cast of upstream column. Formula: `CAST(NULL AS BIGINT)`. (Tier 2 — computed in source) |
| 6 | AmountUSD | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `FirstDepositAmount AS AmountUSD, FirstDepositAmount`. (Tier 2 — literal) |
| 7 | AmountOrigCurrency | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `AmountUSD, AmountUSD`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_optionsplatform`) |
| 8 | FundingTypeID | INT | YES | Arithmetic combination of upstream columns. Formula: `-1 AS FundingTypeID, 3 AS CurrencyID, 'GBP'`. (Tier 2 — computed in source) |
| 9 | CurrencyID | INT | YES | Computed in source (transform kind not classified). Formula: `1 AS CurrencyID, 'USD'`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_optionsplatform`) |
| 10 | Currency | STRING | YES | Computed in source (transform kind not classified). Formula: `1 AS CurrencyID, 'USD'`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_optionsplatform`) |
| 11 | IsPlatformFTD | INT | NO | Computed in source (transform kind not classified). Formula: `IsFTD AS IsPlatformFTD, IsInternalTransfer, IsRedeem, IsIBANTrade`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_tradingplatform`) |
| 12 | IsInternalTransfer | INT | NO | Computed in source (transform kind not classified). Formula: `1 AS IsPlatformFTD, 0 AS IsInternalTransfer, 0 AS IsRedeem, 0`. (Tier 2 — literal) |
| 13 | IsRedeem | INT | NO | Computed in source (transform kind not classified). Formula: `0 AS IsRedeem, 0`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_optionsplatform`) |
| 14 | IsTradeFromIBAN | INT | NO | COALESCE / null-replacement of upstream values. Formula: `COALESCE(IsIBANTrade, 0)`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_tradingplatform`, `main.etoro_kpi_prep.v_mimo_emoneyplatform`, `main.etoro_kpi_prep.v_mimo_optionsplatform` (+1 more)) |
| 15 | MIMOPlatform | STRING | NO | Literal constant set in this object. Formula: `'TradingPlatform'`. (Tier 2 — literal) |
| 16 | IsGlobalFTD | INT | NO | `IsGlobalFTD` computed flag. Formula: `CASE WHEN RealCID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms`) |
| 17 | IsCryptoToFiat | INT | NO | Computed in source (transform kind not classified). Formula: `0 AS IsCryptoToFiat, 0 AS IsRecurring, 0`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_optionsplatform`) |
| 18 | IsRecurring | INT | NO | Computed in source (transform kind not classified). Formula: `0 AS IsCryptoToFiat, 0 AS IsRecurring, 0`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_optionsplatform`) |
| 19 | IsIBANQuickTransfer | INT | NO | Computed in source (transform kind not classified). Formula: `0 AS IsCryptoToFiat, 0 AS IsRecurring, 0`. (Tier 2 — from `main.etoro_kpi_prep.v_mimo_optionsplatform`) |
| 20 | UpdateDate | TIMESTAMP | NO | Literal constant set in this object. Formula: `CURRENT_TIMESTAMP()`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` | Primary | `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_first_deposit_all_platforms.md` |
| `main.etoro_kpi_prep.v_mimo_tradingplatform` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_tradingplatform.md` |
| `main.etoro_kpi_prep.v_mimo_emoneyplatform` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_emoneyplatform.md` |
| `main.etoro_kpi_prep.v_mimo_optionsplatform` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_optionsplatform.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |

### 5.2 Pipeline ASCII Diagram

```
main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
main.etoro_kpi_prep.v_mimo_tradingplatform
main.etoro_kpi_prep.v_mimo_emoneyplatform
... (2 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_mimo_allplatforms   ←── this object
        │
        ▼
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
main.de_output.de_output_ddr_fact_mimo_allplatforms
main.de_output_stg.de_output_ddr_fact_mimo_allplatforms
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` (wiki: `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_first_deposit_all_platforms.md`)
- **JOIN/UNION upstreams**: 4 additional object(s)
- **Wiki coverage**: 4/4 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`
- `main.de_output.de_output_ddr_fact_mimo_allplatforms`
- `main.de_output_stg.de_output_ddr_fact_mimo_allplatforms`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 21 | Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 21/21 | Source: view_definition*
