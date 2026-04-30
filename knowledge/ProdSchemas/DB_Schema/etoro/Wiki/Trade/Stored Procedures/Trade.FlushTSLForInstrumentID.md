# Trade.FlushTSLForInstrumentID

> Flushes pending Trailing Stop Loss (TSL) updates for all position trees of a given instrument by iterating through trees with pending TSL sync records and calling Trade.FlushTSLForSpecificTree for each.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID (instrument whose TSL sync records should be flushed) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FlushTSLForInstrumentID processes pending Trailing Stop Loss (TSL) updates for all position trees on a specific instrument. Trailing stop losses automatically move the stop-loss rate in the profitable direction as the market price moves, but these updates are queued in Trade.SyncTSL rather than applied immediately. This procedure flushes those pending updates.

Without this procedure, TSL updates would accumulate in the sync queue without being applied. This is typically called when an instrument's price feed resumes after a halt, or during scheduled TSL processing.

The procedure finds all distinct TreeIDs where the root position (ParentPositionID=0, StatusID=1=Open) has pending TSL sync records (Status=0), then calls Trade.FlushTSLForSpecificTree for each tree in a loop, each within its own transaction.

---

## 2. Business Logic

### 2.1 Tree-Level TSL Flush

**What**: Processes pending TSL updates at the tree level, not the individual position level.

**Columns/Parameters Involved**: `@InstrumentID`, `Trade.SyncTSL.Status`, `Trade.PositionTbl.TreeID`

**Rules**:
- Only root positions: ParentPositionID = 0 (the head of the copy-trade tree)
- Only open positions: StatusID = 1
- Only pending syncs: Trade.SyncTSL.Status = 0
- One transaction per tree: if one tree fails, others continue
- Distinct TreeIDs prevent duplicate processing

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID to flush TSL sync records for. All position trees on this instrument with pending TSL updates will be processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.PositionTbl | SELECT | Finds root positions with pending TSL for the instrument |
| JOIN | Trade.SyncTSL | SELECT | Identifies positions with pending sync records (Status=0) |
| EXEC | Trade.FlushTSLForSpecificTree | EXEC | Processes TSL flush for each individual tree |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ActivateSplit_Inner | (batch #16) | EXEC | Calls this during stock split activation to flush TSL before split |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FlushTSLForInstrumentID (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.SyncTSL (table)
+-- Trade.FlushTSLForSpecificTree (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT - finds root positions for the instrument |
| Trade.SyncTSL | Table | JOIN - identifies pending TSL sync records |
| Trade.FlushTSLForSpecificTree | Procedure | EXEC - flushes TSL for each tree |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActivateSplit_Inner | Procedure | EXEC - flushes TSL before stock split processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Per-tree transaction | Isolation | Each tree processed in its own transaction |
| THROW on error | Error handling | Errors propagate to caller |

---

## 8. Sample Queries

### 8.1 Check pending TSL sync records for an instrument

```sql
SELECT  DISTINCT p.TreeID, p.PositionID, s.Status
FROM    Trade.PositionTbl p WITH (NOLOCK)
JOIN    Trade.SyncTSL s WITH (NOLOCK) ON p.PositionID = s.PositionID
WHERE   p.InstrumentID = 1001
        AND p.ParentPositionID = 0
        AND p.StatusID = 1
        AND s.Status = 0;
```

### 8.2 Execute TSL flush for an instrument

```sql
EXEC Trade.FlushTSLForInstrumentID @InstrumentID = 1001;
```

### 8.3 View TSL settings for a position tree

```sql
SELECT  pti.TreeID, pti.StopRate, pti.LimitRate, pti.IsTslEnabled, pti.NextThresHold
FROM    Trade.PositionTreeInfo pti WITH (NOLOCK)
WHERE   pti.TreeID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FlushTSLForInstrumentID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.FlushTSLForInstrumentID.sql*
