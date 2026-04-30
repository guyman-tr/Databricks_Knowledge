# History.CloseByUnitsRequests

> Audit log for "close by units" position close requests - records each position selected for closure when a customer requests to close a specific number of units of an instrument.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CloseByUnitsID, PositionID) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 4 active (PK clustered + 3 nonclustered) |

---

## 1. Business Meaning

History.CloseByUnitsRequests captures each "close by units" request executed for a customer. When a customer requests to close a specific quantity of units of an instrument (rather than closing specific positions), Trade.GenerateCloseByUnitsPositionsList determines which positions to close (or partially close) to satisfy the requested unit quantity.

Each request (identified by CloseByUnitsID) can generate multiple rows - one per position that is fully or partially closed to satisfy the total units requested. The sequence of positions is ordered by InitDateTime (oldest first), filling each position's units before moving to the next.

Empty in the current environment (0 rows). Table is on [MAIN] filegroup.

---

## 2. Business Logic

### 2.1 Position Selection Algorithm

**What**: Determines which positions to close (and by how many units) to satisfy a "close N units of instrument X" request.

**Columns/Parameters Involved**: `CloseByUnitsID`, `PositionID`, `IsFullUnitsClose`, `UnitsToClose`, `TotalUnitsToClose`

**Rules**:
- Positions are ordered by InitDateTime ASC (oldest first) using a running AggSum CTE
- Positions are included until AggSum >= TotalUnitsToClose
- For each included position:
  - IsFullUnitsClose=1 if AggSum (including this position) <= TotalUnitsToClose -> close the full position
  - IsFullUnitsClose=0 if this is the last position -> close only the remaining units needed
  - UnitsToClose = AmountInUnitsDecimal (full close) or (TotalUnitsToClose - (AggSum - AmountInUnitsDecimal)) (partial close)
- Only manual positions included (MirrorID=0, ParentPositionID=0, RedeemStatus=0, no pending full close)
- Validates: total available units >= requested units, all positions are same direction (no mixed buy/sell)
- CloseByUnitsID = NEXT VALUE FOR Trade.SeqCloseByUnitsRequests (sequence-based unique ID)
- ClientRequestGuid = idempotency key from client (auto-generated if not provided)

---

## 3. Data Overview

Table is empty in the current environment (0 rows). Written by Trade.GenerateCloseByUnitsPositionsList when the "close by units" trading feature is used.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CloseByUnitsID | bigint | NO | - | VERIFIED | Unique identifier for the close-by-units request batch. From Trade.SeqCloseByUnitsRequests sequence. One ID per API call, multiple rows per ID (one per position). PK component. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID who submitted the close-by-units request. |
| 3 | InstrumentID | int | NO | - | VERIFIED | The instrument being closed. All positions in one request are for the same instrument. Implicit FK to History.Instrument. |
| 4 | PositionID | bigint | NO | - | VERIFIED | One of the positions selected for closure to satisfy the units request. PK component. FK to Trade.PositionTbl. |
| 5 | IsFullUnitsClose | bit | NO | - | VERIFIED | Whether this position is to be fully closed (1) or only partially closed (0). Only the last position in the sequence may be partially closed. |
| 6 | UnitsToClose | decimal(16,8) | YES | - | VERIFIED | Exact number of units to close on this position. For full close = AmountInUnitsDecimal. For partial close = remaining units needed after prior positions. |
| 7 | TotalUnitsToClose | decimal(16,8) | YES | - | VERIFIED | Total units the customer requested to close across all positions in this request. Same value for all rows with the same CloseByUnitsID. |
| 8 | CreationDate | datetime | NO | - | VERIFIED | UTC timestamp when this close request was generated. Set to GETUTCDATE() by Trade.GenerateCloseByUnitsPositionsList. |
| 9 | ClientRequestGuid | uniqueidentifier | YES | - | VERIFIED | Client-supplied idempotency key. Auto-generated (NEWID()) if not provided. Allows the API caller to detect duplicate submissions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | The customer who submitted the close request. |
| PositionID | Trade.PositionTbl | Implicit | The position being closed or partially closed. |
| InstrumentID | History.Instrument | Implicit | The instrument being traded. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GenerateCloseByUnitsPositionsList | CloseByUnitsID, PositionID | Writer | Sole writer - generates the position close list and returns it via OUTPUT INSERTED. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CloseByUnitsRequests (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GenerateCloseByUnitsPositionsList | Stored Procedure | Writer - generates and returns close request list |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CloseByUnitsRequests | CLUSTERED PK | CloseByUnitsID ASC, PositionID ASC | - | - | Active |
| IX_HistoryCloseByUnitsRequests_CID | NONCLUSTERED | CID ASC | - | - | Active |
| IX_HistoryCloseUnitsRequests_ClientRequestGuid | NONCLUSTERED | ClientRequestGuid ASC | - | - | Active |
| IX_HistoryCloseUnitsRequests_PositionID | NONCLUSTERED | PositionID ASC | - | - | Active |

All indexes: FILLFACTOR=95, on [MAIN] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CloseByUnitsRequests | PRIMARY KEY CLUSTERED | (CloseByUnitsID, PositionID), FILLFACTOR=95 |

---

## 8. Sample Queries

### 8.1 Get all positions for a specific close-by-units request
```sql
SELECT CloseByUnitsID, PositionID, InstrumentID, IsFullUnitsClose,
       UnitsToClose, TotalUnitsToClose, CreationDate
FROM History.CloseByUnitsRequests WITH (NOLOCK)
WHERE CloseByUnitsID = 12345
ORDER BY PositionID;
```

### 8.2 Get recent close-by-units activity for a customer
```sql
SELECT CloseByUnitsID, PositionID, InstrumentID, IsFullUnitsClose,
       UnitsToClose, TotalUnitsToClose, CreationDate, ClientRequestGuid
FROM History.CloseByUnitsRequests WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CloseByUnitsRequests | Type: Table | Source: etoro/etoro/History/Tables/History.CloseByUnitsRequests.sql*
