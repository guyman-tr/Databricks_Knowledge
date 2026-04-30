# Trade.PositionsProcessedForIndexDividnds_OLD

> Predecessor of Trade.PositionsProcessedForIndexDividnds. Same schema but not partitioned; CHECK limits ProcessTime < 2024-01-15. Does not exist in live; kept in SSDT for migration reference.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | (PositionID, DividendID, ProcessTime) |
| **Partition** | PRIMARY (no partitioning) |
| **Live DB** | Does not exist (only in SSDT) |
| **Indexes** | PK clustered, IDX_TPPFID_ProcessTime_BIGINT, IX_DividendID |

---

## 1. Business Meaning

Trade.PositionsProcessedForIndexDividnds_OLD is the pre-partitioning version of the dividend position tracking table. It held the same data (which positions were paid for which dividends) but stored everything on the PRIMARY filegroup. A CHECK constraint limits ProcessTime to values before 2024-01-15, indicating this table held historical data up to that cutoff. The current Trade.PositionsProcessedForIndexDividnds took over from that date forward with partitioning on PS_EndMonthIndex.

The table does not exist in live production; it was dropped or renamed during the partitioning migration. SSDT retains the definition for migration and archival reference. PK suffix "_BIGINT" (vs "_BIGINT1" in current) confirms it is the predecessor schema.

---

## 2. Business Logic

### 2.1 Cutoff Date

**What**: CHECK constraint enforces ProcessTime < '2024-01-15 00:00:00.000'.

**Columns/Parameters Involved**: `ProcessTime`

**Rules**:
- All rows must have ProcessTime before 2024-01-15
- Current table (PositionsProcessedForIndexDividnds) holds data from 2024-01-15 onward
- Migration split data by ProcessTime

### 2.2 Schema Parity

**What**: Column set identical to current table.

**Columns/Parameters Involved**: All

**Rules**:
- Same columns: PositionID, DividendID, ProcessTime, PaymentAmount, CreditID, BuyTax, SellTax
- Same PK semantics; different index placement (PRIMARY vs partitioned)

---

## 3. Data Overview

| PositionID | DividendID | ProcessTime | Meaning |
|------------|------------|-------------|---------|
| N/A | - | - | Table not in live. Would have held pre-2024-01-15 dividend payments. |

**Note**: Table does not exist in live database. Historical data, if retained, would be in archive or the current table after migration.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position that received the dividend. |
| 2 | DividendID | int | NO | - | CODE-BACKED | Dividend event. |
| 3 | ProcessTime | datetime | NO | getutcdate() | CODE-BACKED | When processed. CHECK < 2024-01-15. |
| 4 | PaymentAmount | money | YES | - | CODE-BACKED | Amount credited or debited. |
| 5 | CreditID | bigint | YES | - | CODE-BACKED | Credit transaction link. |
| 6 | BuyTax | decimal(16,8) | YES | - | CODE-BACKED | Tax for buy-side. |
| 7 | SellTax | decimal(16,8) | YES | - | CODE-BACKED | Tax for sell-side. |

---

## 5. Relationships

### 5.1 References To

- Trade.PositionTbl (PositionID)
- Trade.IndexDividends (DividendID)

### 5.2 Referenced By

- None in live (table dropped). Replaced by Trade.PositionsProcessedForIndexDividnds.

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.IndexDividends, Trade.PositionTbl -> Trade.PositionsProcessedForIndexDividnds_OLD (SSDT only)

### 6.1 Objects This Depends On

Trade.IndexDividends, Trade.PositionTbl

### 6.2 Objects That Depend On This

None (predecessor table, not in live).

---

## 7. Technical Details

### 7.1 Indexes

- PK_TradePositionsProcessedForIndexDividnds_BIGINT: CLUSTERED (PositionID, DividendID, ProcessTime) ON [PRIMARY]
- IDX_TPPFID_ProcessTime_BIGINT: (ProcessTime) ON [PRIMARY]
- IX_DividendID: (DividendID) ON [PRIMARY]

### 7.2 Constraints

- PK: (PositionID, DividendID, ProcessTime)
- CHECK: ProcessTime < '2024-01-15 00:00:00.000' (constraint name: test12)
- DEFAULT: ProcessTime = getutcdate()

---

*Generated: 2026-03-14 | Quality: 7.0/10*
