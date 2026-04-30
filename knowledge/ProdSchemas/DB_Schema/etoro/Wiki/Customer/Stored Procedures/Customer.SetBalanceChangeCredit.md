# Customer.SetBalanceChangeCredit

> Thin pass-through wrapper that inserts a credit history record via SetBalanceInsertCredit_Native without modifying CustomerMoney balances; returns the new CreditID as a result set.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns the new CreditID (bigint) as a SELECT result row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalanceChangeCredit` is the thinnest member of the SetBalance* family. It performs no balance updates to `Customer.CustomerMoney`. Its sole purpose is to call `Customer.SetBalanceInsertCredit_Native` with all supplied parameters and then return the resulting CreditID to the caller via `SELECT @Identity`.

This design serves scenarios where a credit record must be logged without changing any balance - for example, when a balance adjustment was already applied by another system component, or when a credit event requires an audit trail without a financial impact (such as a data-fix record, a marker event, or a credit type whose balance implications are handled upstream).

The procedure accepts the full complement of optional reference IDs (PositionID, DepositID, MirrorID, etc.) and financial snapshot fields (Credit, Payment, TotalCash, BonusCredit, RealizedEquity, etc.) - identical to the signature of SetBalanceInsertCredit_Native - and forwards them all unchanged.

---

## 2. Business Logic

### 2.1 Pure Credit-Log Pattern

**What**: No balance update; only a credit history INSERT.

**Rules**:
- No UPDATE to Customer.CustomerMoney.
- Calls `Customer.SetBalanceInsertCredit_Native` with all parameters as-is.
- `SET @CID = ISNULL(@CID, -1)` - protects against NULL CID (defaults to system account -1).
- Returns `SELECT @Identity` (the new CreditID) to the caller.
- CreditTypeID can be ANY value from Dictionary.CreditType - this is a universal log entry point.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | - | CODE-BACKED | Customer ID. Defaults to -1 (system account) via ISNULL if NULL is passed. |
| 2 | @CreditTypeID | INT | NO | - | VERIFIED | Type of credit event (1-33, Dictionary.CreditType). Determines what business event this log entry represents. See SetBalanceInsertCredit_Native Section 2.2 for full value map. |
| 3 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | Position reference for position-related credit types. |
| 4 | @ChampionshipID | INT | YES | NULL | CODE-BACKED | Championship event reference. |
| 5 | @CashoutID | INT | YES | NULL | CODE-BACKED | Cashout request reference. |
| 6 | @PaymentID | INT | YES | NULL | CODE-BACKED | PSP payment reference. |
| 7 | @WithdrawID | INT | YES | NULL | CODE-BACKED | Withdrawal request reference. |
| 8 | @DepositID | INT | YES | NULL | CODE-BACKED | Deposit transaction reference. |
| 9 | @UpdateID | INT | YES | NULL | CODE-BACKED | Internal update/event reference. |
| 10 | @CampaignID | INT | YES | NULL | CODE-BACKED | Marketing campaign reference. |
| 11 | @BonusTypeID | INT | YES | NULL | CODE-BACKED | Bonus type reference. |
| 12 | @CompensationReasonID | INT | YES | NULL | CODE-BACKED | Compensation reason reference. |
| 13 | @ManagerID | INT | YES | NULL | CODE-BACKED | Admin/manager who initiated this credit event. |
| 14 | @Credit | MONEY | NO | - | CODE-BACKED | Current credit balance snapshot at time of event. |
| 15 | @Payment | MONEY | NO | - | CODE-BACKED | Cash payment amount of this credit event. |
| 16 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Human-readable description stored in credit history. |
| 17 | @WithdrawProcessingID | INT | YES | NULL | CODE-BACKED | Withdrawal processing batch reference. |
| 18 | @MirrorID | INT | YES | 0 | CODE-BACKED | Copy-trading mirror reference. Defaults to 0 (no mirror). |
| 19 | @TotalCash | MONEY | NO | - | CODE-BACKED | Total cash balance snapshot at time of event. |
| 20 | @TotalCashChange | MONEY | YES | 0 | CODE-BACKED | Change to total cash from this event. |
| 21 | @BonusCredit | MONEY | YES | NULL | CODE-BACKED | Bonus credit balance snapshot. |
| 22 | @RealizedEquity | MONEY | YES | NULL | CODE-BACKED | Realized equity snapshot at time of event. |
| 23 | @MirrorCash | dtPrice | YES | 0 | CODE-BACKED | Mirror cash balance snapshot (high precision decimal). |
| 24 | @StocksOrderID | INT | YES | 0 | CODE-BACKED | Stock order reference. |
| 25 | @MirrorEquity | MONEY | YES | NULL | CODE-BACKED | Mirror equity snapshot. |
| 26 | @BSLRealFunds | MONEY | YES | NULL | CODE-BACKED | BSL real funds snapshot at time of event. |
| 27 | @SubCreditTypeID | INT | YES | 0 | CODE-BACKED | Sub-classification of credit type for granular categorization. |
| 28 | @OriginalPositionID | BIGINT | YES | NULL | CODE-BACKED | Original position ID for re-opened/recovered positions. |
| 29 | @MirrorDividendID | INT | YES | NULL | CODE-BACKED | Mirror dividend payment reference. |
| 30 | @DepositRollbackID | INT | YES | NULL | CODE-BACKED | Original deposit ID being reversed/rolled back. |
| 31 | @InterestMonthlyID | BIGINT | YES | NULL | CODE-BACKED | Monthly interest record reference. |
| 32 | @MoveMoneyReasonID | INT | YES | NULL | CODE-BACKED | Internal money movement reason code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| all params | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Full parameter pass-through to the native credit INSERT procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central router delegates certain CreditTypeIDs to this procedure |
| Various Trade and internal procedures | EXEC | Callers | Used when a credit record is needed without a balance change |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceChangeCredit (procedure)
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit record]
      +-- History.ActiveCreditRecentMemoryBucket (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts credit record with all supplied parameters |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for credit-only log events (no balance change needed) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL(@CID, -1) | Guard | Prevents NULL CID from reaching the INSERT - defaults to system account -1 |
| SELECT @Identity | Return convention | New CreditID returned as result set (not OUTPUT parameter) - callers must read the result set to capture it |

---

## 8. Sample Queries

### 8.1 Log a data-fix credit event for a customer

```sql
-- Log CreditTypeID=31 (Data Fix) without changing balance
EXEC Customer.SetBalanceChangeCredit
    @CID = 12345,
    @CreditTypeID = 31,   -- Data Fix
    @Credit = 1500.00,    -- current balance snapshot
    @Payment = 0,
    @TotalCash = 1500.00,
    @Description = 'Manual data correction by support team',
    @ManagerID = 9876;
-- Result set contains the new CreditID
```

### 8.2 Log a mirror-related credit event

```sql
EXEC Customer.SetBalanceChangeCredit
    @CID = 12345,
    @CreditTypeID = 18,    -- Account balance to mirror
    @MirrorID = 55555,
    @Credit = 800.00,
    @Payment = -200.00,
    @TotalCash = 800.00,
    @MirrorCash = 200.0,
    @MirrorEquity = 200.0,
    @Description = 'Mirror allocation';
```

### 8.3 Verify credit record was created

```sql
DECLARE @CreditID BIGINT = 999888777; -- from SELECT @Identity result

SELECT
    CreditID,
    CID,
    CreditTypeID,
    Credit,
    Payment,
    Description,
    Occurred
FROM History.ActiveCreditBucket_VW WITH (NOLOCK)
WHERE CreditID = @CreditID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceChangeCredit | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceChangeCredit.sql*
