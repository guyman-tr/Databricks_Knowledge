---
object_fqn: main.etoro_kpi_prep.v_ddr_revenues
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_ddr_revenues
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 24
row_count: null
generated_at: '2026-05-19T12:26:22Z'
upstreams:
- main.etoro_kpi_prep.v_revenue_stakingfee
- main.etoro_kpi_prep.v_fact_customeraction_w_metrics
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype
- main.etoro_kpi_prep.v_revenue_optionsplatform
- main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
- main.etoro_kpi_prep.v_revenue_interestfee
- main.etoro_kpi_prep_stg.v_fact_customeraction_w_metrics
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql
concept_count: 14
formula_count: 24
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 2
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 22
  unverified_columns: 0
---

# v_ddr_revenues

> View in `main.etoro_kpi_prep`. 14 business concept(s) in §2; 24 of 24 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_ddr_revenues` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 24 |
| **Concepts** | 14 (see §2) |
| **Downstream consumers** | 3 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Apr 28 13:47:57 UTC 2026 |

---

## 1. Business Meaning

`v_ddr_revenues` is a view in `main.etoro_kpi_prep` that composes 12 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.etoro_kpi_prep.v_revenue_stakingfee` → this object. Canonical upstream documentation: `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_stakingfee.md`. Additional upstreams: 7 object(s), listed in §5 Lineage.

Of its 24 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 2 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 22 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsCopy` discriminator: `MirrorID > 0` → set to 1 else 0
**What**: Computed flag on `IsCopy` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopy`
**Rules**:
- `MirrorID > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L31-L34
**Source(s)**: `main.etoro_kpi_prep.v_fact_customeraction_w_metrics`

### 2.2 `IsLeveraged` discriminator: `Leverage > 1` → set to 1 else 0
**What**: Computed flag on `IsLeveraged` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsLeveraged`
**Rules**:
- `Leverage > 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L36-L39
**Source(s)**: `main.etoro_kpi_prep.v_fact_customeraction_w_metrics`

### 2.3 `d_InstrumentTypeID` discriminator: `ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40)`, `ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40)`, `ActionTypeID = 35` → set to 5
**What**: Computed flag on `d_InstrumentTypeID` set to `5` when the predicates below hold, else `None`.
**Columns Involved**: `d_InstrumentTypeID`
**Rules**:
- `ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40)`
- `ActionTypeID IN (1, 2, 3, 39, 4, 5, 6, 28, 40)`
- `ActionTypeID = 35`
- `IsFeeDividend = 1`
- `ActionTypeID = 35`
- `IsFeeDividend = 2`
- `ActionTypeID = 35`
- `IsFeeDividend = 3`
- `ActionTypeID = 35`
- `IsFeeDividend = 4`
- `ActionTypeID = 36`
- `CompensationReasonID = 117`
- `ActionTypeID = 36`
- `CompensationReasonID = 118`
- `ActionTypeID = 30`
- `IsRedeem = 0`
- `ActionTypeID IN (7, 44)`
- `ActionTypeID IN (8, 45)`
- `ActionTypeID = 36`
- `CompensationReasonID = 30`
- `ActionTypeID = 30`
- `IsRedeem = 1`
- `ActionTypeID = 36`
- `CompensationReasonID = 119`
- `MetricName = '           '`
- `MetricName = '                    '`
- `MetricName = '                     '`
- `MetricName = '                     '`
- `MetricName = '               '`
- `MetricName = '               '`
- `MetricName = '            '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L104-L247

### 2.4 `d_IsSettled` computed flag
**What**: Computed flag on `d_IsSettled` set to `1` when the predicates below hold, else `None`.
**Columns Involved**: `d_IsSettled`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L248-L263

### 2.5 `d_IsCopy` discriminator: `MetricName = '            '` → set to 0
**What**: Computed flag on `d_IsCopy` set to `0` when the predicates below hold, else `None`.
**Columns Involved**: `d_IsCopy`
**Rules**:
- `MetricName = '            '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L264-L279

### 2.6 `d_IsBuy` discriminator: `MetricName = '            '` → set to 1
**What**: Computed flag on `d_IsBuy` set to `1` when the predicates below hold, else `None`.
**Columns Involved**: `d_IsBuy`
**Rules**:
- `MetricName = '            '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L280-L295

### 2.7 `d_IsLeveraged` discriminator: `MetricName = '            '` → set to 0
**What**: Computed flag on `d_IsLeveraged` set to `0` when the predicates below hold, else `None`.
**Columns Involved**: `d_IsLeveraged`
**Rules**:
- `MetricName = '            '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L296-L311

### 2.8 `d_IsFuture` discriminator: `MetricName = '            '` → set to 0
**What**: Computed flag on `d_IsFuture` set to `0` when the predicates below hold, else `None`.
**Columns Involved**: `d_IsFuture`
**Rules**:
- `MetricName = '            '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L312-L327

### 2.9 `d_IsCopyFund` discriminator: `MetricName = '            '` → set to 0
**What**: Computed flag on `d_IsCopyFund` set to `0` when the predicates below hold, else `None`.
**Columns Involved**: `d_IsCopyFund`
**Rules**:
- `MetricName = '            '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L328-L343

### 2.10 `d_IsAirDrop` discriminator: `MetricName = '          '` → set to 0
**What**: Computed flag on `d_IsAirDrop` set to `0` when the predicates below hold, else `None`.
**Columns Involved**: `d_IsAirDrop`
**Rules**:
- `MetricName = '          '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L344-L405

### 2.11 `d_IsMarginTrade` discriminator: `SettlementTypeID = 5`, `MetricName = '    '` → set to 0
**What**: Computed flag on `d_IsMarginTrade` set to `0` when the predicates below hold, else `None`.
**Columns Involved**: `d_IsMarginTrade`
**Rules**:
- `SettlementTypeID = 5`
- `MetricName = '    '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L406-L451

### 2.12 `IncludedInTotalRevenue` discriminator: `MetricName LIKE '              '` → set to 0 else 1
**What**: Computed flag on `IncludedInTotalRevenue` set to `0` when the predicates below hold, else `1`.
**Columns Involved**: `IncludedInTotalRevenue`
**Rules**:
- `MetricName LIKE '              '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` etoro_kpi_prep.sql L463-L472

### 2.13 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `v.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` L70
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.14 Dim lookup via alias `dat` → `gold_sql_dp_prod_we_dwh_dbo_dim_actiontype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `v.ActionTypeID = dat.ActionTypeID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_ddr_revenues.sql` L72
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype`

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
| Filter on discriminator flags | Use `IncludedInTotalRevenue = 1`-style filters on the precomputed flag columns (`IncludedInTotalRevenue`, `IsCopy`, `IsLeveraged`, `d_InstrumentTypeID`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `gold_sql_dp_prod_we_dwh_dbo_dim_actiontype`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `v.InstrumentID = di.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` | `v.ActionTypeID = dat.ActionTypeID` | Lookup via alias `dat` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(ADD_MONTHS(UpdateDate, -1) AS DATE), 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results`) |
| 1 | Date | DATE | YES | Function call computed in source. Formula: `to_date(CAST(DateID AS STRING), 'yyyyMMdd')`. (Tier 2 — literal) |
| 2 | RealCID | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.RealCID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 3 | ActionTypeID | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.ActionTypeID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 4 | ActionType | STRING | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.ActionType`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 5 | InstrumentTypeID | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.InstrumentTypeID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 6 | IsSettled | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsSettled`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 7 | IsCopy | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsCopy`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 8 | Metric | STRING | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.Metric`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 9 | Amount | DOUBLE | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.Amount`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 10 | CountTransactions | LONG | NO | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.CountTransactions`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 11 | IncludedInTotalRevenue | INT | NO | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IncludedInTotalRevenue`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 12 | CountAsActiveTrade | LONG | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.CountAsActiveTrade`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 13 | IsBuy | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsBuy`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 14 | IsLeveraged | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsLeveraged`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 15 | IsFuture | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsFuture`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 16 | IsCopyFund | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsCopyFund`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 17 | IsOpenedFromIBAN | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsOpenedFromIBAN`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 18 | IsClosedToIBAN | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsClosedToIBAN`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 19 | IsRecurring | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsRecurring`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 20 | IsAirDrop | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsAirDrop`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 21 | IsSQF | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsSQF`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 22 | IsC2P | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsC2P`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |
| 23 | IsMarginTrade | INT | YES | Source: `main.etoro_kpi_prep.v_revenue_stakingfee.IsMarginTrade`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi_prep.v_revenue_stakingfee`). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.etoro_kpi_prep.v_revenue_stakingfee` | Primary | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_stakingfee.md` |
| `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_w_metrics.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ActionType.md` |
| `main.etoro_kpi_prep.v_revenue_optionsplatform` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_optionsplatform.md` |
| `main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_cryptotofiat_c2f.md` |
| `main.etoro_kpi_prep.v_revenue_interestfee` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_interestfee.md` |
| `main.etoro_kpi_prep_stg.v_fact_customeraction_w_metrics` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.etoro_kpi_prep.v_revenue_stakingfee
main.etoro_kpi_prep.v_fact_customeraction_w_metrics
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
... (5 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_ddr_revenues   ←── this object
        │
        ▼
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
main.de_output.de_output_ddr_fact_revenue_generating_actions
main.de_output_stg.qa_ddr_fact_revenue_generating_actions
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=24 runtime=24 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.etoro_kpi_prep.v_revenue_stakingfee` (wiki: `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_stakingfee.md`)
- **JOIN/UNION upstreams**: 7 additional object(s)
- **Wiki coverage**: 6/7 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`
- `main.de_output.de_output_ddr_fact_revenue_generating_actions`
- `main.de_output_stg.qa_ddr_fact_revenue_generating_actions`

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

*Generated: 2026-05-19 | Concepts: 14 | Formulas: 24 | Tiers: 0 T1, 2 T2, 0 T3, 0 T4, 0 T5, 22 TN, 0 U | Elements: 24/24 | Source: view_definition*
