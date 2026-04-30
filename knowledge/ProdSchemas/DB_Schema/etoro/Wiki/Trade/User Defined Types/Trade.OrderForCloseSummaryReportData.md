# Trade.OrderForCloseSummaryReportData

> Memory-optimized TVP for close-order execution summary data: units closed, net profit, fees, taxes, and partial-close metadata per position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID, CID |
| **Partition** | N/A |
| **Indexes** | 2 (IDX_CloseExecuted hash, IDX_Level_CloseExecuted_PartialClosePositionID nonclustered) |

---

## 1. Business Meaning

Trade.OrderForCloseSummaryReportData is a memory-optimized table-valued parameter type that holds the outcome of close-order execution. Each row represents a close-operation result for a position: how many units were closed, net profit, fees, taxes, and partial-close details. The type supports both full closes and partial closes with ratio and linked partial-close position metadata.

This type exists to aggregate close-order results for reporting and reconciliation. Procedures such as OrderForCloseUpdate declare a variable of this type and populate it with per-position execution data before further processing or output.

The type flows as a local table variable within procedures that execute close orders. Results are inserted row-by-row as each close completes, then the table is used for JOINs, aggregation, or output to callers.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type groups close-execution metrics (units, profit, fees, taxes) with partial-close metadata (PartialClosePositionID, PartialCloseRatio, PartialClosedPositionAmount) per position.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position being closed. References Trade position. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID owning the position. |
| 3 | CloseExecuted | bit | NO | - | CODE-BACKED | Whether the close was successfully executed. |
| 4 | RequestedUnits | decimal(16,6) | NO | - | NAME-INFERRED | Units requested for close. |
| 5 | Units | decimal(16,6) | NO | - | CODE-BACKED | Actual units closed. |
| 6 | NetProfit | money | NO | - | CODE-BACKED | Net profit from the close. |
| 7 | Level | smallint | NO | - | NAME-INFERRED | Execution level or hierarchy. |
| 8 | PartialClosePositionID | bigint | YES | 0 | CODE-BACKED | ID of child position created by partial close. |
| 9 | PartialClosedPositionAmount | money | YES | - | NAME-INFERRED | Amount closed in the partial close. |
| 10 | OpenPositionAmount | money | YES | - | NAME-INFERRED | Remaining open position amount after partial close. |
| 11 | OpenUnits | decimal(16,6) | YES | - | NAME-INFERRED | Remaining open units. |
| 12 | PartialCloseRatio | decimal(16,15) | YES | - | NAME-INFERRED | Ratio of partial close to total position. |
| 13 | OpenUnitsBaseValueInCents | int | YES | - | NAME-INFERRED | Base value of remaining units in cents. |
| 14 | Amount | money | YES | - | CODE-BACKED | Close amount. |
| 15 | CloseTotalFees | money | YES | - | NAME-INFERRED | Total fees charged on close. |
| 16 | CloseTotalTaxes | money | YES | - | NAME-INFERRED | Total taxes charged on close. |

---

## 5. Relationships

### 5.1 References To (this object points to)

PositionID semantically references Trade position tables; CID references Customer. No declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForCloseUpdate | @ExecutionSummaryReport | Local variable (TVP) | Holds close-execution summary as local table variable for reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForCloseUpdate | Stored Procedure | Local table variable for close-execution summary report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns |
|------------|------|---------|
| IDX_CloseExecuted | HASH (BUCKET_COUNT=2) | CloseExecuted |
| IDX_Level_CloseExecuted_PartialClosePositionID | NONCLUSTERED | Level, CloseExecuted, PartialClosePositionID |

Memory-optimized type (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate OrderForCloseSummaryReportData in a procedure

```sql
DECLARE @ExecutionSummaryReport [Trade].[OrderForCloseSummaryReportData];
INSERT INTO @ExecutionSummaryReport
    (PositionID, CID, CloseExecuted, RequestedUnits, Units, NetProfit, Level,
     PartialClosePositionID, Amount, CloseTotalFees, CloseTotalTaxes)
VALUES
    (1001, 50001, 1, 100.5, 100.5, 250.00, 1, 0, 10000.00, 5.00, 0.00);
```

### 8.2 Populate from close execution results

```sql
INSERT INTO @ExecutionSummaryReport
SELECT PositionID, CID, 1 AS CloseExecuted, @RequestedUnits, @UnitsClosed,
       @NetProfit, @Level, 0, @Amount, @Fees, @Taxes
WHERE @CloseSuccess = 1;
```

### 8.3 Partial close with ratio

```sql
INSERT INTO @ExecutionSummaryReport
    (PositionID, CID, CloseExecuted, RequestedUnits, Units, NetProfit, Level,
     PartialClosePositionID, PartialCloseRatio, PartialClosedPositionAmount,
     OpenUnits, OpenPositionAmount, Amount, CloseTotalFees, CloseTotalTaxes)
VALUES
    (1001, 50001, 1, 50, 50, 125.00, 1, 1002, 0.5, 5000.00,
     50, 5000.00, 5000.00, 2.50, 0.00);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.6/10 (Elements: 8/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 11 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderForCloseSummaryReportData | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OrderForCloseSummaryReportData.sql*
