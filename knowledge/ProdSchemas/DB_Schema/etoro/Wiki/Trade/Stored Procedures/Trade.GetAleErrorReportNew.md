# Trade.GetAleErrorReportNew

> Optimized ALE error report that pushes CID and date filters down to the source queries for better performance.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns combined FOF and Allocation error events with pushed-down filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is an optimized version of Trade.GetAleErrorReport. It reports the same ALE (Apex Logistics Engine) errors - FOF money transfer failures and stock allocation failures - but pushes the CID and date filters down into each source query (materialized via temp tables #step1, #Step2) rather than applying them as post-filters on the UNION. This yields significantly better query performance for filtered queries.

The procedure exists as a performance improvement over the original GetAleErrorReport. It adds a validation that at least one of @CID or @date must be provided (RAISERROR if both NULL), preventing expensive full-table scans.

Data flows through the same synonym tables as GetAleErrorReport (SynMoneyTransferAleLog, SynHedgeApexAleEvent, etc.) but materializes FOF and Allocation results into separate temp tables (#step1, #Step2), applies CID/date filters during materialization, then UNIONs and applies remaining filters in the final SELECT.

---

## 2. Business Logic

### 2.1 Mandatory Filter Validation

**What**: At least one of @CID or @date must be provided.

**Columns/Parameters Involved**: `@CID`, `@date`

**Rules**:
- If both @CID and @date are NULL, RAISERROR is raised
- This prevents accidentally scanning the full error log, which could be very expensive

### 2.2 Pushed-Down Filter Optimization

**What**: CID and date filters are applied at the source query level, not post-UNION.

**Columns/Parameters Involved**: `@CID`, `@date`

**Rules**:
- FOF query: filters FofAle.EventTimestamp by @date and trans.CID by @CID during #step1 materialization
- Allocation query: filters hpe.OccurredAt by @date and tradAlloc.CID by @CID during #Step2 materialization
- History.CloseExecutionPlan temp table also filters by @CID and @date
- Remaining filters (symbol, instrumentID, isBuy, etc.) are applied on the final SELECT from #Final

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Filter by customer ID. At least one of @CID or @date must be provided. |
| 2 | @date | DATE | YES | NULL | CODE-BACKED | Filter by event date. At least one of @CID or @date must be provided. |
| 3 | @symbol | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by instrument symbol (case-insensitive). |
| 4 | @instrumentID | INT | YES | NULL | CODE-BACKED | Filter by instrument ID. |
| 5 | @isBuy | INT | YES | NULL | CODE-BACKED | Filter by direction: 1=Buy, 0=Sell. |
| 6 | @ExternalID | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by external (Apex) request ID. |
| 7 | @apexAccountID | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by Apex clearing account ID. |
| 8 | @AleMessageType | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by ALE message type: 'FOF' or 'Allocation'. |

**Output columns:** Same as Trade.GetAleErrorReport (Date, ExternalID, Status, Message, CID, Symbol, InstrumentID, IsBuy, ApexAccountID, AleType, ID, OrderID) minus ErrorMessage. See [Trade.GetAleErrorReport](Trade.GetAleErrorReport.md) Section 4 for column descriptions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.SynMoneyTransferAleLog | Direct Read (Synonym) | FOF error events |
| FROM | dbo.SynHedgeApexAleEvent | Direct Read (Synonym) | Allocation error events |
| LEFT JOIN | Trade.InstrumentMetaData | Lookup | Instrument metadata |
| LEFT JOIN | Trade.CloseExecutionPlan | Lookup | OrderID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAleErrorReportNew (procedure)
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
└── DB_Logs.History.CloseExecutionPlan (cross-db table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Same as Trade.GetAleErrorReport | - | See [Trade.GetAleErrorReport](Trade.GetAleErrorReport.md) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Validation | RAISERROR | Both @CID and @date cannot be NULL simultaneously |

---

## 8. Sample Queries

### 8.1 Get ALE errors for a specific date

```sql
EXEC Trade.GetAleErrorReportNew @date = '2026-03-16';
```

### 8.2 Get ALE errors for a specific customer

```sql
EXEC Trade.GetAleErrorReportNew @CID = 12345678;
```

### 8.3 Get allocation errors for a customer on a date

```sql
EXEC Trade.GetAleErrorReportNew
    @CID = 12345678,
    @date = '2026-03-16',
    @AleMessageType = 'Allocation';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAleErrorReportNew | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAleErrorReportNew.sql*
