# Trade.PositionOpenByFork

> Tracks positions opened via the fork mechanism when instruments are split (e.g., demo/real or instrument migration).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | None (no PK); uniquely identified by (ForkDate, CID) in practice |
| **Partition** | None; on PRIMARY |
| **Indexes** | 0 |

---

## 1. Business Meaning

Trade.PositionOpenByFork records positions that were opened as a result of an instrument fork. A fork occurs when an instrument is split or migrated (e.g., Real BTC to a new instrument ID, or demo/test positions split from real). Trade.ForkByDB performs the fork: for each customer holding the old instrument at fork date, it nets units, compensates, and opens a new position on the new instrument.

This table prevents double-processing: Trade.ForkByDB left-joins PositionOpenByFork and excludes CIDs where a row already exists for the same ForkDate. After opening a position via Trade.PositionOpenForFork, ForkByDB inserts a row with ForkDate, PositionID, Occurred, CID, InstrumentID, amount details, rates, HedgeServerID, Reason, and Units.

The table is an audit/tracking layer. It has no primary key and all columns are nullable, reflecting its append-only, operational use. The logical uniqueness is (ForkDate, CID) per fork run.

---

## 2. Business Logic

### 2.1 Fork Processing

Trade.ForkByDB builds #PositionsToFork from Trade.GetPositionData for the forked instrument, excluding CIDs already in PositionOpenByFork for the fork date. It processes each CID: opens a position via Trade.PositionOpenForFork, then inserts into PositionOpenByFork with ForkDate, the new PositionID, Occurred, CID, new InstrumentID, AmountInUnitsDecimal, Amount, InitForexRate, UnitMargin, LimitRate, StopRate, HedgeServerID, Reason, Units.

### 2.2 Deduplication

The LEFT JOIN ... WHERE F.CID IS NULL ensures each CID is processed only once per ForkDate for a given fork run.

---

## 3. Data Overview

| ForkDate | PositionID | Occurred | CID | InstrumentID | AmountInUnitsDecimal | Amount | InitForexRate | UnitMargin | LimitRate | StopRate | HedgeServerID | Reason | Units |
|----------|------------|----------|-----|--------------|---------------------|--------|---------------|------------|-----------|----------|--------------|--------|-------|
| 2021-11-17 | 12345678 | 2021-11-17 12:00 | 99999 | 100001 | 0.5 | 25000 | 50000 | 50000 | 55000 | 45000 | 1 | 1 | 1 |
| - | - | - | - | - | - | - | - | - | - | - | - | - | - |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ForkDate | datetime | YES | - | VERIFIED | Date of the instrument fork. |
| 2 | PositionID | bigint | YES | - | VERIFIED | Position ID of the newly opened position (Trade.Position). |
| 3 | Occurred | datetime | YES | - | VERIFIED | When the forked position was opened. |
| 4 | CID | int | YES | - | VERIFIED | Customer ID. |
| 5 | InstrumentID | int | YES | - | VERIFIED | New instrument ID post-fork. |
| 6 | AmountInUnitsDecimal | decimal(16,8) | YES | - | VERIFIED | Position size in units (decimal). |
| 7 | Amount | money | YES | - | VERIFIED | Position amount in account currency. |
| 8 | InitForexRate | dtPrice | YES | - | VERIFIED | Opening rate. |
| 9 | UnitMargin | decimal(16,8) | YES | - | VERIFIED | Unit margin at open. |
| 10 | LimitRate | dtPrice | YES | - | CODE-BACKED | Take-profit rate. |
| 11 | StopRate | dtPrice | YES | - | CODE-BACKED | Stop-loss rate. |
| 12 | HedgeServerID | int | YES | - | VERIFIED | Hedge server for the position. |
| 13 | Reason | int | YES | - | CODE-BACKED | Fork reason code (passed from ForkByDB). |
| 14 | Units | int | YES | - | VERIFIED | Units parameter from fork. |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Key | Relationship |
|------------------|-----|--------------|
| Trade.Position | PositionID | The opened position |
| Trade.Instrument (implicit) | InstrumentID | New instrument |
| HedgeServer | HedgeServerID | Hedge server |
| Customer (implicit) | CID | Customer |

### 5.2 Referenced By

| Object | Usage |
|--------|-------|
| Trade.ForkByDB | Reads to exclude already-forked CIDs; inserts new rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.ForkByDB -> Trade.PositionOpenByFork
Trade.PositionOpenForFork -> Trade.Position (creates position)

### 6.1 Objects This Depends On

| Object | Type | Purpose |
|--------|------|---------|
| Trade.Position | Table | PositionID |
| Trade.Instrument | Table | InstrumentID |
| Trade.GetPositionData | Function | Source positions for fork |

### 6.2 Objects That Depend On This

| Object | Type | Purpose |
|--------|------|---------|
| Trade.ForkByDB | Procedure | Writes and reads for deduplication |

---

## 7. Technical Details

### 7.1 Indexes

None. Consider an index on (ForkDate, CID) for fork deduplication if volume grows.

### 7.2 Constraints

None.

---

## 8. Sample Queries

```sql
-- Positions opened by a specific fork
SELECT ForkDate, PositionID, CID, InstrumentID, AmountInUnitsDecimal, Amount, Occurred
FROM Trade.PositionOpenByFork WITH (NOLOCK)
WHERE ForkDate = @ForkDate
ORDER BY CID;

-- Check if customer was already forked for a date
SELECT 1
FROM Trade.PositionOpenByFork WITH (NOLOCK)
WHERE ForkDate = @DateOfFork AND CID = @CID;

-- Fork summary by instrument
SELECT InstrumentID, ForkDate, COUNT(*) AS PositionsOpened, SUM(Amount) AS TotalAmount
FROM Trade.PositionOpenByFork WITH (NOLOCK)
GROUP BY InstrumentID, ForkDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.0/10 | Sources: DDL, Trade.ForkByDB*
