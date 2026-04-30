# History.GetHistoryDataForAll10To19Days

> Returns all closed positions within a 10-19 day date range in the legacy HistoryData bulk-export format, joining History.Credit for credit enrichment. One of four age-range shards routed by History.GetHistoryDataForAll.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate/@ToDate (date range, DATEDIFF 10-19 days intended); routed from History.GetHistoryDataForAll |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **10-to-19-day shard** of the `GetHistoryDataForAll` family. It returns closed positions from `History.Position` within a caller-supplied date range, enriched with instrument, currency, and credit (CreditTypeID=4 close credit) data. It is one of four structurally identical age-range variants (`1To3Days`, `4To9Days`, `10To19Days`, `MoreThen20Days`) that `History.GetHistoryDataForAll` routes between based on the date range span. Using different procedures for different age ranges allows each to be tuned for its target partition or archive table.

The legacy comment `// public List<HistoryDataForAll> getHistoryReportForAll(string db, DateTime from, DateTime to)` on `GetHistoryDataForAll` confirms these feed a Java/.NET batch history export web service endpoint.

---

## 2. Business Logic

### 2.1 Date Range Filter on CloseOccurred

**What**: Filters positions by `CloseOccurred BETWEEN @FromDate AND @ToDate`.

**Rules**: `WHERE History.Position.CloseOccurred >= @FromDate AND History.Position.CloseOccurred <= @ToDate AND histCredit.CreditTypeID = 4`

Uses `CloseOccurred` (actual close time), unlike `GetHistoryDataByCID` which uses `EndDateTime`.

### 2.2 CreditTypeID=4 Credit Join Enrichment

**What**: JOINs `History.Credit` to retrieve the close credit record (CreditTypeID=4 = Close Position) for each position.

**Rules**: INNER JOIN `History.Credit` on `PositionID` AND `CreditTypeID = 4`. Returns `Credit` field from the credit record.

Note: This procedure (and 4To9Days, MoreThen20Days) uses `History.Credit`. The `1To3Days` variant uses `History.ActiveCredit` instead, since very recent close credits may not yet be archived.

### 2.3 Game.ForexResult UNION for GameType

**What**: Resolves GameTypeID from both History and Game schema ForexResult tables.

**Rules**: `UNION` of `History.ForexResult` and `Game.ForexResult` joined by ForexResultID.

### 2.4 Profit and Gain

**Profit**: `CAST(NetProfit + Commission AS FLOAT)`
**Gain**: `CAST(ISNULL(CAST(NetProfit+Commission AS FLOAT)/NULLIF(CAST(Amount AS FLOAT),0)*100,0) AS FLOAT)` - returns 0 on null/divide-by-zero.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of CloseOccurred date range. Intended for ranges of 10-19 calendar days when called via GetHistoryDataForAll. |
| 2 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of CloseOccurred date range. |

**Result set columns** (common to all GetHistoryDataForAll* variants):

| Column | Source | Description |
|--------|--------|-------------|
| PositionID | History.Position | Unique position identifier |
| GameName | Dictionary.GameType.Name | Game type name |
| IsBuy | History.Position.IsBuy | 1=Buy/Long, 0=Sell/Short |
| CurrencyBuy | Trade.Instrument.BuyCurrencyID | Buy currency ID |
| CurrencySell | Trade.Instrument.SellCurrencyID | Sell currency ID |
| BuyCurAbbreviation | Dictionary.Currency.Abbreviation | Buy currency code |
| SellCurAbbreviation | Dictionary.Currency.Abbreviation | Sell currency code |
| BuyCurrencyTypeID | Dictionary.Currency.CurrencyTypeID | Buy currency type |
| SellCurrencyTypeID | Dictionary.Currency.CurrencyTypeID | Sell currency type |
| OpenDate | History.Position.OpenOccurred | Open timestamp |
| CloseDate | History.Position.CloseOccurred | Actual close timestamp |
| Amount | History.Position.Amount (FLOAT) | Invested amount |
| Units | History.Position.AmountInUnitsDecimal | Units traded |
| OpenRate | History.Position.InitForexRate | Opening rate |
| CloseRate | History.Position.EndForexRate | Closing rate |
| Spread | History.Position.Commission*100 | Commission in basis points |
| Profit | NetProfit+Commission (FLOAT) | Net P&L |
| Gain | (NetProfit+Commission)/Amount*100 | Percentage return |
| LimitRate | History.Position.LimitRate | Take-profit rate |
| StopRate | History.Position.StopRate | Stop-loss rate |
| CID | History.Position.CID | Customer ID |
| ParentPositionID | History.Position.ParentPositionID (ISNULL to 0) | Copy trade parent position |
| OrigParentPositionID | History.Position.OrigParentPositionID (ISNULL to 0) | Original parent (detach tracking) |
| MirrorID | History.Position.MirrorID (ISNULL to 0) | CopyTrader mirror ID |
| Leverage | History.Position.Leverage | Leverage ratio |
| Credit | History.Credit.Credit | Credit amount from the CreditTypeID=4 close credit record |
| CloseOnEndOfWeek | History.Position.CloseOnEndOfWeek (ISNULL to 0) | 1 if auto-closed at end of week |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary source; filtered by CloseOccurred date range. |
| JOIN | History.Credit | Read | INNER JOIN on PositionID for CreditTypeID=4 close credits. Returns Credit field. |
| JOIN | History.ForexResult UNION Game.ForexResult | Read | Game type ID resolution. |
| JOIN | Dictionary.GameType | Lookup | Game name. |
| JOIN | Trade.Instrument | Lookup | Buy/sell currency IDs. |
| JOIN | Dictionary.Currency (x2) | Lookup | Currency abbreviations and type IDs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.GetHistoryDataForAll | EXEC | Router call | Invoked when DATEDIFF(dd, @FromDate, @EndDate) is between 10 and 19. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetHistoryDataForAll10To19Days (procedure)
├── History.Position (table)
├── History.Credit (view)
├── History.ForexResult (table) [game type]
├── Game.ForexResult (table) [game type]
├── Dictionary.GameType (table) [cross-schema]
├── Trade.Instrument (table) [cross-schema]
└── Dictionary.Currency (table) [cross-schema - x2]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Main source filtered by CloseOccurred date range. |
| History.Credit | View | INNER JOIN for CreditTypeID=4 close credit (Credit field). |
| History.ForexResult | Table | UNION branch for game type. |
| Game.ForexResult | Table | UNION branch for game type. |
| Dictionary.GameType | Table | Game name lookup. |
| Trade.Instrument | Table | Buy/sell currency IDs. |
| Dictionary.Currency | Table | Currency abbreviations and type IDs (x2). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetHistoryDataForAll | Procedure | Routes here when date range is 10-19 days. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| History.Credit (not ActiveCredit) | Age-range design | Uses the archived credit view; positions 10-19 days old are expected to be fully archived. GetHistoryDataForAll1To3Days uses History.ActiveCredit for very recent credits. |
| No parameter validation | Caller responsibility | No enforcement that @FromDate < @ToDate or that the range is 10-19 days. Caller (GetHistoryDataForAll) is responsible for routing. |

---

## 8. Sample Queries

### 8.1 Get history for a 15-day range (typically via orchestrator)

```sql
-- Direct call (bypasses GetHistoryDataForAll routing)
EXEC History.GetHistoryDataForAll10To19Days
    @FromDate = '2024-12-01',
    @ToDate = '2024-12-15';

-- Preferred: via orchestrator (routes automatically)
EXEC History.GetHistoryDataForAll
    @FromDate = '2024-12-01',
    @EndDate = '2024-12-15';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetHistoryDataForAll10To19Days | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetHistoryDataForAll10To19Days.sql*
