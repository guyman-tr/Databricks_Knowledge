# Trade.GetHistoryInsights

> Calculates point-in-time market exposure analytics: unique users per side, total units, and position counts per instrument at a given timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (key in all three result sets) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure produces a snapshot of platform-wide market exposure at a specific point in time. For every instrument, it reports: how many unique users hold net-long vs net-short positions, total units held on each side, and total position counts on each side. Only non-copy positions (MirrorID=0) are included, providing a view of direct customer exposure.

The procedure exists to power the "Market Insights" analytics feature, showing traders the buy/sell sentiment distribution across instruments. This data helps traders gauge market consensus and the platform's dealing desk understand aggregate exposure.

Data flow: caller passes @Timestamp. The SP builds a unified position set by combining currently-open positions from Trade.PositionTbl (StatusID=1, opened before @Timestamp) with historical positions from History.Position (that were open at @Timestamp). This is aggregated into a #Exposure temp table, which is then queried three times to produce three result sets.

---

## 2. Business Logic

### 2.1 Point-in-Time Position Reconstruction

**What**: Rebuilds the set of positions that existed at a given moment by combining live and historical data.

**Columns/Parameters Involved**: `@Timestamp`, `StatusID`, `InitDateTime`, `CloseOccurred`, `MirrorID`

**Rules**:
- Live positions: Trade.PositionTbl WHERE StatusID=1 AND InitDateTime <= @Timestamp AND MirrorID=0
- Historical positions: History.Position WHERE @Timestamp BETWEEN InitDateTime AND CloseOccurred AND MirrorID=0
- UNION ALL combines both sets (a position appears in exactly one source at any point in time)
- MirrorID=0 excludes copy positions to show only direct customer exposure

### 2.2 Net Direction Classification

**What**: Classifies each user's net exposure per instrument as Buy or Sell based on signed unit total.

**Columns/Parameters Involved**: `IsBuy`, `Units`, `TotalUnits`, `BuyUniques`, `SellUniques`

**Rules**:
- TotalUnits = SUM(IIF(IsBuy=1, 1, -1) * Units) per CID per InstrumentID
- TotalUnits > 0 -> user counted as BuyUnique
- TotalUnits < 0 -> user counted as SellUnique
- A user with equal buy and sell units nets to zero and is counted in neither bucket

**Diagram**:
```
Trade.PositionTbl (open, MirrorID=0)    History.Position (was open at @Timestamp, MirrorID=0)
            |                                       |
            +------------- UNION ALL ---------------+
                            |
                    GROUP BY InstrumentID, CID, IsBuy
                    --> #Exposure (InstrumentID, CID, IsBuy, Units, Positions)
                            |
        +-------------------+--------------------+
        |                   |                    |
  Result Set 1        Result Set 2         Result Set 3
  BuyUniques/         BuyUnits/            BuyPositions/
  SellUniques         SellUnits            SellPositions
  (net direction      (raw unit totals)    (position counts)
   per user)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Timestamp | DATETIME | NO | - | CODE-BACKED | Point-in-time snapshot moment. Determines which positions were open at this instant. |

### Result Set 1 - Unique Users Per Side

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 3 | BuyUniques | INT | NO | - | CODE-BACKED | Count of unique users whose net units > 0 (net-long). |
| 4 | SellUniques | INT | NO | - | CODE-BACKED | Count of unique users whose net units < 0 (net-short). |

### Result Set 2 - Units Per Side

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 6 | BuyUnits | MONEY | NO | - | CODE-BACKED | Total units held in Buy positions across all users. |
| 7 | SellUnits | MONEY | NO | - | CODE-BACKED | Total units held in Sell positions across all users. |

### Result Set 3 - Positions Per Side

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 9 | BuyPositions | INT | NO | - | CODE-BACKED | Total count of Buy positions across all users. |
| 10 | SellPositions | INT | NO | - | CODE-BACKED | Total count of Sell positions across all users. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.PositionTbl | FROM (CTE) | Open positions at the snapshot time |
| (body) | History.Position | FROM (CTE) | Historically open positions at the snapshot time |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHistoryInsights (procedure)
+-- Trade.PositionTbl (table)
+-- History.Position (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | CTE - currently open positions (StatusID=1, MirrorID=0) |
| History.Position | Table | CTE - historically open positions at @Timestamp |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses #Exposure temp table for intermediate aggregation.

---

## 8. Sample Queries

### 8.1 Execute for current snapshot

```sql
EXEC Trade.GetHistoryInsights @Timestamp = '2026-03-16 12:00:00';
```

### 8.2 Equivalent first result set (unique users)

```sql
;WITH Positions AS (
    SELECT InstrumentID, CID, IsBuy, AmountInUnitsDecimal
    FROM   Trade.PositionTbl WITH (NOLOCK)
    WHERE  MirrorID = 0 AND InitDateTime <= '2026-03-16' AND StatusID = 1
    UNION ALL
    SELECT InstrumentID, CID, IsBuy, AmountInUnitsDecimal
    FROM   History.Position WITH (NOLOCK)
    WHERE  MirrorID = 0 AND '2026-03-16' BETWEEN InitDateTime AND CloseOccurred
)
SELECT InstrumentID,
       SUM(IIF(TotalUnits > 0, 1, 0)) AS BuyUniques,
       SUM(IIF(TotalUnits < 0, 1, 0)) AS SellUniques
FROM   (
    SELECT InstrumentID, CID, SUM(IIF(IsBuy=1,1,-1) * SUM(AmountInUnitsDecimal)) OVER (PARTITION BY InstrumentID, CID) AS TotalUnits
    FROM   Positions
    GROUP BY InstrumentID, CID, IsBuy
) a
GROUP BY InstrumentID;
```

### 8.3 Check exposure for a specific instrument

```sql
EXEC Trade.GetHistoryInsights @Timestamp = GETUTCDATE();
-- Filter result sets for InstrumentID = 1001 in application layer
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHistoryInsights | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetHistoryInsights.sql*
