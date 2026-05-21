---
object_fqn: main.etoro_kpi_prep.v_revenue_adminfee
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_adminfee
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:26:34Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_adminfee.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_adminfee.sql
concept_count: 1
formula_count: 8
tier_breakdown:
  tier1_columns: 6
  tier2_columns: 1
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 1
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_adminfee

> View in `main.etoro_kpi_prep`. 1 business concept(s) in §2; 7 of 8 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_adminfee` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 8 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:02:56 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_adminfee` is a view in `main.etoro_kpi_prep` that composes a UNION ALL with sign-flipped amount legs (deposit/withdraw composition).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md`.

Of its 8 columns: 6 inherit byte-for-byte from upstream wikis (Tier 1), 1 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Sign-flip leg `main` (multiplies `DECIMAL` by -1)
**What**: This subselect contributes the negative-sign leg of a UNION ALL composition — amount columns are multiplied by -1 so the downstream rollup nets to (deposit - withdraw).
**Columns Involved**: `DECIMAL`
**Rules**:
- `-1 * fca.Amount` (sign-flip on amount)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_adminfee.sql` L12
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`

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
| Sum amounts directly for net flow | Amount columns are already sign-flipped per leg — summing them yields net flow (deposits - withdraws). No need to subset by MIMOAction unless you want gross flow. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Sign flip in scope(s) `main` means summing amount columns nets to (deposit - withdraw). Multiply by -1 again if you want gross withdraw amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | LONG | YES | Position identifier. Allocated by Internal.GetPositionID_Bigint. Unique per position. HASH distribution key. DWH note: for ActionTypeID=36 + CompensationReasonID IN (117,118), extracted from Description field via reverse string parsing with TRY_CAST fallback. COALESCE prefers Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 1 | RealCID | INT | YES | Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | DateID | INT | YES | Integer date key in YYYYMMDD format. DELETE+INSERT keyed on this column. 6,356 distinct dates from April 2008 to present. Passthrough from Fact_CustomerAction.DateID. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| 3 | Occurred | TIMESTAMP | YES | UTC timestamp when the action occurred. Passthrough from Fact_CustomerAction. (Tier 1 — source-dependent) |
| 4 | AdminFee | DECIMAL | YES | Cast of upstream column. Formula: `CAST(-1 * Amount AS DECIMAL(38, 6))`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`) |
| 5 | IsSettled | INT | YES | 1 = real asset, 0 = CFD asset. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 5 — Expert Review) |
| 6 | MirrorID | INT | YES | FK to Trade.Mirror. 0/NULL = manual trade. Positive = copy-trade position. DWH note: set to 0 if action Occurred after a detach-from-mirror event (ActionTypeID=19) for the same PositionID. COALESCE from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 7 | SettlementTypeID | INT | YES | Modern settlement classification from Dim_Position. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. DWH note: switched from FCA to Dim_Position source (2025-10-15) because FCA shows NULL on overnights. (Tier 1 — Trade.PositionTbl) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution
        │
        ▼
main.etoro_kpi_prep.v_revenue_adminfee   ←── this object
        │
        ▼
main.etoro_kpi_prep.mv_revenue_trading
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=8 runtime=8 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md`)

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 8 | Tiers: 6 T1, 1 T2, 0 T3, 0 T4, 1 T5, 0 TN, 0 U | Elements: 8/8 | Source: view_definition*
