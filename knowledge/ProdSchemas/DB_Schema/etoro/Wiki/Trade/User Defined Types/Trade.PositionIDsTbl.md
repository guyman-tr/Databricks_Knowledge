# Trade.PositionIDsTbl

> A table-valued parameter type for passing batches of position IDs to stored procedures, enabling bulk position-level operations such as detachment, adjustment, and filtering.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.PositionIDsTbl is a table-valued parameter (TVP) type for passing sets of position IDs into stored procedures. PositionID is the primary key of Trade.PositionTbl - the central table tracking every open and closed trading position on the eToro platform. This type enables bulk position operations without row-by-row processing.

This type supports operations that act on groups of positions simultaneously: detaching copied positions from mirrors, performing position adjustments, retrieving filtered position data for APIs, and building context data for close orders. Without it, each position operation would require a separate procedure call.

Application services, copy-trade engines, and internal tools collect sets of position IDs, populate a PositionIDsTbl, and pass it to the relevant procedure. The procedure JOINs against the TVP to scope its operation to exactly the specified positions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type specialized for the PositionID domain.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | VERIFIED | Position ID - the primary identifier for trading positions in Trade.PositionTbl. Each PositionID uniquely identifies a single open or closed position (buy/sell of a financial instrument). Used for bulk position filtering in data APIs, mirror detachment, position adjustment, and close-order context retrieval. No primary key constraint on the type, so duplicates are technically possible but handled by consuming procedure logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID semantically references Trade.PositionTbl.PositionID but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DetachPositionsFromMirror | @PositionIDs | Parameter (TVP) | Detaches specified positions from their copy-trade mirror |
| Trade.GetDataForPositionAdjustment | @PositionIDs | Parameter (TVP) | Retrieves position data needed for adjustment operations |
| Trade.PositionAdjustment | @PositionIDs | Parameter (TVP) | Performs adjustments on specified positions |
| Trade.GetPositionsChangesForDataApi | @PositionIDs | Parameter (TVP) | Filters position changes for data API export |
| Trade.GetPositionsForDataApi | @PositionIDs | Parameter (TVP) | Filters positions for data API export |
| Trade.GetPositionsByFilters | @PositionIDs | Parameter (TVP) | Retrieves positions matching specified filters and IDs |
| Trade.GetOrderForCloseContextData | @PositionIDs | Parameter (TVP) | Builds context data for close orders on specified positions |
| Trade.GetOrderForCloseContextData_EladTest | @PositionIDs | Parameter (TVP) | Test version of close order context data retrieval |
| Trade.GetOpenPositionsData | @PositionIDs | Parameter (TVP) | Retrieves open position data for specified IDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DetachPositionsFromMirror | Stored Procedure | READONLY parameter for mirror detachment |
| Trade.GetDataForPositionAdjustment | Stored Procedure | READONLY parameter for adjustment data |
| Trade.PositionAdjustment | Stored Procedure | READONLY parameter for position adjustment |
| Trade.GetPositionsChangesForDataApi | Stored Procedure | READONLY parameter for data API |
| Trade.GetPositionsForDataApi | Stored Procedure | READONLY parameter for data API |
| Trade.GetPositionsByFilters | Stored Procedure | READONLY parameter for filtered position retrieval |
| Trade.GetOrderForCloseContextData | Stored Procedure | READONLY parameter for close context |
| Trade.GetOpenPositionsData | Stored Procedure | READONLY parameter for open position data |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate a PositionIDsTbl for mirror detachment

```sql
DECLARE @PosIDs Trade.PositionIDsTbl;
INSERT INTO @PosIDs (PositionID) VALUES (900000001), (900000002), (900000003);
EXEC Trade.DetachPositionsFromMirror @PositionIDs = @PosIDs;
```

### 8.2 Use PositionIDsTbl to retrieve open position data

```sql
DECLARE @PositionIDs Trade.PositionIDsTbl;
INSERT INTO @PositionIDs (PositionID)
SELECT  PositionID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   CID = 12345 AND IsBuy = 1 AND OpenDateTime > '2026-01-01';

EXEC Trade.GetOpenPositionsData @PositionIDs = @PositionIDs;
```

### 8.3 Use PositionIDsTbl to get close order context data

```sql
DECLARE @Positions Trade.PositionIDsTbl;
INSERT INTO @Positions (PositionID)
SELECT  PositionID
FROM    Trade.OrderForClose WITH (NOLOCK)
WHERE   Status = 1;

EXEC Trade.GetOrderForCloseContextData @PositionIDs = @Positions;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionIDsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionIDsTbl.sql*
