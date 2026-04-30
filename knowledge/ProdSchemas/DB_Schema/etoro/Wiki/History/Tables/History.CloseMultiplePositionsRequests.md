# History.CloseMultiplePositionsRequests

> Audit log for "close multiple positions" requests - records each position evaluated (included or excluded) when a customer submits a batch position close request.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | RequestID - IDENTITY PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CloseMultiplePositionsRequests is the audit log for batch position close operations. When a customer submits a list of PositionIDs to close simultaneously, Trade.GenerateCloseMultiplePositionsList evaluates each position and records the outcome here - including positions that were excluded (e.g., copy positions, positions already in close process) with an explanation in Details.

Unlike History.CloseByUnitsRequests (which closes by quantity), this table captures closes by explicit position selection.

19,020 rows. Active table - rows written via Trade.GenerateCloseMultiplePositionsList.

Key design feature: IsExcluded flag + Details column captures both the included positions (IsExcluded=0) and the excluded ones (IsExcluded=1, Details explains why). This provides a complete audit trail for the entire close request, not just what was processed.

---

## 2. Business Logic

### 2.1 Position Inclusion/Exclusion Rules

**What**: Each position in the batch request is evaluated and recorded with an inclusion/exclusion decision.

**Columns/Parameters Involved**: `PositionID`, `IsExcluded`, `Details`, `ExitOrderID`, `CloseByUnitsID`, `MirrorID`

**Exclusion rules**:
| Condition | IsExcluded | Details |
|-----------|-----------|---------|
| Position not found | 1 | "Position not found" |
| MirrorID > 0 | 1 | "Excluded - the Position is a copy Position" |
| RedeemStatus > 0 | 1 | "Excluded - the Position is in Redeem process" |
| Full exit order already exists (toe.OrderID IS NOT NULL AND toe.UnitsToDeduct IS NULL) | 1 | "Excluded - Full Exit order already exists" |
| Partial close-by-units order exists | 0 | "CloseByUnits partial exit order will be converted to full" |
| Normal manual position | 0 | NULL |

### 2.2 ClientRequestGuid Idempotency

ClientRequestGuid is auto-generated (NEWID()) if not provided by caller, enabling deduplication of repeated submissions.

---

## 3. Data Overview

19,020 rows total. Active table.

| Column | Sample Values |
|--------|--------------|
| IsExcluded | 0 (included) or 1 (excluded) |
| Details | NULL (normal) or exclusion reason string |
| ExitOrderID | Linked exit order if one was created |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | VERIFIED | Customer ID. NULL if the position was not found (maps to IsExcluded=1, Details="Position not found"). |
| 2 | PositionID | bigint | NO | - | VERIFIED | The position being evaluated for close. |
| 3 | InstrumentID | int | YES | - | VERIFIED | Instrument of the position. NULL if position not found. |
| 4 | PositionAmountInUnitsDecimal | decimal(16,8) | YES | - | VERIFIED | The full position size in units at time of request. From Trade.Position.AmountInUnitsDecimal. |
| 5 | CreationDate | datetime | NO | - | VERIFIED | UTC timestamp when this record was created. Set to GETUTCDATE() by Trade.GenerateCloseMultiplePositionsList. |
| 6 | IsExcluded | tinyint | NO | - | VERIFIED | Whether this position was excluded from the close operation: 0=included for close, 1=excluded. See exclusion rules in business logic. |
| 7 | ExitOrderID | bigint | YES | - | VERIFIED | The exit order ID created/referenced for this position close. NULL if position was excluded or no exit order exists. From Trade.OrdersExit.OrderID. |
| 8 | CloseByUnitsID | bigint | YES | - | VERIFIED | If this position had a partial close-by-units exit order, the CloseByUnitsID of that order. Links to History.CloseByUnitsRequests. NULL otherwise. |
| 9 | MirrorID | bigint | YES | - | VERIFIED | MirrorID from the position, if this is a copy trade. Non-zero values cause IsExcluded=1. |
| 10 | ExitOrderUnitsToDeduct | decimal(16,8) | YES | - | VERIFIED | Units to deduct on the exit order. From Trade.OrdersExit.UnitsToDeduct. NULL for full closes. |
| 11 | ClientRequestGuid | uniqueidentifier | YES | - | VERIFIED | Client-supplied idempotency key. Auto-generated (NEWID()) if not provided. Same for all rows in the same batch request. |
| 12 | Details | varchar(256) | YES | - | VERIFIED | Human-readable exclusion reason, or NULL for included positions. Set by CASE logic in Trade.GenerateCloseMultiplePositionsList. |
| 13 | RequestID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | VERIFIED | Surrogate PK. Auto-incremented row identifier. No business meaning. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | The customer who submitted the request. |
| PositionID | Trade.PositionTbl | Implicit | The position being evaluated for close. |
| CloseByUnitsID | History.CloseByUnitsRequests | Implicit | Links to the CloseByUnits request if a partial close order existed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GenerateCloseMultiplePositionsList | PositionID, IsExcluded | Writer | Sole writer - evaluates batch and records each position outcome. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CloseMultiplePositionsRequests (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GenerateCloseMultiplePositionsList | Stored Procedure | Writer - records position close outcomes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CloseMultiplePositionsRequests | CLUSTERED PK | RequestID ASC | - | - | Active |

All indexes: FILLFACTOR=95, on [MAIN] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CloseMultiplePositionsRequests | PRIMARY KEY CLUSTERED | RequestID, FILLFACTOR=95 |

---

## 8. Sample Queries

### 8.1 Get all positions in a multi-close request
```sql
SELECT PositionID, CID, InstrumentID, IsExcluded, Details,
       ExitOrderID, PositionAmountInUnitsDecimal, CreationDate
FROM History.CloseMultiplePositionsRequests WITH (NOLOCK)
WHERE ClientRequestGuid = '00000000-0000-0000-0000-000000000000'
ORDER BY RequestID;
```

### 8.2 Get recent close requests for a customer
```sql
SELECT TOP 100 RequestID, PositionID, InstrumentID, IsExcluded,
               Details, CreationDate, ClientRequestGuid
FROM History.CloseMultiplePositionsRequests WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CloseMultiplePositionsRequests | Type: Table | Source: etoro/etoro/History/Tables/History.CloseMultiplePositionsRequests.sql*
