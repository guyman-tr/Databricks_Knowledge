# Operational.GetSettlementDateForTrade

> Looks up the settlement date for a given symbol and trade date from Apex trade activity data, returning distinct settlement dates for buy/sell trades.

| Property | Value |
|----------|-------|
| **Schema** | Operational |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns settlement date information |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides an operational lookup for settlement dates. Given a stock symbol and trade date, it queries the Apex EXT872 Trade Activity table to find the corresponding settlement date. This is useful for operations teams who need to know when a specific trade will settle (typically T+1 for US equities).

The procedure filters for actual buy ('B') and sell ('S') trades only, excluding other trade types (corrections, cancellations, etc.). It uses case-insensitive symbol matching.

---

## 2. Business Logic

### 2.1 Settlement Date Lookup

**What**: Finds settlement dates from Apex trade records for a specific symbol and trade date.

**Columns/Parameters Involved**: `@Symbol`, `@TradeDate`, `BuySellCode`, `SettlementDate`

**Rules**:
- Only includes trades with BuySellCode IN ('B', 'S') - actual buys and sells
- Symbol comparison is case-insensitive (LOWER on both sides)
- Returns DISTINCT results to eliminate duplicates when multiple trades exist for the same symbol/date
- Uses NOLOCK for non-blocking read

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Symbol | VARCHAR(10) | NO | - | CODE-BACKED | Ticker symbol to look up (case-insensitive). |
| 2 | @TradeDate | DATE | NO | - | CODE-BACKED | Trade date to find settlement date for. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Symbol | varchar(35) | YES | - | CODE-BACKED | Ticker symbol from the trade record. |
| 2 | ProcessDate | datetime2(7) | YES | - | CODE-BACKED | Business processing date of the trade file. |
| 3 | TradeDate | datetime2(7) | YES | - | CODE-BACKED | Execution date of the trade. |
| 4 | SettlementDate | datetime2(7) | YES | - | CODE-BACKED | Settlement date - when the trade settles (typically T+1 for US equities). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| N/A | apex.EXT872_TradeActivity | Read | Queries trade activity for settlement dates |

### 5.2 Referenced By (other objects point to this)

No known callers in SSDT. Likely called ad-hoc by operations staff.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Operational.GetSettlementDateForTrade (procedure)
└── apex.EXT872_TradeActivity (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.EXT872_TradeActivity | Table | READER - queries for settlement dates |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up settlement date for AAPL trade

```sql
EXEC Operational.GetSettlementDateForTrade @Symbol = 'AAPL', @TradeDate = '2026-04-10';
```

### 8.2 Check settlement for multiple symbols

```sql
EXEC Operational.GetSettlementDateForTrade @Symbol = 'TSLA', @TradeDate = '2026-04-10';
EXEC Operational.GetSettlementDateForTrade @Symbol = 'MSFT', @TradeDate = '2026-04-10';
```

### 8.3 Equivalent direct query

```sql
SELECT DISTINCT Symbol, ProcessDate, TradeDate, SettlementDate
FROM apex.EXT872_TradeActivity WITH (NOLOCK)
WHERE BuySellCode IN ('B','S')
  AND LOWER(Symbol) = LOWER('AAPL')
  AND TradeDate = '2026-04-10';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Operational.GetSettlementDateForTrade | Type: Stored Procedure | Source: Sodreconciliation/Sodreconciliation/Operational/Stored Procedures/Operational.GetSettlementDateForTrade.sql*
