---
object_fqn: main.billing.bronze_etoro_billing_cashoutrollbacktracking
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_cashoutrollbacktracking
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 23
row_count: null
generated_at: '2026-05-18T10:58:29Z'
upstreams:
- etoro.Billing.CashoutRollbackTracking
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md
  source_database: etoro
  source_schema: Billing
  source_table: CashoutRollbackTracking
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/CashoutRollbackTracking
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 23
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_cashoutrollbacktracking

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.CashoutRollbackTracking`). 23 of 23 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_cashoutrollbacktracking` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 23 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Nov 18 08:15:07 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.CashoutRollbackTracking` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md`.

- Lake path: `Bronze/etoro/Billing/CashoutRollbackTracking`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.CashoutRollbackTracking`
- 23 of 23 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RollbackID | LONG | YES | Auto-incrementing primary key for this rollback event record. Output via @RollbackID OUTPUT parameter of AddCashoutRollbackTrackingRecord (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 1 | CID | INT | YES | Customer ID of the account whose withdrawal is being rolled back. Not passed directly by the caller - derived inside AddCashoutRollbackTrackingRecord by querying Billing.Withdraw for the given WithdrawID. Implicit FK to Customer.CustomerStatic(CID) (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 2 | WitdrawToFundingID | INT | YES | ID of the specific payment leg (Billing.WithdrawToFunding) being rolled back. Note: column name has a typo ("Witdraw" not "Withdraw") inherited from the original design. Has a NC index for lookup performance. Implicit FK to Billing.WithdrawToFunding(ID) (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 3 | PaymentStatusID | INT | YES | Status of the rollback at time of recording. Always 2 across all 7,349 rows (set from @CashoutStatusID parameter). Uses the same CashoutStatus lookup as Billing.Withdraw. The constant value 2 suggests rollbacks are only recorded when the payment is in a specific pre-rollback state (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 4 | TotalRollbackAmountInUSD | DECIMAL | YES | Running cumulative total of all rollback amounts (in USD) applied to the same WitdrawToFundingID at the time this event is recorded. Passed by the caller; caller maintains the running total externally. Can be negative when corrections are applied (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 5 | TotalRollbackAmountInCurrency | DECIMAL | YES | Running cumulative total in the original transaction currency (identified by CurrencyID). Parallel to TotalRollbackAmountInUSD but in the customer-facing currency (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 6 | RollbackAmountInUSD | DECIMAL | YES | The incremental amount (in USD) reversed in this specific rollback event. Negative values indicate a rollback correction (reversal of a previous rollback). Summed by GetCashoutRollbackAmounts to compute net rollback totals (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 7 | RollbackAmountInCurrency | DECIMAL | YES | The incremental amount in the original transaction currency for this rollback event. Parallel to RollbackAmountInUSD (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 8 | CurrencyID | INT | YES | Currency of the amount columns (*InCurrency). Implicit FK to Dictionary.Currency. Passed in by caller (optional, defaults to NULL in proc signature but stored as NOT NULL). Common values: 1=USD, 2=EUR (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 9 | ExchangeRate | DECIMAL | YES | Exchange rate between the rollback currency and USD applicable at the time of this rollback event. Passed by the caller, distinct from the original withdrawal exchange rate (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 10 | BaseExchangeRate | DECIMAL | YES | Base exchange rate from the original Billing.WithdrawToFunding leg, copied at rollback time by AddCashoutRollbackTrackingRecord (not passed by the caller - fetched automatically from WithdrawToFunding). Uses dbo.dtPrice UDT (decimal price type) (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 11 | ExchangeFee | INT | YES | Exchange fee percentage from the original Billing.WithdrawToFunding leg, copied at rollback time alongside BaseExchangeRate (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 12 | ReferenceNumber | STRING | YES | Optional external reference number for the rollback transaction (e.g., payment provider reference for the refund). NULL when no external reference is available (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 13 | RollbackReasonID | INT | YES | Reason code for the rollback. Maps to @RollbackType parameter in AddCashoutRollbackTrackingRecord. No Dictionary lookup table found. Observed values: 0 (1,170 rows - default/unknown), 1 (70 rows), 3 (6,080 rows - dominant), 4 (29 rows - appears in correction events) (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 14 | Comments | STRING | YES | Optional free-text notes about the rollback reason or context. NULL in most entries (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 15 | RollbackDate | TIMESTAMP | YES | Date/time when the rollback event occurred (as reported by the caller via @RollbackDate). Distinct from CreateDate - allows back-dating when recording a rollback that was initiated at a different time (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 16 | CreateDate | TIMESTAMP | YES | UTC timestamp when this tracking record was inserted. Always set to GETUTCDATE() inside AddCashoutRollbackTrackingRecord, not controlled by caller (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 17 | ModificationDate | TIMESTAMP | YES | Set to GETUTCDATE() at INSERT (same as CreateDate). No UPDATE procedure found, so this field may remain equal to CreateDate for all rows (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 18 | ManagerID | INT | YES | ID of the back-office manager who initiated the rollback, or 0 for system-initiated rollbacks. Passed via @ManagerID (optional parameter). Implicit FK to BackOffice.Manager or similar admin user table (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 19 | IsCanceled | BOOLEAN | YES | Always 0 across all 7,349 rows. Hardcoded to 0 in AddCashoutRollbackTrackingRecord INSERT. No UPDATE procedure changes it. May have been intended to allow cancelling a rollback record but the feature was never implemented (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 20 | WithdrawID | INT | YES | The parent withdrawal request ID (Billing.Withdraw.WithdrawID). Never NULL in practice (all 7,349 rows populated). Implicit FK to Billing.Withdraw. Enables grouping rollback events by withdrawal in GetCashoutRollbackAmounts (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 21 | WithdrawToFundingActionID | INT | YES | The most recent History.WithdrawToFundingAction.WithdrawToFundingActionID for the payment leg at the time of rollback. Fetched automatically inside AddCashoutRollbackTrackingRecord; not passed by caller. Links this rollback to its corresponding action history entry. Implicit FK to History.WithdrawToFundingAction (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |
| 22 | CreditID | LONG | YES | Always NULL in current data. Likely reserved for linking to a credit note or credit account entry issued as part of the rollback. Feature not yet implemented or not used in current flows (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.CashoutRollbackTracking` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.CashoutRollbackTracking
        │
        ▼
main.billing.bronze_etoro_billing_cashoutrollbacktracking   ←── this object
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
| RollbackID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| WitdrawToFundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| PaymentStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| TotalRollbackAmountInUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| TotalRollbackAmountInCurrency | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| RollbackAmountInUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| RollbackAmountInCurrency | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| ExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| BaseExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| ExchangeFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| ReferenceNumber | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| RollbackReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| Comments | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| RollbackDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| IsCanceled | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| WithdrawID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| WithdrawToFundingActionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |
| CreditID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.CashoutRollbackTracking) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 23 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 23/23 | Source: bronze_tier1_inheritance*
