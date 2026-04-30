# History.GetHistoryDataForAllMoreThen20Days

> Returns all closed positions within a 20+ day date range in the legacy HistoryData bulk-export format, joining History.Credit for close credit enrichment. One of four age-range shards routed by History.GetHistoryDataForAll.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate/@ToDate (date range, DATEDIFF >= 20 days intended); routed from History.GetHistoryDataForAll |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **20-plus-day shard** of the `GetHistoryDataForAll` family, intended for wider date ranges such as monthly or quarterly exports. It is structurally identical to `GetHistoryDataForAll4To9Days` and `GetHistoryDataForAll10To19Days` - all three use `History.Credit` and join `Dictionary.GameType` via the ForexResult UNION. The separation into age-range variants was designed for SQL Server query-plan optimization (each variant can have its own index hints or execution plan tuned for its expected data volume).

See `History.GetHistoryDataForAll` for the routing logic and full family overview.

---

## 2. Business Logic

Identical to `GetHistoryDataForAll10To19Days`:
- `WHERE History.Position.CloseOccurred >= @FromDate AND CloseOccurred <= @ToDate AND histCredit.CreditTypeID = 4`
- INNER JOIN `History.Credit` on PositionID
- UNION of `History.ForexResult` and `Game.ForexResult` for GameTypeID
- Same column list and calculations

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of CloseOccurred date range. Intended for ranges of 20+ calendar days when called via GetHistoryDataForAll. |
| 2 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of CloseOccurred date range. |

**Result set columns**: Identical to `GetHistoryDataForAll10To19Days` - PositionID, GameName, IsBuy, CurrencyBuy/Sell, Abbreviations, TypeIDs, OpenDate, CloseDate, Amount, Units, OpenRate, CloseRate, Spread, Profit, Gain, LimitRate, StopRate, CID, ParentPositionID, OrigParentPositionID, MirrorID, Leverage, Credit, CloseOnEndOfWeek.

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
| History.GetHistoryDataForAll | EXEC | Router call | Invoked when DATEDIFF(dd, @FromDate, @EndDate) >= 20. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetHistoryDataForAllMoreThen20Days (procedure)
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
| History.GetHistoryDataForAll | Procedure | Routes here for date ranges >= 20 days. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| History.Credit (not ActiveCredit) | Age assumption | Positions 20+ days old are fully archived. |
| Wide range performance | Risk | For very large ranges (months, years), the History.Position CloseOccurred scan combined with History.Credit join may be slow without appropriate index coverage. |

---

## 8. Sample Queries

### 8.1 Get history for a monthly range (typically via orchestrator)

```sql
EXEC History.GetHistoryDataForAll
    @FromDate = '2024-01-01',
    @EndDate = '2024-01-31';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetHistoryDataForAllMoreThen20Days | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetHistoryDataForAllMoreThen20Days.sql*
