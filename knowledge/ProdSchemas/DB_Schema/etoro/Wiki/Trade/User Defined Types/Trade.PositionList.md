# Trade.PositionList

> A memory-optimized table-valued parameter type for passing position ID and instrument ID pairs to close-position workflows, enabling efficient mirror close processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint), InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | 1: PK NONCLUSTERED HASH on PositionID (BUCKET_COUNT=1024) |

---

## 1. Business Meaning

Trade.PositionList is a memory-optimized table-valued parameter (TVP) type that carries PositionID-InstrumentID pairs. It models the set of positions selected for a close operation, typically when closing copy-trade mirror positions. Each row identifies one position and its instrument for downstream processing.

This type exists to support mirror close flows where the system must process a batch of positions by PositionID while retaining InstrumentID for lookups (e.g., pricing, exposure checks). The hash index on PositionID provides fast point lookups during JOINs. Memory-optimized storage reduces contention and improves throughput in high-volume close scenarios.

The application or mirror-close engine builds a PositionList from the positions to close, passes it to Trade.GetPositionsForCloseMirror or Trade.GetPositionsForCloseMirrorMot, which JOIN against it to gather context and execute the close plan.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type pairs two identifiers; the business meaning is in the consuming procedure logic.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position identifier from Trade.PositionTbl. Primary key of the type (hash index). Each row represents one position in the close batch. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier for the position. Enables instrument-level lookups (pricing, exposures) without a second query. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID semantically references Trade.PositionTbl.PositionID and InstrumentID references Trade.Instrument.InstrumentID; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForCloseMirror | @PositionList | Parameter (TVP) | Populates and passes position-instrument pairs for mirror close |
| Trade.GetPositionsForCloseMirrorMot | @PositionList | Parameter (TVP) | Memory-optimized version of mirror close context retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForCloseMirror | Stored Procedure | READONLY parameter for mirror close |
| Trade.GetPositionsForCloseMirrorMot | Stored Procedure | READONLY parameter for mirror close (MOT) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Bucket Count |
|-----------|------|-------------|--------------|
| PK (implicit) | NONCLUSTERED HASH | PositionID ASC | 1024 |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Declare and populate PositionList for mirror close

```sql
DECLARE @PositionList Trade.PositionList;
INSERT INTO @PositionList (PositionID, InstrumentID)
SELECT  PositionID, InstrumentID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   MirrorID = 1234 AND IsOpen = 1;

EXEC Trade.GetPositionsForCloseMirrorMot @PositionList = @PositionList;
```

### 8.2 Single position for close

```sql
DECLARE @List Trade.PositionList;
INSERT INTO @List (PositionID, InstrumentID) VALUES (900000001, 42);
EXEC Trade.GetPositionsForCloseMirror @PositionList = @List;
```

### 8.3 Build from closed mirror positions

```sql
DECLARE @Positions Trade.PositionList;
INSERT INTO @Positions (PositionID, InstrumentID)
SELECT  hp.PositionID, hp.InstrumentID
FROM    History.Position hp WITH (NOLOCK)
WHERE   hp.MirrorID = 5678 AND hp.CloseOccurred >= '2026-01-01';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionList | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionList.sql*
