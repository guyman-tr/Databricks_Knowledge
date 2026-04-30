# History.GetHistoryDataForAll4To9Days

> Returns all closed positions within a 4-9 day date range in the legacy HistoryData bulk-export format, joining History.Credit for close credit enrichment. One of four age-range shards routed by History.GetHistoryDataForAll.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate/@ToDate (date range, DATEDIFF 4-9 days intended); routed from History.GetHistoryDataForAll |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **4-to-9-day shard** of the `GetHistoryDataForAll` family. It returns closed positions within a caller-supplied date range using `History.Credit` (the archived credit view) for credit enrichment. Positions in this age range are expected to have their CreditTypeID=4 close credits fully migrated from `History.ActiveCredit` to `History.Credit`.

It is structurally identical to `GetHistoryDataForAll10To19Days` and `GetHistoryDataForAllMoreThen20Days`. The primary distinction from `GetHistoryDataForAll1To3Days` is using `History.Credit` instead of `History.ActiveCredit`, and returning a real GameName (via GameType join).

See `History.GetHistoryDataForAll` for the routing logic and full family overview.

---

## 2. Business Logic

### 2.1 Date Range Filter and Credit Join

Same as `GetHistoryDataForAll10To19Days`:
- `WHERE History.Position.CloseOccurred >= @FromDate AND CloseOccurred <= @ToDate AND histCredit.CreditTypeID = 4`
- INNER JOIN `History.Credit` on PositionID for Credit field

### 2.2 Game.ForexResult UNION

Same as `GetHistoryDataForAll10To19Days`: UNION of History.ForexResult and Game.ForexResult for GameTypeID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of CloseOccurred date range. Intended for ranges of 4-9 calendar days when called via GetHistoryDataForAll. |
| 2 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of CloseOccurred date range. |

**Result set columns**: Identical to `GetHistoryDataForAll10To19Days` - see that procedure's Section 4 for full column list (PositionID, GameName, IsBuy, CurrencyBuy/Sell, Abbreviations, TypeIDs, OpenDate, CloseDate, Amount, Units, OpenRate, CloseRate, Spread, Profit, Gain, LimitRate, StopRate, CID, ParentPositionID, OrigParentPositionID, MirrorID, Leverage, Credit, CloseOnEndOfWeek).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary source; filtered by CloseOccurred. |
| JOIN | History.Credit | Read | INNER JOIN for CreditTypeID=4 close credits. |
| JOIN | History.ForexResult UNION Game.ForexResult | Read | Game type resolution. |
| JOIN | Dictionary.GameType | Lookup | Game name. |
| JOIN | Trade.Instrument | Lookup | Currency IDs. |
| JOIN | Dictionary.Currency (x2) | Lookup | Currency abbreviations and type IDs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.GetHistoryDataForAll | EXEC | Router call | Invoked when DATEDIFF(dd, @FromDate, @EndDate) is between 4 and 9. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetHistoryDataForAll4To9Days (procedure)
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
| History.Position | Table | Main source filtered by CloseOccurred. |
| History.Credit | View | INNER JOIN for CreditTypeID=4 close credits. |
| History.ForexResult | Table | UNION for game type. |
| Game.ForexResult | Table | UNION for game type. |
| Dictionary.GameType | Table | Game name. |
| Trade.Instrument | Table | Currency IDs. |
| Dictionary.Currency | Table | Currency abbreviations and type IDs (x2). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetHistoryDataForAll | Procedure | Routes here for date ranges 4-9 days. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| History.Credit (not ActiveCredit) | Age assumption | Positions 4-9 days old are assumed to have archived credits in History.Credit. |

---

## 8. Sample Queries

### 8.1 Get history for a 7-day range (typically via orchestrator)

```sql
EXEC History.GetHistoryDataForAll
    @FromDate = '2026-03-14',
    @EndDate = '2026-03-21';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetHistoryDataForAll4To9Days | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetHistoryDataForAll4To9Days.sql*
