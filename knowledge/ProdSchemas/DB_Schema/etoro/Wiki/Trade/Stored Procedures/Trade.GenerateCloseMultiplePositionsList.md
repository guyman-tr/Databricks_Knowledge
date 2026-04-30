# Trade.GenerateCloseMultiplePositionsList

> Validates and records a batch close request for multiple positions, identifying which positions can be closed and which must be excluded.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset of close request records with exclusion status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure processes a "close multiple positions" request where a customer (or admin) submits a list of position IDs to close simultaneously. Unlike the close-by-units procedure which distributes a unit amount across positions, this procedure targets specific positions by ID and evaluates each one individually for eligibility.

The procedure exists to support bulk position closure with detailed per-position feedback. When a user selects multiple positions to close from the UI, the system needs to determine which can actually be closed versus which must be excluded (e.g., copy positions, positions in redeem, positions already pending a close). Rather than silently failing, the procedure records a detailed reason for each exclusion.

Data flows from the caller's position ID list (via TVP) through Trade.Position (view with partition elimination) and Trade.OrdersExit, where each position is evaluated. Results are inserted into History.CloseMultiplePositionsRequests for audit, and the valid positions are returned to the caller for execution. Partition elimination is used on both Trade.Position and Trade.OrdersExit joins for performance (added by Ran Ovadia, 12/01/2021).

---

## 2. Business Logic

### 2.1 Position Exclusion Rules

**What**: Each position is individually evaluated for close eligibility, with excluded positions receiving a human-readable reason.

**Columns/Parameters Involved**: `CID`, `MirrorID`, `RedeemStatus`, `OrderID`, `UnitsToDeduct`, `CloseByUnitsID`

**Rules**:
- Position not found (CID IS NULL after LEFT JOIN) -> "Position not found"
- MirrorID > 0 -> "Excluded - the Position is a copy Position" (CopyTrader positions cannot be closed individually)
- RedeemStatus > 0 -> "Excluded - the Position is in Redeem process" (already being redeemed)
- Full exit order already exists (OrderID not null AND UnitsToDeduct is null) -> "Excluded - Full Exit order already exists"
- Partial close-by-units exit order exists (CloseByUnitsID > 0 AND UnitsToDeduct > 0) -> "CloseByUnits partial exit order will be converted to full" (not excluded, but noted)

**Diagram**:
```
For each PositionID in input:
  Position exists?  NO -> "Position not found" (IsExcluded=1)
  Is copy position? YES -> "Copy Position" (IsExcluded=1)
  In redeem?        YES -> "In Redeem process" (IsExcluded=1)
  Full exit exists? YES -> "Full Exit order already exists" (IsExcluded=1)
  Partial exit?     YES -> Convert to full (IsExcluded=0, noted)
  Otherwise              -> Eligible (IsExcluded=0)
```

### 2.2 Partition Elimination Pattern

**What**: The procedure uses modulo-based partition elimination for efficient lookups against partitioned tables.

**Columns/Parameters Involved**: `PositionID`, `PartitionCol`, `CID`

**Rules**:
- Trade.Position is joined with `tp.PartitionCol = P.PositionID % 50` for partition elimination
- Trade.OrdersExit is joined with `tp.CID % 50 = toe.PartitionCol` for partition elimination
- This avoids full partition scans on large partitioned tables

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionIDs | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing the list of position IDs to close. Uses READONLY TVP pattern. Must not be empty (RAISERROR if empty). |
| 2 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client-provided idempotency/tracking GUID. Auto-generated via NEWID() if not provided. Links all rows in this batch request. |

**Output columns (returned via SELECT from #CloseMultiplePositionsRequests):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | CID | INT | YES | - | CODE-BACKED | Customer ID owning the position. NULL if the position was not found in Trade.Position (invalid PositionID). Only non-NULL rows are returned in the final SELECT. |
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | The position ID being evaluated, from the input TVP. |
| 5 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument of the position. From Trade.Position. |
| 6 | PositionAmountInUnitsDecimal | DECIMAL(16,8) | YES | - | CODE-BACKED | Current unit amount of the position (AmountInUnitsDecimal from Trade.Position). Represents how many units will be closed if this position is eligible. |
| 7 | CreationDate | DATETIME | NO | - | CODE-BACKED | GETUTCDATE() at insertion time. When this close-multiple request was generated. |
| 8 | IsExcluded | BIT | NO | - | CODE-BACKED | 1 = position cannot be closed (see Details for reason). 0 = position is eligible for closure. |
| 9 | ExitOrderID | BIGINT | YES | - | CODE-BACKED | If a pending exit order exists in Trade.OrdersExit, its OrderID. NULL if no pending exit order. Used to detect positions already being closed. |
| 10 | CloseByUnitsID | BIGINT | YES | - | CODE-BACKED | If a pending close-by-units partial exit exists, its batch ID. When present with UnitsToDeduct > 0, the partial close is converted to a full close. |
| 11 | MirrorID | BIGINT | YES | - | CODE-BACKED | The CopyTrader mirror ID. MirrorID > 0 indicates this is a copy position and will be excluded from manual close. |
| 12 | ExitOrderUnitsToDeduct | DECIMAL(16,8) | YES | - | CODE-BACKED | UnitsToDeduct from Trade.OrdersExit. If not null, indicates a pending partial close. If null with an ExitOrderID, indicates a pending full close. |
| 13 | ClientRequestGuid | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Request tracking GUID (provided or auto-generated). Same for all rows in this batch. |
| 14 | Details | VARCHAR(256) | YES | - | CODE-BACKED | Human-readable exclusion reason. NULL for eligible positions. Contains detailed text like "Excluded - the Position is a copy Position" for excluded rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionIDs | Trade.IdIntList | UDT | Table-valued parameter type containing position IDs |
| LEFT JOIN | Trade.Position | Direct Read (View) | Reads position details with partition elimination |
| LEFT JOIN | Trade.OrdersExit | Direct Read | Checks for existing exit orders (pending closes) |
| INSERT INTO | History.CloseMultiplePositionsRequests | Write | Records the close request for audit trail |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not discovered | - | - | No callers found in SQL repo. Likely called by application service directly. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GenerateCloseMultiplePositionsList (procedure)
├── Trade.Position (view)
├── Trade.OrdersExit (table)
├── History.CloseMultiplePositionsRequests (table)
└── Trade.IdIntList (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | LEFT JOIN to get position details with partition elimination |
| Trade.OrdersExit | Table | LEFT JOIN to detect existing exit orders |
| History.CloseMultiplePositionsRequests | Table | INSERT INTO for audit trail |
| Trade.IdIntList | User Defined Type | TVP input parameter type |

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
| Validation 1 | RAISERROR | @PositionIDs TVP must not be empty |

---

## 8. Sample Queries

### 8.1 Close multiple positions (requires TVP declaration)

```sql
DECLARE @Positions Trade.IdIntList;
INSERT INTO @Positions (Id) VALUES (100001), (100002), (100003);

EXEC Trade.GenerateCloseMultiplePositionsList
    @PositionIDs = @Positions,
    @ClientRequestGuid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Check close-multiple request history

```sql
SELECT  cmpr.PositionID,
        cmpr.IsExcluded,
        cmpr.Details,
        cmpr.CreationDate
FROM    History.CloseMultiplePositionsRequests cmpr WITH (NOLOCK)
WHERE   cmpr.ClientRequestGuid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
ORDER BY cmpr.PositionID;
```

### 8.3 Find positions excluded from close-multiple requests

```sql
SELECT  cmpr.PositionID,
        cmpr.CID,
        cmpr.Details,
        cmpr.CreationDate
FROM    History.CloseMultiplePositionsRequests cmpr WITH (NOLOCK)
WHERE   cmpr.IsExcluded = 1
    AND cmpr.CreationDate >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY cmpr.CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GenerateCloseMultiplePositionsList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GenerateCloseMultiplePositionsList.sql*
