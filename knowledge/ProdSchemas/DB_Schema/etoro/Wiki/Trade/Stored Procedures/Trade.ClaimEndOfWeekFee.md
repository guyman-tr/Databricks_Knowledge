# Trade.ClaimEndOfWeekFee

> Charges an end-of-week (overnight/weekend) fee on a position by subtracting the fee via Billing.AmountSubstract, updating Trade.PositionTbl.EndOfWeekFee, and logging the change to History.PositionChangeLog.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ClaimEndOfWeekFee is the core procedure for charging overnight/weekend holding fees on open positions. In CFD trading, positions held over the weekend incur a financing fee (also called a swap or rollover fee). This procedure is called for each position that owes a fee.

The fee amount is pre-calculated by the caller and passed in as @Fee. If @Fee=0, the procedure returns immediately with @Claimed=1 (nothing to charge). Otherwise, it:

1. **Subtracts the fee** via Billing.AmountSubstract with CreditTypeID=14 (EndOfWeekFee)
2. **Updates the position** to accumulate the fee in Trade.PositionTbl.EndOfWeekFee and records the LastEOWClameDate
3. **Logs the change** via History.PositionChangeLog_Insert with ChangeTypeID=4

The @Claimed OUTPUT parameter tells the caller whether the fee was successfully applied. The entire operation runs within an explicit transaction.

---

## 2. Business Logic

### 2.1 Fee Charging

**What**: Subtracts the fee from the customer's account using Billing.AmountSubstract.

**Columns/Parameters Involved**: `@CID`, `@CurrencyID`, `@Fee`, `@PositionID`, `@MirrorID`

**Rules**:
- CurrencyID comes from Customer.Customer.CurrencyID
- WeekendFeePrecentage also read but not used (pre-calculated @Fee is used instead)
- CreditTypeID=14 identifies the charge as an end-of-week fee
- Amount converted to cents: @Amount = CAST(@Fee * 100 AS INTEGER)
- Description: 'End Of Week Fee Claimed By System'
- GCID=0 (system-initiated)

### 2.2 Position Update

**What**: Accumulates the fee on the position record and captures previous/new values.

**Columns/Parameters Involved**: `Trade.PositionTbl.EndOfWeekFee`, `LastEOWClameDate`

**Rules**:
- EndOfWeekFee = EndOfWeekFee + @Fee (cumulative)
- LastEOWClameDate = GETUTCDATE()
- Uses UPDATE...OUTPUT to capture DELETED.EndOfWeekFee (previous) and INSERTED values into @Info table variable
- Also captures HedgeID, Amount, ParentPositionID, OrigParentPositionID, TreeID

### 2.3 Tree Info Enrichment

**What**: Reads CloseOnEndOfWeek, LimitRate, StopRate from Trade.PositionTreeInfo.

**Rules**:
- Joins @Info to Trade.PositionTreeInfo on TreeID
- These values are needed for the PositionChangeLog entry

### 2.4 Change Log

**What**: Records the fee charge event in the position audit trail.

**Columns/Parameters Involved**: ChangeTypeID=4 (fee charge)

**Rules**:
- Calls History.PositionChangeLog_Insert with full position state
- AmountChanged=0 (the position amount doesn't change, only the fee)
- @NewAmount = @PreviousAmount (amount unchanged)
- MirrorRealizedEquity=0, AccountRealizedEquity=0 (not relevant for fee charges)
- If @Answer <> 0, RAISERROR

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID being charged. |
| 2 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position being charged the end-of-week fee. |
| 3 | @Claimed | BIT (OUTPUT) | NO | - | CODE-BACKED | 1 if fee was successfully charged, 0 if not. |
| 4 | @Fee | MONEY | NO | - | CODE-BACKED | Pre-calculated fee amount in dollars (not cents). |
| 5 | @MirrorID | INT | NO | - | CODE-BACKED | Mirror ID associated with the position (0 if not a mirror position). |
| 6 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Last operation price rate ID for audit trail. |
| 7 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Last operation price rate value. |
| 8 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Last operation conversion rate ID for audit trail. |
| 9 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Last operation conversion rate value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | SELECT | WeekendFeePrecentage, CurrencyID |
| @CID | Billing.AmountSubstract | EXEC | Fee deduction from account |
| @PositionID | Trade.PositionTbl | UPDATE | Accumulate EndOfWeekFee, set LastEOWClameDate |
| TreeID | Trade.PositionTreeInfo | SELECT | CloseOnEndOfWeek, LimitRate, StopRate |
| @CID | Customer.Login | SELECT | ClientVersion for change log |
| (calls) | History.PositionChangeLog_Insert | EXEC | Audit trail with ChangeTypeID=4 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| End-of-week fee batch | (external) | EXEC | Called per position during fee sweep |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ClaimEndOfWeekFee (procedure)
+-- Customer.Customer (table)
+-- Billing.AmountSubstract (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.PositionTreeInfo (table)
+-- Customer.Login (table)
+-- History.PositionChangeLog_Insert (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | CurrencyID, WeekendFeePrecentage |
| Billing.AmountSubstract | Procedure | Fee deduction |
| Trade.PositionTbl | Table | UPDATE EndOfWeekFee |
| Trade.PositionTreeInfo | Table | Tree-level rate data |
| Customer.Login | Table | ClientVersion |
| History.PositionChangeLog_Insert | Procedure | Audit trail |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| End-of-week fee batch job | External | Per-position fee charging |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Atomicity | Billing + position update + change log are atomic |
| Fee in dollars, billing in cents | Conversion | @Amount = CAST(@Fee * 100 AS INTEGER) |
| Nested transaction support | Pattern | @@TRANCOUNT check in CATCH for rollback vs commit |
| RETURN 0 on success, 60000 on failure | Convention | Standard error code pattern |

---

## 8. Sample Queries

### 8.1 Claim end-of-week fee

```sql
DECLARE @Claimed BIT;
EXEC Trade.ClaimEndOfWeekFee
    @CID = 12345,
    @PositionID = 67890,
    @Claimed = @Claimed OUTPUT,
    @Fee = 1.50,
    @MirrorID = 0;
SELECT @Claimed AS WasClaimed;
```

### 8.2 Check accumulated fees on a position

```sql
SELECT PositionID, EndOfWeekFee, LastEOWClameDate
FROM   Trade.PositionTbl WITH (NOLOCK)
WHERE  PositionID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ClaimEndOfWeekFee | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ClaimEndOfWeekFee.sql*
