# Hedge.SetNetOpenDollarPersistData

> Bulk-upserts the global net open dollar exposure cache: updates existing instrument rows and inserts new ones from the TVP, enabling the hedge server to persist its dollar-denominated exposure snapshot to Hedge.PositionsNetOpenDollarTbl.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NetOpenDollarToUpdate (TVP with exposure snapshot) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.SetNetOpenDollarPersistData` is the **upsert writer** for `Hedge.PositionsNetOpenDollarTbl` - the global net open exposure cache that stores one row per instrument representing total customer exposure in dollar terms. The hedge server calls this procedure to persist its dollar-denominated exposure snapshot so that monitoring tools (e.g., INSight exposure display) and downstream consumers can read current aggregate risk figures.

This procedure exists because the hedge server computes net open exposure in-memory and must persist it to the database periodically for reporting, recovery, and operational visibility. Dollar-denominated figures (NetOpenDollars, NetOpenNormalize) provide a common currency measure across instruments with different unit types (barrels, shares, lots, etc.), enabling cross-instrument risk comparison.

Data flows through this object as follows: the hedge server computes the current net open exposure per instrument, populates a `Hedge.PositionsNetOpenDollarPersistTable` TVP with one row per instrument, then calls this procedure. For instruments already in the table, all columns are updated including the net direction (IsBuy can flip as customer positions shift). For instruments not yet in the table, a new row is inserted. There is no DELETE path here - zero-unit cleanup is handled separately by `Hedge.DeleteZeroRowNetOpenHedgePersistData`.

---

## 2. Business Logic

### 2.1 Manual UPSERT: UPDATE Then INSERT-WHERE-NOT-EXISTS

**What**: The procedure performs a two-step UPSERT without a MERGE statement - matching on InstrumentID as the natural key.

**Columns/Parameters Involved**: `@NetOpenDollarToUpdate`, `InstrumentID` (join key)

**Rules**:
- Step 1: UPDATE all columns (IsBuy, NetOpenUnits, NetOpenDollars, NetOpenNormalize, LastDataID, LastUpdated) for rows where `PND.InstrumentID = NOD.InstrumentID`. IsBuy is overwritten - the net direction can change between cycles.
- Step 2: INSERT rows from the TVP where the InstrumentID does NOT already exist in the table (NOT EXISTS subquery).
- Both steps use WITH (NOLOCK) on the read side - consistency is achieved through the data model (one row per instrument, keyed on PK), not through locking.
- No explicit transaction wrapping - if Step 2 fails after Step 1 completes, some rows may be updated but not all new rows inserted. The hedge server is expected to retry.

**Diagram**:
```
@NetOpenDollarToUpdate TVP (rows: [{InstrumentID, IsBuy, Units, Dollars, ...}])
  |
  +-> UPDATE PositionsNetOpenDollarTbl  (InstrumentID matches -> update ALL columns)
  |
  +-> INSERT INTO PositionsNetOpenDollarTbl (InstrumentID NOT in table -> new row)
```

### 2.2 IsBuy as Net Direction (Updates on Every Cycle)

**What**: Unlike `Hedge.PositionsHedgeTbl` where IsBuy is part of the PK and separate rows exist for long/short, here IsBuy is the net result - it can flip and is overwritten each cycle.

**Columns/Parameters Involved**: `IsBuy`, `NetOpenUnits`

**Rules**:
- IsBuy=1: aggregate customer book is net long on this instrument at the time of the snapshot.
- IsBuy=0: aggregate customer book is net short.
- When the net direction shifts from long to short (or vice versa), the UPDATE overwrites IsBuy with the new value.
- There is one row per instrument - not one row per direction. The magnitude (NetOpenUnits) always represents the net figure; IsBuy indicates which side is winning.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NetOpenDollarToUpdate | Hedge.PositionsNetOpenDollarPersistTable | NO | - | CODE-BACKED | Read-only TVP carrying the hedge server's current net open dollar exposure snapshot. One row per instrument. Structure mirrors `Hedge.PositionsNetOpenDollarTbl`: contains InstrumentID, IsBuy, NetOpenUnits, NetOpenDollars, NetOpenNormalize, LastDataID, LastUpdated. All columns nullable in the TVP except LastUpdated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NetOpenDollarToUpdate | Hedge.PositionsNetOpenDollarPersistTable | TVP (UDT) | Input TVP type carrying the exposure snapshot |
| (UPDATE target) | Hedge.PositionsNetOpenDollarTbl | MODIFIER | Updates all columns for instruments that already have a row |
| (INSERT target) | Hedge.PositionsNetOpenDollarTbl | WRITER | Inserts new rows for instruments not yet in the table |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Called externally by the hedge server process.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.SetNetOpenDollarPersistData (procedure)
+-- Hedge.PositionsNetOpenDollarTbl (table) [MODIFIER + WRITER]
+-- Hedge.PositionsNetOpenDollarPersistTable (type) [@NetOpenDollarToUpdate parameter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PositionsNetOpenDollarTbl | Table | Target of UPDATE (existing instruments) and INSERT (new instruments) |
| Hedge.PositionsNetOpenDollarPersistTable | User Defined Type | Parameter type for @NetOpenDollarToUpdate - defines the TVP schema |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally by the hedge server.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No explicit transaction | Atomicity gap | Step 1 (UPDATE) and Step 2 (INSERT) are separate statements with no wrapping transaction. If Step 2 fails, rows updated in Step 1 are committed. The hedge server is expected to handle retry. |
| WITH (NOLOCK) on reads | Isolation | Read side of UPDATE JOIN and NOT EXISTS check use NOLOCK for performance; PK uniqueness guarantees prevent phantom row issues |

---

## 8. Sample Queries

### 8.1 Persist a net open dollar exposure snapshot for two instruments
```sql
DECLARE @Exposure [Hedge].[PositionsNetOpenDollarPersistTable];
INSERT INTO @Exposure (InstrumentID, IsBuy, NetOpenUnits, NetOpenDollars, NetOpenNormalize, LastDataID, LastUpdated)
VALUES (1,    1, 15500000.000000, 1255300.000000, 1255.300000, 112233, GETDATE()),
       (5,    0,  2300000.000000,  310500.000000,  310.500000, 112233, GETDATE());

EXEC [Hedge].[SetNetOpenDollarPersistData]
    @NetOpenDollarToUpdate = @Exposure;
```

### 8.2 Read current global net exposure after persist (verify upsert result)
```sql
SELECT  InstrumentID,
        CASE WHEN IsBuy = 1 THEN 'Net Long' ELSE 'Net Short' END AS NetDirection,
        NetOpenUnits,
        NetOpenDollars,
        NetOpenNormalize,
        LastDataID,
        LastUpdated
FROM    [Hedge].[PositionsNetOpenDollarTbl] WITH (NOLOCK)
ORDER BY NetOpenDollars DESC;
```

### 8.3 Identify instruments in the TVP that will trigger INSERT vs UPDATE
```sql
-- Rows in TVP that will be INSERTED (new instruments):
SELECT  tvp.InstrumentID
FROM    [Hedge].[PositionsNetOpenDollarTbl] p WITH (NOLOCK)
RIGHT JOIN (SELECT 1 AS InstrumentID UNION SELECT 5) tvp ON p.InstrumentID = tvp.InstrumentID
WHERE   p.InstrumentID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.SetNetOpenDollarPersistData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.SetNetOpenDollarPersistData.sql*
