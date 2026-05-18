---
object_fqn: main.billing.bronze_recurringmanager_scheduler_execution
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_recurringmanager_scheduler_execution
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-18T10:58:50Z'
upstreams:
- RecurringManager.Scheduler.Execution
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md
  source_database: RecurringManager
  source_schema: Scheduler
  source_table: Execution
  source_repo: PaymentsDBs
  datalake_path: Bronze/RecurringManager/Scheduler/Execution
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 13
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_recurringmanager_scheduler_execution

> Bronze ingest in `main.billing` (1:1 passthrough of `RecurringManager.Scheduler.Execution`). 13 of 13 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_recurringmanager_scheduler_execution` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-18 |
| **Created** | Wed Jan 15 04:16:08 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `RecurringManager.Scheduler.Execution` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md`.

- Lake path: `Bronze/RecurringManager/Scheduler/Execution`
- Copy strategy: `Override`
- Source database: `RecurringManager` (`PaymentsDBs`)
- Source schema/table: `Scheduler.Execution`
- 13 of 13 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ExecutionId | INT | YES | Auto-incrementing primary key. ~856K rows exist. Referenced in GetExecutionByPaymentExecution, GetExecutionsForPlan, UpdateExecutionPlannedDate, RevertExecution, and alert procedures (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 1 | PlanId | INT | YES | FK to Scheduler.Plan.PlanId. Links this execution to its parent schedule. Indexed with ExecutionStatusId and ExecutionTypeId for efficient lookups. Each plan generates one execution per billing cycle (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 2 | PaymentExecutionId | INT | YES | Cross-schema FK to the payment execution record in the Recurring schema. One-to-one relationship per execution attempt. Used by GetExecutionByPaymentExecution for reverse lookups. The unique filtered index UQ_Scheduler_Execution ensures only one active (status=1) execution exists per PaymentExecutionId + ExecutionTypeId combination (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 3 | PlannedDate | TIMESTAMP | YES | UTC timestamp of when this execution should be processed. Set during creation based on the plan's frequency, start date, and charging day. Used by GetExecutionsToProcessWithLock's WHERE clause (`PlannedDate < GETUTCDATE()`) to pick up due executions. Can be modified by UpdateExecutionPlannedDate when rescheduling (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 4 | ExecutionTypeId | INT | YES | Classification of execution attempt: 1=Planned (regular scheduled charge), 2=Dunning (retry after soft decline). Currently 100% of rows are Planned. Filtered by GetExecutionsToProcessWithLock and SetStampForExecutionsWithLock. See [Execution Type](_glossary.md#execution-type). (Dictionary.ExecutionType) (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 5 | ExecutionStatusId | INT | YES | Lifecycle state: 1=Planned (1.9%), 2=WaitingForProcess, 3=Sent (0.01%), 4=Canceled (12.6%), 5=Failed (0.003%), 6=Done (85.4%). Heavily indexed across 5 indexes. UpdateExecutionsStatus refuses to update rows in status 4 or 6 (terminal states). See [Execution Status](_glossary.md#execution-status). (Dictionary.ExecutionStatus) (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 6 | CreateDate | TIMESTAMP | YES | UTC timestamp of when the execution record was created, set to GETDATE() in CreateOrGetExecution. Distinct from PlannedDate (when it should run) and ActualExecutionDate (when it was actually picked up) (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 7 | Stamp | STRING | YES | Distributed lock token. NULL = unclaimed and available for processing. Set to a GUID by GetExecutionsToProcessWithLock/SetStampForExecutionsWithLock to claim ownership. Prevents duplicate processing across multiple RecurringScheduler worker pods. 14.5% NULL (unclaimed: Planned + Canceled-before-processing) (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 8 | ActualExecutionDate | TIMESTAMP | YES | UTC timestamp of when the execution was actually picked up for processing (not when the charge completed). Set to GETUTCDATE() simultaneously with Stamp by the lock procedures. NULL = not yet processed (7%). Indexed for alert queries that detect stuck executions (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 9 | SysStartTime | TIMESTAMP | YES | System-versioning row start time. Automatically managed by SQL Server temporal tables (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 10 | SysEndTime | TIMESTAMP | YES | System-versioning row end time. 9999-12-31 = current version. Previous versions stored in History.Execution (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 11 | RecurringProgramTypeId | INT | YES | Program classification: 1=RecurringDeposit, 2=RecurringInvestment. NULL for 52% of rows (legacy - column added after initial launch). Routes execution results to the correct downstream handler. See [Recurring Program Type](_glossary.md#recurring-program-type). (Dictionary.RecurringProgramType) (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |
| 12 | VersionStamp | STRING | YES | Optimistic concurrency token for planned date modifications. Set by UpdateExecutionPlannedDate, checked by RevertExecution before reverting. NULL for 99.4% of rows. Non-NULL indicates the execution's PlannedDate was rescheduled and the VersionStamp identifies the modification version (Tier 1 — inherited from RecurringManager.Scheduler.Execution). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RecurringManager.Scheduler.Execution` | Primary | `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` |

### 4.2 Pipeline ASCII Diagram

```
RecurringManager.Scheduler.Execution
        │
        ▼
main.billing.bronze_recurringmanager_scheduler_execution   ←── this object
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
| ExecutionId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| PlanId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| PaymentExecutionId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| PlannedDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| ExecutionTypeId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| ExecutionStatusId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| Stamp | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| ActualExecutionDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| RecurringProgramTypeId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |
| VersionStamp | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Scheduler.Execution) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 13 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
