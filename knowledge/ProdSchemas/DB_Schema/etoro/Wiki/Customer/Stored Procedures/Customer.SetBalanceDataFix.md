# Customer.SetBalanceDataFix

> Directly overwrites CustomerMoney balance fields with supplied absolute values (NULL = keep current), optionally recalculates BSLRealFunds from Trade.PnL, and logs CreditTypeID=31 (DataFix) - used by PostMIMOOperations and manual data correction workflows.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @Credit MONEY, @RealizedEquity MONEY, @TotalCash MONEY; @CreditID BIGINT OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalanceDataFix` is the only `SetBalance*` procedure that performs **absolute overwrites** rather than delta additions. Where `SetBalanceDeposit` adds to Credit (+= amount), `SetBalanceDataFix` sets Credit directly to the supplied value. This makes it uniquely suited for data correction scenarios where the exact correct balance is known and needs to be written regardless of the current state.

Key use cases:
- **PostMIMOOperations** calls this to apply recalculated balance values after a MIMO event (the MIMO calculation determines the exact correct BSLRealFunds, BonusCredit, etc.).
- **Manual data fixes** by support/operations teams when a balance discrepancy is identified and the exact correct value is computed externally.
- **PostMIMOOperationsDebug** (same logic with richer position data source).

NULL parameters are "no-op" per field: passing `@Credit = NULL` keeps the existing Credit value. This allows callers to fix only specific fields without affecting others.

There is no MIMO trigger, no Service Broker notification, and no affiliate tracking - DataFix is a pure correction tool, not a financial flow event.

---

## 2. Business Logic

### 2.1 Absolute Overwrite (Not Delta)

**What**: Each balance field is SET to the supplied value (not incremented).

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`, `TotalCash`, `BonusCredit`

**Rules**:
- `Credit = ISNULL(@Credit, Credit)` - if @Credit supplied, overwrite; if NULL, keep current
- `RealizedEquity = ISNULL(@RealizedEquity, RealizedEquity)` - same
- `TotalCash = ISNULL(@TotalCash, TotalCash)` - same
- `BonusCredit = ISNULL(@BonusCredit, BonusCredit)` - same
- All four fields are always included in the UPDATE statement; NULL = no change for that field.

### 2.2 BSLRealFunds Three-Mode Update

**What**: BSLRealFunds can be left unchanged, explicitly set, or calculated from RealizedEquity and live PnL.

**Columns/Parameters Involved**: `BSLRealFunds`, `@ShouldChangeBSLRealFunds`, `@BSLRealFunds`, `Trade.PnL`

**Rules**:
```
IF @ShouldChangeBSLRealFunds = 0:
  BSLRealFunds unchanged

IF @ShouldChangeBSLRealFunds = 1 AND @BSLRealFunds IS NOT NULL:
  BSLRealFunds = @BSLRealFunds (explicit value)

IF @ShouldChangeBSLRealFunds = 1 AND @BSLRealFunds IS NULL:
  @PnL = SUM(Trade.PnL.PnLInDollars) WHERE CID = @CID
  BSLRealFunds = ISNULL(@RealizedEquity, RealizedEquity) - ISNULL(@BonusCredit, BonusCredit) + @PnL
```

The formula `RealizedEquity - BonusCredit + PnL` represents the "real funds" concept: equity minus promotional credits plus unrealized PnL.

### 2.3 Credit Record (Payment = 0, TotalCashChange = 0)

**What**: Logs the data fix as a credit history event with zero payment amount.

**Rules**:
- `@CreditTypeID = 31` (DataFix, hardcoded)
- `@Payment = 0` - no financial flow; this is a correction, not a transaction
- `@TotalCashChange = 0` - same
- Passes the new (post-fix) values of Credit, RealizedEquity, TotalCash, BonusCredit, BSLRealFunds to the credit record as snapshots.
- Returns `@CreditID OUTPUT`.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose balance is being corrected. |
| 2 | @Credit | MONEY | YES | - | CODE-BACKED | Absolute new Credit value to write. NULL = keep current Credit unchanged. |
| 3 | @RealizedEquity | MONEY | YES | - | CODE-BACKED | Absolute new RealizedEquity to write. NULL = keep current. |
| 4 | @TotalCash | MONEY | YES | - | CODE-BACKED | Absolute new TotalCash to write. NULL = keep current. |
| 5 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable description of the data fix, stored in the credit history record. |
| 6 | @BonusCredit | MONEY | YES | - | CODE-BACKED | Absolute new BonusCredit to write. NULL = keep current. |
| 7 | @ShouldChangeBSLRealFunds | TINYINT | YES | 0 | CODE-BACKED | Controls BSLRealFunds update mode: 0=leave unchanged, 1=update (using @BSLRealFunds if supplied, or calculate from RealizedEquity-BonusCredit+PnL). |
| 8 | @BSLRealFunds | MONEY | YES | NULL | CODE-BACKED | Explicit BSLRealFunds value to write when @ShouldChangeBSLRealFunds=1. NULL with @ShouldChangeBSLRealFunds=1 triggers auto-calculation from Trade.PnL. |
| 9 | @CreditID | BIGINT | YES | 0 (OUTPUT) | CODE-BACKED | OUTPUT: CreditID of the DataFix credit record created. Allows callers to reference the correction event. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | Absolute UPDATE of Credit, RealizedEquity, TotalCash, BonusCredit, BSLRealFunds (conditional) |
| @CID | Trade.PnL | READ (conditional) | SUM PnLInDollars for auto-BSLRealFunds calculation when @ShouldChangeBSLRealFunds=1 and @BSLRealFunds=NULL |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=31 DataFix credit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.PostMIMOOperations | EXEC | Caller | Applies MIMO-recalculated balance corrections after position events |
| Customer.PostMIMOOperationsDebug | EXEC | Caller | Same as PostMIMOOperations but with debug-mode position data source |
| Manual data correction tools | External | Callers | Used by support/operations to fix specific balance discrepancies |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceDataFix (procedure)
+-- Customer.CustomerMoney (table) [absolute UPDATE Credit, RealizedEquity, TotalCash, BonusCredit, BSLRealFunds]
+-- Trade.PnL (table/view) [conditional READ for BSLRealFunds auto-calculation]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=31]
      +-- History.ActiveCreditRecentMemoryBucket (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - absolute overwrite of balance fields |
| Trade.PnL | Table/View | SELECT (conditional) - SUM PnLInDollars for BSLRealFunds auto-calculation |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=31 DataFix record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.PostMIMOOperations | Procedure | Calls this to apply MIMO recalculated balance corrections |
| Customer.PostMIMOOperationsDebug | Procedure | Calls this same as PostMIMOOperations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Absolute overwrite (not delta) | Critical design | Unlike all other SetBalance* procs (which use +=), this writes exact values. Callers must compute the correct target value externally before calling. |
| NULL = no-op per field | Design | ISNULL guard means NULL parameter leaves that field unchanged - enables field-selective correction |
| @Payment = 0 | Audit convention | DataFix records have Payment=0 - they are corrections, not financial flows. Distinguishes them from deposit/withdrawal records in the credit history. |
| BSLRealFunds formula | BSL logic | `RealizedEquity - BonusCredit + PnL` = real funds: equity minus promotional credits plus unrealized position gains |
| No MIMO trigger | Design | DataFix itself is not a MIMO event. Called BY PostMIMOOperations after MIMO calculation, not before. |
| No Service Broker | Design | No downstream payment processing needed for internal corrections |

---

## 8. Sample Queries

### 8.1 Find all data fix events for a customer

```sql
SELECT
    acb.CreditID,
    acb.Credit AS CreditAfterFix,
    acb.RealizedEquity AS EquityAfterFix,
    acb.TotalCashChange,
    acb.BSLRealFunds AS BSLAfterFix,
    acb.BonusCredit AS BonusCreditAfterFix,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 31
ORDER BY acb.Occurred DESC
```

### 8.2 Check what MIMO event preceded a DataFix

```sql
DECLARE @CID INT = 12345;

SELECT TOP 5
    acb.CreditID,
    acb.CreditTypeID,
    ct.Name AS EventType,
    acb.Credit,
    acb.RealizedEquity,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acb.CreditTypeID
WHERE acb.CID = @CID
ORDER BY acb.Occurred DESC
-- Look for CreditTypeID=31 rows preceded by MIMO events (1, 2, 6, 7, 11, 28, etc.)
```

### 8.3 Verify BSLRealFunds recalculation correctness

```sql
DECLARE @CID INT = 12345;

SELECT
    cm.Credit,
    cm.RealizedEquity,
    cm.BonusCredit,
    cm.BSLRealFunds AS CurrentBSL,
    ISNULL(SUM(p.PnLInDollars), 0) AS CurrentPnL,
    cm.RealizedEquity - cm.BonusCredit + ISNULL(SUM(p.PnLInDollars), 0) AS ExpectedBSL,
    cm.BSLRealFunds - (cm.RealizedEquity - cm.BonusCredit + ISNULL(SUM(p.PnLInDollars), 0)) AS BSLDrift
FROM Customer.CustomerMoney cm WITH (NOLOCK)
LEFT JOIN Trade.PnL p WITH (NOLOCK) ON p.CID = cm.CID
WHERE cm.CID = @CID
GROUP BY cm.Credit, cm.RealizedEquity, cm.BonusCredit, cm.BSLRealFunds
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceDataFix | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceDataFix.sql*
