# Trade.MostPopularInstruments

## 1. Business Meaning

Snapshot of the most popular instruments by number of manual (real, non-copy) positions opened in the last 90 days. Used to surface trending instruments to users (e.g., API for "popular" or "trending" lists) and to prioritize display or recommendations.

## 2. Business Logic

- **Calculation**: `Trade.InsertMostPopularInstruments` aggregates from `Trade.GetPositionData` where ParentPositionID = 0 (manual positions) and OpenOccurred >= 90 days ago.
- **Refresh**: Full replace—procedure deletes all rows, then inserts fresh results in a single transaction.
- **Consumption**: `Trade.GetMostPopularInstrumentsForAPI` returns top N instruments (default 200) ordered by NumOfManuallPositions DESC.
- **Typo**: Column name "NumOfManuallPositions" has a double "l" in "Manuall".

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count | ~3,090 |
| Partitioning | None |
| System versioning | Yes (History.MostPopularInstruments) |
| Refresh | By Trade.InsertMostPopularInstruments (likely scheduled) |

**Sample top instruments** (by NumOfManuallPositions):
- InstrumentID 100017: 1,889,377
- InstrumentID 28: 1,665,868
- InstrumentID 18: 1,625,734
- InstrumentID 100080: 1,527,692
- InstrumentID 100000: 1,456,247

## 4. Elements

| # | Column | Type | Nullable | Default | Description |
|---|--------|------|----------|---------|-------------|
| 1 | InstrumentID | int | NO | - | Instrument. FK to Trade.Instrument. |
| 2 | NumOfManuallPositions | int | YES | - | Count of manual positions opened in last 90 days. |
| 3 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | Temporal period start. |
| 4 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59 | Temporal period end. |

## 5. Relationships

| From | To | Type | Join |
|------|-----|------|------|
| InstrumentID | Trade.Instrument | Implicit FK | Instrument metadata |
| Source data | Trade.GetPositionData | Aggregation | ParentPositionID=0, OpenOccurred last 90 days |
| History table | History.MostPopularInstruments | System versioning | Auto-populated |

## 6. Dependencies

**Referenced by procedures:**
- `Trade.GetMostPopularInstrumentsForAPI` – Reads top instruments for API consumption.
- `Trade.InsertMostPopularInstruments` – Populates table (full replace).

**Related tables:**
- `Trade.GetPositionData` (view/function) – Source for position counts.
- `History.MostPopularInstruments` – History table.

## 7. Technical Details

- **Primary key**: InstrumentID
- **System-versioned temporal table**: SysStartTime, SysEndTime; history in History schema.
- **Constraints**: DF_Department_SysStartTime, DF_Department_SysEndTime (legacy naming).
- **Filegroup**: PRIMARY.
- **Fillfactor**: 95.

## 8. Sample Queries

```sql
-- Top 50 most popular instruments
SELECT TOP 50 InstrumentID, NumOfManuallPositions
FROM Trade.MostPopularInstruments
ORDER BY NumOfManuallPositions DESC;

-- Same as API proc (default 200)
SELECT TOP 200 InstrumentID
FROM Trade.MostPopularInstruments
ORDER BY NumOfManuallPositions DESC;

-- Join to instrument names
SELECT m.InstrumentID, m.NumOfManuallPositions, i.InstrumentDisplayName
FROM Trade.MostPopularInstruments m
JOIN Trade.Instrument i ON m.InstrumentID = i.InstrumentID
ORDER BY m.NumOfManuallPositions DESC;
```

## 9. Atlassian Knowledge Sources

- Jira/Confluence: Search for "most popular instruments", "trending instruments", "popular symbols", "GetMostPopularInstrumentsForAPI".
- No direct Confluence/Jira references found in codebase.

---

*Generated: 2026-03-14 | Quality: 8.0/10*
