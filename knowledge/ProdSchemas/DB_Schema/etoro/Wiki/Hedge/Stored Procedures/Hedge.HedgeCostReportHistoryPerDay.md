# Hedge.HedgeCostReportHistoryPerDay

> Computes the daily hedge cost report by aggregating and differencing history tables (CustomerClosedPositions, CustomerOpenPositions, AccountStatus) and account adjustments, producing a per-day per-server breakdown of client P&L, eToro commission, account P&L, and total hedge cost with percentage ratios.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Date, HedgeServerID, Customers P&L Realized/Unrealized, Commission Realized/Unrealized, Account P&L Realized/Unrealized, Hedge Cost Realized/Unrealized, Total Hedge Cost, Hedge Cost %, Adjustments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.HedgeCostReportHistoryPerDay` is the primary hedge cost reporting procedure. It answers the question: **"For each hedge server and each trading day, what did the hedge operation cost eToro?"**

The procedure assembles four data streams from the history tables - realized customer P&L, unrealized customer P&L (day-over-day delta), realized account P&L (Balance delta), and unrealized account P&L (NetPL delta) - then combines them with account transaction adjustments to compute:

- **Clients P&L Realized**: Total net profit/loss of positions customers closed in the period.
- **Etoro Commission Realized**: Commission collected when customers closed positions.
- **Clients P&L Unrealized**: Day-over-day change in the open position P&L mark-to-market.
- **Etoro Commission Unrealized**: Day-over-day change in commission accrued on open positions.
- **Account Diff Realized**: Day-over-day Balance change of the hedge account (the realized account-level cost).
- **Account P&L Unrealized**: Day-over-day NetPL change of the hedge account (the unrealized account-level cost).
- **Hedge Cost Realized/Unrealized**: Formula: ZeroPL - Account Diff (realized), Clients Unrealized - Account Unrealized.
- **Total Hedge Cost**: Sum of realized and unrealized hedge cost, plus Adjustments.
- **Hedge Cost %**: Total hedge cost as a fraction of total commission.

The final result set has one row per (HedgeServerID, Date) plus a TOTALS row (SUM across all servers) appended via UNION at `MAX(Date) + 1 minute`.

Called by `Hedge.HedgeCostReportHistoryShell` as the daily-granularity variant.

**Design notes**:
- Saturdays are excluded from all queries (`DATENAME(dw, OccurredAt) != 'Saturday'`) - markets are closed and would show artificial zero-P&L days.
- `@HedgeServerID = 0` means "all servers" (implemented via `CASE WHEN @HedgeServerID = 0 THEN HedgeServerID ELSE @HedgeServerID END`).
- Zero-row fallback: If any temp table query returns no rows, placeholder zeros are inserted from `Trade.HedgeServer` to ensure every active server appears in the output.
- `Rebate` is always 0 in both the per-row and totals rows. A `-- what is it?` comment in the code indicates this column is a placeholder, likely reserved for a rebate feature not yet implemented.

---

## 2. Business Logic

### 2.1 Temp Table 1: Realized Customer P&L (Summation)

**What**: Aggregates actual realized customer P&L by day.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@HedgeServerID`

**Rules**:
- Source: `History.CustomerClosedPositions` (populated by `Hedge.ArchiveCustomerClosedPositions`).
- Rounds `OccurredAt` to day: `DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt))`.
- SUM: `NetPL`, `CommissionOnClose`, `ZeroPL` per (HedgeServerID, day).
- Filter: `OccurredAt BETWEEN @StartDate AND @EndDate AND DATENAME(dw, OccurredAt) != 'Saturday'`.
- Fallback: If @@ROWCOUNT = 0, inserts zeros for all relevant HedgeServers from `Trade.HedgeServer`.

### 2.2 Temp Table 2: Unrealized Customer P&L (Day-Over-Day Delta)

**What**: Computes the change in open position mark-to-market between consecutive days.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@HedgeServerID`

**Rules**:
- Source: `History.CustomerOpenPositions` (populated by `Hedge.ArchiveCustomerOpenPositions`).
- Queries one extra day back: `BETWEEN DATEADD(DAY,-1,@StartDate) AND @EndDate` to enable delta for the first day.
- CTE `maxDates`: For each (HedgeServerID, day), finds `MAX(OccurredAt)` (latest snapshot in that day) and assigns `Rnum` (sequential day number per server).
- CTE `financialData`: Joins `History.CustomerOpenPositions` to `maxDates` on `OccurredAt = maxdate`, SUMs `UnrealizedPL`, `CommissionOnOpen`, `UnrealizedZeroPL` per (HedgeServerID, day).
- Delta: Self-join `financialData a JOIN financialData b WHERE a.Rnum + 1 = b.Rnum` - computes `b.value - a.value` (today minus yesterday) for UnrealizedPL, CommissionOnOpen, UnrealizedZeroPL.

### 2.3 Temp Table 3: Account Balance Delta (Realized Account P&L)

**What**: Computes the day-over-day change in hedge account Balance as a measure of realized hedge cost.

**Rules**:
- Source: `History.AccountStatus`.
- Same maxDates/financialData delta pattern as temp table 2, but reads only `Balance`.
- Result: `b.Balance - a.Balance AS NetPL` per (HedgeServerID, day).
- Interpretation: A rising Balance means the hedge account gained money (eToro earned from the hedge position). A falling Balance is a hedge cost.

### 2.4 Temp Table 4: Account NetPL Delta (Unrealized Account P&L)

**What**: Computes the day-over-day change in the hedge account's NetPL (mark-to-market open position value).

**Rules**:
- Source: `History.AccountStatus` (same table as #3, same maxDates/CTE pattern, but reads `NetPL` instead of `Balance`).
- Result: `b.NetPL - a.NetPL AS UnrealizedNetPL` per (HedgeServerID, day).

### 2.5 Combination and Hedge Cost Formulas

**What**: LEFT JOINs all four temp tables on (HedgeServerID, RowDate) and computes the hedge cost metrics.

**Rules**:
- `#Hedge_Cost_Report_Dates`: UNION of all RowDates from all four temp tables - ensures no dates are missed even if one source is sparse.
- `#Hedge_Cost_Report_Computed` derives (before Adjustments update):
  - `Hedge Cost - Realized = ZeroPL - Account Diff Realized` (internally: `ISNULL(ZeroPL,0) - ISNULL(c1.NetPL,0)`)
  - `Hedge Cost - Unrealized = Clients P&L Unrealized - Account P&L Unrealized`
- `Amount` column: Updated via a CTE from `Hedge.AccountTransactions`. Deposits (TransactionTypeID=1) add positively; withdrawals (TransactionTypeID=2) subtract. Groups by day.
- Final SELECT adds: `Hedge Cost - Realized + Amount AS [Hedge Cost - Realized]` (Adjustments are incorporated).
- `Total Hedge Cost = Hedge Cost Realized + Hedge Cost Unrealized`.
- `Total Hedge Cost % = Total Hedge Cost / (Commission Realized + Commission Unrealized)` (returns '--' if denominator = 0).
- `Hedge Cost with Rebate % = (Total Hedge Cost - Rebate) / Total Commission` (Rebate is always 0 currently).
- `Overall H.C Contribution % = (server Total Hedge Cost / overall Total Commission) * 100` using window function `SUM(...) OVER (PARTITION BY 1)`.
- UNION adds a totals row: `MAX(Date) + 1 minute` as the date with SUM() of all metric columns across all servers/days.

**Diagram**:
```
History.CustomerClosedPositions
  | SUM per day, BETWEEN @Start AND @End, excl. Saturday
  v
#Hedge_Cost_Report_CustomerClosedPositions (Realized: NetPL, Commission, ZeroPL)

History.CustomerOpenPositions
  | maxDates CTE (latest snapshot per day), @Start-1 AND @End, excl. Saturday
  | financialData CTE (SUM per day)
  | delta: b.value - a.value (Rnum+1 = Rnum)
  v
#Hedge_Cost_Report_CustomerOpenPositions (Unrealized: UnrealizedPL delta, CommissionOnOpen delta)

History.AccountStatus
  | maxDates CTE (Balance) -> delta
  v
#Hedge_Cost_Report_AccountClosedPositions (Balance delta = Account Diff Realized)

History.AccountStatus
  | maxDates CTE (NetPL) -> delta
  v
#Hedge_Cost_Report_AccountOpenPositions (NetPL delta = Account P&L Unrealized)

  | UNION of all dates
  v
#Hedge_Cost_Report_Dates

  | LEFT JOIN all 4 temp tables
  | Compute: Hedge Cost Realized/Unrealized
  v
#Hedge_Cost_Report_Computed

  | UPDATE Amount from Hedge.AccountTransactions
  | Final SELECT + UNION totals row
  v
Result: one row per (HedgeServerID, Date) + TOTALS row
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | '2010-01-01' | CODE-BACKED | Report window start (inclusive). Used as BETWEEN lower bound for realized P&L. For unrealized delta queries, queries one extra day back (DATEADD(DAY,-1,@StartDate)) to enable delta calculation for the first day. Default of '2010-01-01' is a sentinel - callers must supply actual dates. |
| 2 | @EndDate | DATETIME | NO | '2010-01-01' | CODE-BACKED | Report window end (inclusive). Used as BETWEEN upper bound for all queries. Also determines the ceiling for the unrealized delta window. Default of '2010-01-01' is a sentinel - callers must supply actual dates. |
| 3 | @HedgeServerID | INT | NO | 0 | CODE-BACKED | Target hedge server filter. 0 = all servers (implemented via CASE WHEN). Non-zero = single server. Controls which servers appear in output and in the totals UNION row header. |

**Output columns (result set):**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Date | datetime | Day bucket (truncated to midnight). Totals row: MAX(Date) + 1 minute. |
| 2 | Hedge Server ID | int | Hedge server identifier. |
| 3 | Customers P&L Realized | decimal | SUM(NetPL) from History.CustomerClosedPositions - total net profit/loss of positions closed in this day. |
| 4 | Customers Commission Realized | decimal | SUM(CommissionOnClose) - eToro commission collected on closed positions. |
| 5 | Customers Zero P&L Realized | decimal | SUM(ZeroPL) from History.CustomerClosedPositions - zero-commission P&L component for realized positions. |
| 6 | Customers P&L Unrealized | decimal | Day-over-day delta of SUM(UnrealizedPL) from History.CustomerOpenPositions - change in open position mark-to-market. |
| 7 | Customers Commission Unrealized | decimal | Day-over-day delta of SUM(CommissionOnOpen) - change in accrued open position commission. |
| 8 | Customers Zero P&L Unrealized | decimal | Day-over-day delta of SUM(UnrealizedZeroPL) from History.CustomerOpenPositions. |
| 9 | Account P&L Realized | decimal | Day-over-day delta of Balance from History.AccountStatus - the hedge account's realized P&L change. |
| 10 | Account P&L - Unrealized | decimal | Day-over-day delta of NetPL from History.AccountStatus - the hedge account's unrealized P&L change. |
| 11 | Rebate | decimal | Always 0. Placeholder for a rebate feature not yet implemented (in-code comment: "what is it?"). |
| 12 | Hedge Cost - Realized | decimal | ZeroPL - Account Diff Realized + Adjustments (Amount from AccountTransactions). |
| 13 | Hedge Cost - Unrealized | decimal | Customers P&L Unrealized - Account P&L Unrealized. |
| 14 | Total Hedge Cost | decimal | Hedge Cost Realized + Hedge Cost Unrealized. |
| 15 | Total Hedge Cost % | varchar | Total Hedge Cost / (Commission Realized + Commission Unrealized). Returns '--' when commission is 0. |
| 16 | Hedge Cost with Rebate % | varchar | (Total Hedge Cost - Rebate) / Total Commission. Returns '--' when commission is 0. Currently identical to Total Hedge Cost % since Rebate = 0. |
| 17 | Overall H.C Contribution % | varchar | Per-server total hedge cost as a percentage of the overall (all-server) total commission. Uses OVER (PARTITION BY 1) window function. |
| 18 | Adjustments | decimal | Net account transactions (deposits minus withdrawals) for the day from Hedge.AccountTransactions. TransactionTypeID=1: deposit (positive); TransactionTypeID=2: withdrawal (negative). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | History.CustomerClosedPositions | READ | Source of realized customer P&L (SUM per day) |
| - | History.CustomerOpenPositions | READ (NOLOCK) | Source of unrealized customer P&L (day-over-day delta) |
| - | History.AccountStatus | READ (NOLOCK) | Source of both realized (Balance delta) and unrealized (NetPL delta) account P&L |
| - | Hedge.AccountTransactions | READ | Source of deposit/withdrawal adjustments by day |
| - | Trade.HedgeServer | READ | Used only for zero-row fallback inserts - provides HedgeServerID list |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HedgeCostReportHistoryShell | EXEC call | Caller | Orchestrator that calls both PerDay and PerHour variants based on report type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeCostReportHistoryPerDay (procedure)
|-- History.CustomerClosedPositions (table) [READ - SUM per day]
|-- History.CustomerOpenPositions (table) [READ NOLOCK - delta per day]
|-- History.AccountStatus (table) [READ NOLOCK - Balance + NetPL delta]
|-- Hedge.AccountTransactions (table) [READ - amount adjustment]
+-- Trade.HedgeServer (table) [READ - zero-row fallback only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CustomerClosedPositions | Table | Realized customer P&L: SUM(NetPL, CommissionOnClose, ZeroPL) per day |
| History.CustomerOpenPositions | Table | Unrealized customer P&L: day-over-day delta of end-of-day snapshots |
| History.AccountStatus | Table | Account P&L: Balance delta (realized) and NetPL delta (unrealized) |
| Hedge.AccountTransactions | Table | Adjustments: net deposits/withdrawals per day per server |
| Trade.HedgeServer | Table | Zero-row fallback: inserts placeholder rows for all servers when no data exists |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeCostReportHistoryShell | Stored Procedure | Calls this procedure to produce the daily hedge cost report |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATENAME(dw,...) != 'Saturday' | Business filter | Excludes Saturday data from all queries - markets are closed and would distort the report with artificial gaps |
| @HedgeServerID = 0 | Business convention | Sentinel value meaning "all servers" - implemented in all WHERE clauses via CASE WHEN |
| IF @@ROWCOUNT = 0 | Resilience | Zero-row fallback ensures every active hedge server appears in output even with no history data |
| Rebate = 0 | Business placeholder | Rebate column always 0; developer left "what is it?" comment in code; reserved for future use |

---

## 8. Sample Queries

### 8.1 Execute for a daily date range
```sql
EXEC [Hedge].[HedgeCostReportHistoryPerDay]
    @StartDate    = '2026-03-01 00:00:00',
    @EndDate      = '2026-03-19 00:00:00',
    @HedgeServerID = 0  -- 0 = all servers
```

### 8.2 Execute for a single hedge server
```sql
EXEC [Hedge].[HedgeCostReportHistoryPerDay]
    @StartDate    = '2026-03-18 00:00:00',
    @EndDate      = '2026-03-19 00:00:00',
    @HedgeServerID = 1
```

### 8.3 Check source data for a specific day's realized P&L
```sql
SELECT HedgeServerID,
       SUM(NetPL) AS TotalNetPL,
       SUM(CommissionOnClose) AS TotalCommission,
       SUM(ZeroPL) AS TotalZeroPL
FROM [History].[CustomerClosedPositions] WITH (NOLOCK)
WHERE OccurredAt BETWEEN '2026-03-18 00:00:00' AND '2026-03-19 00:00:00'
  AND DATENAME(dw, OccurredAt) != 'Saturday'
GROUP BY HedgeServerID
ORDER BY HedgeServerID
```

### 8.4 Check account adjustments for a date
```sql
SELECT HedgeServerID,
       DATEADD(day, 0, DATEDIFF(day, 0, OccurredAtAccount)) AS Day,
       SUM(CASE WHEN TransactionTypeID = 2 THEN Amount * (-1)
                WHEN TransactionTypeID = 1 THEN Amount
                ELSE 0 END) AS NetAdjustment
FROM [Hedge].[AccountTransactions]
WHERE CAST(OccurredAtAccount AS DATE) = '2026-03-18'
GROUP BY HedgeServerID, DATEADD(day, 0, DATEDIFF(day, 0, OccurredAtAccount))
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | INSight/HedgeCost display reads these exact report columns: Clients P&L Realized/Unrealized, Etoro Commission Realized/Unrealized, Account Diff; data flows from History SQL DB; used by Master Dealer tool and Account Management tool for hedge cost monitoring |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeCostReportHistoryPerDay | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.HedgeCostReportHistoryPerDay.sql*
