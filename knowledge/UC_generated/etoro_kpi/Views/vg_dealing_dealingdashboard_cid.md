---
object_fqn: main.etoro_kpi.vg_dealing_dealingdashboard_cid
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.vg_dealing_dealingdashboard_cid
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 30
row_count: null
generated_at: '2026-05-19T15:20:45Z'
upstreams:
- main.dealing.bi_output_dealing_dealingdashboard_cid
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_dealing_dealingdashboard_cid.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_dealing_dealingdashboard_cid.sql
concept_count: 0
formula_count: 30
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 30
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_dealing_dealingdashboard_cid

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 30 of 30 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_dealing_dealingdashboard_cid` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 30 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Wed Feb 04 07:20:21 UTC 2026 |

---

## 1. Business Meaning

`vg_dealing_dealingdashboard_cid` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dealing.bi_output_dealing_dealingdashboard_cid` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`).

Of its 30 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 30 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

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
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

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
| 1 | Date | DATE | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: etoro_kpi.vg_dealing_dealingdashboard_cid -- Captured:…`. (Tier 2 — computed in source) |
| 1 | HedgeServerID | INT | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 2 | InstrumentType | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 3 | InstrumentID | INT | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 4 | InstrumentDisplayName | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 5 | InstrumentName | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 6 | Symbol | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 7 | SellCurrency | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 8 | Exchange | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 9 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 10 | Country | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 11 | Region | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 12 | Mifid | STRING | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 13 | IsCopy | INT | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 14 | IsCFD | INT | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 15 | Leverage | INT | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 16 | NOP | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 17 | LongOpenPositions | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 18 | ShortOpenPositions | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 19 | UnitsNOP | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 20 | UnitsBuy | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 21 | UnitsSell | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 22 | RealizedZero | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 23 | ChangeInUnrealizedZero | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 24 | TotalZero | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 25 | VariableSpread | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 26 | OverNightFee | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 27 | Dividend | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 28 | OverNightFee_Long | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |
| 29 | OverNightFee_Short | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, HedgeServerID , InstrumentType , InstrumentID , InstrumentDisplayName , InstrumentName , Symbol , SellCurrency , Exchange , Regulation , Country , Region , Mifid , IsCopy ,…`. (Tier 2 — from `main.dealing.bi_output_dealing_dealingdashboard_cid`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dealing.bi_output_dealing_dealingdashboard_cid` | Primary | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.dealing.bi_output_dealing_dealingdashboard_cid
        │
        ▼
main.etoro_kpi.vg_dealing_dealingdashboard_cid   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=30 runtime=30 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dealing.bi_output_dealing_dealingdashboard_cid` (wiki: `(no wiki)`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 30 | Tiers: 0 T1, 30 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 30/30 | Source: view_definition*
