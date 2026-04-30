# Trade.Instrument_080121

> Minimal point-in-time snapshot of instrument spread configuration; captures InstrumentID, AskSpr, BidSpr from August 1, 2021 or January 8, 2021.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | None (InstrumentID not PK) |
| **Partition** | PRIMARY |
| **Indexes** | None defined |

---

## 1. Business Meaning

Trade.Instrument_080121 is a minimal point-in-time snapshot table with only three columns: InstrumentID, AskSpr (ask spread), and BidSpr (bid spread). The "_080121" suffix suggests a snapshot date of August 1, 2021 (DDMMYY) or January 8, 2021 (MMDDYY); the former is more likely for a numeric date format.

The parent table Trade.Instrument stores all tradable instruments. Spread values (AskSpr, BidSpr) are critical for pricing and margin calculations. This archive captures a subset of that configuration at a specific point in time, likely for a one-time analysis, audit, or comparison of spread changes.

The live database has 0 rows. The table appears to have been used for a historical capture and is no longer populated or referenced.

---

## 2. Business Logic

None. Read-only archive. No procedures reference this table.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count (live) | 0 |
| Last known activity | Snapshot date 080121 |
| Purpose | Spread configuration archive for analysis or comparison |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NULL | - | High | FK to Trade.Instrument |
| 2 | AskSpr | decimal(16,8) | NULL | - | High | Ask spread value at snapshot time |
| 3 | BidSpr | decimal(16,8) | NULL | - | High | Bid spread value at snapshot time |

---

## 5. Relationships

### 5.1 References To
- Trade.Instrument (InstrumentID) - instrument whose spreads were captured

### 5.2 Referenced By
None. Archive table; not used by other objects.

---

## 6. Dependencies

### 6.1 Objects This Depends On
- Trade.Instrument (conceptually; no FK constraint)

### 6.2 Objects That Depend On This
None.

---

## 7. Technical Details

### 7.1 Indexes
None defined.

### 7.2 Constraints
None. InstrumentID is nullable; no primary key.

---

*Generated: 2026-03-14 | Quality: 6.5/10*
*Object: Trade.Instrument_080121 | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Instrument_080121.sql*
