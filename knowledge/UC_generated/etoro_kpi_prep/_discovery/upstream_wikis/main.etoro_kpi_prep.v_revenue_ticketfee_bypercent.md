---
object_fqn: main.etoro_kpi_prep.v_revenue_ticketfee_bypercent
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_ticketfee_bypercent
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:04:49Z'
upstreams:
- main.general.bronze_historycosts_history_costs
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_ticketfee_bypercent.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_ticketfee_bypercent.sql
concept_count: 2
formula_count: 6
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 5
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_ticketfee_bypercent

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 6 of 6 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_ticketfee_bypercent` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 6 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:54 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_ticketfee_bypercent` is a view in `main.etoro_kpi_prep` that composes a UNION ALL with sign-flipped amount legs (deposit/withdraw composition), 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.general.bronze_historycosts_history_costs` → this object. Canonical upstream documentation: `knowledge/UC_generated/general/<Tables|Views>/bronze_historycosts_history_costs.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 6 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 5 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Sign-flip leg `after_20260308` (multiplies `DECIMAL` by -1)
**What**: This subselect contributes the negative-sign leg of a UNION ALL composition — amount columns are multiplied by -1 so the downstream rollup nets to (deposit - withdraw).
**Columns Involved**: `DECIMAL`
**Rules**:
- `-1 * fca.Amount` (sign-flip on amount)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_ticketfee_bypercent.sql` L59
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.2 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fca.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_ticketfee_bypercent.sql` L62
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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |
| Sum amounts directly for net flow | Amount columns are already sign-flipped per leg — summing them yields net flow (deposits - withdraws). No need to subset by MIMOAction unless you want gross flow. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `fca.InstrumentID = di.InstrumentID` | Lookup via alias `di` |

### 3.4 Gotchas

- Sign flip in scope(s) `after_20260308` means summing amount columns nets to (deposit - withdraw). Multiply by -1 again if you want gross withdraw amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | LONG | YES | Cast of upstream column. Formula: `CAST(PositionID AS BIGINT)`. (Tier 2 — from `main.general.bronze_historycosts_history_costs`) |
| 1 | RealCID | INT | YES | Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Occurred | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `Occurred`. (Tier 2 — from `main.general.bronze_historycosts_history_costs`) |
| 3 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(Occurred, 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.general.bronze_historycosts_history_costs`) |
| 4 | TicketFeeByPercent | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CAST(CASE WHEN CAST(DATE_FORMAT(Occurred, 'yyyyMMdd') AS INT) < 20250525 THEN 0 ELSE ValueInAccountCurrency END AS DECIMAL(38, 6))`. (Tier 2 — from `main.general.bronze_historycosts_history_costs`) |
| 5 | ActionType | STRING | YES | Literal constant set in this object. Formula: `'Open'`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.general.bronze_historycosts_history_costs` | Primary | `knowledge/UC_generated/general/<Tables|Views>/bronze_historycosts_history_costs.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

### 5.2 Pipeline ASCII Diagram

```
main.general.bronze_historycosts_history_costs
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
        │
        ▼
main.etoro_kpi_prep.v_revenue_ticketfee_bypercent   ←── this object
        │
        ▼
main.etoro_kpi_prep.mv_revenue_trading
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=6 runtime=6 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.general.bronze_historycosts_history_costs` (wiki: `knowledge/UC_generated/general/<Tables|Views>/bronze_historycosts_history_costs.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep.mv_revenue_trading`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 6 | Tiers: 1 T1, 5 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: view_definition*
