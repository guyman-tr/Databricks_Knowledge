# Customer.SetBalanceClosePosition

> Closes a trading position's financial impact: updates TotalCash by the closed amount, RealizedEquity by NetProfit, Credit for non-mirror positions, deducts BonusCredit consumed, updates Trade.Mirror for copy-trading positions, and logs the credit record - outputs BonusChange and CreditID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @PositionID BIGINT, @Amount INT (cents), @MirrorID INT; @BonusChange MONEY OUTPUT, @CreditID BIGINT OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a trading position is closed on eToro, `SetBalanceClosePosition` applies the financial settlement to the customer's account. This is the most complex single-position balance procedure because it must handle the distinction between:

1. **Standalone positions** (not mirror-copied): Credit, TotalCash, and RealizedEquity are all updated.
2. **Mirror-copied positions** (copy-trading): Credit is NOT changed on the customer level; the equivalent cash goes to/from `Trade.Mirror.Amount` instead.
3. **BonusCredit** associated with the position: reduced by the amount originally allocated at open (floor at 0).
4. **NetProfit** vs **Amount**: RealizedEquity uses `@NetProfit/100` (pure profit/loss), while TotalCash and Credit use `@Amount/100` (total position value returned, including cost basis).

A retry loop (up to 3 attempts) is used to determine `@IsMirror` from `History.Position_Active UNION Trade.PositionTbl` when the caller does not supply the value - recently-closed positions may appear in either table depending on how fast the close committed.

---

## 2. Business Logic

### 2.1 Mirror Status Determination (Retry Logic)

**What**: Determines whether the closing position belongs to an active mirror.

**Columns/Parameters Involved**: `@IsMirror`, `@PositionID`, `History.Position_Active`, `Trade.PositionTbl`

**Rules**:
- If `@IsMirror` is provided by caller: used directly (short-circuit).
- If `@IsMirror IS NULL`: queries `History.Position_Active UNION Trade.PositionTbl` filtering `PositionID = @PositionID AND CloseOccurred >= DATEDIFF(DAY,-1,GETDATE())`.
- `@IsMirror = CASE WHEN ISNULL(MirrorID,0) > 0 AND ISNULL(ParentPositionID,0) > 0 THEN 1 ELSE 0 END`.
- Retry loop (up to 3 attempts) - if `@IsMirror IS NULL` after query, increments retry counter and re-queries. If still NULL after 3 attempts: `RAISERROR('@IsMirror cannot be null', 16, 16)`.

### 2.2 CustomerMoney Settlement

**What**: Applies the closed position's financial outcome to the customer's balance.

**Columns/Parameters Involved**: `TotalCash`, `RealizedEquity`, `Credit`, `BonusCredit`

**Rules**:
- `@CreditChangeInDollar = CAST(@Amount AS MONEY) / 100`
- `TotalCash += @CreditChangeInDollar` (always - the full position cash is returned)
- `RealizedEquity += ISNULL(@NetProfit, 0) / 100` (only the profit/loss component)
- `Credit += @CreditChangeInDollar` ONLY if `@IsMirror = 0` (standalone position)
- `BonusCredit = MAX(0, BonusCredit - @BonusCredit)` - consume/reduce bonus (floor at 0)
- Uses variable assignments instead of OUTPUT clause for capturing new/old values.

```
Standalone position close:        Mirror-copied position close:
  TotalCash      += amount/100      TotalCash      += amount/100
  RealizedEquity += netProfit/100   RealizedEquity += netProfit/100
  Credit         += amount/100      Credit         - UNCHANGED
  BonusCredit    -= bonus (>=0)     BonusCredit    -= bonus (>=0)
```

### 2.3 Trade.Mirror Settlement (Conditional)

**What**: For mirror positions, the mirror's cash and equity are updated instead of (or in addition to) customer Credit.

**Columns/Parameters Involved**: `Trade.Mirror.Amount`, `Trade.Mirror.RealizedEquity`, `Trade.Mirror.NetProfit`

**Rules**:
- If `@IsMirror = 1`:
  - `Amount = ROUND(Amount + @CreditChangeInDollar, 2)` - mirror cash increases by closed amount
  - `RealizedEquity += ISNULL(@NetProfit, 0) / 100`
  - `NetProfit += ISNULL(@NetProfit, 0) / 100`

### 2.4 BonusChange Output

**What**: Reports the change in BonusCredit resulting from this position close.

**Rules**:
- `@BonusChange = new BonusCredit - old BonusCredit`
- Typically negative (bonus was consumed by the position).
- Caller uses this to track bonus consumption for position close events.

### 2.5 Credit Record

**What**: Logs the position close with flexible CreditTypeID.

**Rules**:
- Default `@CreditTypeID = 4` (ClosePosition).
- Can be overridden by caller (e.g., 22 or 23 for compulsory/expiry closes, 30 for hierarchy close).
- `@Payment = @CustomerCreditChange`: 0 for mirror positions, `@CreditChangeInDollar` for standalone.
- `@TotalCashChange = @CreditChangeInDollar` (TotalCash always changes).
- `@MirrorCash` = ROUND(old mirror cash + CreditChangeInDollar, 2) if mirror position, else NULL.
- `@SubCreditTypeID` and `@OriginalPositionID` passed through for granular classification.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account whose position is being closed. |
| 2 | @Amount | INT | NO | - | VERIFIED | Position close value in CENTS. Divided by 100 for dollars. Applied to TotalCash and Credit (non-mirror). This is the full position cash value returned, NOT just profit. |
| 3 | @CreditTypeID | INT | YES | 4 | CODE-BACKED | Credit event type. Default 4=ClosePosition. Overridable for special close types (22=compulsory, 23=expiry, 30=hierarchy close, etc.). |
| 4 | @Description | VARCHAR(100) | NO | - | CODE-BACKED | Human-readable description of the close event, stored in credit history. |
| 5 | @ManagerID | INT | YES | 0 | CODE-BACKED | Admin/manager ID for admin-initiated closes. 0 = system/automated close. |
| 6 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position being closed. Stored in credit record and used to look up IsMirror status when not supplied. |
| 7 | @MirrorID | INT | NO | - | CODE-BACKED | Copy-trading mirror ID. 0 = standalone position. Determines whether Trade.Mirror is updated and whether Credit changes. |
| 8 | @BonusCredit | MONEY | YES | 0 | CODE-BACKED | Bonus amount to consume/deduct on close. Reduces CustomerMoney.BonusCredit by this value (floored at 0). |
| 9 | @BonusChange | MONEY | NO | - (OUTPUT) | CODE-BACKED | OUTPUT: actual change to BonusCredit (typically negative = bonus consumed). Caller uses to track bonus lifecycle. |
| 10 | @SubCreditTypeID | TINYINT | YES | NULL | CODE-BACKED | Sub-classification of the close event type. Passed to SetBalanceInsertCredit_Native for granular reporting. |
| 11 | @IsPartial | TINYINT | YES | 0 | CODE-BACKED | Indicates this is a partial position close (1) vs full close (0). Passed as parameter; not used within this procedure's SQL body but may be used in calling context. |
| 12 | @OriginalPositionID | BIGINT | YES | NULL | CODE-BACKED | Original position ID for re-opened or recovered positions. Passed through to SetBalanceInsertCredit_Native. |
| 13 | @NetProfit | MONEY | YES | NULL | CODE-BACKED | Net profit/loss of the position in CENTS divided by 100. Applied to RealizedEquity and Trade.Mirror.RealizedEquity. Distinct from @Amount (total cash returned). |
| 14 | @IsMirror | INT | YES | NULL | CODE-BACKED | Whether position is a mirror-copied position. NULL = auto-detect via retry loop from Position tables. 1 = mirror, 0 = standalone. |
| 15 | @CreditID | BIGINT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: CreditID of the new credit record created. Available since 2021-11-17 (Bonnie). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE TotalCash, RealizedEquity, Credit (conditional), BonusCredit |
| @MirrorID | Trade.Mirror | MODIFIER (conditional) | UPDATE Amount, RealizedEquity, NetProfit for mirror positions |
| @PositionID | History.Position_Active | READ (conditional) | Determines IsMirror via UNION query when @IsMirror not supplied |
| @PositionID | Trade.PositionTbl | READ (conditional) | Fallback for IsMirror detection via UNION query |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs position close credit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=4 (and related close types) here |
| Trade position close pipelines | External | Callers | Called by position close service when finalizing a position settlement |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceClosePosition (procedure)
+-- Customer.CustomerMoney (table) [UPDATE TotalCash, RealizedEquity, Credit, BonusCredit]
+-- Trade.Mirror (table) [conditional UPDATE Amount, RealizedEquity, NetProfit]
+-- History.Position_Active (table) [conditional READ for IsMirror detection]
+-- Trade.PositionTbl (table) [conditional READ for IsMirror detection fallback]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit record]
      +-- History.ActiveCreditRecentMemoryBucket (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - TotalCash, RealizedEquity, Credit (conditional), BonusCredit |
| Trade.Mirror | Table | UPDATE (conditional) - Amount, RealizedEquity, NetProfit |
| History.Position_Active | Table | SELECT (conditional) - IsMirror determination |
| Trade.PositionTbl | Table | SELECT (conditional) - IsMirror determination fallback |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts close position credit record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=4 and related position close events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @Amount = INT (cents) | Unit convention | Divided by 100 for dollars; @NetProfit = MONEY in cents (also /100) |
| Mirror Credit bypass | Design | Mirror positions do not change Credit in CustomerMoney - only Trade.Mirror.Amount changes. This preserves the logical separation between customer balance and mirror balance. |
| BonusCredit floor at 0 | Business rule | `MAX(0, BonusCredit - @BonusCredit)` - bonus credit cannot go negative on position close |
| Retry loop (3 attempts) | Resilience | IsMirror determination retries 3 times when table data is briefly unavailable after close |
| @Amount vs @NetProfit | Design | TotalCash tracks cash flows (total value); RealizedEquity tracks profit/loss only. Both needed for accurate reporting. |

---

## 8. Sample Queries

### 8.1 Find position closes with bonus consumption

```sql
SELECT
    acb.CreditID,
    acb.PositionID,
    acb.MirrorID,
    acb.Payment AS CreditChange,
    acb.TotalCashChange,
    acb.RealizedEquity,
    acb.BonusCredit AS BonusCreditAfterClose,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 4
ORDER BY acb.Occurred DESC
```

### 8.2 Find mirror vs non-mirror position close balance impact

```sql
SELECT
    acb.CreditTypeID,
    CASE WHEN acb.MirrorID > 0 THEN 'Mirror' ELSE 'Standalone' END AS PositionType,
    COUNT(*) AS CloseCount,
    SUM(acb.TotalCashChange) AS TotalCashImpact,
    AVG(acb.Payment) AS AvgCreditImpact
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID IN (4, 22, 23, 30)
GROUP BY acb.CreditTypeID,
         CASE WHEN acb.MirrorID > 0 THEN 'Mirror' ELSE 'Standalone' END
ORDER BY acb.CreditTypeID
```

### 8.3 Verify NetProfit vs Amount for a specific close

```sql
DECLARE @PositionID BIGINT = 123456789;

SELECT
    acb.PositionID,
    acb.Payment AS CreditChange,
    acb.TotalCashChange AS AmountReturnedToTotalCash,
    acb.RealizedEquity AS RealizedEquityAfterClose,
    acb.BonusCredit AS BonusCreditAfterClose,
    acb.MirrorID,
    acb.MirrorCash,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.PositionID = @PositionID
    AND acb.CreditTypeID IN (4, 22, 23, 30)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceClosePosition | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceClosePosition.sql*
