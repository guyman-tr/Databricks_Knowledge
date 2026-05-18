---
object_fqn: main.billing.bronze_recurringmanager_recurring_payment
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_recurringmanager_recurring_payment
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-18T10:58:48Z'
upstreams:
- RecurringManager.Recurring.Payment
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md
  source_database: RecurringManager
  source_schema: Recurring
  source_table: Payment
  source_repo: PaymentsDBs
  datalake_path: Bronze/RecurringManager/Recurring/Payment
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

# bronze_recurringmanager_recurring_payment

> Bronze ingest in `main.billing` (1:1 passthrough of `RecurringManager.Recurring.Payment`). 13 of 13 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_recurringmanager_recurring_payment` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Dec 08 04:14:20 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `RecurringManager.Recurring.Payment` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md`.

- Lake path: `Bronze/RecurringManager/Recurring/Payment`
- Copy strategy: `Override`
- Source database: `RecurringManager` (`PaymentsDBs`)
- Source schema/table: `Recurring.Payment`
- 13 of 13 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentId | INT | YES | Auto-incrementing primary key uniquely identifying each recurring payment plan. Referenced by PaymentExecution.PaymentId, PaymentConsent.PaymentId, and Scheduler.Plan.PaymentId. Current max ~200,820 (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 1 | Cid | INT | YES | Customer ID identifying the account holder who owns this recurring plan. Indexed for lookups by customer (IX_RecurringPayment_CID). Used by GetPaymentsByCid and Alert_CIDWithMoreThanAllowed to find all plans for a customer (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 2 | FundingId | INT | YES | External reference to the customer's payment method (credit card, bank account, etc.) in the billing/payments system. Can be updated via UpdatePayment when a customer changes their funding source, and reverted via RevertPayment (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 3 | Amount | DECIMAL | YES | The recurring payment amount in the currency specified by CurrencyId. Represents the fixed amount charged each execution cycle. Can be modified via UpdatePayment and reverted via RevertPayment. Observed range: 50-1,300 in sample data (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 4 | CurrencyId | INT | YES | Currency of the recurring payment amount. References an external currency dictionary (likely etoro Dictionary.Currency). Top values: 1 (49% - likely USD), 2 (25% - likely EUR), 3 (16% - likely GBP), 5 (6% - likely AUD). 26 distinct currencies observed (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 5 | StatusId | INT | YES | Payment plan lifecycle status. No explicit Dictionary table exists in this database - values inferred from code and data: 1=Active (8.2%, created by CreatePayment, included in duplicate check), 2=Cancelled (57.1%, voluntary termination), 3=Blocked (34.1%, hard decline from processor), 4=Invalid (0.01%, rare terminal state), 5=Pending/Paused (0.6%, included with Active in duplicate prevention). Indexed for filtering (IX_RecurringPayment_StatusId) (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 6 | CreateDate | TIMESTAMP | YES | UTC timestamp when the payment plan was first created by CreatePayment. Auto-set via default constraint. Indexed for time-range queries (IX_RecurringPayment_CreateDate). Used by alert SPs to find recently created but unscheduled payments (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 7 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the last modification to this payment. Set to GETUTCDATE() by UpdatePayment on every update. NULL if never modified after creation. Used by alert SPs with time-window filtering (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 8 | StatusReasonId | INT | YES | Reason why the payment reached its current status. FK to Dictionary.StatusReason: 1=RemovedMOP (1.5% - payment method removed), 2=CancelledByUser (34% - voluntary cancellation), 3=CancelledByBO (0.001% - back-office cancellation), 4=CanceledInvestment (6% - investment program cancelled), 5=HardDecline (6% - processor permanently declined). NULL for active payments (53%) (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 9 | RecurringProgramTypeId | INT | YES | Type of recurring program. FK to Dictionary.RecurringProgramType: 1=RecurringDeposit (84% - periodic account deposits), 2=RecurringInvestment (16% - periodic portfolio investments). Defaults to 1. A customer can have only one active plan per type (enforced by CreatePayment) (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 10 | VersionStamp | STRING | YES | Optimistic concurrency token (GUID format). Set when a modification is in progress. RevertPayment checks `WHERE VersionStamp LIKE @VersionStamp` before reverting - if another process changed it, the revert is a no-op. Cleared to NULL on successful revert. NULL for most rows (no pending modification) (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 11 | AuthenticationId | INT | YES | Reference to an external authentication/authorization record for the payment method. Populated when the funding method requires SCA (Strong Customer Authentication) or similar verification. NULL when no authentication is needed (e.g., previously authorized methods) (Tier 1 — inherited from RecurringManager.Recurring.Payment). |
| 12 | Generation | INT | YES | Modification counter tracking how many update rounds the plan has undergone. 0=original/unmodified (98%), 1=modified once (2%). Reset to 0 by UpdatePayment on non-status updates; preserved on status changes. Used with VersionStamp for concurrency control (Tier 1 — inherited from RecurringManager.Recurring.Payment). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RecurringManager.Recurring.Payment` | Primary | `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` |

### 4.2 Pipeline ASCII Diagram

```
RecurringManager.Recurring.Payment
        │
        ▼
main.billing.bronze_recurringmanager_recurring_payment   ←── this object
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
| PaymentId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| Cid | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| FundingId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| Amount | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| CurrencyId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| StatusId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| StatusReasonId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| RecurringProgramTypeId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| VersionStamp | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| AuthenticationId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |
| Generation | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.Payment) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 13 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
