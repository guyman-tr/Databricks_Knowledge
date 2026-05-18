---
object_fqn: main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 12
row_count: null
generated_at: '2026-05-18T10:58:50Z'
upstreams:
- RecurringManager.Recurring.PaymentExecutionDepositResult
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md
  source_database: RecurringManager
  source_schema: Recurring
  source_table: PaymentExecutionDepositResult
  source_repo: PaymentsDBs
  datalake_path: Bronze/RecurringManager/Recurring/PaymentExecutionDepositResult
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 12
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_recurringmanager_recurring_paymentexecutiondepositresult

> Bronze ingest in `main.billing` (1:1 passthrough of `RecurringManager.Recurring.PaymentExecutionDepositResult`). 12 of 12 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 12 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Feb 10 13:17:22 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `RecurringManager.Recurring.PaymentExecutionDepositResult` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md`.

- Lake path: `Bronze/RecurringManager/Recurring/PaymentExecutionDepositResult`
- Copy strategy: `Override`
- Source database: `RecurringManager` (`PaymentsDBs`)
- Source schema/table: `Recurring.PaymentExecutionDepositResult`
- 12 of 12 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentExecutionDepositResultId | INT | YES | Auto-incrementing primary key. PAGE compressed. Current max ~354,564 (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 1 | PaymentExecutionId | INT | YES | FK to Recurring.PaymentExecution.PaymentExecutionId. Links this result to the execution that triggered the billing attempt. Part of the upsert key with CycleNumber. Indexed (PAGE compressed) (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 2 | CycleNumber | INT | YES | Billing cycle number matching the execution's cycle. Part of the upsert key with PaymentExecutionId (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 3 | AmountInUsd | DECIMAL | YES | The deposit amount converted to USD. Used for financial reporting and reconciliation. The original amount in the payment's currency is stored in PaymentExecutionRequest.Amount (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 4 | DepositId | INT | YES | External reference to the deposit transaction in the billing/payments system. Created by the payment processor when the charge is initiated. Used for reconciliation between the recurring system and the billing ledger (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 5 | PaymentStatusId | INT | YES | Raw billing processor response status. NOT from Dictionary.PaymentExecutionStatus - these are external billing system codes: 2=Approved (89.5%), 3=Declined (10%), 35=Severe failure (0.5%), 4=Other failure (0.1%). Maps to ExecutionStatusResultConfig for outcome classification (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 6 | StatusCode | INT | YES | Specific billing processor sub-code for declined transactions. NULL for successful deposits. Combined with PaymentStatusId, used to look up the handling rule in ExecutionStatusResultConfig (e.g., code 1214=insufficient funds, code 1960=expired card) (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 7 | GroupKey | STRING | YES | Grouping key for batched deposit results. Typically empty string in current data. May be used for multi-part transactions or grouped charges (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 8 | ExecutionResultStatusId | INT | YES | System's classification of the billing result. FK to Dictionary.ExecutionResultStatus: 1=Success (89.5%), 2=SoftDecline (3.2%), 3=HardDecline (7.4%). Determined by looking up (PaymentStatusId, StatusCode) in ExecutionStatusResultConfig (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 9 | PaymentDate | TIMESTAMP | YES | Timestamp of when the billing processor actually processed the payment. May differ from CreateDate if there was a processing delay. NULL in some edge cases (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 10 | CreateDate | TIMESTAMP | YES | UTC timestamp when this result row was first created. Set to GETUTCDATE() by UpsertPaymentExecutionDepositResult (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |
| 11 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the last update. Set to GETUTCDATE() by UpsertPaymentExecutionDepositResult on both insert and update (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RecurringManager.Recurring.PaymentExecutionDepositResult` | Primary | `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` |

### 4.2 Pipeline ASCII Diagram

```
RecurringManager.Recurring.PaymentExecutionDepositResult
        │
        ▼
main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult   ←── this object
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
| PaymentExecutionDepositResultId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| PaymentExecutionId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| CycleNumber | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| AmountInUsd | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| DepositId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| PaymentStatusId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| StatusCode | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| GroupKey | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| ExecutionResultStatusId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| PaymentDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Recurring.PaymentExecutionDepositResult) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 12 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 12/12 | Source: bronze_tier1_inheritance*
