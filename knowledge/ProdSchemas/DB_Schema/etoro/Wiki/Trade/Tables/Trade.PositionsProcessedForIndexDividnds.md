# Trade.PositionsProcessedForIndexDividnds

> Tracks which positions have been processed for each dividend event. Each row equals one position paid for one dividend; PaymentAmount records the actual credit/debit. Active table despite the "Dividnds" typo.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | (PositionID, DividendID, ProcessTime) |
| **Partition** | PS_EndMonthIndex(ProcessTime) |
| **Live DB** | Exists, ~3,201 rows (ACTIVE) |
| **Indexes** | PK clustered, IDX_TPPFID_ProcessTime_BIGINT1, IX_DividendID, IX_PPFD_CreditID |

---

## 1. Business Meaning

Trade.PositionsProcessedForIndexDividnds is the central tracking table for dividend payments to positions. When a dividend event (Trade.IndexDividends) is processed, the system identifies eligible positions and credits or debits them. Each row records that a specific PositionID was paid (or debited, for short positions) for a specific DividendID at a given ProcessTime. PaymentAmount holds the actual amount credited/debited; negative values indicate short-position adjustments. CreditID links to the credit transaction record.

This table exists so the dividend pipeline can avoid double-paying and can report how many positions were paid per dividend. Without it, there would be no audit trail of which positions received which dividends. The typo "Dividnds" in the name is inherited; the table is actively used and should not be renamed without a migration plan.

---

## 2. Business Logic

### 2.1 One Row Per Position Per Dividend

**What**: Each (PositionID, DividendID, ProcessTime) combination is unique.

**Columns/Parameters Involved**: `PositionID`, `DividendID`, `ProcessTime`

**Rules**:
- One row per position per dividend per processing run
- ProcessTime defaults to getutcdate() at insert
- PK ensures no duplicate payments

### 2.2 PaymentAmount Sign

**What**: PaymentAmount is positive for long positions (credit) and can be negative for short positions (debit).

**Columns/Parameters Involved**: `PaymentAmount`

**Rules**:
- Long (buy) positions: PaymentAmount > 0, credited to customer
- Short (sell) positions: PaymentAmount < 0, debited from customer

### 2.3 Partitioning by ProcessTime

**What**: Table is partitioned by ProcessTime for efficient archival and range queries.

**Columns/Parameters Involved**: `ProcessTime`

**Rules**:
- Partition scheme PS_EndMonthIndex(ProcessTime)
- Indexes ON PS_EndMonthIndex(ProcessTime) support partition elimination

---

## 3. Data Overview

| PositionID | DividendID | ProcessTime | PaymentAmount | CreditID | BuyTax | SellTax | Meaning |
|------------|------------|-------------|---------------|----------|--------|---------|---------|
| 2150264818 | 132 | 2026-03-12 | 0.33 | 2174648725 | 0.27 | 0.46 | Long position paid 0.33, tax rates applied |
| - | - | - | -0.17 | - | - | - | Short position: negative PaymentAmount (debit) |

**Live data**: ~3,201 rows. Mix of long and short positions. CreditID links to credit transaction.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | FK to Trade.PositionTbl (logical). Position that received the dividend. |
| 2 | DividendID | int | NO | - | CODE-BACKED | FK to Trade.IndexDividends. Dividend event. |
| 3 | ProcessTime | datetime | NO | getutcdate() | CODE-BACKED | When this position was processed for this dividend. Partition key. |
| 4 | PaymentAmount | money | YES | - | CODE-BACKED | Amount credited (positive) or debited (negative). |
| 5 | CreditID | bigint | YES | - | CODE-BACKED | Links to credit transaction record. |
| 6 | BuyTax | decimal(16,8) | YES | - | CODE-BACKED | Tax rate applied for buy-side positions. |
| 7 | SellTax | decimal(16,8) | YES | - | CODE-BACKED | Tax rate applied for sell-side positions. |

---

## 5. Relationships

### 5.1 References To

- Trade.PositionTbl (PositionID) - Position that was paid
- Trade.IndexDividends (DividendID) - Dividend event
- Credit table (CreditID) - Credit transaction (implicit)

### 5.2 Referenced By

- Trade.GetPayedDividendsAndPositions - Reader
- Trade.PayDividendsForPositions - Writer
- Trade.MarkDividendPositionAsPaid - Writer
- Trade.GetDividendNumPaidPositions - Reader
- Trade.GetDividendPaidPositionsHash - Reader

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.IndexDividends, Trade.PositionTbl -> Trade.PositionsProcessedForIndexDividnds

### 6.1 Objects This Depends On

Trade.IndexDividends, Trade.PositionTbl

### 6.2 Objects That Depend On This

Trade.GetPayedDividendsAndPositions, Trade.PayDividendsForPositions, Trade.MarkDividendPositionAsPaid, Trade.GetDividendNumPaidPositions, Trade.GetDividendPaidPositionsHash

---

## 7. Technical Details

### 7.1 Indexes

- PK_TradePositionsProcessedForIndexDividnds_BIGINT1: CLUSTERED (PositionID, DividendID, ProcessTime) ON PS_EndMonthIndex(ProcessTime)
- IDX_TPPFID_ProcessTime_BIGINT1: (ProcessTime) ON PS_EndMonthIndex(ProcessTime)
- IX_DividendID: (DividendID) ON PS_EndMonthIndex(ProcessTime)
- IX_PPFD_CreditID: (CreditID) ON [PRIMARY]

### 7.2 Constraints

- PK: (PositionID, DividendID, ProcessTime)
- DEFAULT: ProcessTime = getutcdate()

---

*Generated: 2026-03-14 | Quality: 8.5/10*
