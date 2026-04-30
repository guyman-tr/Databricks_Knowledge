# Trade.GetAleErrorReport

> Reports failed ALE (Apex Logistics Engine) operations - both Fund-of-Funds money transfers and stock allocation errors - with optional multi-filter search.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns combined FOF and Allocation error events from ALE integration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure generates an error report for the Apex Logistics Engine (ALE) integration, which handles the real stock (DMA) trading pipeline through Apex Clearing. It combines two types of failed operations: (1) FOF (Fund-of-Funds) money transfer failures from SynMoneyTransferAleLog, and (2) Stock allocation failures from SynHedgeApexAleEvent. These are operations that were sent to Apex but did not complete successfully.

The procedure exists to support operations monitoring and troubleshooting of the Apex Clearing integration. When stock allocations or money transfers fail, operations teams need to identify, diagnose, and resolve the issues. This report provides a unified view of both failure types with multiple search filters.

Data flows from multiple synonym tables (Syn*) that reference external logging databases, combined via UNION ALL into a single CTE, filtered by multiple optional parameters, and joined with Customer.CustomerStatic to resolve CID from ApexAccountID. The procedure also queries Trade.CloseExecutionPlan and its history counterpart to resolve OrderIDs for allocation errors.

---

## 2. Business Logic

### 2.1 Dual Error Source Union

**What**: Combines FOF money transfer errors and stock allocation errors into a single report.

**Columns/Parameters Involved**: `Type`, `AleType`

**Rules**:
- FOF (Fund-of-Funds): Money transfer operations that failed (State NOT IN 'Completed','FundsPosted'). All instrument-related fields are NULL for FOF entries.
- Allocation: Stock buy/sell allocation requests that had errors or non-success statuses. Includes instrument details (Symbol, InstrumentID, IsBuy) and OrderID resolution.
- Both types are normalized into the same column structure via UNION ALL

### 2.2 Multi-Parameter Optional Filtering

**What**: Eight optional filters narrow results across date, customer, instrument, and external identifiers.

**Columns/Parameters Involved**: All 8 filter parameters

**Rules**:
- Each filter uses the pattern `(@param = Column OR @param IS NULL)` for optional filtering
- All filters are combined with AND logic
- Supports OFFSET/FETCH pagination via @pageNumber and @itemsPerPage

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @date | DATE | YES | NULL | CODE-BACKED | Filter by event date. NULL returns all dates. |
| 2 | @symbol | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by instrument symbol (case-insensitive). |
| 3 | @instrumentID | INT | YES | NULL | CODE-BACKED | Filter by instrument ID. |
| 4 | @cid | INT | YES | NULL | CODE-BACKED | Filter by customer ID. |
| 5 | @isBuy | INT | YES | NULL | CODE-BACKED | Filter by direction: 1=Buy, 0=Sell. |
| 6 | @ExternalID | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by external (Apex) request ID. |
| 7 | @apexAccountID | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by Apex clearing account ID. |
| 8 | @AleMessageType | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by ALE message type: 'FOF' or 'Allocation'. |
| 9 | @pageNumber | INT | YES | 1 | CODE-BACKED | Page number for pagination (1-based). |
| 10 | @itemsPerPage | INT | YES | 100 | CODE-BACKED | Number of items per page. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 11 | Date | DATETIME | YES | - | CODE-BACKED | When the ALE event occurred. |
| 12 | ExternalID | VARCHAR(30) | YES | - | CODE-BACKED | External request ID from Apex. |
| 13 | Status | VARCHAR | YES | - | CODE-BACKED | ALE event status (e.g., error state from Apex). |
| 14 | Message | VARCHAR | YES | - | CODE-BACKED | Human-readable message from Apex about the failure. |
| 15 | CID | INT | YES | - | CODE-BACKED | Customer ID (resolved from ApexAccountID if not directly available). |
| 16 | Symbol | VARCHAR | YES | - | CODE-BACKED | Instrument symbol (NULL for FOF entries). |
| 17 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID (NULL for FOF entries). |
| 18 | IsBuy | BIT | YES | - | CODE-BACKED | Direction (NULL for FOF entries). |
| 19 | ApexAccountID | VARCHAR | YES | - | CODE-BACKED | Apex clearing account identifier. |
| 20 | AleType | VARCHAR | YES | - | CODE-BACKED | Type of ALE event: 'FOF' or 'Allocation {SourceName}'. |
| 21 | ID | NVARCHAR(50) | YES | - | CODE-BACKED | Internal event ID (TransferResponseID for FOF, PayloadId for Allocation). |
| 22 | OrderID | BIGINT | YES | - | CODE-BACKED | Associated trading order ID (resolved from CloseExecutionPlan). |
| 23 | ErrorMessage | VARCHAR | YES | - | CODE-BACKED | Detailed error message from allocation request errors. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.SynMoneyTransferAleLog | Direct Read (Synonym) | FOF money transfer ALE events |
| LEFT JOIN | dbo.SynMoneyTransferRequestLog | Lookup (Synonym) | FOF transfer request details |
| FROM | dbo.SynHedgeApexAleEvent | Direct Read (Synonym) | Allocation ALE events |
| LEFT JOIN | dbo.SynHedgeApexAleEventMessage | Lookup (Synonym) | ALE event message text |
| LEFT JOIN | dbo.SynHedgeAllocationRequests | Lookup (Synonym) | Allocation request details |
| LEFT JOIN | dbo.SynHedgeAllocationRequestsErrors | Lookup (Synonym) | Allocation error details |
| LEFT JOIN | dbo.SynHedgeAllocationSource | Lookup (Synonym) | Allocation source name |
| LEFT JOIN | dbo.SynAllocationGetRequestLog | Lookup (Synonym) | Trade allocation request log |
| LEFT JOIN | Trade.InstrumentMetaData | Lookup | Instrument symbol and display name |
| LEFT JOIN | Trade.CloseExecutionPlan | Lookup | OrderID resolution for positions |
| FROM | DB_Logs.History.CloseExecutionPlan | Direct Read (Cross-DB) | Historical OrderID resolution |
| INNER JOIN | Customer.CustomerStatic | Cross-Schema Read | Resolve CID from ApexAccountID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAleErrorReport (procedure)
├── dbo.SynMoneyTransferAleLog (synonym)
├── dbo.SynMoneyTransferRequestLog (synonym)
├── dbo.SynHedgeApexAleEvent (synonym)
├── dbo.SynHedgeApexAleEventMessage (synonym)
├── dbo.SynHedgeAllocationRequests (synonym)
├── dbo.SynHedgeAllocationRequestsErrors (synonym)
├── dbo.SynHedgeAllocationSource (synonym)
├── dbo.SynAllocationGetRequestLog (synonym)
├── Trade.InstrumentMetaData (table)
├── Trade.CloseExecutionPlan (table)
├── DB_Logs.History.CloseExecutionPlan (cross-db table)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SynMoneyTransferAleLog | Synonym | SELECT - FOF error events |
| dbo.SynHedgeApexAleEvent | Synonym | SELECT - Allocation error events |
| Trade.InstrumentMetaData | Table | LEFT JOIN - instrument symbol |
| Trade.CloseExecutionPlan | Table | LEFT JOIN - OrderID resolution |
| Customer.CustomerStatic | Table | INNER JOIN - CID from ApexID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all ALE errors for today

```sql
EXEC Trade.GetAleErrorReport @date = '2026-03-16';
```

### 8.2 Filter by customer and instrument

```sql
EXEC Trade.GetAleErrorReport
    @cid = 12345678,
    @instrumentID = 1001,
    @pageNumber = 1,
    @itemsPerPage = 50;
```

### 8.3 Filter FOF errors only

```sql
EXEC Trade.GetAleErrorReport
    @AleMessageType = 'FOF',
    @date = '2026-03-16';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAleErrorReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAleErrorReport.sql*
