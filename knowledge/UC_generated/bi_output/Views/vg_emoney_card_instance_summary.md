---
object_fqn: main.bi_output.vg_emoney_card_instance_summary
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_emoney_card_instance_summary
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T15:01:58Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_card_instance_summary.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_card_instance_summary.sql
concept_count: 0
formula_count: 6
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 3
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_emoney_card_instance_summary

> View in `main.bi_output`. 0 business concept(s) in §2; 6 of 6 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_card_instance_summary` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 6 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jan 19 11:58:45 UTC 2026 |

---

## 1. Business Meaning

`vg_emoney_card_instance_summary` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Card_Instance_Summary.md`.

Of its 6 columns: 3 inherit byte-for-byte from upstream wikis (Tier 1), 3 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | CID | LONG | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 1 | Customer_Card_ID | LONG | YES | Auto-incrementing surrogate PK of the card instance. Referenced by FiatCardStatuses.CardInstanceId. DWH note: renamed from Id in dbo.FiatCardInstances. (Tier 1 — dbo.FiatCardInstances) |
| 2 | Customer_Card_Status | STRING | YES | Current lifecycle status of THIS specific card instance. Resolved via JOIN on eMoney_Dictionary_CardStatus (newest FiatCardStatuses event by EventTimestamp DESC). 0=NotActivated (32.9%), 1=Activated (29.8%), 2=Blocked (11.2%), 7=Expired (21.8%), 4=Risk, 5=Stolen (3.4%), 6=Lost (0.8%), 3=Suspended, 8=Fraud, NULL=0.1%. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 3 | Customer_Card_Order_Date | TIMESTAMP | YES | Date the card instance was first issued — CAST(MIN(FiatCardStatuses.EventTimestamp WHERE CardStatusId=0) AS DATE). First NotActivated event = card creation/delivery. NULL for 1,120 instances with no status history. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 4 | Customer_Card_Activation_Date | TIMESTAMP | YES | Date the cardholder first activated this card instance — CAST(MIN(FiatCardStatuses.EventTimestamp WHERE CardStatusId=1) AS DATE). NULL for 59,932 rows (45.9%) where the card was never activated by the cardholder. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 5 | Customer_Card_Expiration_Date | TIMESTAMP | YES | Expiration date of this card instance. NULL for instances where expiration is not yet set. DWH note: CAST from datetime2 to DATE from FiatCardInstances.CardExpirationDate. (Tier 1 — dbo.FiatCardInstances) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | Primary | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Card_Instance_Summary.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
        │
        ▼
main.bi_output.vg_emoney_card_instance_summary   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=6 runtime=6 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` (wiki: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Card_Instance_Summary.md`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 6 | Tiers: 3 T1, 3 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: view_definition*
