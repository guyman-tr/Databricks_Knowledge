# Trade.GetHistoryInsightsTest

> Test variant of Trade.GetHistoryInsights - identical logic for point-in-time market exposure analytics.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (key in all three result sets) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a test/development copy of Trade.GetHistoryInsights with identical logic. It calculates point-in-time market exposure analytics: unique users per side, total units, and position counts per instrument at a given timestamp. Only non-copy positions (MirrorID=0) are included.

The test variant exists to allow testing changes to the insights logic without affecting the production procedure. The code is an exact copy of Trade.GetHistoryInsights.

Data flow: identical to Trade.GetHistoryInsights. Combines open positions from Trade.PositionTbl (StatusID=1) with historical positions from History.Position that were open at @Timestamp. Aggregates into #Exposure temp table and produces three result sets.

---

## 2. Business Logic

### 2.1 Point-in-Time Position Reconstruction

**What**: Same as Trade.GetHistoryInsights - rebuilds position set at a moment by combining live and historical data.

**Columns/Parameters Involved**: `@Timestamp`, `StatusID`, `InitDateTime`, `CloseOccurred`, `MirrorID`

**Rules**:
- Live positions: Trade.PositionTbl WHERE StatusID=1 AND InitDateTime <= @Timestamp AND MirrorID=0
- Historical positions: History.Position WHERE @Timestamp BETWEEN InitDateTime AND CloseOccurred AND MirrorID=0
- See [Trade.GetHistoryInsights](Trade.GetHistoryInsights.md) for full documentation

### 2.2 Net Direction Classification

**What**: Same as production - classifies users as net-long or net-short per instrument.

**Rules**:
- TotalUnits = SUM(IIF(IsBuy=1, 1, -1) * Units) per user per instrument
- Positive total = BuyUnique, Negative total = SellUnique

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Timestamp | DATETIME | NO | - | CODE-BACKED | Point-in-time snapshot moment. Identical to production variant. |

### Result Set 1 - Unique Users Per Side

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 3 | BuyUniques | INT | NO | - | CODE-BACKED | Count of unique users with net-long exposure. |
| 4 | SellUniques | INT | NO | - | CODE-BACKED | Count of unique users with net-short exposure. |

### Result Set 2 - Units Per Side

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 6 | BuyUnits | MONEY | NO | - | CODE-BACKED | Total Buy-side units across all users. |
| 7 | SellUnits | MONEY | NO | - | CODE-BACKED | Total Sell-side units across all users. |

### Result Set 3 - Positions Per Side

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 9 | BuyPositions | INT | NO | - | CODE-BACKED | Total Buy position count. |
| 10 | SellPositions | INT | NO | - | CODE-BACKED | Total Sell position count. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.PositionTbl | FROM (CTE) | Open positions at snapshot time |
| (body) | History.Position | FROM (CTE) | Historically open positions at snapshot time |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHistoryInsightsTest (procedure)
+-- Trade.PositionTbl (table)
+-- History.Position (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | CTE - open positions (StatusID=1, MirrorID=0) |
| History.Position | Table | CTE - historical positions open at @Timestamp |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Identical implementation to Trade.GetHistoryInsights.

---

## 8. Sample Queries

### 8.1 Execute test variant

```sql
EXEC Trade.GetHistoryInsightsTest @Timestamp = '2026-03-16 12:00:00';
```

### 8.2 Compare with production

```sql
EXEC Trade.GetHistoryInsights @Timestamp = '2026-03-16 12:00:00';
EXEC Trade.GetHistoryInsightsTest @Timestamp = '2026-03-16 12:00:00';
-- Results should be identical
```

### 8.3 Point-in-time snapshot for yesterday

```sql
EXEC Trade.GetHistoryInsightsTest @Timestamp = DATEADD(DAY, -1, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHistoryInsightsTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetHistoryInsightsTest.sql*
