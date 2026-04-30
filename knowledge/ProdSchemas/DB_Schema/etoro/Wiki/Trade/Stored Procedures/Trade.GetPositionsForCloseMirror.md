# Trade.GetPositionsForCloseMirror

> Retrieves open positions for a CopyTrader mirror and customer, then calls the natively compiled GetPositionsForCloseMirrorMot to return three result sets: positions to close, positions already in the standard close pipeline, and positions in the delayed close pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId INT, @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the public-facing entry point for the CopyTrader mirror close data workflow. It fetches all open positions for a given mirror and customer from Trade.PositionTbl, loads them into the Trade.PositionList TVP, and delegates to the natively compiled `Trade.GetPositionsForCloseMirrorMot` for the actual work. The result is three result sets the calling service uses to determine exactly which positions need close orders submitted.

The procedure exists as a wrapper to separate concerns: the disk-based query against Trade.PositionTbl (which cannot run in a natively compiled proc) from the in-memory logic that checks execution pipelines. The Mot procedure is natively compiled for performance; this wrapper handles the PositionTbl lookup and TVP population.

Data flows: Step 1: declares a Trade.PositionList TVP, populates it with positions WHERE MirrorID=@mirrorId AND CID=@cid AND StatusID=1. Step 2: EXEC Trade.GetPositionsForCloseMirrorMot passing the TVP and CID. Returns the three result sets from GetPositionsForCloseMirrorMot directly to the caller.

---

## 2. Business Logic

### 2.1 Two-Stage Architecture: Disk Read -> In-Memory Processing

**What**: Separates the disk-based PositionTbl query from the natively compiled in-memory logic.

**Columns/Parameters Involved**: `@mirrorId`, `@cid`, `@PositionList`

**Rules**:
- Stage 1 (this procedure): SELECT open positions for the mirror from Trade.PositionTbl (disk), load into @PositionList TVP.
- Stage 2 (GetPositionsForCloseMirrorMot): Use @PositionList to check CloseExecutionPlan and DelayedOrderForClose at maximum speed.
- If no positions exist for the mirror/CID combination, @PositionList is empty and GetPositionsForCloseMirrorMot returns three empty result sets.

### 2.2 Three Result Sets Returned

**What**: GetPositionsForCloseMirrorMot returns three result sets (see that procedure's documentation for full detail).

**Columns/Parameters Involved**: Result sets 1, 2, 3 from GetPositionsForCloseMirrorMot

**Rules**:
- Result set 1: Open positions (PositionID, InstrumentID) - what needs to be closed.
- Result set 2: Positions with active standard close orders (PositionID) - already in standard pipeline.
- Result set 3: Positions with pending delayed close orders (PositionID) - already in delayed pipeline.
- Caller: submit close orders for ResultSet1 MINUS ResultSet2 MINUS ResultSet3.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | INT | NO | - | CODE-BACKED | The CopyTrader Mirror ID identifying the copier-leader relationship. Open positions for this mirror are fetched from Trade.PositionTbl. FK to Trade.Mirror.MirrorID. |
| 2 | @cid | INT | NO | - | CODE-BACKED | The customer (copier) ID. Scopes the position lookup to a single customer. Passed through to GetPositionsForCloseMirrorMot for execution plan lookups. |

**Output**: See Trade.GetPositionsForCloseMirrorMot for full output column documentation (three result sets).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @mirrorId | Trade.Mirror | Lookup | The mirror being closed |
| @cid + @mirrorId | Trade.PositionTbl | Primary source | Open positions for the mirror/customer combination |
| @PositionList | Trade.PositionList | TVP type | Intermediate container for position data |
| (EXEC) | Trade.GetPositionsForCloseMirrorMot | Callee | Delegates to the natively compiled Mot procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Mirror close workflow (application service) | @mirrorId, @cid | Application call | Called when a customer stops copying a leader or when a mirror is administratively closed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsForCloseMirror (procedure)
├── Trade.PositionTbl (table)
├── Trade.PositionList (user-defined type)
└── Trade.GetPositionsForCloseMirrorMot (procedure, natively compiled)
      ├── Trade.CloseExecutionPlan (table)
      ├── Trade.OrderForClose (table)
      ├── Dictionary.OrderForExecutionStatus (table)
      └── Trade.DelayedOrderForClose (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT open positions (StatusID=1) for the mirror/CID to populate @PositionList |
| Trade.PositionList | User Defined Type | TVP type used as the intermediate container |
| Trade.GetPositionsForCloseMirrorMot | Procedure | Delegated-to natively compiled procedure that performs the execution plan checks |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Mirror management service | External application | Calls this procedure to get data needed for mirror closure without duplicate close orders |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None explicit.

---

## 8. Sample Queries

### 8.1 Execute for a specific mirror and customer

```sql
EXEC Trade.GetPositionsForCloseMirror
    @mirrorId = 12345,
    @cid = 1234567;
-- Returns 3 result sets
```

### 8.2 Check open positions for a mirror (Stage 1 equivalent)

```sql
SELECT PositionID, InstrumentID
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE MirrorID = 12345
  AND CID = 1234567
  AND StatusID = 1;
```

### 8.3 Identify positions with both standard and delayed close orders

```sql
-- Positions in both pipelines (would appear in ResultSet2 AND ResultSet3)
SELECT cep.PositionID
FROM Trade.CloseExecutionPlan cep WITH (NOLOCK)
INNER JOIN Trade.OrderForClose ofc WITH (NOLOCK) ON cep.OrderID = ofc.OrderID
INNER JOIN Dictionary.OrderForExecutionStatus os WITH (NOLOCK) ON ofc.StatusID = os.ID
WHERE cep.CID = 1234567 AND os.IsTerminal = 0
INTERSECT
SELECT PositionID
FROM Trade.DelayedOrderForClose WITH (NOLOCK)
WHERE CID = 1234567 AND StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 callee analyzed (GetPositionsForCloseMirrorMot) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsForCloseMirror | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsForCloseMirror.sql*
