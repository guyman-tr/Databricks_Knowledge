# Trade.PositionsAndNewSL

> A table-valued parameter type for bulk stop-loss updates: pairs each position ID with its new stop-loss rate, used when manually modifying SL for crypto positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | Clustered PK on PositionID |

---

## 1. Business Meaning

Trade.PositionsAndNewSL is a table-valued parameter (TVP) type that pairs PositionID with a new stop-loss (SL) Rate. It models the set of positions whose stop-loss must be updated to a new value, typically in a manual bulk adjustment scenario for crypto positions.

This type exists to support manual SL modification workflows where back-office or admin users apply new stop-loss levels to multiple positions in one call. The clustered primary key on PositionID ensures uniqueness and efficient lookups when the procedure processes the batch.

The application populates this type from user input or admin tools, passes it to Trade.ManualModifySLForCriptoPositions, which updates each position's stop-loss to the supplied rate. Uses [dbo].[dtPrice] for the rate column.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Each row is an independent position-to-rate mapping; the procedure applies the update per row.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position identifier. Links to Trade.PositionTbl. Each row specifies one position to update. Clustered PK. |
| 2 | Rate | dbo.dtPrice | NO | - | CODE-BACKED | New stop-loss rate to apply. Uses custom scalar type dtPrice for decimal pricing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID references Trade.PositionTbl; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManualModifySLForCriptoPositions | @tbl | Parameter (TVP) | Bulk updates stop-loss for crypto positions to the provided rates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies. Uses [dbo].[dtPrice] scalar type for Rate.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManualModifySLForCriptoPositions | Stored Procedure | READONLY parameter for bulk SL modification |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns |
|-----------|------|-------------|
| PK (implicit) | CLUSTERED | PositionID ASC |

### 7.2 Constraints

None beyond the primary key (IGNORE_DUP_KEY = OFF).

---

## 8. Sample Queries

### 8.1 Declare and populate for bulk SL update

```sql
DECLARE @tbl Trade.PositionsAndNewSL;
INSERT INTO @tbl (PositionID, Rate)
VALUES (900000001, 45000.50), (900000002, 45100.00);

EXEC Trade.ManualModifySLForCriptoPositions @tbl = @tbl;
```

### 8.2 Single position SL update

```sql
DECLARE @One Trade.PositionsAndNewSL;
INSERT INTO @One (PositionID, Rate) VALUES (900000001, 12345.67);
EXEC Trade.ManualModifySLForCriptoPositions @tbl = @One;
```

### 8.3 Build from positions meeting criteria

```sql
DECLARE @Updates Trade.PositionsAndNewSL;
INSERT INTO @Updates (PositionID, Rate)
SELECT  PositionID, StopRate * 0.95
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   InstrumentID IN (SELECT InstrumentID FROM Trade.Instrument WHERE SymbolFull LIKE 'BTC%')
        AND IsOpen = 1 AND StopRate IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsAndNewSL | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionsAndNewSL.sql*
