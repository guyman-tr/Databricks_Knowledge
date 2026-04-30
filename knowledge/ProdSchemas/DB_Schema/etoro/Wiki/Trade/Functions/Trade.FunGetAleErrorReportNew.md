# Trade.FunGetAleErrorReportNew

> Inline TVF that produces an ALE (Allocation / Liquidity Execution) error report by combining FOF (Funds-Out/Funds) transfer errors and hedge allocation errors for a given customer and date, with instrument and order context.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with Date, ExternalID, Status, Message, CID, Symbol, InstrumentID, IsBuy, ApexAccountID, AleType, ID, OrderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunGetAleErrorReportNew aggregates error data from two ALE streams: (1) FOF (Funds-Out/Funds) transfers from SynMoneyTransferAleLog and SynMoneyTransferRequestLog, and (2) hedge allocation events from SynHedgeApexAleEvent and related Syn* tables. It filters by @CID and @date, and returns a unified error report with status, message, instrument context, and OrderID where available. Used for operational troubleshooting, BI reporting, and ALE reconciliation.

This function exists because ALE failures span multiple systems (money transfer, hedge allocation); a single queryable view simplifies error investigation. The FinalData CTE UNIONs FOF and Allocation rows, resolving instrument display names and OrderID from CloseExecutionPlan (both live Trade and History from DB_Logs). BIReader has GRANT SELECT for BI/ETL access.

Data flows: invoked by BI tools, ad-hoc queries, and potentially alerting. Parameters @CID and @date control scope. Returns one row per error event with human-readable Symbol, InstrumentDisplayName, and OrderID when linkable to CloseExecutionPlan.

---

## 2. Business Logic

### 2.1 FOF (Funds-Out) Errors

**What**: Step1Data selects from SynMoneyTransferAleLog where State NOT IN ('Completed','FundsPosted').

**Columns/Parameters Involved**: `FofAle.*`, `trans.*`, `@date`, `@CID`

**Rules**:
- Type='FOF', AleType='FOF'
- ID = TransferResponseID (converted to NVARCHAR(50))
- ExternalID = TransferRequestID
- Status = FofAle.State
- Message = FofAle.Reason
- InstrumentID, IsBuy, OrderID = NULL (FOF has no position context)
- Filter: EventTimestamp in @date range, trans.CID = @CID or @CID NULL

### 2.2 Allocation Errors

**What**: Step2Data selects from SynHedgeApexAleEvent joined to SynHedgeAllocationRequests, SynAllocationGetRequestLog, and message/error tables.

**Columns/Parameters Involved**: `hpe.*`, `tradAlloc.*`, `hpa.*`, `hae.*`, `das.*`

**Rules**:
- Type='Allocation', AleType = CONCAT('Allocation', AllocationSourceName) if present
- ID = PayloadId, ExternalID = PayloadExternalId
- Status = PayloadStatus, Message = hpa.MessageText, ErrorMessage = hae.ErrorMessage
- InstrumentID, IsBuy (IsOpen), PositionID from tradAlloc
- OrderID resolved via CloseExecutionPlan (Trade) or HistoryData (DB_Logs.History.CloseExecutionPlan) on PositionID

### 2.3 HistoryData and OrderID Resolution

**What**: HistoryData CTE pre-fetches PositionID, OrderID from DB_Logs.History.CloseExecutionPlan for @CID and @date. FinalData uses ISNULL(cep.OrderID, cepH.OrderID) to prefer live Trade.CloseExecutionPlan, fallback to History.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID filter. NULL = all customers. |
| 2 | @date | DATE | NO | - | CODE-BACKED | Date filter. Events in [@date, @date+1 day). NULL = no date filter. |
| 3 | Date (return) | datetime | - | - | CODE-BACKED | Event timestamp (FofAle.EventTimestamp or hpe.OccurredAt). |
| 4 | ExternalID (return) | varchar | - | - | CODE-BACKED | External reference (TransferRequestID or PayloadExternalId). |
| 5 | Status (return) | varchar | - | - | CODE-BACKED | Event status (FOF State or PayloadStatus). |
| 6 | Message (return) | varchar | - | - | CODE-BACKED | Human-readable message (FofAle.Reason or hpa.MessageText). |
| 7 | CID (return) | int | YES | - | CODE-BACKED | Customer ID. |
| 8 | Symbol (return) | varchar(100) | YES | - | CODE-BACKED | InstrumentMetaData.Symbol. NULL for FOF. |
| 9 | InstrumentID (return) | int | YES | - | CODE-BACKED | Instrument. NULL for FOF. Implicit FK to Trade.Instrument. |
| 10 | IsBuy (return) | bit | YES | - | CODE-BACKED | IsOpen from allocation (1=open, 0=close). NULL for FOF. |
| 11 | ApexAccountID (return) | varchar | YES | - | CODE-BACKED | Provider account ID (trans.ProviderAccountID or tradAlloc.ProviderAccountID). |
| 12 | AleType (return) | varchar | - | - | CODE-BACKED | 'FOF' or 'Allocation' + optional AllocationSourceName. |
| 13 | ID (return) | varchar | - | - | CODE-BACKED | Internal ID (TransferResponseID or PayloadId). |
| 14 | OrderID (return) | bigint | YES | - | CODE-BACKED | OrderID from CloseExecutionPlan when PositionID links. NULL when not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | SynMoneyTransferAleLog | FROM | FOF errors |
| - | SynMoneyTransferRequestLog | LEFT JOIN | FOF CID/ProviderAccountID |
| - | SynHedgeApexAleEvent | FROM | Allocation events |
| - | SynHedgeApexAleEventMessage | LEFT JOIN | Message text |
| - | SynHedgeAllocationRequests | LEFT JOIN | Allocation request |
| - | SynHedgeAllocationRequestsErrors | LEFT JOIN | Error details |
| - | SynHedgeAllocationSource | LEFT JOIN | Allocation source name |
| - | SynAllocationGetRequestLog | LEFT JOIN | tradAlloc (CID, InstrumentID, PositionID) |
| InstrumentID | Trade.InstrumentMetaData | LEFT JOIN | Symbol, InstrumentDisplayName |
| PositionID | Trade.CloseExecutionPlan | LEFT JOIN | OrderID (live) |
| PositionID | DB_Logs.History.CloseExecutionPlan | LEFT JOIN | OrderID (history) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BIReader | GRANT SELECT | Permission | BI/ETL read access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunGetAleErrorReportNew (function)
├── dbo.SynMoneyTransferAleLog (table)
├── dbo.SynMoneyTransferRequestLog (table)
├── dbo.SynHedgeApexAleEvent (table)
├── dbo.SynHedgeApexAleEventMessage (table)
├── dbo.SynHedgeAllocationRequests (table)
├── dbo.SynHedgeAllocationRequestsErrors (table)
├── dbo.SynHedgeAllocationSource (table)
├── dbo.SynAllocationGetRequestLog (table)
├── Trade.InstrumentMetaData (table)
├── Trade.CloseExecutionPlan (table)
└── DB_Logs.History.CloseExecutionPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| SynMoneyTransferAleLog | Table | FOF errors |
| SynMoneyTransferRequestLog | Table | FOF CID, ProviderAccountID |
| SynHedgeApexAleEvent | Table | Allocation events |
| SynHedgeApexAleEventMessage | Table | Message text |
| SynHedgeAllocationRequests | Table | Allocation request |
| SynHedgeAllocationRequestsErrors | Table | Error message |
| SynHedgeAllocationSource | Table | Allocation source name |
| SynAllocationGetRequestLog | Table | tradAlloc |
| Trade.InstrumentMetaData | Table | Symbol, InstrumentDisplayName |
| Trade.CloseExecutionPlan | Table | OrderID by PositionID |
| DB_Logs.History.CloseExecutionPlan | Table | OrderID by PositionID (history) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BIReader | Database role | GRANT SELECT |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF with 14 columns |
| COLLATE SQL_Latin1_General_CP1_CI_AS | Collation | Ensures compatible UNION between Step1 and Step2 |
| CAST(Symbol AS VARCHAR(100)), CAST(InstrumentDisplayName AS VARCHAR(100)) | Type | Consistent output column types |

---

## 8. Sample Queries

### 8.1 Get ALE errors for a customer on a date

```sql
SELECT  Date, ExternalID, Status, Message, CID, Symbol, InstrumentID, IsBuy,
        ApexAccountID, AleType, ID, OrderID
FROM    Trade.FunGetAleErrorReportNew(9263423, '2026-03-14');
```

### 8.2 Get all ALE errors for a date

```sql
SELECT  Date, CID, AleType, Status, Message, Symbol, InstrumentID, OrderID
FROM    Trade.FunGetAleErrorReportNew(NULL, '2026-03-14')
ORDER BY Date DESC;
```

### 8.3 Filter by AleType

```sql
SELECT  Date, ExternalID, Status, Message, Symbol, InstrumentID
FROM    Trade.FunGetAleErrorReportNew(9263423, '2026-03-14')
WHERE   AleType LIKE 'Allocation%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Code analysis*
*Sources: Atlassian: 0 Confluence + 0 Jira | Syn* tables: 10+ | Corrections: 0 applied*
*Object: Trade.FunGetAleErrorReportNew | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunGetAleErrorReportNew.sql*
