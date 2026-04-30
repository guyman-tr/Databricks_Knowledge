# Trade.DelistAlert

> Returns PositionIDs of open positions on recently delisted instruments (non-tradable within the last 2 hours) for alerting purposes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns PositionID result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies **open positions on instruments that have recently been delisted** (marked non-tradable). When an instrument is delisted, customers who hold open positions on that instrument need to be notified so they understand their positions will be force-closed. This procedure provides the list of affected PositionIDs.

The procedure checks History.InstrumentMetaData (the temporal/system-versioned history table) for instruments that became non-tradable (Tradable=0) within the last 2 hours. It then cross-references those instruments against Trade.PositionTbl to find open positions (StatusID=1). The 2-hour lookback window ensures the alert catches recent delistings without repeatedly alerting on old ones.

This is a read-only diagnostic/alerting procedure. The actual position closing is handled by Trade.DelistStock, which iterates through positions and calls Trade.ManualPositionClose_Crisis. This procedure likely feeds an alerting system or monitoring dashboard that triggers or confirms the delist process.

---

## 2. Business Logic

### 2.1 Recent Delist Detection via Temporal History

**What**: Uses system-versioned history to find instruments that became non-tradable within the last 2 hours.

**Columns/Parameters Involved**: `History.InstrumentMetaData.Tradable`, `History.InstrumentMetaData.SysEndTime`, `Trade.PositionTbl.InstrumentID`, `Trade.PositionTbl.StatusID`

**Rules**:
- Looks at History.InstrumentMetaData WHERE Tradable = 0 AND SysEndTime > DATEADD(HOUR, -2, GETUTCDATE())
- SysEndTime > 2h ago means the row was valid (Tradable=0) recently - the instrument's non-tradable state was active within the 2-hour window
- Collects DISTINCT InstrumentIDs into a temp table with a clustered index
- Only proceeds if delisted instruments are found (IF EXISTS check)

### 2.2 Open Position Lookup

**What**: Returns open positions affected by recent delistings.

**Columns/Parameters Involved**: `Trade.PositionTbl.PositionID`, `Trade.PositionTbl.InstrumentID`, `Trade.PositionTbl.StatusID`

**Rules**:
- Queries Trade.PositionTbl WITH (NOLOCK) for positions WHERE InstrumentID IN (delisted instruments) AND StatusID = 1 (Open)
- Returns only PositionID - the consumer determines what action to take
- Uses OPTION(RECOMPILE) on the History query for plan optimization

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters. It returns a result set of PositionIDs.

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | PositionID | BIGINT | NO | - | CODE-BACKED | Position IDs of open positions on recently delisted instruments. Each row represents a position that may need force-closure due to instrument delisting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | History.InstrumentMetaData | Read | Queries temporal history to find instruments that became non-tradable in the last 2 hours |
| (SELECT) | Trade.PositionTbl | Read | Finds open positions (StatusID=1) on delisted instruments |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Alerting system / monitoring) | N/A | Consumer | Called by alerting tools to identify positions affected by recent instrument delistings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DelistAlert (procedure)
+-- History.InstrumentMetaData (table)
+-- Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.InstrumentMetaData | Table | SELECT - reads temporal history for recently delisted instruments |
| Trade.PositionTbl | Table | SELECT - finds open positions on delisted instruments |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo | - | Likely called externally by alerting infrastructure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Uses OPTION(RECOMPILE) on the History.InstrumentMetaData query for plan optimization, as the temporal history table may have variable data distributions.

---

## 8. Sample Queries

### 8.1 Preview recently delisted instruments

```sql
SELECT  DISTINCT InstrumentID
FROM    History.InstrumentMetaData WITH (NOLOCK)
WHERE   Tradable = 0
        AND SysEndTime > DATEADD(HOUR, -2, GETUTCDATE());
```

### 8.2 Count open positions per recently delisted instrument

```sql
SELECT  tp.InstrumentID, COUNT(*) AS OpenPositionCount
FROM    Trade.PositionTbl tp WITH (NOLOCK)
WHERE   tp.InstrumentID IN (
            SELECT DISTINCT InstrumentID
            FROM History.InstrumentMetaData WITH (NOLOCK)
            WHERE Tradable = 0 AND SysEndTime > DATEADD(HOUR, -2, GETUTCDATE())
        )
        AND tp.StatusID = 1
GROUP BY tp.InstrumentID;
```

### 8.3 Run the procedure directly

```sql
EXEC Trade.DelistAlert;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.3/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DelistAlert | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DelistAlert.sql*
