# Billing.AddCashoutRollbackTrackingRecord

> Inserts a single rollback tracking record into `Billing.CashoutRollbackTracking` for a withdrawal payment leg reversal, auto-deriving the customer ID, exchange rate details, and latest action history ID from related tables before persisting the event.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @RollbackID OUTPUT (SCOPE_IDENTITY of inserted CashoutRollbackTracking row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AddCashoutRollbackTrackingRecord` is the atomic writer for the cashout rollback audit trail. When a processed withdrawal payment must be reversed - a returned bank transfer, a chargeback, or a provider-initiated refund - this procedure creates one row in `Billing.CashoutRollbackTracking` capturing the incremental amount reversed, the cumulative rollback total for the payment leg, the exchange context, and the reason for the reversal.

The procedure exists as a dedicated single-responsibility writer so that the orchestrating procedure (`Billing.AddCashoutRollback`) can handle broader rollback coordination (updating `Billing.WithdrawToFunding`, modifying the parent `Billing.Withdraw` record) while this proc handles the pure tracking INSERT. Callers pass the rollback amounts and status; the proc auto-derives the customer ID, base exchange rate, exchange fee, and the most recent action history link - reducing the surface area that callers need to manage.

Data flows: this procedure is called as Step 3 inside `Billing.AddCashoutRollback`. It reads three source tables (`Billing.Withdraw`, `Billing.WithdrawToFunding`, `History.WithdrawToFundingAction`) before writing one row to `Billing.CashoutRollbackTracking`. The returned `@RollbackID` is the new row's primary key, surfaced back to the caller for downstream use.

---

## 2. Business Logic

### 2.1 Auto-Derived Fields (Not Passed by Caller)

**What**: Three fields in the inserted row are not provided by the caller - they are automatically fetched inside the procedure from related tables, reducing the caller's coupling to internal table structures.

**Parameters/Columns Involved**: `CID`, `BaseExchangeRate`, `ExchangeFee`, `WithdrawToFundingActionID`

**Rules**:
- `CID` is looked up from `Billing.Withdraw WHERE WithdrawID = @WithdrawID` - the customer is always the owner of the withdrawal record, not passed in separately.
- `BaseExchangeRate` and `ExchangeFee` are fetched from `Billing.WithdrawToFunding WHERE WithdrawID = @WithdrawID AND ID = @WithdrawToFundingID` - these represent the exchange conditions at the time the original payment leg was executed.
- `WithdrawToFundingActionID` is the most recent action history entry for the payment leg: `SELECT TOP 1 ... FROM History.WithdrawToFundingAction WHERE BW2F_ID = @WithdrawToFundingID ORDER BY WithdrawToFundingActionID DESC`.
- `CreateDate` and `ModificationDate` are both set to `GETUTCDATE()` internally.
- `IsCanceled` is hardcoded to `0` - rollback tracking records are never inserted in a cancelled state.

**Diagram**:
```
Caller provides:
  @WithdrawID, @CashoutStatusID, @WithdrawToFundingID
  @RollbackAmountInUSD/Currency, @TotalRollbackAmountInUSD/Currency
  @CurrencyID, @RollbackType, @ExchangeRate
  @ReferenceNumber, @Comments, @RollbackDate, @ManagerID

Procedure auto-fetches:
  CID              <- Billing.Withdraw WHERE WithdrawID = @WithdrawID
  BaseExchangeRate, ExchangeFee
                   <- Billing.WithdrawToFunding WHERE WithdrawID=@WithdrawID AND ID=@WithdrawToFundingID
  WithdrawToFundingActionID
                   <- History.WithdrawToFundingAction WHERE BW2F_ID=@WithdrawToFundingID (TOP 1 DESC)

INSERT -> Billing.CashoutRollbackTracking
RETURN <- @RollbackID (SCOPE_IDENTITY)
```

### 2.2 Parameter vs Column Name Mismatch (@RollbackType -> RollbackReasonID)

**What**: The procedure parameter `@RollbackType` maps to the column `RollbackReasonID` in `CashoutRollbackTracking`. The naming inconsistency is a historical artifact.

**Parameters/Columns Involved**: `@RollbackType`, `CashoutRollbackTracking.RollbackReasonID`

**Rules**:
- The caller passes `@RollbackType INT = NULL` and the INSERT places it directly into the `RollbackReasonID` column.
- Observed values in live data: 0 (default/unknown - 1,170 rows), 1 (70 rows), 3 (6,080 rows - dominant at 83%), 4 (29 rows - correction events). No Dictionary lookup table was found for this enum.
- When the caller passes NULL for `@RollbackType`, the column receives NULL.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INTEGER | NO | - | VERIFIED | ID of the parent withdrawal request being rolled back. Used internally to look up the customer CID and to fetch BaseExchangeRate/ExchangeFee from Billing.WithdrawToFunding. FK to Billing.Withdraw.WithdrawID. |
| 2 | @CashoutStatusID | INTEGER | NO | - | VERIFIED | Cashout status recorded in CashoutRollbackTracking.PaymentStatusID. In practice always 2 (live data shows all 7,349 rows have PaymentStatusID=2). Represents the status of the payment leg at rollback initiation. See [Cashout Status](../_glossary.md#cashout-status). |
| 3 | @WithdrawToFundingID | INTEGER | NO | - | VERIFIED | ID of the specific payment leg (Billing.WithdrawToFunding.ID) being reversed. Used internally to fetch BaseExchangeRate/ExchangeFee and to find the latest WithdrawToFundingActionID. Stored in CashoutRollbackTracking.WitdrawToFundingID (note the typo in the column name - inherited from original design). |
| 4 | @RollbackAmountInUSD | MONEY | YES | NULL | VERIFIED | Incremental amount (in USD) reversed in this specific rollback event. Can be negative to represent a correction (rollback of a rollback). Stored in CashoutRollbackTracking.RollbackAmountInUSD. |
| 5 | @RollbackAmountInCurrency | MONEY | YES | NULL | VERIFIED | Incremental amount in the original transaction currency (identified by @CurrencyID) for this rollback event. Parallel to @RollbackAmountInUSD. Stored in CashoutRollbackTracking.RollbackAmountInCurrency. |
| 6 | @TotalRollbackAmountInUSD | MONEY | YES | NULL | VERIFIED | Running cumulative total (in USD) of all rollbacks applied to this payment leg at the time of this event. The caller is responsible for computing and passing the correct running total. Can be negative when corrections reverse prior rollbacks. Stored in CashoutRollbackTracking.TotalRollbackAmountInUSD. |
| 7 | @TotalRollbackAmountInCurrency | MONEY | NO | - | VERIFIED | Running cumulative total in the original transaction currency. Unlike the other amount parameters this has no default value and is required. Stored in CashoutRollbackTracking.TotalRollbackAmountInCurrency. |
| 8 | @CurrencyID | INT | YES | NULL | CODE-BACKED | Currency of the *InCurrency amount columns. Implicit FK to Dictionary.Currency. Common values: 1=USD, 2=EUR. Stored in CashoutRollbackTracking.CurrencyID. |
| 9 | @RollbackType | INT | YES | NULL | CODE-BACKED | Reason code for the rollback. Stored in CashoutRollbackTracking.RollbackReasonID (parameter name differs from column name - historical artifact). Observed values: 0=unknown/default, 1, 3 (dominant - 83% of rows), 4 (correction events). No Dictionary lookup table found. |
| 10 | @ExchangeRate | MONEY | YES | NULL | CODE-BACKED | Exchange rate between the rollback currency and USD applicable at the time of this rollback as provided by the caller. Distinct from BaseExchangeRate (which is auto-fetched from the original payment leg). Stored in CashoutRollbackTracking.ExchangeRate. |
| 11 | @ReferenceNumber | VARCHAR(50) | YES | NULL | NAME-INFERRED | Optional external reference number for the rollback transaction (e.g., payment provider refund reference). NULL when no external reference is available. Stored in CashoutRollbackTracking.ReferenceNumber. |
| 12 | @Comments | VARCHAR(255) | YES | NULL | NAME-INFERRED | Optional free-text notes about the rollback reason or context. NULL in most entries. Stored in CashoutRollbackTracking.Comments. |
| 13 | @RollbackDate | DATETIME | YES | NULL | CODE-BACKED | Date/time when the rollback event occurred as reported by the caller. Allows back-dating when recording a rollback initiated at a different time than when this proc runs. Distinct from CreateDate (always GETUTCDATE() internally). Stored in CashoutRollbackTracking.RollbackDate. |
| 14 | @ManagerID | INT | YES | NULL | CODE-BACKED | ID of the back-office manager who initiated the rollback, or NULL/0 for system-initiated rollbacks. Stored in CashoutRollbackTracking.ManagerID. |
| 15 | @RollbackID | BIGINT | YES | NULL OUTPUT | VERIFIED | OUTPUT parameter. Returns SCOPE_IDENTITY() of the newly inserted CashoutRollbackTracking row. Enables the calling procedure (Billing.AddCashoutRollback) to reference the new rollback record in subsequent steps. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | Implicit (SELECT) | Fetches CID for the inserted record; the withdrawal owner's customer ID. |
| @WithdrawToFundingID | Billing.WithdrawToFunding | Implicit (SELECT) | Fetches BaseExchangeRate and ExchangeFee from the original payment leg execution record. |
| @WithdrawToFundingID | History.WithdrawToFundingAction | Implicit (SELECT) | Fetches the most recent action history entry ID for the payment leg at rollback time. |
| (INSERT target) | Billing.CashoutRollbackTracking | WRITER | Single insert destination; creates one rollback tracking event row per call. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AddCashoutRollback | EXEC call (Step 3) | CALLER | Sole caller; orchestrates broader rollback (updates WithdrawToFunding and Withdraw) then delegates tracking record creation to this proc. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AddCashoutRollbackTrackingRecord (procedure)
|- Billing.Withdraw (table)                    [SELECT CID]
|- Billing.WithdrawToFunding (table)           [SELECT BaseExchangeRate, ExchangeFee]
|- History.WithdrawToFundingAction (table)     [SELECT TOP 1 latest action ID]
+- Billing.CashoutRollbackTracking (table)     [INSERT - write target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT CID WHERE WithdrawID = @WithdrawID |
| Billing.WithdrawToFunding | Table | SELECT BaseExchangeRate, ExchangeFee WHERE WithdrawID = @WithdrawID AND ID = @WithdrawToFundingID |
| History.WithdrawToFundingAction | Table | SELECT TOP 1 WithdrawToFundingActionID WHERE BW2F_ID = @WithdrawToFundingID ORDER BY ID DESC |
| Billing.CashoutRollbackTracking | Table | INSERT - the sole write target of this procedure |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AddCashoutRollback | Stored Procedure | Calls this proc as Step 3 of the cashout rollback orchestration flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute a rollback tracking record (full parameter set)
```sql
DECLARE @NewRollbackID BIGINT;
EXEC Billing.AddCashoutRollbackTrackingRecord
    @WithdrawID                    = 181164,
    @CashoutStatusID               = 2,
    @WithdrawToFundingID           = 300259,
    @RollbackAmountInUSD           = 150.00,
    @RollbackAmountInCurrency      = 150.00,
    @TotalRollbackAmountInUSD      = 150.00,
    @TotalRollbackAmountInCurrency = 150.00,
    @CurrencyID                    = 1,      -- USD
    @RollbackType                  = 3,      -- most common reason code
    @ExchangeRate                  = 1.0,
    @ReferenceNumber               = 'REFUND-2026-001',
    @Comments                      = 'Provider returned payment',
    @RollbackDate                  = GETUTCDATE(),
    @ManagerID                     = 42,
    @RollbackID                    = @NewRollbackID OUTPUT;
SELECT @NewRollbackID AS InsertedRollbackID;
```

### 8.2 Verify the inserted record (check auto-derived fields)
```sql
SELECT  CRT.RollbackID,
        CRT.CID,
        CRT.WitdrawToFundingID,
        CRT.PaymentStatusID,
        CRT.RollbackAmountInUSD,
        CRT.TotalRollbackAmountInUSD,
        CRT.RollbackReasonID,
        CRT.BaseExchangeRate,
        CRT.ExchangeFee,
        CRT.WithdrawToFundingActionID,
        CRT.CreateDate
FROM    Billing.CashoutRollbackTracking CRT WITH (NOLOCK)
WHERE   CRT.RollbackID = 1; -- replace with @NewRollbackID from the EXEC above
```

### 8.3 View all rollback events for a withdrawal with original vs rollback exchange rates
```sql
SELECT  CRT.RollbackID,
        CRT.CID,
        W.CashoutStatusID       AS WithdrawStatus,
        WTF.BaseExchangeRate    AS OriginalBaseRate,
        CRT.BaseExchangeRate    AS RollbackBaseRate,
        CRT.RollbackAmountInUSD,
        CRT.TotalRollbackAmountInUSD,
        CRT.RollbackReasonID,
        CRT.RollbackDate,
        CRT.CreateDate
FROM    Billing.CashoutRollbackTracking CRT WITH (NOLOCK)
INNER JOIN Billing.Withdraw W WITH (NOLOCK)
        ON CRT.WithdrawID = W.WithdrawID
INNER JOIN Billing.WithdrawToFunding WTF WITH (NOLOCK)
        ON CRT.WitdrawToFundingID = WTF.ID
WHERE   CRT.WithdrawID = 181164
ORDER BY CRT.RollbackID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 8.7/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AddCashoutRollbackTrackingRecord | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AddCashoutRollbackTrackingRecord.sql*
