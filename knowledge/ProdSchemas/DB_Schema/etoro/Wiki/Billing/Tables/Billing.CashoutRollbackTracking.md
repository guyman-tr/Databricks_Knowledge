# Billing.CashoutRollbackTracking

> Audit trail for cashout (withdrawal) rollback events; each row records one rollback transaction - a reversal of a processed payment leg - with both the partial rollback amount and the running cumulative rollback total for the withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RollbackID (BIGINT IDENTITY, PK CLUSTERED) |
| **Partition** | N/A - DICTIONARY filegroup |
| **Indexes** | 2 (PK clustered + 1 NC on WitdrawToFundingID) |

---

## 1. Business Meaning

`Billing.CashoutRollbackTracking` records every rollback action applied to a withdrawal payment leg. When a processed withdrawal payment must be reversed - for example, a returned bank transfer, a chargeback, or a payment system error - a rollback record is created here to track what amount was recovered, from which payment leg, and why.

The table holds 7,349 rows covering rollback events from January 2023 onward. All rows have `PaymentStatusID=2` and `IsCanceled=0`, indicating it records only confirmed rollback operations. Each row captures both the incremental amount reversed in this specific rollback event (`RollbackAmountInUSD`) and the cumulative total reversed so far across all rollbacks for the same payment leg (`TotalRollbackAmountInUSD`). Negative amounts appear (e.g., RollbackID 2 has -875 USD) representing corrections or reversals of a rollback.

Data enters exclusively via `Billing.AddCashoutRollbackTrackingRecord`, which is called as Step 3 in `Billing.AddCashoutRollback`. That parent procedure also updates the WithdrawToFunding leg and upserts the Withdraw record before creating the tracking entry. `Billing.GetCashoutRollbackAmounts` queries this table to compute cumulative rollback sums vs. original payment amounts for reconciliation.

---

## 2. Business Logic

### 2.1 Partial Rollback Tracking (Two-Amount Pattern)

**What**: Each rollback event stores both the incremental and cumulative rollback amounts, enabling partial recovery tracking across multiple rollback events on the same payment leg.

**Columns/Parameters Involved**: `RollbackAmountInUSD`, `TotalRollbackAmountInUSD`, `RollbackAmountInCurrency`, `TotalRollbackAmountInCurrency`, `WitdrawToFundingID`

**Rules**:
- `RollbackAmountInUSD` = amount recovered in this specific rollback event (can be partial).
- `TotalRollbackAmountInUSD` = running cumulative total of all rollbacks for the same WithdrawToFunding leg at the time of this event.
- `GetCashoutRollbackAmounts` computes `SUM(RollbackAmountInUSD)` grouped by WitdrawToFundingID and by WithdrawID to produce current totals, which are then compared against original amounts from Billing.WithdrawToFunding and Billing.Withdraw.
- Negative RollbackAmountInUSD values represent rollback corrections (rollback of a rollback).

**Diagram**:
```
Withdrawal (WithdrawID)
  +--> PaymentLeg1 (WitdrawToFundingID)
         RollbackID=1: RollbackAmountInUSD=+875, TotalRollbackAmountInUSD=+1750
         RollbackID=2: RollbackAmountInUSD=-875, TotalRollbackAmountInUSD=-875  (correction)
         RollbackID=3: RollbackAmountInUSD=+100, TotalRollbackAmountInUSD=+975
```

### 2.2 Exchange Rate Capture at Rollback Time

**What**: Exchange rate at the time of rollback is preserved separately from the original payment exchange rate.

**Columns/Parameters Involved**: `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `CurrencyID`

**Rules**:
- `BaseExchangeRate` and `ExchangeFee` are copied from `Billing.WithdrawToFunding` at the time `AddCashoutRollbackTrackingRecord` runs (not from the original deposit/withdraw rate).
- `ExchangeRate` is passed in by the caller as the rate applicable to the rollback.
- `CurrencyID` identifies the currency of the rollback amounts. CurrencyID=1=USD, CurrencyID=2=EUR (from Dictionary.Currency).

---

## 3. Data Overview

| RollbackID | WitdrawToFundingID | RollbackAmountInUSD | TotalRollbackAmountInUSD | RollbackReasonID | Meaning |
|------------|-------------------|---------------------|--------------------------|------------------|---------|
| 1 | 181164 | +875.00 | +1750.00 | 1 | First partial rollback on this payment leg - 875 USD recovered, cumulative total 1750 (another rollback existed before). |
| 2 | 181164 | -875.00 | -875.00 | 4 | Correction of the previous rollback - negative amount reverses the prior +875 entry. Running total shows net negative. |
| 3 | 181164 | +100.00 | +975.00 | 1 | A new partial rollback of 100 USD on the same leg; cumulative climbs back to 975. |
| 4 | 181164 | -100.00 | -100.00 | 4 | Correction of the +100 rollback. Same pattern as row 2. |
| 5 | 300259 | +150.00 | +1145.00 | 3 | Rollback on a different payment leg (different WitdrawToFundingID, different CID). RollbackReasonID=3 is the most common reason (83% of rows). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RollbackID | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key for this rollback event record. Output via @RollbackID OUTPUT parameter of AddCashoutRollbackTrackingRecord. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID of the account whose withdrawal is being rolled back. Not passed directly by the caller - derived inside AddCashoutRollbackTrackingRecord by querying Billing.Withdraw for the given WithdrawID. Implicit FK to Customer.CustomerStatic(CID). |
| 3 | WitdrawToFundingID | int | NO | - | VERIFIED | ID of the specific payment leg (Billing.WithdrawToFunding) being rolled back. Note: column name has a typo ("Witdraw" not "Withdraw") inherited from the original design. Has a NC index for lookup performance. Implicit FK to Billing.WithdrawToFunding(ID). |
| 4 | PaymentStatusID | int | NO | - | CODE-BACKED | Status of the rollback at time of recording. Always 2 across all 7,349 rows (set from @CashoutStatusID parameter). Uses the same CashoutStatus lookup as Billing.Withdraw. The constant value 2 suggests rollbacks are only recorded when the payment is in a specific pre-rollback state. |
| 5 | TotalRollbackAmountInUSD | money | NO | - | VERIFIED | Running cumulative total of all rollback amounts (in USD) applied to the same WitdrawToFundingID at the time this event is recorded. Passed by the caller; caller maintains the running total externally. Can be negative when corrections are applied. |
| 6 | TotalRollbackAmountInCurrency | money | NO | - | VERIFIED | Running cumulative total in the original transaction currency (identified by CurrencyID). Parallel to TotalRollbackAmountInUSD but in the customer-facing currency. |
| 7 | RollbackAmountInUSD | money | NO | - | VERIFIED | The incremental amount (in USD) reversed in this specific rollback event. Negative values indicate a rollback correction (reversal of a previous rollback). Summed by GetCashoutRollbackAmounts to compute net rollback totals. |
| 8 | RollbackAmountInCurrency | money | NO | - | VERIFIED | The incremental amount in the original transaction currency for this rollback event. Parallel to RollbackAmountInUSD. |
| 9 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the amount columns (*InCurrency). Implicit FK to Dictionary.Currency. Passed in by caller (optional, defaults to NULL in proc signature but stored as NOT NULL). Common values: 1=USD, 2=EUR. |
| 10 | ExchangeRate | money | NO | - | CODE-BACKED | Exchange rate between the rollback currency and USD applicable at the time of this rollback event. Passed by the caller, distinct from the original withdrawal exchange rate. |
| 11 | BaseExchangeRate | dbo.dtPrice | NO | - | VERIFIED | Base exchange rate from the original Billing.WithdrawToFunding leg, copied at rollback time by AddCashoutRollbackTrackingRecord (not passed by the caller - fetched automatically from WithdrawToFunding). Uses dbo.dtPrice UDT (decimal price type). |
| 12 | ExchangeFee | int | NO | - | VERIFIED | Exchange fee percentage from the original Billing.WithdrawToFunding leg, copied at rollback time alongside BaseExchangeRate. |
| 13 | ReferenceNumber | varchar(50) | YES | - | NAME-INFERRED | Optional external reference number for the rollback transaction (e.g., payment provider reference for the refund). NULL when no external reference is available. |
| 14 | RollbackReasonID | int | NO | - | CODE-BACKED | Reason code for the rollback. Maps to @RollbackType parameter in AddCashoutRollbackTrackingRecord. No Dictionary lookup table found. Observed values: 0 (1,170 rows - default/unknown), 1 (70 rows), 3 (6,080 rows - dominant), 4 (29 rows - appears in correction events). |
| 15 | Comments | varchar(255) | YES | - | NAME-INFERRED | Optional free-text notes about the rollback reason or context. NULL in most entries. |
| 16 | RollbackDate | datetime | NO | - | CODE-BACKED | Date/time when the rollback event occurred (as reported by the caller via @RollbackDate). Distinct from CreateDate - allows back-dating when recording a rollback that was initiated at a different time. |
| 17 | CreateDate | datetime | NO | - | VERIFIED | UTC timestamp when this tracking record was inserted. Always set to GETUTCDATE() inside AddCashoutRollbackTrackingRecord, not controlled by caller. |
| 18 | ModificationDate | datetime | NO | - | CODE-BACKED | Set to GETUTCDATE() at INSERT (same as CreateDate). No UPDATE procedure found, so this field may remain equal to CreateDate for all rows. |
| 19 | ManagerID | int | NO | - | CODE-BACKED | ID of the back-office manager who initiated the rollback, or 0 for system-initiated rollbacks. Passed via @ManagerID (optional parameter). Implicit FK to BackOffice.Manager or similar admin user table. |
| 20 | IsCanceled | bit | NO | - | VERIFIED | Always 0 across all 7,349 rows. Hardcoded to 0 in AddCashoutRollbackTrackingRecord INSERT. No UPDATE procedure changes it. May have been intended to allow cancelling a rollback record but the feature was never implemented. |
| 21 | WithdrawID | int | YES | - | VERIFIED | The parent withdrawal request ID (Billing.Withdraw.WithdrawID). Never NULL in practice (all 7,349 rows populated). Implicit FK to Billing.Withdraw. Enables grouping rollback events by withdrawal in GetCashoutRollbackAmounts. |
| 22 | WithdrawToFundingActionID | int | YES | - | VERIFIED | The most recent History.WithdrawToFundingAction.WithdrawToFundingActionID for the payment leg at the time of rollback. Fetched automatically inside AddCashoutRollbackTrackingRecord; not passed by caller. Links this rollback to its corresponding action history entry. Implicit FK to History.WithdrawToFundingAction. |
| 23 | CreditID | bigint | YES | - | NAME-INFERRED | Always NULL in current data. Likely reserved for linking to a credit note or credit account entry issued as part of the rollback. Feature not yet implemented or not used in current flows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer whose withdrawal is being rolled back. Populated by looking up Billing.Withdraw. |
| WitdrawToFundingID | Billing.WithdrawToFunding | Implicit (typo in name) | The specific payment leg being reversed. Indexed for lookup performance. |
| WithdrawID | Billing.Withdraw | Implicit | Parent withdrawal request. Enables per-withdrawal rollback aggregation. |
| CurrencyID | Dictionary.Currency | Implicit | Currency of the rollback amounts. |
| WithdrawToFundingActionID | History.WithdrawToFundingAction | Implicit | History log entry at the time of rollback. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AddCashoutRollbackTrackingRecord | (all columns) | WRITER | Sole insert procedure; called as Step 3 of Billing.AddCashoutRollback. |
| Billing.AddCashoutRollback | (orchestrator) | WRITER (via proc) | Top-level rollback handler; updates WithdrawToFunding and Withdraw before calling the tracking writer. |
| Billing.GetCashoutRollbackAmounts | RollbackAmountInUSD, WitdrawToFundingID, WithdrawID | READER | Computes SUM of rollback amounts per payment leg and per withdrawal for reconciliation. |
| Billing.BI_Cashout_State_Report | (reporting) | READER | Business intelligence report on cashout/rollback state. |
| Billing.BI_WithdrawRollback_PIPS_Report | (reporting) | READER | BI report on withdrawal rollbacks in PIPS system. |
| Billing.GetRollbackedPaymentOrdersReport | (reporting) | READER | Admin report listing rolled-back payment orders. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutRollbackTracking (table)
  (no code-level DDL dependencies - table has no FK constraints)
  Implicit runtime dependencies:
  |- Billing.Withdraw (table)        [WitdrawToFundingID lookup source]
  |- Billing.WithdrawToFunding (table) [BaseExchangeRate/ExchangeFee source]
```

### 6.1 Objects This Depends On

No dependencies (no FK constraints in DDL). Runtime data dependencies resolved inside AddCashoutRollbackTrackingRecord.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AddCashoutRollbackTrackingRecord | Stored Procedure | WRITER - inserts all rows |
| Billing.AddCashoutRollback | Stored Procedure | WRITER (orchestrator) - calls AddCashoutRollbackTrackingRecord |
| Billing.GetCashoutRollbackAmounts | Stored Procedure | READER - aggregates rollback amounts |
| Billing.BI_Cashout_State_Report | Stored Procedure | READER - BI reporting |
| Billing.BI_WithdrawRollback_PIPS_Report | Stored Procedure | READER - BI reporting |
| Billing.GetRollbackedPaymentOrdersReport | Stored Procedure | READER - admin report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOfficeCashoutRollbackTracking | CLUSTERED PK | RollbackID ASC | - | - | Active |
| IX_WitdrawToFundingID_CashoutRollbackTracking | NONCLUSTERED | WitdrawToFundingID ASC | - | - | Active (FILLFACTOR 100) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOfficeCashoutRollbackTracking | PRIMARY KEY CLUSTERED | Unique rollback event identifier |

---

## 8. Sample Queries

### 8.1 Get all rollback events for a specific withdrawal
```sql
SELECT  CRT.RollbackID,
        CRT.WitdrawToFundingID,
        CRT.RollbackAmountInUSD,
        CRT.TotalRollbackAmountInUSD,
        CRT.RollbackReasonID,
        CRT.RollbackDate,
        CRT.CreateDate
FROM    Billing.CashoutRollbackTracking CRT WITH (NOLOCK)
WHERE   CRT.WithdrawID = 181164
ORDER BY CRT.RollbackID;
```

### 8.2 Compute net rollback amounts per payment leg (same logic as GetCashoutRollbackAmounts)
```sql
SELECT  CRT.WitdrawToFundingID,
        SUM(CRT.RollbackAmountInUSD)    AS NetRollbackAmountUSD,
        COUNT(*)                        AS RollbackEventCount
FROM    Billing.CashoutRollbackTracking CRT WITH (NOLOCK)
GROUP BY CRT.WitdrawToFundingID
ORDER BY NetRollbackAmountUSD DESC;
```

### 8.3 Rollback events with customer and withdrawal context
```sql
SELECT  CRT.RollbackID,
        CRT.CID,
        W.WithdrawID,
        CRT.WitdrawToFundingID,
        CRT.RollbackAmountInUSD,
        CRT.TotalRollbackAmountInUSD,
        CRT.RollbackReasonID,
        CRT.RollbackDate
FROM    Billing.CashoutRollbackTracking CRT WITH (NOLOCK)
INNER JOIN Billing.Withdraw W WITH (NOLOCK)
        ON CRT.WithdrawID = W.WithdrawID
ORDER BY CRT.RollbackID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.5/10 (Elements: 8.3/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CashoutRollbackTracking | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CashoutRollbackTracking.sql*
