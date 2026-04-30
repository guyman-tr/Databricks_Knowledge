# Trade.DetachPositionsByCountryAndInstrument

> Batch-detaches all mirrored (copy-trade) positions for a given instrument in specified countries, converting eligible positions to real stock ownership.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID, @CountryIDList |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a **regulatory/compliance batch detachment tool**. When a financial instrument becomes restricted for certain countries (e.g., due to regulatory changes, ESMA restrictions, or license limitations), this procedure finds all copy-trade (mirrored) positions held by customers in those countries for that instrument and detaches each one individually. The detachment converts eligible positions to real stock ownership (@SetPositionsAsReal=1), ensuring copiers retain their holdings independently rather than having positions force-closed.

The procedure acts as an orchestrator: it identifies affected positions by joining Trade.Position with Customer.CustomerStatic on CountryID, then iterates through each position calling `Trade.DetachPositionsFromMirror` with error isolation per position (TRY/CATCH with silent error swallowing to ensure one failure doesn't block others).

---

## 2. Business Logic

### 2.1 Affected Position Discovery

**What**: Finds all mirrored positions for the instrument held by customers in the target countries.

**Columns/Parameters Involved**: `@InstrumentID`, `@CountryIDList`, `Trade.Position.MirrorID`, `Customer.CustomerStatic.CountryID`

**Rules**:
- SELECT DISTINCT tp.MirrorID, tp.PositionID FROM Trade.Position
- JOIN Customer.CustomerStatic ON CID to get CountryID
- JOIN @CountryIDList TVP to filter by target countries
- WHERE MirrorID <> 0 (only mirrored positions) AND InstrumentID = @InstrumentID
- Results stored in #PositionList with StatusID=0 (pending)
- Clustered index created on MirrorID for efficient iteration

### 2.2 Per-Position Detachment Loop

**What**: Iterates through each position and calls the detachment procedure.

**Columns/Parameters Involved**: `Trade.DetachPositionsFromMirror`, `@SetPositionsAsReal = 1`

**Rules**:
- WHILE loop processes one position at a time (TOP 1 ORDER BY MirrorID DESC)
- Calls Trade.DetachPositionsFromMirror with @SetPositionsAsReal=1
- Each call wrapped in TRY/CATCH — errors are silently caught to avoid cascading failures
- Updates #PositionList.StatusID=1 after each attempt (regardless of success/failure)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument being restricted. All mirrored positions for this instrument in the target countries will be detached. |
| 2 | @CountryIDList | dbo.IdIntList (TVP) | READONLY | - | CODE-BACKED | List of country IDs where the instrument is being restricted. Joined against Customer.CustomerStatic.CountryID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Position (view) | Read | Filters positions by InstrumentID |
| CID | Customer.CustomerStatic | Read | Joins to resolve customer's country |
| @CountryIDList | dbo.IdIntList | UDT (TVP) | Country ID list type |
| (EXEC) | Trade.DetachPositionsFromMirror | Procedure call | Core detachment logic, called per position with @SetPositionsAsReal=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Manual/Admin) | N/A | Direct caller | Typically called by operations/compliance teams for regulatory actions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DetachPositionsByCountryAndInstrument (procedure)
+-- Trade.Position (view)
+-- Customer.CustomerStatic (table)
+-- Trade.DetachPositionsFromMirror (procedure)
    +-- Trade.Mirror (table)
    +-- Trade.PositionTbl (table)
    +-- Trade.PositionTreeInfo (table)
    +-- Trade.PostDetachOperation (table)
    +-- Customer.SetBalanceInsertCredit_Native (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Find mirrored positions for the instrument |
| Customer.CustomerStatic | Table | Resolve customer country |
| Trade.DetachPositionsFromMirror | Stored Procedure | Per-position detachment with real-stock conversion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Uses NOLOCK hint on Trade.Position read. The WHILE loop with TOP(1) pattern processes positions one at a time. Silent CATCH block means individual failures are not surfaced — consider adding logging for production monitoring. The UPDATE on #PositionList has a bug: `WHERE MirrorID = @MirrorID AND @PositionID = @PositionID` should be `AND PositionID = @PositionID` (missing column name), but this appears to work because @PositionID is always non-zero (truthy).

---

## 8. Sample Queries

### 8.1 Preview affected positions before running

```sql
SELECT  DISTINCT tp.MirrorID, tp.PositionID, tp.CID, cc.CountryID
FROM    Trade.Position tp WITH (NOLOCK)
        JOIN Customer.CustomerStatic cc ON tp.CID = cc.CID
WHERE   tp.MirrorID <> 0
        AND tp.InstrumentID = 1001
        AND cc.CountryID IN (1, 2, 3);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DetachPositionsByCountryAndInstrument | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DetachPositionsByCountryAndInstrument.sql*
