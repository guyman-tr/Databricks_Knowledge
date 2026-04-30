# History.GetHistoryDataForAll1To3Days

> Returns all closed positions within a 0-3 day date range in the legacy HistoryData bulk-export format, using History.ActiveCredit (not History.Credit) for credit enrichment of very recently closed positions. One of four age-range shards routed by History.GetHistoryDataForAll.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate/@ToDate (date range, DATEDIFF < 4 days intended); routed from History.GetHistoryDataForAll |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **0-to-3-day shard** of the `GetHistoryDataForAll` family, specifically designed for very recently closed positions. Unlike the other three age-range variants (4To9Days, 10To19Days, MoreThen20Days), this procedure joins `History.ActiveCredit` instead of `History.Credit` because positions closed within the last 3 days may have close credits that have not yet been migrated from the active credit buffer to the archived credit view.

Two additional behavioral differences distinguish this variant: `GameName` is always returned as an empty string `''` (no `Dictionary.GameType` join), and the credit join includes an additional date filter `histCredit.Occurred > @FromDate` (appearing in both the JOIN condition and the WHERE clause - the WHERE occurrence is a redundant duplicate from the FB 25351 fix).

The change history note `--Geri Reshef, 13/03/2015, FB: 25351 (EndDateTime => CloseOccurred, double appearance of History.Position)` documents a prior bug fix.

---

## 2. Business Logic

### 2.1 Date Range Filter on CloseOccurred

**What**: Filters positions closed within the very recent window (intended < 4 days).

**Rules**: `WHERE History.Position.CloseOccurred >= @FromDate AND History.Position.CloseOccurred <= @ToDate AND histCredit.Occurred > @FromDate AND histCredit.CreditTypeID = 4`

### 2.2 History.ActiveCredit (not History.Credit) for Recent Credits

**What**: The most important behavioral difference vs sibling procedures.

**Rules**: JOIN `History.ActiveCredit` on `PositionID AND histCredit.Occurred > @FromDate AND histCredit.CreditTypeID = 4`.

Very recently closed positions (< 3 days) still have their CreditTypeID=4 close credits in `History.ActiveCredit` before the archival batch migrates them to `History.Credit`. Using ActiveCredit here ensures these positions are not missed due to archival lag.

The `histCredit.Occurred > @FromDate` filter in the JOIN condition is redundant with the same filter in the WHERE clause (FB 25351 legacy artifact).

### 2.3 GameName Always Empty String

**What**: Unlike sibling procedures that JOIN `Dictionary.GameType`, this procedure returns `'' AS GameName`.

**Rules**: No ForexResult or GameType join. The GameName column is always an empty string.

This is likely an optimization (skipping the join for the most recent positions) or an oversight retained from the FB 25351 fix that removed a double join.

### 2.4 Profit and Gain

Same as sibling procedures:
**Profit**: `CAST(NetProfit + Commission AS FLOAT)`
**Gain**: `CAST(ISNULL(CAST(NetProfit+Commission AS FLOAT)/NULLIF(CAST(Amount AS FLOAT),0)*100,0) AS FLOAT)`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of CloseOccurred date range. Intended for ranges < 4 calendar days when called via GetHistoryDataForAll. Also used as the lower bound for histCredit.Occurred filter. |
| 2 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of CloseOccurred date range. |

**Result set columns** (same schema as GetHistoryDataForAll4To9Days except GameName is always ''):

| Column | Source | Description |
|--------|--------|-------------|
| PositionID | History.Position | Unique position identifier |
| GameName | Hardcoded '' | Always empty string (no GameType join in this variant) |
| IsBuy | History.Position.IsBuy | 1=Buy/Long, 0=Sell/Short |
| CurrencyBuy/CurrencySell | Trade.Instrument | Buy/sell currency IDs |
| BuyCurAbbreviation/SellCurAbbreviation | Dictionary.Currency | Currency codes |
| BuyCurrencyTypeID/SellCurrencyTypeID | Dictionary.Currency | Currency type IDs |
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
| ParentPositionID | History.Position.ParentPositionID (ISNULL 0) | Copy trade parent |
| OrigParentPositionID | History.Position.OrigParentPositionID (ISNULL 0) | Original parent |
| MirrorID | History.Position.MirrorID (ISNULL 0) | Mirror ID |
| Leverage | History.Position.Leverage | Leverage ratio |
| Credit | History.ActiveCredit.Credit | Close credit amount (from active credit buffer) |
| CloseOnEndOfWeek | History.Position.CloseOnEndOfWeek (ISNULL 0) | 1 if auto-closed at end of week |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary source; filtered by CloseOccurred date range. |
| JOIN | History.ActiveCredit | Read | INNER JOIN for CreditTypeID=4 close credits (active/recent credit buffer). |
| JOIN | Trade.Instrument | Lookup | Buy/sell currency IDs. |
| JOIN | Dictionary.Currency (x2) | Lookup | Currency abbreviations and type IDs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.GetHistoryDataForAll | EXEC | Router call | Invoked when DATEDIFF(dd, @FromDate, @EndDate) < 4. Also invoked as fallback (empty result) when @FromDate > @EndDate. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetHistoryDataForAll1To3Days (procedure)
├── History.Position (table)
├── History.ActiveCredit (table) [NOT History.Credit - recent credits only]
├── Trade.Instrument (table) [cross-schema]
└── Dictionary.Currency (table) [cross-schema - x2]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Main source filtered by CloseOccurred date range. |
| History.ActiveCredit | Table | INNER JOIN for CreditTypeID=4 close credits in the active (not yet archived) credit buffer. |
| Trade.Instrument | Table | Buy/sell currency IDs. |
| Dictionary.Currency | Table | Currency abbreviations and type IDs (x2). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetHistoryDataForAll | Procedure | Routes here for date ranges < 4 days; also used as empty-result fallback. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| History.ActiveCredit (not History.Credit) | Key design difference | Serves positions whose close credits haven't yet migrated to History.Credit archive. |
| GameName always '' | Known limitation | No GameType join means GameName is always empty in this variant; sibling procedures return the real GameType name. |
| Duplicate histCredit.Occurred filter | Legacy artifact | The `histCredit.Occurred > @FromDate` filter appears in both JOIN and WHERE; the WHERE occurrence is redundant (FB 25351 fix artifact). |
| Fallback empty result | Design | When DATEDIFF < 0 (invalid range), GetHistoryDataForAll calls this procedure WITH RECOMPILE to return an empty result set. |

---

## 8. Sample Queries

### 8.1 Get history for a 2-day range (typically via orchestrator)

```sql
-- Direct call
EXEC History.GetHistoryDataForAll1To3Days
    @FromDate = '2026-03-19',
    @ToDate = '2026-03-21';

-- Preferred: via orchestrator
EXEC History.GetHistoryDataForAll
    @FromDate = '2026-03-19',
    @EndDate = '2026-03-21';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetHistoryDataForAll1To3Days | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetHistoryDataForAll1To3Days.sql*
