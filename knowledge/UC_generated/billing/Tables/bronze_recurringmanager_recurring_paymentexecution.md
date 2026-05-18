---
object_fqn: main.billing.bronze_recurringmanager_recurring_paymentexecution
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_recurringmanager_recurring_paymentexecution
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-18T10:58:49Z'
upstreams:
- RecurringManager.Recurring.PaymentExecution
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md
  source_database: RecurringManager
  source_schema: Recurring
  source_table: PaymentExecution
  source_repo: PaymentsDBs
  datalake_path: Bronze/RecurringManager/Recurring/PaymentExecution
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_recurringmanager_recurring_paymentexecution

> Bronze ingest in `main.billing` (1:1 passthrough of `RecurringManager.Recurring.PaymentExecution`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_recurringmanager_recurring_paymentexecution` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-18 |
| **Created** | Sat Dec 17 14:21:08 UTC 2022 |

---

## 1. What it is

Bronze ingest table populated from production source `RecurringManager.Recurring.PaymentExecution` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md`.

- Lake path: `Bronze/RecurringManager/Recurring/PaymentExecution`
- Copy strategy: `Override`
- Source database: `RecurringManager` (`PaymentsDBs`)
- Source schema/table: `Recurring.PaymentExecution`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentExecutionId | INT | YES | Auto-incrementing primary key. Current max ~859,547. Referenced by PaymentExecutionDepositResult, PaymentExecutionRequest, Notification, and Scheduler.Execution (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution). |
| 1 | PaymentId | INT | YES | FK to Recurring.Payment.PaymentId. Identifies which recurring plan this execution belongs to. Multiple executions per payment over time (one per billing cycle + retries). Indexed for lookup (IX_PaymentExecution_PaymentId) and composite queries (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution). |
| 2 | StatusId | INT | YES | Execution lifecycle status. FK to Dictionary.PaymentExecutionStatus: 1=Planned (1.9%), 2=InProcess, 3=SentToBilling (0.003%), 4=SendToBillingFailed, 5=SoftDeclined (1.3%), 6=HardDeclined (7.5%), 7=Approved (76.5%), 8=Cancelled (12.6%), 9=Skipped (0.2%), 10=Retry. Updated by UpdatePaymentExecutionStatus with optimistic concurrency on previous state (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution). |
| 3 | CycleNumber | INT | YES | Which billing cycle this execution represents (1 = first cycle, 2 = second, etc.). Combined with Retries to uniquely identify an execution attempt. Part of the unique filtered index for Planned executions (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution). |
| 4 | Retries | INT | YES | Retry count within the cycle (1 = first attempt). Used by CreatePaymentExecution in the duplicate check: `NOT EXISTS (PaymentId + StatusId + Retries)`. Part of the unique filtered index for Planned executions (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution). |
| 5 | CreateDate | TIMESTAMP | YES | UTC timestamp when this execution was created by CreatePaymentExecution. Auto-set via default constraint (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution). |
| 6 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the last status change. Set to GETUTCDATE() by UpdatePaymentExecutionStatus and CreatePaymentExecution. NULL if never modified after creation. Used by alert SPs for time-window filtering of stuck executions (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RecurringManager.Recurring.PaymentExecution` | Primary | `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md` |

### 4.2 Pipeline ASCII Diagram

```
RecurringManager.Recurring.PaymentExecution
        │
        ▼
main.billing.bronze_recurringmanager_recurring_paymentexecution   ←── this object
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
| PaymentExecutionId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution) |
| PaymentId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution) |
| StatusId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution) |
| CycleNumber | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution) |
| Retries | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecution) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
