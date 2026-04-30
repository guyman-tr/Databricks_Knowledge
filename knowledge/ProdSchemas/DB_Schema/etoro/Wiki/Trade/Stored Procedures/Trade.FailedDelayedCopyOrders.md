# Trade.FailedDelayedCopyOrders

> Reports failed delayed copy orders (US DMA flow) for a given date, enriching them with customer Apex account IDs, order status/type names, and instrument symbols for operations investigation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @date - filters by order date |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure generates a diagnostic report for failed delayed copy orders in the US DMA (Direct Market Access) execution flow. When a copy-trading order fails due to specific error codes (1010-1014), this report collects the details for operations team investigation.

The procedure exists because the US DMA flow uses a delayed execution model where copy orders are queued via `Trade.OpenExecutionPlan` and executed asynchronously via `Trade.OrderForOpen`. When these orders fail with error codes 1010-1014, the customer's copied position was not opened, which may cause their portfolio to diverge from the leader they are copying.

The report searches both current (`Trade.OpenExecutionPlan`/`Trade.OrderForOpen`) and historical (`History.OpenExecutionPlan`/`History.OrderForOpen`) tables, then enriches the results with the customer's Apex brokerage account ID (from `Customer.CustomerStatic.ApexID`), human-readable order type and status names, and instrument symbols for easy identification.

---

## 2. Business Logic

### 2.1 DMA Error Code Filtering

**What**: Targets specific copy order failure codes in the US DMA flow.

**Columns/Parameters Involved**: `ErrorCode`, `CustomerFlow`

**Rules**:
- Error codes filtered: 1010, 1011, 1012, 1013, 1014 (specific DMA execution failures)
- CustomerFlow must be 1 (US_DMA flow only - not applicable to other flows)
- Both current and history tables are searched since failed orders may have been archived

### 2.2 Apex Account Resolution

**What**: Maps eToro CIDs to external Apex brokerage account IDs for US DMA reporting.

**Columns/Parameters Involved**: `CID`, `ApexID`

**Rules**:
- ApexID from Customer.CustomerStatic identifies the customer's account at the Apex Clearing brokerage
- Required for coordinating with the external broker about failed order execution

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @date | date | NO | - | CODE-BACKED | Date to filter failed orders by. Compared against CONVERT(DATE, OpenOccurred) to find orders that failed on this specific date. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID of the copier whose order failed. |
| 2 | ApexAccountID | varchar | YES | - | CODE-BACKED | Customer's Apex Clearing brokerage account ID from Customer.CustomerStatic. |
| 3 | eToroOrderID | bigint | NO | - | CODE-BACKED | eToro order identifier (same as OrderID). |
| 4 | OrderStatus | varchar | YES | - | CODE-BACKED | Human-readable order status from Dictionary.OrderForExecutionStatus. |
| 5 | OrderType | varchar | YES | - | CODE-BACKED | Human-readable order type from Dictionary.OrderType. |
| 6 | ExecutionID | bigint | YES | - | CODE-BACKED | Execution plan identifier linking order to execution pipeline. |
| 7 | OpenOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the order was submitted. |
| 8 | AmountRequested | money | YES | - | CODE-BACKED | Dollar amount the copier requested to invest. |
| 9 | AmountReceived | money | YES | - | CODE-BACKED | Dollar amount actually filled (FilledAmount). May differ from requested. |
| 10 | QuantityRequested | decimal(16,8) | YES | - | CODE-BACKED | Number of units/shares requested (AmountInUnits). |
| 11 | Side | varchar | YES | - | CODE-BACKED | Computed: 'BUY' when IsBuy=1, 'SELL' when IsBuy=0. |
| 12 | Symbol | varchar | YES | - | CODE-BACKED | Instrument ticker symbol from Trade.InstrumentMetaData. |
| 13 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier. |
| 14 | ErrorMessage | varchar(300) | YES | - | CODE-BACKED | Error message from the failed execution attempt. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Trade.OpenExecutionPlan | READER | Current execution plans for matching failed orders |
| JOIN | Trade.OrderForOpen | READER | Current open orders with error codes 1010-1014 and CustomerFlow=1 |
| JOIN | History.OpenExecutionPlan | READER | Archived execution plans |
| JOIN | History.OrderForOpen | READER | Archived failed open orders |
| JOIN | Customer.CustomerStatic | READER | Gets ApexID for customer |
| LEFT JOIN | Dictionary.OrderType | READER | Resolves order type to name |
| LEFT JOIN | Dictionary.OrderForExecutionStatus | READER | Resolves status ID to name |
| LEFT JOIN | Trade.InstrumentMetaData | READER | Gets instrument Symbol |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | Called by operations/support teams for DMA failure investigation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FailedDelayedCopyOrders (procedure)
+-- Trade.OpenExecutionPlan (table)
+-- Trade.OrderForOpen (table)
+-- History.OpenExecutionPlan (table)
+-- History.OrderForOpen (table)
+-- Customer.CustomerStatic (table)
+-- Dictionary.OrderType (table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenExecutionPlan | Table | LEFT JOIN to match orders with execution plans |
| Trade.OrderForOpen | Table | JOIN - current failed orders |
| History.OpenExecutionPlan | Table | LEFT JOIN to match archived orders with plans |
| History.OrderForOpen | Table | JOIN - archived failed orders |
| Customer.CustomerStatic | Table | JOIN - gets Apex brokerage account ID |
| Dictionary.OrderType | Table | LEFT JOIN - resolves order type name |
| Dictionary.OrderForExecutionStatus | Table | LEFT JOIN - resolves order status name |
| Trade.InstrumentMetaData | Table | LEFT JOIN - gets instrument symbol |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run Failed DMA Copy Orders Report

```sql
EXEC Trade.FailedDelayedCopyOrders @date = '2026-03-15'
```

### 8.2 Check DMA Error Code Distribution

```sql
SELECT ErrorCode,
       COUNT(*) AS FailureCount,
       MIN(OpenOccurred) AS FirstFailure,
       MAX(OpenOccurred) AS LastFailure
  FROM Trade.OrderForOpen WITH (NOLOCK)
 WHERE ErrorCode IN (1010, 1011, 1012, 1013, 1014)
   AND CustomerFlow = 1
   AND OpenOccurred > DATEADD(DAY, -7, GETUTCDATE())
 GROUP BY ErrorCode
 ORDER BY FailureCount DESC
```

### 8.3 Find DMA Customers by Apex Account

```sql
SELECT cs.CID,
       cs.ApexID,
       COUNT(p.PositionID) AS OpenPositions
  FROM Customer.CustomerStatic cs WITH (NOLOCK)
  LEFT JOIN Trade.Position p WITH (NOLOCK) ON cs.CID = p.CID
 WHERE cs.ApexID IS NOT NULL
 GROUP BY cs.CID, cs.ApexID
 ORDER BY cs.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FailedDelayedCopyOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.FailedDelayedCopyOrders.sql*
