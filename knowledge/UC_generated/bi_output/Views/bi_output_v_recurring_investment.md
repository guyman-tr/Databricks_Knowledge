---
object_fqn: main.bi_output.bi_output_v_recurring_investment
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_v_recurring_investment
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 63
row_count: null
generated_at: '2026-06-19T14:35:51Z'
upstreams:
- main.general.bronze_recurringinvestment_recurringinvestment_planinstances
- main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans
- main.general.bronze_recurringinvestment_recurringinvestment_plans
- main.bi_db.bronze_recurringinvestment_dictionary_planstatus
- main.experience.bronze_recurringinvestment_dictionary_plantype
- main.experience.bronze_recurringinvestment_dictionary_copytype
- main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid
- main.bi_db.bronze_recurringinvestment_dictionary_planeventcode
- main.experience.bronze_recurringinvestment_dictionary_positionstatus
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_v_recurring_investment.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_v_recurring_investment.sql
concept_count: 0
formula_count: 63
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 63
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_v_recurring_investment

> View in `main.bi_output`. 0 business concept(s) in §2; 63 of 63 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_v_recurring_investment` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 63 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-06-19 |
| **Created** | Tue Feb 24 11:50:39 UTC 2026 |

---

## 1. Business Meaning

`bi_output_v_recurring_investment` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.PlanInstances.md`. Additional upstreams: 8 object(s), listed in §5 Lineage.

Of its 63 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 63 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | ActiveDate | DATE | YES | Function call computed in source. Formula: `DATE(date_trunc('month', NextOrderDate))`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 1 | ActiveMonth | STRING | YES | Arithmetic combination of upstream columns. Formula: `date_format(NextOrderDate, 'yyyy-MM')`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 2 | ID | INT | YES | Direct passthrough from upstream. Formula: `ID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 3 | PlanType | INT | YES | Direct passthrough from upstream. Formula: `PlanType`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 4 | PlaneTypeName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.experience.bronze_recurringinvestment_dictionary_plantype`) |
| 5 | GCID | LONG | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 6 | CID | LONG | YES | Direct passthrough from upstream. Formula: `CID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 7 | InstrumentID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 8 | RecurringDepositID | INT | YES | Direct passthrough from upstream. Formula: `RecurringDepositID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 9 | Amount | DECIMAL | YES | Direct passthrough from upstream. Formula: `Amount`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 10 | CurrencyID | INT | YES | Direct passthrough from upstream. Formula: `CurrencyID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 11 | PlanStatusID | INT | YES | Direct passthrough from upstream. Formula: `PlanStatusID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 12 | PlanStatusName | STRING | YES | Direct passthrough from upstream. Formula: `StatusName`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_dictionary_planstatus`) |
| 13 | DepositPlanStatusID | INT | YES | Direct passthrough from upstream. Formula: `DepositPlanStatusID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 14 | StatusReasonID | INT | YES | Direct passthrough from upstream. Formula: `StatusReasonID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 15 | PlanCreationDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `CreationDate`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 16 | EndDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `EndDate`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 17 | ValidFrom | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `ValidFrom`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 18 | ValidTo | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `ValidTo`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 19 | DepositStartDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `DepositStartDate`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 20 | RepeatsOn | INT | YES | Direct passthrough from upstream. Formula: `RepeatsOn`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 21 | FrequencyID | INT | YES | Direct passthrough from upstream. Formula: `FrequencyID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 22 | FundingID | INT | YES | Direct passthrough from upstream. Formula: `FundingID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 23 | CopyType | INT | YES | Direct passthrough from upstream. Formula: `CopyType`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 24 | CopyTypeName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.experience.bronze_recurringinvestment_dictionary_copytype`) |
| 25 | Trace | STRING | YES | Direct passthrough from upstream. Formula: `Trace`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 26 | InstanceID | INT | YES | Direct passthrough from upstream. Formula: `InstanceID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 27 | InstanceStatusID | INT | YES | Direct passthrough from upstream. Formula: `InstanceStatusID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 28 | InstanceStatusName | STRING | YES | Direct passthrough from upstream. Formula: `InstanceStatusID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid`) |
| 29 | InstanceStatusReasonID | INT | YES | Direct passthrough from upstream. Formula: `InstanceStatusReasonID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 30 | InstanceStatusReasonName | STRING | YES | Direct passthrough from upstream. Formula: `EventName`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_dictionary_planeventcode`) |
| 31 | NextOrderDate | TIMESTAMP | YES | Arithmetic combination of upstream columns. Formula: `date_format(NextOrderDate, 'yyyy-MM')`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 32 | CreationDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `CreationDate`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 33 | DepositID | INT | YES | Direct passthrough from upstream. Formula: `DepositID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 34 | DepositAmountUsd | DECIMAL | YES | Direct passthrough from upstream. Formula: `DepositAmountUsd`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 35 | DepositDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `DepositDate`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 36 | DepositCycleNumber | INT | YES | Direct passthrough from upstream. Formula: `DepositCycleNumber`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 37 | HighLevelDepositStatusId | INT | YES | Direct passthrough from upstream. Formula: `HighLevelDepositStatusId`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 38 | DepositStatusID | INT | YES | Direct passthrough from upstream. Formula: `DepositStatusID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 39 | OrderID | INT | YES | Direct passthrough from upstream. Formula: `OrderID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 40 | OrderTradeDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `OrderTradeDate`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 41 | OrderStatusId | INT | YES | Direct passthrough from upstream. Formula: `OrderStatusId`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 42 | PositionExecutionDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `PositionExecutionDate`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 43 | ValidFromInstance | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `ValidFrom ValidFromInstance`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 44 | ValidToInstance | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `ValidTo ValidToInstance`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 45 | PositionFailErrorCode | INT | YES | Direct passthrough from upstream. Formula: `PositionFailErrorCode`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 46 | MirrorID | INT | YES | Direct passthrough from upstream. Formula: `MirrorID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 47 | MirrorOrderCreated | INT | YES | Direct passthrough from upstream. Formula: `MirrorOrderCreated`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 48 | CopyPositionStatusID | INT | YES | Direct passthrough from upstream. Formula: `CopyPositionStatusID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 49 | CopyFailErrorCode | INT | YES | Direct passthrough from upstream. Formula: `CopyFailErrorCode`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 50 | DepositFailReason | INT | YES | Direct passthrough from upstream. Formula: `DepositFailReason`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 51 | TraceInstance | STRING | YES | Computed in source (transform kind not classified). Formula: `Trace TraceInstance`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 52 | CopyParentCID | LONG | YES | Direct passthrough from upstream. Formula: `CopyParentCID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 53 | CopyparentGCID | LONG | YES | Direct passthrough from upstream. Formula: `CopyparentGCID`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 54 | HasBackupPayment | BOOLEAN | YES | Direct passthrough from upstream. Formula: `HasBackupPayment`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 55 | PositionStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `PositionStatus PositionStatusID`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 56 | PositionStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `PositionStatus PositionStatusName`. (Tier 2 — from `main.experience.bronze_recurringinvestment_dictionary_positionstatus`) |
| 57 | IsSkip | INT | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN STRING(InstanceStatusID) in ('3', '4') THEN 1 else 0 END IsSkip`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 58 | ActivePlan | INT | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN max(DepositID) over (partition by ID order by NextOrderDate ASC) is not null and EndDate is null and DepositStatusID = 2 THEN …`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`, `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 59 | PositionAmountUSD | DECIMAL | YES | Direct passthrough from upstream. Formula: `positionamountusd`. (Tier 2 — from `main.general.bronze_recurringinvestment_recurringinvestment_planinstances`) |
| 60 | AmountUSD | DECIMAL | YES | Direct passthrough from upstream. Formula: `amountusd`. (Tier 2 — from `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans`) |
| 61 | IsChurnPlan | INT | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN MAX(ActivePlan) over (partition by ID order by NextOrderDate) = 1 and ActivePlan = 0 THEN 1 else 0 END IsChurnPlan`. (Tier 2 — computed in source) |
| 62 | IsActiveUser | INT | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN sum(ActivePlan) over (partition by CID, activemonth order by NextOrderDate ASC) >= 1 --and ActivePlan = 0 THEN 1 else 0 END IsActiveUser -- isActiveUser = 0 is…`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` | Primary | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.PlanInstances.md` |
| `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` |
| `main.general.bronze_recurringinvestment_recurringinvestment_plans` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.Plans.md` |
| `main.bi_db.bronze_recurringinvestment_dictionary_planstatus` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md` |
| `main.experience.bronze_recurringinvestment_dictionary_plantype` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanType.md` |
| `main.experience.bronze_recurringinvestment_dictionary_copytype` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.CopyType.md` |
| `main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.InstanceStatusID.md` |
| `main.bi_db.bronze_recurringinvestment_dictionary_planeventcode` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanEventCode.md` |
| `main.experience.bronze_recurringinvestment_dictionary_positionstatus` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PositionStatus.md` |

### 5.2 Pipeline ASCII Diagram

```
main.general.bronze_recurringinvestment_recurringinvestment_planinstances
main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans
main.general.bronze_recurringinvestment_recurringinvestment_plans
... (6 more upstream(s))
        │
        ▼
main.bi_output.bi_output_v_recurring_investment   ←── this object
        │
        ▼
main.bi_output_stg.test_tom
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=63 runtime=63 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` (wiki: `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.PlanInstances.md`)
- **JOIN/UNION upstreams**: 8 additional object(s)
- **Wiki coverage**: 8/8 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output_stg.test_tom`

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

*Generated: 2026-06-19 | Concepts: 0 | Formulas: 63 | Tiers: 0 T1, 63 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 63/63 | Source: view_definition*
