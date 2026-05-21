---
object_fqn: main.etoro_kpi_prep.v_revenue_commission
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_revenue_commission
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T12:26:36Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_commission.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_commission.sql
concept_count: 2
formula_count: 15
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 5
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 1
  tier_null_columns: 0
  unverified_columns: 0
---

# v_revenue_commission

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 14 of 15 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_commission` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 15 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:03:00 UTC 2026 |

---

## 1. Business Meaning

`v_revenue_commission` is a view in `main.etoro_kpi_prep` that composes 2 CASE-based classifier flag(s) computed from upstream IDs.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`.

Of its 15 columns: 9 inherit byte-for-byte from upstream wikis (Tier 1), 5 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `ActionType` discriminator: `ActionTypeID IN (1, 2, 3, 39)` → set to '    ' else '     '
**What**: Computed flag on `ActionType` set to `'    '` when the predicates below hold, else `'     '`.
**Columns Involved**: `ActionType`
**Rules**:
- `ActionTypeID IN (1, 2, 3, 39)`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_commission.sql` etoro_kpi_prep.sql L17-L20
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.2 `IsActiveTrade` discriminator: `MirrorID > 0` → set to 1 else 0
**What**: Computed flag on `IsActiveTrade` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsActiveTrade`
**Rules**:
- `MirrorID > 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_revenue_commission.sql` etoro_kpi_prep.sql L21-L28
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

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
| Filter on discriminator flags | Use `ActionType = 1`-style filters on the precomputed flag columns (`ActionType`, `IsActiveTrade`) instead of recomputing the underlying CASE predicates downstream. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | LONG | YES | Surrogate bigint from `Internal.GetPositionID_Bigint` domain; unique trade position key. (Tier 1 — Trade.PositionTbl) |
| 1 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 2 | DateID | INT | YES | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 3 | Occurred | TIMESTAMP | YES | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 4 | etr_ymd | STRING | YES | Direct passthrough from upstream. Formula: `etr_ymd`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 5 | Commission | DECIMAL | YES | Open commission in dollars (`/100` cents conversion on ingest per `Dim_Position` lineage notes). (Tier 1 — Trade.PositionTbl) |
| 6 | CommissionOnClose | DECIMAL | YES | Close commission dollars — reopen-adjust net-of-original per `Dim_Position` wiki. **`CommissionOnCloseOrig` preserves untouched close fee.** (Tier 1 — Trade.PositionTbl) |
| 7 | CommissionByUnits | DECIMAL | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 8 | ActionTypeID | INT | YES | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds. (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) |
| 9 | ActionType | STRING | NO | `ActionType` discriminator: `ActionTypeID IN (1, 2, 3, 39)` → set to '    ' else '     '. Formula: `CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN 'Open' ELSE 'Close' END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 10 | IsActiveTrade | INT | NO | `IsActiveTrade` discriminator: `MirrorID > 0` → set to 1 else 0. Formula: `CASE WHEN MirrorID > 0 AND COALESCE(IsAirdrop, 0) = 0 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 11 | IsSettled | INT | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 12 | MirrorID | INT | YES | FK to Trade.Mirror (`0`/NULL ⇒ manual trading; >0 ⇒ copy-trade child). (Tier 1 — Trade.PositionTbl) |
| 13 | SettlementTypeID | INT | YES | **`Dictionary.SettlementTypes`** modern encoding (`0 CFD`, `1 REAL`, `2 TRS`, `3 CMT`, `4 REAL_FUTURES`, `5 MARGIN_TRADE`). Supersedes naïve `IsSettled` reads. (Tier 1 — Trade.PositionTbl) |
| 14 | TotalCommission | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `ELSE 0 END AS DECIMAL(38, 6) )`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
        │
        ▼
main.etoro_kpi_prep.v_revenue_commission   ←── this object
        │
        ▼
main.etoro_kpi_prep.mv_revenue_trading
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=15 runtime=15 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 15 | Tiers: 9 T1, 5 T2, 0 T3, 0 T4, 1 T5, 0 TN, 0 U | Elements: 15/15 | Source: view_definition*
