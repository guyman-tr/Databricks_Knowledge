---
object_fqn: main.bi_output.bi_output_vg_daily_commission
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_daily_commission
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 37
row_count: null
generated_at: '2026-05-19T15:01:50Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.trading.bronze_etoro_trade_instrumentgroups
- main.trading.bronze_etoro_trade_instrumentmetadata
- main.trading.bronze_etoro_trade_providertoinstrument
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_daily_commission.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_daily_commission.sql
concept_count: 5
formula_count: 37
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 37
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_daily_commission

> View in `main.bi_output`. 5 business concept(s) in §2; 37 of 37 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_daily_commission` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 37 |
| **Concepts** | 5 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Tue Jan 20 14:00:14 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_daily_commission` is a view in `main.bi_output` that composes 4 CASE-based classifier flag(s) computed from upstream IDs, 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyCommisionReport.md`. Additional upstreams: 4 object(s), listed in §5 Lineage.

Of its 37 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 37 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsFuture` discriminator: `isfuture = 1` (futures contract per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsFuture` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsFuture`
**Rules**:
- `isfuture = 1` (futures contract per upstream wiki)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_daily_commission.sql` bi_output.sql L71-L71
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.2 `IsSQF` computed flag
**What**: Computed flag on `IsSQF` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsSQF`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_daily_commission.sql` bi_output.sql L72-L72
**Source(s)**: `main.trading.bronze_etoro_trade_instrumentgroups`

### 2.3 `Is_245` computed flag
**What**: Computed flag on `Is_245` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `Is_245`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_daily_commission.sql` bi_output.sql L73-L73

### 2.4 `IsUSStock` computed flag
**What**: Computed flag on `IsUSStock` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsUSStock`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_daily_commission.sql` bi_output.sql L74-L74

### 2.5 Filter on scope `sqf_instruments`: `GroupID = 59`
**What**: `WHERE` clause at the top of scope `sqf_instruments` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `GroupID`
**Rules**:
- `GroupID = 59`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_daily_commission.sql` L19

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
| Filter on discriminator flags | Use `IsFuture = 1`-style filters on the precomputed flag columns (`IsFuture`, `IsSQF`, `IsUSStock`, `Is_245`) instead of recomputing the underlying CASE predicates downstream. |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `sqf_instruments` applies `GroupID = 59` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | LONG | YES | Computed in source (transform kind not classified). Formula: `select RealCID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 1 | InstrumentID | INT | YES | Computed in source (transform kind not classified). Formula: `SELECT DISTINCT InstrumentID`. (Tier 2 — from `main.trading.bronze_etoro_trade_instrumentgroups`) |
| 2 | Instrument | STRING | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 3 | InstrumentTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 4 | InstrumentType | STRING | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 5 | FullDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 6 | DateID | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 7 | Commissions | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 8 | FullCommissions | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 9 | VolumeOnOpen | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 10 | VolumeOnClose | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 11 | RollOverFee | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 12 | IsSettled | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 13 | IsMirror | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 14 | CommissionOnOpen | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 15 | CommissionOnCloseAdjustment | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 16 | FullCommissionOnOpen | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 17 | FullCommissionOnCloseAdjustment | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 18 | CommissionOnClose | DOUBLE | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 19 | FullCommissionOnClose | DOUBLE | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 20 | IsBuy | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 21 | IsLeverage | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 22 | IsAirDrop | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 23 | SettlementTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 24 | TicketFee | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 25 | TicketFeeByPercent | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 26 | AdminFee | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 27 | SpotAdjustFee | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 28 | InvestedAmountOpen | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 29 | CountUU | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 30 | IsMarginTrade | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentID , Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , d…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 31 | instrumentdisplayname | STRING | YES | Computed in source (transform kind not classified). Formula: `, Instrument , InstrumentTypeID , InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , RollOverFee , dc…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 32 | symbol | STRING | YES | Computed in source (transform kind not classified). Formula: `select InstrumentID, InstrumentDisplayName, IsFuture, Symbol`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 33 | IsFuture | INT | NO | `IsFuture` discriminator: `isfuture = 1` (futures contract per upstream wiki) → set to 1 else 0. Formula: `, InstrumentType , FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , RollOverFee , IsSettled , IsMirror , Commissi…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 34 | IsSQF | INT | NO | `IsSQF` computed flag. Formula: `, FullDate , DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , RollOverFee , IsSettled , IsMirror , CommissionOnOpen , Commis…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 35 | Is_245 | INT | NO | `Is_245` computed flag. Formula: `, DateID , Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , RollOverFee , IsSettled , IsMirror , CommissionOnOpen , CommissionOnCloseAdjus…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |
| 36 | IsUSStock | INT | NO | `IsUSStock` computed flag. Formula: `, Commissions , FullCommissions , VolumeOnOpen , VolumeOnClose , RollOverFee , IsSettled , IsMirror , CommissionOnOpen , CommissionOnCloseAdjustment , F…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyCommisionReport.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.trading.bronze_etoro_trade_instrumentgroups` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentGroups.md` |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentMetaData.md` |
| `main.trading.bronze_etoro_trade_providertoinstrument` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderToInstrument.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.trading.bronze_etoro_trade_instrumentgroups
... (2 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_daily_commission   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=37 runtime=37 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyCommisionReport.md`)
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

*Generated: 2026-05-19 | Concepts: 5 | Formulas: 37 | Tiers: 0 T1, 37 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 37/37 | Source: view_definition*
