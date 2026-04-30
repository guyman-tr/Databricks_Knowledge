# History.GetHistoryReportByCIDAndDates

> Returns a customer's closed positions opened within a date range in a report-enriched format: includes CopyTrader leader name, credit TotalCash, instrument price precision (from Trade.ProviderToInstrument), and EndOfWeekFee. No row count limit.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (single customer) + @BeginDate/@EndDate date range on OpenOccurred/EndDateTime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a **per-customer history report** that returns all closed positions for a specific customer opened within a date range, enriched with CopyTrader context (leader name), credit summary (TotalCash), instrument price precision, and the EndOfWeekFee charged at position close. It is the most complete of the per-customer history procedures, adding columns not available in `GetHistoryDataByCID`.

Key differences from `GetHistoryDataByCID`:
- Adds `CopyTrader Name`, `TotalCash`, `Precision`, `EndOfWeekFee`
- Filters by `OpenOccurred >= @BeginDate AND EndDateTime < @EndDate` (open date, not close date)
- Returns ALL matching positions (no TOP N)
- Joins `Trade.ProviderToInstrument` for price precision
- Profit = `NetProfit` only (Commission is commented out of the formula)

---

## 2. Business Logic

### 2.1 Date Filter - Open Date vs Close Date

**What**: Filters positions by when they were OPENED (not closed) within the date range.

**Rules**:
- `HP.OpenOccurred >= @BeginDate` - position opened on or after start date
- `HP.EndDateTime < @EndDate` - position archived before end date (strict less-than)
- Note: `EndDateTime` is the archive timestamp, not `CloseOccurred` (actual close time)

This returns positions that OPENED in the window and have been archived. A position opened at the start of the range but closed much later would still appear if EndDateTime < @EndDate.

### 2.2 CopyTrader Name via History.Mirror

**What**: Resolves the CopyTrader leader's username for each position.

**Rules**: `LEFT JOIN (SELECT DISTINCT MirrorID, ParentUserName FROM History.Mirror WHERE CID = @CID) Mirror ON HP.MirrorID = Mirror.MirrorID`

Returns `ISNULL(Mirror.ParentUserName,'')` as `CopyTrader Name`. Empty string for non-copy positions. DISTINCT on MirrorID+ParentUserName to avoid row multiplication from multiple Mirror records.

### 2.3 TotalCash from History.Credit

**What**: Retrieves the TotalCash value from the CreditTypeID=4 (Close Position) credit.

**Rules**: INNER JOIN `History.Credit` on `PositionID AND CreditTypeID = 4`. Returns `histCredit.TotalCash`.

`TotalCash` = running account balance at the time of the close credit.

### 2.4 Precision from Trade.ProviderToInstrument

**What**: Returns the price precision for the instrument.

**Rules**: JOIN `Trade.ProviderToInstrument ON InstrumentID = HP.InstrumentID`. Returns `Precision`.

Note: No provider filter is applied. If multiple providers exist for the same instrument, this JOIN may produce duplicate rows (potential row multiplication issue).

### 2.5 Profit Formula (Commission Commented Out)

**What**: Profit uses only NetProfit; Commission is excluded (commented out).

**Rules**: `CAST(NetProfit/*+Commission*/ AS FLOAT) AS Profit`

**Inconsistency**: The `Gain` formula still includes Commission: `CAST(NetProfit*100+Commission*100 AS INT)`. This means Profit and Gain are calculated differently in this procedure. For positions with non-zero Commission, Gain reflects Profit+Commission while Profit does not include Commission.

### 2.6 EndOfWeekFee

**What**: Returns `HP.EndOfWeekFee` - the overnight/rollover fee charged when a position was closed at end-of-week.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters both History.Position.CID and History.Mirror.CID for CopyTrader name lookup. |
| 2 | @BeginDate | DATETIME | NO | - | CODE-BACKED | Start of range filter on History.Position.OpenOccurred (position open date, not close date). |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of range filter on History.Position.EndDateTime (strict less-than). Note: this is the archive timestamp, not CloseOccurred. |

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| PositionID | History.Position | Unique position identifier |
| CopyTrader Name | History.Mirror.ParentUserName | Leader's username (empty string if not a copy trade) |
| GameName | Dictionary.GameType.Name | Game type name |
| IsBuy | History.Position.IsBuy | 1=Buy/Long, 0=Sell/Short |
| CurrencyBuy | Trade.Instrument.BuyCurrencyID | Buy currency ID |
| CurrencySell | Trade.Instrument.SellCurrencyID | Sell currency ID |
| BuyCurAbbreviation | Dictionary.Currency.Abbreviation | Buy currency code |
| SellCurAbbreviation | Dictionary.Currency.Abbreviation | Sell currency code |
| BuyCurrencyTypeID | Dictionary.Currency.CurrencyTypeID | Buy currency type |
| SellCurrencyTypeID | Dictionary.Currency.CurrencyTypeID | Sell currency type |
| OpenDate | History.Position.InitDateTime | Open timestamp (InitDateTime, not OpenOccurred) |
| CloseDate | History.Position.EndDateTime | Close/archive timestamp |
| Amount | History.Position.Amount (FLOAT) | Invested amount |
| Units | History.Position.AmountInUnitsDecimal | Units traded |
| OpenRate | History.Position.InitForexRate (DOUBLE) | Opening exchange rate |
| CloseRate | History.Position.EndForexRate (DOUBLE) | Closing exchange rate |
| Spread | History.Position.Commission*100 (INT) | Commission in basis points |
| Profit | History.Position.NetProfit (FLOAT) | Net P&L (Commission NOT included - see Section 2.5) |
| Gain | (NetProfit+Commission)/Amount*100 | Percentage return (includes Commission - inconsistent with Profit) |
| LimitRate | History.Position.LimitRate | Take-profit rate |
| StopRate | History.Position.StopRate | Stop-loss rate |
| Leverage | History.Position.Leverage | Leverage ratio |
| TotalCash | History.Credit.TotalCash | Running account balance at position close (from CreditTypeID=4 credit) |
| Precision | Trade.ProviderToInstrument.Precision | Instrument price decimal precision |
| EndOfWeekFee | History.Position.EndOfWeekFee | Overnight/rollover fee charged at end-of-week close |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary source; filtered by CID + date range (OpenOccurred + EndDateTime). |
| JOIN | History.Credit | Read | INNER JOIN for CreditTypeID=4 close credits; returns TotalCash. |
| JOIN | History.ForexResult UNION Game.ForexResult | Read | Game type ID. |
| JOIN | Dictionary.GameType | Lookup | Game name. |
| JOIN | Trade.Instrument | Lookup | Currency IDs. |
| JOIN | Dictionary.Currency (x2) | Lookup | Currency abbreviations and type IDs. |
| LEFT JOIN | History.Mirror | Read | CopyTrader leader name (DISTINCT by MirrorID, filtered by CID). |
| JOIN | Trade.ProviderToInstrument | Lookup | Instrument price precision. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Position history / account statement API | EXEC | Direct call | Per-customer detailed history report with CopyTrader context and precision data. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetHistoryReportByCIDAndDates (procedure)
├── History.Position (table)
├── History.Credit (view)
├── History.Mirror (table)
├── History.ForexResult (table) [game type]
├── Game.ForexResult (table) [game type]
├── Dictionary.GameType (table) [cross-schema]
├── Trade.Instrument (table) [cross-schema]
├── Dictionary.Currency (table) [cross-schema - x2]
└── Trade.ProviderToInstrument (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Main source filtered by CID, OpenOccurred, EndDateTime. |
| History.Credit | View | INNER JOIN for CreditTypeID=4 TotalCash. |
| History.Mirror | Table | LEFT JOIN (DISTINCT by MirrorID, CID filter) for ParentUserName. |
| History.ForexResult | Table | UNION branch for game type. |
| Game.ForexResult | Table | UNION branch for game type. |
| Dictionary.GameType | Table | Game name lookup. |
| Trade.Instrument | Table | Buy/sell currency IDs. |
| Dictionary.Currency | Table | Currency abbreviations and type IDs (x2). |
| Trade.ProviderToInstrument | Table | Instrument price precision. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Position history / account statement reporting (application) | External | Detailed per-customer history with CopyTrader and credit data. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Profit/Gain inconsistency | Known issue | Profit = NetProfit only (Commission commented out). Gain = (NetProfit+Commission)/Amount*100. These formulas are inconsistent for positions with non-zero Commission. |
| ProviderToInstrument row multiplication | Risk | No provider filter on Trade.ProviderToInstrument; if multiple providers serve the same instrument, duplicate rows may appear. |
| OpenOccurred filter (not CloseOccurred) | Caller note | Date range filters on position OPEN date, not close date. Positions opened in the range but closed after @EndDate do NOT appear (excluded by EndDateTime < @EndDate). |
| InitDateTime for OpenDate | Column note | OpenDate comes from InitDateTime, not OpenOccurred. These differ when a position was pre-calculated before being formally opened. |

---

## 8. Sample Queries

### 8.1 Get history report for a customer in Q1 2024

```sql
EXEC History.GetHistoryReportByCIDAndDates
    @CID = 12345,
    @BeginDate = '2024-01-01',
    @EndDate = '2024-04-01';
```

### 8.2 Verify position count for the same date range

```sql
SELECT COUNT(*) AS PositionCount
FROM History.Position HP WITH (NOLOCK)
WHERE HP.CID = 12345
  AND HP.OpenOccurred >= '2024-01-01'
  AND HP.EndDateTime < '2024-04-01';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetHistoryReportByCIDAndDates | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetHistoryReportByCIDAndDates.sql*
