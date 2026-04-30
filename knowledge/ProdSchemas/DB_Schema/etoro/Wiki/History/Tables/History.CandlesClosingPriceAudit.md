# History.CandlesClosingPriceAudit

> Manual audit log for corrections to candle closing prices; each row records who changed a closing price for which instrument and date, capturing both the previous and new bid/ask values.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on ID) |

---

## 1. Business Meaning

History.CandlesClosingPriceAudit is a manually-written audit log (not a SQL Server temporal table) that records corrections made to candle closing prices in eToro's pricing system. When a back-office operator or system process corrects an erroneous or stale closing price for an instrument on a specific date, the change is logged here with the old and new bid/ask values, the timestamp, and the username making the change.

Candle closing prices are used for daily mark-to-market, portfolio valuations, and historical charting. Incorrect closing prices can cause visible discrepancies in customer portfolio history and PnL calculations. This audit trail exists to provide accountability for any manual price corrections and to support post-correction investigations.

The table currently has 0 rows and no references in the codebase, suggesting the tool or process that was intended to write here either was never deployed or was replaced by another mechanism.

---

## 2. Business Logic

### 2.1 Manual Price Correction Audit

**What**: Each row records one correction event for one instrument's closing price on one date.

**Columns/Parameters Involved**: `DateOfChange`, `ClosingPriceDate`, `Username`, `InstrumentID`, `PreviousBid`, `PreviousAsk`, `NewBid`, `NewAsk`

**Rules**:
- DateOfChange: when the correction was applied (operational timestamp)
- ClosingPriceDate: the candle date whose closing price was corrected (business date being fixed)
- Username: the operator or service account that made the correction
- PreviousBid/PreviousAsk: the erroneous values that were in place before correction
- NewBid/NewAsk: the corrected values
- No unique constraint on (InstrumentID, ClosingPriceDate) - the same candle could theoretically be corrected multiple times
- Not connected to SQL Server SYSTEM_VERSIONING; written by application code or stored procedure that is not currently in the SSDT repo

---

## 3. Data Overview

The table is empty (0 rows). No procedure references found in the codebase.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY | CODE-BACKED | Surrogate primary key. Auto-incremented IDENTITY(1,1). Uniquely identifies each correction event. |
| 2 | DateOfChange | datetime | NO | - | CODE-BACKED | Timestamp when the price correction was applied. Operational timestamp - when the change was made, not the candle date being fixed. |
| 3 | ClosingPriceDate | datetime | NO | - | CODE-BACKED | The candle date whose closing price was corrected. The business date being rectified - e.g., 2024-03-15 end-of-day price for an instrument. |
| 4 | Username | varchar(255) | NO | - | CODE-BACKED | The operator login or service account that applied the correction. Provides accountability for manual price adjustments. |
| 5 | InstrumentID | int | NO | - | CODE-BACKED | The instrument whose closing price was corrected. Implicit FK to Trade.Instrument. |
| 6 | PreviousBid | decimal(16,8) | NO | - | CODE-BACKED | The erroneous bid price that was in place before the correction. Captured for audit and potential rollback. 8 decimal places for precision with crypto and fractional-priced instruments. |
| 7 | PreviousAsk | decimal(16,8) | NO | - | CODE-BACKED | The erroneous ask price before correction. Paired with PreviousBid to reconstruct the pre-correction spread. |
| 8 | NewBid | decimal(16,8) | NO | - | CODE-BACKED | The corrected bid price applied to the candle. |
| 9 | NewAsk | decimal(16,8) | NO | - | CODE-BACKED | The corrected ask price applied to the candle. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The instrument whose candle closing price was corrected |

### 5.2 Referenced By (other objects point to this)

No references found in the codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CandlesClosingPriceAudit (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HCCPA | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCCPA | PRIMARY KEY | ID - surrogate PK for each correction event |

Storage: ON [PRIMARY] filegroup with FILLFACTOR = 90.

---

## 8. Sample Queries

### 8.1 Get all corrections for a specific instrument
```sql
SELECT ID, DateOfChange, ClosingPriceDate, Username,
       PreviousBid, PreviousAsk, NewBid, NewAsk
FROM [History].[CandlesClosingPriceAudit]
WHERE InstrumentID = @InstrumentID
ORDER BY DateOfChange DESC
```

### 8.2 Find corrections for a specific candle date
```sql
SELECT InstrumentID, DateOfChange, Username,
       PreviousBid, PreviousAsk, NewBid, NewAsk
FROM [History].[CandlesClosingPriceAudit]
WHERE ClosingPriceDate = @ClosingPriceDate
ORDER BY InstrumentID
```

### 8.3 Recent correction activity
```sql
SELECT TOP 20 ID, InstrumentID, ClosingPriceDate, DateOfChange, Username,
       PreviousBid, NewBid, (NewBid - PreviousBid) AS BidDelta
FROM [History].[CandlesClosingPriceAudit]
ORDER BY DateOfChange DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 7.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no references in codebase) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CandlesClosingPriceAudit | Type: Table | Source: etoro/etoro/History/Tables/History.CandlesClosingPriceAudit.sql*
