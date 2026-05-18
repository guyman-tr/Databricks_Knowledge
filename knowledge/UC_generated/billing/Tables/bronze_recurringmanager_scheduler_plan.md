---
object_fqn: main.billing.bronze_recurringmanager_scheduler_plan
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_recurringmanager_scheduler_plan
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 9
row_count: null
generated_at: '2026-05-18T10:58:51Z'
upstreams:
- RecurringManager.Scheduler.Plan
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md
  source_database: RecurringManager
  source_schema: Scheduler
  source_table: Plan
  source_repo: PaymentsDBs
  datalake_path: Bronze/RecurringManager/Scheduler/Plan
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_recurringmanager_scheduler_plan

> Bronze ingest in `main.billing` (1:1 passthrough of `RecurringManager.Scheduler.Plan`). 9 of 9 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_recurringmanager_scheduler_plan` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 9 |
| **Generated** | 2026-05-18 |
| **Created** | Wed Jan 15 04:15:52 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `RecurringManager.Scheduler.Plan` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md`.

- Lake path: `Bronze/RecurringManager/Scheduler/Plan`
- Copy strategy: `Override`
- Source database: `RecurringManager` (`PaymentsDBs`)
- Source schema/table: `Scheduler.Plan`
- 9 of 9 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlanId | INT | YES | Auto-incrementing primary key uniquely identifying each recurring payment schedule. Referenced by Scheduler.Execution.PlanId to link executions to their parent plan. Currently ~189K plans exist (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |
| 1 | PaymentId | INT | YES | Foreign key to the Recurring.Payment table identifying which user payment instruction this schedule belongs to. One-to-one relationship enforced by CreateOrGetPlan's idempotent check. Used as the primary lookup key by GetPlanByPaymentId and SetEndDateForPlanOfPayment. Indexed for fast lookups (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |
| 2 | FrequencyId | INT | YES | Billing cycle frequency: 1=Weekly (15%), 2=BiWeekly (7%), 3=Monthly (78%). See [Frequency](_glossary.md#frequency) for full definitions. Determines how the scheduler calculates the next PlannedDate for each execution. Can be updated via UpdatePlan. (Dictionary.Frequency) (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |
| 3 | StartDate | TIMESTAMP | YES | UTC timestamp of when the first execution should occur. Used by the scheduling engine to calculate subsequent execution dates based on FrequencyId. Set once during plan creation via CreateOrGetPlan. Range: 2021-06-09 to 2026-05-15 (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |
| 4 | StartDateWithUserOffset | STRING | YES | ISO 8601 formatted start date preserving the user's local timezone offset (e.g., "2026-05-10T03:00:00+02:00"). Stored alongside StartDate to prevent timezone conversion ambiguity when displaying the schedule to the user. Never used for scheduling calculations - only for display (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |
| 5 | EndDate | TIMESTAMP | YES | UTC timestamp when the plan was terminated. NULL = plan is active and generating executions. Set by SetEndDateForPlanOfPayment to GETUTCDATE() when the user cancels or the system stops the plan. 91.2% of plans have EndDate set (ended). Once set, the plan is permanently inactive (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |
| 6 | SysStartTime | TIMESTAMP | YES | System-versioning row start time. Automatically managed by SQL Server temporal tables. Tracks when this version of the row became current (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |
| 7 | SysEndTime | TIMESTAMP | YES | System-versioning row end time. Value of 9999-12-31 indicates the current version. When a row is modified, the previous version is moved to History.Plan with SysEndTime set to the modification timestamp (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |
| 8 | ChargingDay | INT | YES | Day of the month (1-28) when the charge should occur for Monthly plans. NULL for 66% of plans (legacy plans created before this column was added, or Weekly/BiWeekly plans where the charge day is derived from StartDate). Can be updated via UpdatePlan if the user changes their preferred billing day (Tier 1 — inherited from RecurringManager.Scheduler.Plan). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RecurringManager.Scheduler.Plan` | Primary | `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` |

### 4.2 Pipeline ASCII Diagram

```
RecurringManager.Scheduler.Plan
        │
        ▼
main.billing.bronze_recurringmanager_scheduler_plan   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| PlanId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |
| PaymentId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |
| FrequencyId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |
| StartDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |
| StartDateWithUserOffset | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |
| EndDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |
| ChargingDay | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Plan) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 9 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 9/9 | Source: bronze_tier1_inheritance*
