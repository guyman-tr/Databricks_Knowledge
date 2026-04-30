# Trade.GetOrdersForExecutionReportV2_JUNK

> Older JUNK variant of the TradeBlotterAPI execution report V2 - identical structure to GetOrdersForExecutionReportV2 but without MirrorID output column.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All parameters optional; 5-minute window required |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersForExecutionReportV2_JUNK` is an older development/JUNK version of `Trade.GetOrdersForExecutionReportV2`. It has the same parameters, same 5-minute window constraint, same CustomerFlow=1 US DMA scope, same CopySd classification logic, and same four-source order assembly pattern - but the `#order_temp` table was defined WITHOUT the `MirrorID` column. The final output therefore omits MirrorID.

**WHY:** This is an intermediate development artifact that preceded V2. When MirrorID was added to the execution report output (to support copy-trade context in TradeBlotter), this version was superseded and left as JUNK. It remains in the schema for historical reference.

**HOW:** Identical to GetOrdersForExecutionReportV2 except: `#order_temp` does not include a MirrorID column, and the final SELECT does not output MirrorID or AggregatedAmountInUnits. All other logic (EMS two-stage loading, CopySd classification, ExecutionPlan table joins, date window) is identical.

---

## 2. Business Logic

### 2.1 5-Minute Window Constraint

**What:** Identical to V2. Max 5-minute date range enforced.

**Rules:**
- `IF DATEDIFF(MINUTE, @DateFrom, @DateTo) > 5 -> RAISERROR('Date range is too big. Please select range up to 5 minutes.', 16, 1); RETURN`

### 2.2 US DMA Scope and CopySd - Identical to V2

**What:** Same CustomerFlow=1 filter, same INNER JOIN on ApexID IS NOT NULL, same CopySd classification from Dictionary.OpenPositionActionType and Dictionary.ClosePositionActionType.

**Rules:** See `Trade.GetOrdersForExecutionReportV2` Section 2.2 and 2.3 for identical logic.

### 2.3 Key Difference: No MirrorID

**What:** The only structural difference from V2 is the absence of MirrorID in output.

**Columns/Parameters Involved:** `MirrorID` (present in V2, absent here)

**Rules:**
- `#order_temp` definition in JUNK version: CopySd VARCHAR(MAX) NULL is the last column - no MirrorID
- `#order_temp` definition in V2: MirrorID INT NULL is added after CopySd
- Final SELECT in JUNK: does not include MirrorID or AggregatedAmountInUnits columns
- All other output columns are identical to V2

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters (identical to GetOrdersForExecutionReportV2):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | INT | YES | NULL | CODE-BACKED | Customer ID filter. |
| 2 | @ApexAccountID | VARCHAR(100) | YES | NULL | CODE-BACKED | Apex brokerage account ID filter. |
| 3 | @EtoroOrderID | BIGINT | YES | NULL | CODE-BACKED | Specific eToro order ID. |
| 4 | @ApexOrderID | VARCHAR(100) | YES | NULL | CODE-BACKED | Apex-side order ID. |
| 5 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Instrument ID filter. Resolved from @Symbol if provided. |
| 6 | @IsBuy | INT | YES | NULL | CODE-BACKED | Direction filter: 1=BUY, 0=SELL, NULL=both. |
| 7 | @OrderTypeId | INT | YES | NULL | CODE-BACKED | Order type: 17=open by amount, 18=open by units, 19=close, 20=close all. |
| 8 | @TradingStatusId | INT | YES | NULL | CODE-BACKED | Trading status ID filter. |
| 9 | @DealingStatusId | VARCHAR(100) | YES | NULL | CODE-BACKED | EMS/Apex status filter (case-insensitive). |
| 10 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of date range. REQUIRED. Max 5 minutes from @DateTo. |
| 11 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of date range. REQUIRED. Max 5 minutes from @DateFrom. |
| 12 | @Symbol | VARCHAR(100) | YES | NULL | CODE-BACKED | Instrument symbol. Resolved to @InstrumentID. |

**Output Columns (final SELECT DISTINCT - same as V2 but without MirrorID and AggregatedAmountInUnits):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 13 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 14 | ApexAccountID | VARCHAR | YES | - | CODE-BACKED | Apex brokerage account ID. |
| 15 | EtoroOrderID | BIGINT | YES | - | CODE-BACKED | eToro order ID. |
| 16 | TrdOrderStatusKey | INT | YES | - | CODE-BACKED | Trading status ID. |
| 17 | TrdOrderStatusValue | NVARCHAR | YES | - | CODE-BACKED | Trading status label (e.g., 'FILLED', 'REJECTED'). |
| 18 | OrderTypeKey | INT | YES | - | CODE-BACKED | Order type ID. |
| 19 | OrderTypeValue | VARCHAR | YES | - | CODE-BACKED | Order type label. |
| 20 | IsOrderClosed | BIT | NO | - | CODE-BACKED | 0=live queue; 1=DB_Logs.History archive. |
| 21 | ExecutionID | BIGINT | YES | - | CODE-BACKED | Execution routing ID. |
| 22 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Order placement timestamp. |
| 23 | RequestedPrice | VARCHAR(3) | NO | 'MKT' | CODE-BACKED | Always 'MKT'. |
| 24 | AmountRequested | MONEY | YES | - | CODE-BACKED | Requested amount from ExecutionPlan. NULL for close orders. |
| 25 | AmountReceived | MONEY | YES | - | CODE-BACKED | Filled amount. |
| 26 | QuantityRequested | DECIMAL(16,8) | NO | - | CODE-BACKED | Units requested from ExecutionPlan. |
| 27 | QuantityExecuted | DECIMAL(16,8) | NO | - | CODE-BACKED | Units filled from ExecutedOrders. |
| 28 | IsNotional | VARCHAR(9) | YES | - | CODE-BACKED | 'Notional' for OrderType=17; 'UnitBased' for others. |
| 29 | SideKey | INT | NO | - | CODE-BACKED | IsBuy: 1=BUY, 0=SELL. |
| 30 | SideValue | VARCHAR(4) | NO | - | CODE-BACKED | 'BUY' or 'SELL'. |
| 31 | Symbol | VARCHAR | YES | - | CODE-BACKED | Instrument ticker symbol. |
| 32 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Full instrument display name. |
| 33 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID. |
| 34 | ExecutedPrice | DECIMAL(16,8) | YES | - | CODE-BACKED | Execution price (NULL for live orders; InitForexRate or EndForexRate for historical). |
| 35 | GrossValue | DECIMAL | YES | - | CODE-BACKED | QuantityExecuted * ExecutedPrice. |
| 36 | TrdErrorMessage | VARCHAR(MAX) | YES | - | CODE-BACKED | Trading system error message. |
| 37 | PositionID | BIGINT | YES | - | CODE-BACKED | Resulting position ID. |
| 38 | IsPositionOpened | INT | YES | - | CODE-BACKED | 1 if position still active in PositionTbl; 0 otherwise. |
| 39 | ApexOrderID | VARCHAR | YES | - | CODE-BACKED | Apex-side order ID from SynHedgeEMSOrders. |
| 40 | CopySd | VARCHAR(MAX) | YES | - | CODE-BACKED | Copy/Self-Directed classification. |
| 41 | DealingStatusId | VARCHAR(100) | YES | - | CODE-BACKED | Echo of @DealingStatusId input. |
| 42 | OpenCorrelationID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Execution plan correlation ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Identical to `Trade.GetOrdersForExecutionReportV2`. See that document for the full reference list. The only difference is MirrorID is not used in output.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. JUNK version - not actively called by production systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

Same as `Trade.GetOrdersForExecutionReportV2`. See that document.

### 6.1 Objects This Depends On

Same as `Trade.GetOrdersForExecutionReportV2` (see that document). All same tables and views.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | JUNK version, not called by production code |

---

## 7. Technical Details

### 7.1 Indexes

Same as `Trade.GetOrdersForExecutionReportV2`. Identical temp table index strategy.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 5-minute window | Input validation | Same as V2 |
| CustomerFlow=1 | Scope filter | US DMA only |
| No MirrorID | Structural | This version omits MirrorID - key difference from V2 |
| WITH RECOMPILE | Performance | Fresh plan each call |

---

## 8. Sample Queries

### 8.1 All orders for a customer in a 5-minute window

```sql
EXEC Trade.GetOrdersForExecutionReportV2_JUNK
    @Cid = 7234263,
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
```

### 8.2 Filled orders by dealing status

```sql
EXEC Trade.GetOrdersForExecutionReportV2_JUNK
    @DealingStatusId = 'Filled',
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
```

### 8.3 Orders for specific instrument

```sql
EXEC Trade.GetOrdersForExecutionReportV2_JUNK
    @Symbol = 'AAPL',
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 42 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersForExecutionReportV2_JUNK | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersForExecutionReportV2_JUNK.sql*
