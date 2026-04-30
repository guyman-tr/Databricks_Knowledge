# History.MostPopularInstruments

> SQL Server temporal history table automatically maintained by the database engine, recording every past snapshot of Trade.MostPopularInstruments - the trading popularity leaderboard showing how many open positions exist per instrument across the last 90 days.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.MostPopularInstruments is the temporal history backing table for Trade.MostPopularInstruments. SQL Server's SYSTEM_VERSIONING populates it automatically whenever Trade.MostPopularInstruments is refreshed.

Trade.MostPopularInstruments is a pre-computed popularity ranking table that counts how many non-copy (ParentPositionID=0) positions have been opened per instrument over the last 90 days. This ranking feeds the trading platform's "Popular Instruments" feature - showing new users which instruments are most actively traded. The table is periodically refreshed by `Trade.InsertMostPopularInstruments`, which runs a DELETE all + INSERT fresh data cycle. Each complete refresh causes the old population to be archived here as a temporal snapshot.

The column name `NumOfManuallPositions` ("manually" = non-copy, ParentPositionID=0) counts positions opened by customers directly rather than via copy trading. The historical data allows analyzing how instrument popularity changes over time.

Live data shows current top instruments: InstrumentID=100017 (1.89M positions), InstrumentID=28 (1.67M), InstrumentID=18 (1.63M), InstrumentID=100080 (1.53M), InstrumentID=100000 (1.46M).

---

## 2. Business Logic

### 2.1 Periodic Full Refresh - DELETE + INSERT Temporal Pattern

**What**: Trade.InsertMostPopularInstruments performs a complete table replacement each run. This DELETE+INSERT pattern causes ALL current rows to be archived to History before being deleted (temporal DELETE = row archived), and the fresh data is then inserted as new live rows.

**Columns/Parameters Involved**: `InstrumentID`, `NumOfManuallPositions`, `SysStartTime`, `SysEndTime`

**Rules**:
- `Trade.InsertMostPopularInstruments` runs within a transaction: BEGIN -> DELETE Trade.MostPopularInstruments -> INSERT all instruments -> COMMIT
- The DELETE generates one history row per instrument (the old popularity count before refresh)
- The INSERT generates new live rows with SysStartTime = refresh time
- SysEndTime in History = the moment of the DELETE during the refresh
- The 90-day lookback window (OpenOccurred >= DATEADD(day, -90, CAST(GETUTCDATE() AS DATE))) means gradual changes as old positions age out and new ones come in
- `Trade.GetMostPopularInstrumentsForAPI` reads the live table to serve API responses - History enables auditing past popularity states

### 2.2 Source Query - Only Non-Copy Positions Count

**What**: The popularity metric specifically excludes copy positions (ParentPositionID != 0), counting only positions customers opened themselves.

**Columns/Parameters Involved**: `NumOfManuallPositions`

**Rules**:
- Source: `Trade.GetPositionData WHERE ParentPositionID = 0 AND OpenOccurred >= DATEADD(day, -90, CAST(GETUTCDATE() AS DATE))`
- Column named NumOfManuallPositions ("manually") = opened by customer themselves (not via copy trading)
- Each refresh produces one row per InstrumentID with the 90-day position count
- Instruments with zero positions in the last 90 days are absent from the table entirely

---

## 3. Data Overview

0 rows in test environment history (no refreshes have occurred since test DB setup). Live table has current popularity data (at least 5 instruments with 1M+ positions each).

Representative history row:

| InstrumentID | NumOfManuallPositions | SysStartTime | SysEndTime |
|---|---|---|---|
| 100017 | 1876543 | 2026-03-10 06:00:00 | 2026-03-11 06:00:01 | Snapshot of prior popularity count before next daily refresh. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument for which popularity was measured. References Trade.Instrument.InstrumentID (no FK enforced in history table). InstrumentID=0 does not appear (only instruments with actual positions). Multiple history rows may share the same InstrumentID from different refresh cycles. |
| 2 | NumOfManuallPositions | int | YES | - | CODE-BACKED | Count of non-copy (manually opened) positions for this instrument opened in the past 90 days, as of the time of the last refresh. Column name has "Manually" misspelling (vs "Manually") and "Positions" concept (ParentPositionID=0 filter). NULL theoretically possible but should not occur in practice - all rows have a count. |
| 3 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | UTC timestamp when this instrument's popularity count became current in Trade.MostPopularInstruments. Populated automatically by SQL Server SYSTEM_VERSIONING. Represents the INSERT time during a refresh cycle. datetime2(7) = 100-nanosecond precision. |
| 4 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC timestamp when this popularity count was superseded. For history rows, this is the DELETE timestamp during the next refresh cycle. The interval [SysStartTime, SysEndTime) represents how long this popularity ranking was current. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | References the instrument being ranked. No FK enforced in history. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.MostPopularInstruments | SYSTEM_VERSIONING | Writer (automatic) | Live temporal table - SQL Server archives old rows here on DELETE and UPDATE |

---

## 6. Dependencies

```
History.MostPopularInstruments (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: Trade.MostPopularInstruments (live temporal table)
    - Refreshed by: Trade.InsertMostPopularInstruments (periodic scheduled job)
      - Reads: Trade.GetPositionData (view)
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.MostPopularInstruments | Table | Live temporal table - this is its HISTORY_TABLE |
| Trade.GetMostPopularInstrumentsForAPI | Stored Procedure | Reads the live table to serve API popularity rankings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MostPopularInstruments | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression applied.

### 7.2 Constraints

No constraints on history table. Live table PK: CLUSTERED on InstrumentID ASC, FILLFACTOR=95.

---

## 8. Sample Queries

### 8.1 Historical popularity ranking at a specific date

```sql
SELECT InstrumentID, NumOfManuallPositions
FROM [Trade].[MostPopularInstruments]
FOR SYSTEM_TIME AS OF '2026-01-01 00:00:00'
ORDER BY NumOfManuallPositions DESC
```

### 8.2 Track how a specific instrument's popularity has changed over time

```sql
SELECT InstrumentID, NumOfManuallPositions, SysStartTime, SysEndTime,
       SysEndTime - SysStartTime AS ValidDuration
FROM [History].[MostPopularInstruments] WITH (NOLOCK)
WHERE InstrumentID = 100017
UNION ALL
SELECT InstrumentID, NumOfManuallPositions, SysStartTime, SysEndTime, NULL
FROM [Trade].[MostPopularInstruments] WITH (NOLOCK)
WHERE InstrumentID = 100017
ORDER BY SysStartTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.InsertMostPopularInstruments) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.MostPopularInstruments | Type: Table | Source: etoro/etoro/History/Tables/History.MostPopularInstruments.sql*
