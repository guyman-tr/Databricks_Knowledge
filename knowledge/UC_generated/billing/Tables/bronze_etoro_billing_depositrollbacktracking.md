---
object_fqn: main.billing.bronze_etoro_billing_depositrollbacktracking
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_depositrollbacktracking
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 20
row_count: null
generated_at: '2026-05-18T10:58:33Z'
upstreams:
- etoro.Billing.DepositRollbackTracking
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md
  source_database: etoro
  source_schema: Billing
  source_table: DepositRollbackTracking
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/DepositRollbackTracking
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 20
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_depositrollbacktracking

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.DepositRollbackTracking`). 20 of 20 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_depositrollbacktracking` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 20 |
| **Generated** | 2026-05-18 |
| **Created** | Wed Jan 18 07:22:54 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.DepositRollbackTracking` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md`.

- Lake path: `Bronze/etoro/Billing/DepositRollbackTracking`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.DepositRollbackTracking`
- 20 of 20 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RollbackID | LONG | YES | Surrogate primary key. Auto-incremented. NOT FOR REPLICATION prevents identity gaps on replication subscribers. bigint allows for high volume over time (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 1 | CID | INT | YES | Customer whose deposit is being rolled back. Explicit FK to Customer.CustomerStatic(CID). Populated from Billing.Deposit.CID at time of rollback (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 2 | DepositID | INT | YES | The deposit being rolled back. Explicit FK to Billing.Deposit(DepositID). Multiple rollback rows may exist per DepositID (e.g., chargeback then cancel) (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 3 | PaymentStatusID | INT | YES | Type of rollback action. Explicit FK to Dictionary.PaymentStatus. Allowed values: 2=Approved(CancelRollback), 11=Chargeback, 12=Refund, 26=RefundAsChargeback, 37=ChargebackReversal, 38=RefundReversal, 39=ReversedDeposit. Distribution: 12=51%, 39=16%, 2=16%, 11=12%, 26=5% (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 4 | TotalRollbackAmountInUSD | DECIMAL | YES | Cumulative total amount rolled back for this deposit across all actions, in USD. Represents the running total at the time of this action. May exceed RollbackAmountInUSD for partial rollbacks (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 5 | TotalRollbackAmountInCurrency | DECIMAL | YES | Same as TotalRollbackAmountInUSD but in the deposit's original currency. Populated from @TotalRollbackAmountInCurrency parameter (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 6 | RollbackAmountInUSD | DECIMAL | YES | Amount rolled back by this specific action, in USD. Computed if not provided: @RollbackAmountInCurrency * @ExchangeRate. Used in Customer.SetBalance call: CAST(RollbackAmountInUSD * 100 AS INT) = amount in cents (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 7 | RollbackAmountInCurrency | DECIMAL | YES | Amount rolled back by this specific action, in the deposit's original currency. The primary input amount from the caller (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 8 | CurrencyID | INT | YES | Currency of the original deposit. Inherited from Billing.Deposit.CurrencyID at time of rollback. Implicit FK to Dictionary.Currency (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 9 | ExchangeRate | DECIMAL | YES | Exchange rate used for currency conversion at time of rollback. User-defined type dtPrice (decimal). Defaults to the original deposit ExchangeRate if not explicitly passed. Used to convert RollbackAmountInCurrency to USD (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 10 | BaseExchangeRate | DECIMAL | YES | Base exchange rate from the original deposit, carried forward to the rollback record for PIP calculation consistency. Inherited from Billing.Deposit.BaseExchangeRate (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 11 | ExchangeFee | INT | YES | Exchange fee from the original deposit, inherited at rollback time. Used in PIP calculations via Billing.CalculateDepositRollbackPIPsUSD (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 12 | ReferenceNumber | STRING | YES | External payment processor reference number for this rollback action (e.g., chargeback case ID, refund transaction ID). NULL when not provided by the processor (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 13 | RollbackReasonID | INT | YES | Categorizes why the rollback was performed. Lookup table not in SSDT repo. Dominant values: 0=no specific reason (56%), 2=most common tracked reason (43%). 18 distinct values observed (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 14 | Comments | STRING | YES | Free-text notes added by the manager performing the rollback. Passed to Customer.SetBalance as @Description. NULL when not provided (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 15 | RollbackDate | TIMESTAMP | YES | The effective date of the rollback (e.g., date the chargeback was received from the processor). Distinct from CreateDate - represents when the event occurred in the external system, not when it was recorded in eToro's database (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 16 | CreateDate | TIMESTAMP | YES | UTC timestamp when this rollback record was created in eToro's system. Set to GETDATE() at time of procedure execution (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 17 | ModificationDate | TIMESTAMP | YES | UTC timestamp of last modification. Initially set to GETDATE() = same as CreateDate. Updated when IsCanceled is set to 1 by a subsequent cancel-rollback action (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 18 | ManagerID | INT | YES | Back-office manager who performed the rollback. Explicit FK to BackOffice.Manager(ManagerID). Passed to Customer.SetBalance for audit trail (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |
| 19 | IsCanceled | BOOLEAN | YES | Whether this rollback was subsequently canceled. 0=active rollback (default on insert), 1=canceled by a later PaymentStatusID=2 action on the same deposit. 2,909 rows (16%) have IsCanceled=1. When canceling, all IsCanceled=0 rows for the DepositID are set to 1 before the new row is inserted (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.DepositRollbackTracking` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.DepositRollbackTracking
        │
        ▼
main.billing.bronze_etoro_billing_depositrollbacktracking   ←── this object
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
| RollbackID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| DepositID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| PaymentStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| TotalRollbackAmountInUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| TotalRollbackAmountInCurrency | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| RollbackAmountInUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| RollbackAmountInCurrency | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| ExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| BaseExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| ExchangeFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| ReferenceNumber | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| RollbackReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| Comments | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| RollbackDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |
| IsCanceled | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.DepositRollbackTracking) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 20 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 20/20 | Source: bronze_tier1_inheritance*
