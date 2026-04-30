# Trade.GetAllocationDataResiduals

> Retrieves residual allocation request data from the hedge provider with instrument details, filtered to residual allocation sources only.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns residual hedge allocation requests with optional filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves residual (leftover) allocation requests from the hedge/clearing process. Residual allocations are secondary allocation attempts that occur when the primary allocation was partially filled or when position reconciliation discovers discrepancies. These are specifically allocation source types 1 and 2, representing automated residual reconciliation processes.

The procedure exists to give operations visibility into residual allocation activity. Unlike `Trade.GetAllocationData` which shows all allocations, this focuses on the residual/reconciliation subset, which is critical for monitoring settlement completeness.

Data flows from `dbo.SynHedgeAllocationRequests` (hedge allocation requests) joined to `Trade.InstrumentMetaData` (instrument display) and `dbo.SynHedgeAllocationSource` (allocation source names), filtered to `AllocationSource IN (1, 2)`.

---

## 2. Business Logic

### 2.1 Residual Source Filter

**What**: Only returns allocations from residual/reconciliation sources.

**Columns/Parameters Involved**: `AllocationSource`

**Rules**:
- `WHERE har.AllocationSource IN (1, 2)` - limits to residual allocation sources
- Source 1 and 2 are the automated reconciliation processes (resolved from SynHedgeAllocationSource)

### 2.2 Date Range Conversion

**What**: Converts the date parameter to a full-day range for accurate filtering.

**Columns/Parameters Involved**: `@date`, `@startDate`, `@endDate`

**Rules**:
- `@startDate = CAST(@date AS VARCHAR) + ' 00:00:00'` - start of day
- `@endDate = DATEADD(DAY, 1, @startDate)` - start of next day
- Uses BETWEEN for the time range filter on RequestSendTime
- When @date IS NULL, no date filter is applied

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @date | DATE | YES | NULL | CODE-BACKED | Optional date filter. When provided, filters to allocations sent on this date. Converted to a start/end range internally. |
| 2 | @symbol | VARCHAR(30) | YES | NULL | CODE-BACKED | Optional instrument symbol filter (case-insensitive via LOWER comparison). |
| 3 | @instrumentID | INT | YES | NULL | CODE-BACKED | Optional instrument ID filter. |
| 4 | @ExternalID | VARCHAR(30) | YES | NULL | CODE-BACKED | Optional external allocation request ID filter. Originally was @cid parameter, changed per comment by Ran Ovadia (2023-04-20). |
| 5 | AllocationRequestID | VARCHAR | - | - | CODE-BACKED | Unique allocation request identifier from the hedge system. |
| 6 | EToroExternalID | VARCHAR | - | - | CODE-BACKED | eToro's external reference ID for the allocation. |
| 7 | Account | VARCHAR | - | - | CODE-BACKED | Clearing account identifier. |
| 8 | InstrumentID | INT | - | - | CODE-BACKED | Instrument being allocated. FK to Trade.Instrument. |
| 9 | Symbol | NVARCHAR | - | - | CODE-BACKED | Instrument ticker symbol from InstrumentMetaData. |
| 10 | InstrumentDisplayName | NVARCHAR | - | - | CODE-BACKED | Human-readable instrument name. |
| 11 | Units | DECIMAL | - | - | CODE-BACKED | Number of shares/units in the allocation request. |
| 12 | Price | DECIMAL | - | - | CODE-BACKED | Allocation execution price. |
| 13 | IsBuy | BIT | - | - | CODE-BACKED | Direction: 1 = buy allocation, 0 = sell allocation. |
| 14 | RequestSendTime | DATETIME | - | - | CODE-BACKED | When the allocation request was sent to the clearing provider. Used for date filtering. |
| 15 | AllocationSource | VARCHAR | - | - | CODE-BACKED | Resolved name of the allocation source (from SynHedgeAllocationSource). Only sources 1 and 2 (residual types) are included. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.SynHedgeAllocationRequests | SELECT FROM | Hedge allocation requests |
| (body) | Trade.InstrumentMetaData | INNER JOIN | Instrument display data |
| (body) | dbo.SynHedgeAllocationSource | INNER JOIN | Allocation source type names |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllocationDataResiduals (procedure)
+-- dbo.SynHedgeAllocationRequests (synonym)
+-- Trade.InstrumentMetaData (table)
+-- dbo.SynHedgeAllocationSource (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SynHedgeAllocationRequests | Synonym | SELECT FROM - allocation request data |
| Trade.InstrumentMetaData | Table | INNER JOIN - instrument display info |
| dbo.SynHedgeAllocationSource | Synonym | INNER JOIN - allocation source names |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get residual allocations for today
```sql
EXEC Trade.GetAllocationDataResiduals @date = '2026-03-16';
```

### 8.2 Get residual allocations for a specific instrument
```sql
EXEC Trade.GetAllocationDataResiduals @symbol = 'AAPL';
```

### 8.3 Get all residual allocations (no filter)
```sql
EXEC Trade.GetAllocationDataResiduals;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllocationDataResiduals | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllocationDataResiduals.sql*
