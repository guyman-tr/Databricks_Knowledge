# Trade.PositionCloseValidation

> Validates partial-close arithmetic integrity by verifying that a position's current units and amounts equal the sum of the open and closed portions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (partition key: @PositionID%50) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionCloseValidation is the pre-execution integrity gate called by Trade.PositionClose immediately before a partial close is committed. Its job is to confirm that the proposed split of a position is arithmetically consistent: the sum of what will remain open (OpenUnits, OpenPositionAmount, OpenUnitsBaseValueInCents) plus what is being closed (PartialClosedUnits, PartialClosedPositionAmount, PartialClosedUnitsBaseValueInCents) must equal the position's current values in Trade.PositionTbl.

For a full close (@IsPartial=0), the SP returns immediately with no validation because there is nothing to split - the position is simply closed in full. For partial closes, all three numeric dimensions (units, amount, base value in cents) are checked against the live row in Trade.PositionTbl. If any check fails, the SP raises an error with a descriptive message that includes the actual vs. expected values, causing Trade.PositionClose to roll back.

The use of XLOCK + ROWLOCK hints on the Trade.PositionTbl read ensures no concurrent modification occurs between reading the current values and the subsequent UPDATE in Trade.PositionClose. This SP was added as part of a partial-close hardening initiative (Ran Ovadia, January 2021).

---

## 2. Business Logic

### 2.1 Regular Close - No Validation (Short-Circuit)

**What**: For a full close (@IsPartial=0), the SP immediately returns without performing any validation.

**Columns/Parameters Involved**: @IsPartial

**Rules**:
- IF @IsPartial=0: RETURN (no reads, no validations, no errors)
- Design rationale: a full close cannot have arithmetic inconsistency because no split occurs

### 2.2 Partial Close - Units Consistency Check

**What**: Validates that the current AmountInUnitsDecimal on the position equals the sum of the open portion and the closed portion.

**Columns/Parameters Involved**: Trade.PositionTbl.AmountInUnitsDecimal, @OpenUnits, @PartialClosedUnits

**Rules**:
- Check: |CurrentAmountInUnits - (@OpenUnits + @PartialClosedUnits)| <= 0.000001
- Tolerance of 0.000001 accommodates floating-point rounding in decimal arithmetic
- Failure message: 'Current Amount In Units ({actual}) isn''t equal to Open Units ({open}) +Partial Closed Units ({closed})'
- Raises RAISERROR severity 16, state 16 on failure

### 2.3 Partial Close - Amount Consistency Check

**What**: Validates that the current Amount (money) on the position equals the sum of the open and closed position amounts.

**Columns/Parameters Involved**: Trade.PositionTbl.Amount, @OpenPositionAmount, @PartialClosedPositionAmount

**Rules**:
- Check: |CurrentAmount - (@PartialClosedPositionAmount + @OpenPositionAmount)| <= 0.0001
- Tolerance of 0.0001 (wider than units) accommodates MONEY type precision
- Failure message: 'Current Amount ({actual}) isn''t equal to Open Position Amount ({open}) +Partial Closed Position Amount ({closed})'
- Raises RAISERROR severity 16, state 16 on failure

### 2.4 Partial Close - Units Base Value Consistency Check

**What**: Validates that the current UnitsBaseValueCents on the position exactly equals the sum of the open and closed base values (in cents).

**Columns/Parameters Involved**: Trade.PositionTbl.UnitsBaseValueCents, @OpenUnitsBaseValueInCents, @PartialClosedUnitsBaseValueInCents

**Rules**:
- Check: CurrentUnitsBaseValue = @PartialClosedUnitsBaseValueInCents + @OpenUnitsBaseValueInCents (exact, no tolerance - INT arithmetic)
- Failure message: 'Current Units base value ({actual}) isn''t equal to Open Units base value ({open}) +Partial Closed Units base value ({closed})'
- Raises RAISERROR severity 16, state 16 on failure

### 2.5 Row Locking During Read

**What**: The read of Trade.PositionTbl uses XLOCK + ROWLOCK hints to prevent concurrent modification during validation.

**Rules**:
- WITH(XLOCK,ROWLOCK): acquires exclusive row-level lock on the PositionTbl row
- Partition elimination: WHERE PositionID = @PositionID AND StatusID = 1 AND PartitionCol = @PositionID%50
- Only open positions (StatusID=1) are readable; if the position has already been closed or is not found, @Current* variables remain NULL and all three validation checks will fire with NULL comparisons (raising errors)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position to validate. Partition key: @PositionID%50. Reads Trade.PositionTbl with XLOCK+ROWLOCK. |
| 2 | @IsPartial | BIT | NO | - | CODE-BACKED | 1=partial close (run validations), 0=full close (return immediately). |
| 3 | @OpenUnits | DECIMAL(16,6) | NO | - | CODE-BACKED | Units that will remain open after the partial close. Must sum with @PartialClosedUnits to match current AmountInUnitsDecimal. |
| 4 | @PartialClosedUnits | DECIMAL(16,6) | NO | - | CODE-BACKED | Units being closed in this partial close. Must sum with @OpenUnits to match current AmountInUnitsDecimal. |
| 5 | @OpenUnitsBaseValueInCents | INT | NO | - | CODE-BACKED | Base value in cents for the open portion. Must sum with @PartialClosedUnitsBaseValueInCents to match current UnitsBaseValueCents (exact). |
| 6 | @PartialClosedUnitsBaseValueInCents | INT | NO | - | CODE-BACKED | Base value in cents for the closed portion. Must sum with @OpenUnitsBaseValueInCents to match current UnitsBaseValueCents (exact). |
| 7 | @PartialClosedPositionAmount | MONEY | NO | - | CODE-BACKED | Dollar amount being closed. Must sum with @OpenPositionAmount to match current Amount (tolerance 0.0001). |
| 8 | @OpenPositionAmount | MONEY | NO | - | CODE-BACKED | Dollar amount remaining open. Must sum with @PartialClosedPositionAmount to match current Amount (tolerance 0.0001). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (XLOCK,ROWLOCK) | Trade.PositionTbl | DML read (locking) | Reads AmountInUnitsDecimal, Amount, UnitsBaseValueCents for the given open position |

### 5.2 Referenced By (other objects point to this)

| Caller | How Used |
|--------|----------|
| Trade.PositionClose | Called during partial close execution to validate split arithmetic before committing the close |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionCloseValidation (procedure)
+-- Trade.PositionTbl (table) - READ with XLOCK+ROWLOCK for current units/amount/base value
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT AmountInUnitsDecimal, Amount, UnitsBaseValueCents WITH(XLOCK,ROWLOCK) WHERE StatusID=1 AND PartitionCol=@PositionID%50 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionClose | Stored Procedure | Calls this SP before executing a partial close to verify arithmetic consistency |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Validation only runs for partial closes (@IsPartial=1)
- Units check tolerance: +/- 0.000001 (accounts for DECIMAL floating-point)
- Amount check tolerance: +/- 0.0001 (accounts for MONEY precision)
- Base value check: exact INT equality (no tolerance)
- XLOCK+ROWLOCK prevents concurrent modification between validation read and subsequent UPDATE in Trade.PositionClose

---

## 8. Sample Queries

### 8.1 Validate a partial close split (called internally by Trade.PositionClose)

```sql
EXEC Trade.PositionCloseValidation
    @PositionID                          = 123456789,
    @IsPartial                           = 1,
    @OpenUnits                           = 0.75,
    @PartialClosedUnits                  = 0.25,
    @OpenUnitsBaseValueInCents           = 7500,
    @PartialClosedUnitsBaseValueInCents  = 2500,
    @PartialClosedPositionAmount         = 25.00,
    @OpenPositionAmount                  = 75.00;
-- Returns without error if arithmetic checks out; raises error if values don't match
```

### 8.2 Find recent partial close validation failures in Trade.PositionClose error logs

```sql
SELECT PositionID, CID, FailReason, RequestCloseOccurred
FROM History.PositionFailWrite WITH (NOLOCK)
WHERE FailReason LIKE '%isn''t equal to%'
ORDER BY RequestCloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed (Trade.PositionClose) | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionCloseValidation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionCloseValidation.sql*
