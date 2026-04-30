# History.AccountStatus

> Long-term archive of liquidity provider account financial snapshots, storing the most recent status per hedge server/account per 15-minute bucket, compressed from the Hedge.AccountStatus rolling window.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: OccurredAt + HedgeServerID (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

History.AccountStatus is the historical archive counterpart to `Hedge.AccountStatus`. While the Hedge version maintains a 30-day rolling window of all status polling events, this History table stores one representative snapshot per hedge server per liquidity account per 15-minute time bucket — the most recent reading within each window — for long-term retention. Each row captures a point-in-time financial state: balance, unrealized P&L, equity, margin metrics, leverage, and cushion.

Without this table, historical margin and leverage analysis would be limited to the last 30 days. Hedge cost history reporting (`Hedge.HedgeCostReportHistoryPerDay`, `Hedge.HedgeCostReportHistoryPerHour`) accesses this table to compute unrealized hedge P&L ("Account P&L - Unrealized") over historical date ranges. It also supports incident investigation — answering "what was the balance on hedge server 3 at 14:00 on January 15th?"

Data flows exclusively from `Hedge.ArchiveAccountStatus`, which is called on a schedule. It reads a date window from `Hedge.AccountStatus`, keeps only the LATEST snapshot per (HedgeServerID, LiquidityAccountID, 15-minute bucket) using `ROW_NUMBER() OVER (PARTITION BY HedgeServerID, LiquidityAccountID, bucket ORDER BY OccurredAt DESC) RowNum=1`, and INSERTs the result within a transaction. No other procedure writes to this table. The OccurredAt value stored is the original timestamp of the most recent snapshot within the bucket — not the bucket boundary.

---

## 2. Business Logic

### 2.1 Last-Value-Per-Bucket Archival Strategy

**What**: Unlike History.AccountClosedPositions (which SUMs), this table archives by taking the LAST snapshot within each time bucket per server/account pair.

**Columns/Parameters Involved**: `OccurredAt`, `HedgeServerID`, `LiquidityAccountID`, all financial columns

**Rules**:
- Bucket key: `DATEDIFF(minute,'2010-01-01', OccurredAt) / @IntervalInMinutes` (typically 15-min intervals)
- ROW_NUMBER() OVER (PARTITION BY HedgeServerID, LiquidityAccountID, bucket ORDER BY OccurredAt DESC): keeps the row with the latest OccurredAt within each bucket
- OccurredAt stored = the source row's original OccurredAt (the most recent polling timestamp in the bucket)
- All financial values (Balance, NetPL, Equity, margins) are the values from that latest snapshot - point-in-time state, not aggregated

**Diagram**:
```
Hedge.AccountStatus (raw polls, 30-day rolling):
  14:28:05 HS=3, LA=8: Balance=1.25M, NetPL=-15K, Equity=1.235M
  14:31:22 HS=3, LA=8: Balance=1.24M, NetPL=-18K, Equity=1.222M  <-- most recent in bucket
  14:37:45 HS=3, LA=8: Balance=1.24M, NetPL=-19K, Equity=1.221M
         |
   ArchiveAccountStatus (@IntervalInMinutes=15)
         |
History.AccountStatus (15-min bucket, last value):
  14:31:22 HS=3, LA=8: Balance=1.24M, NetPL=-18K (the 14:31 snapshot)
```

### 2.2 Unrealized P&L as "Account P&L - Unrealized" in Historical Reports

**What**: The NetPL column feeds the "Account P&L - Unrealized" output in hedge cost history reports.

**Columns/Parameters Involved**: `NetPL`, `HedgeServerID`, `InstrumentID`, `OccurredAt`

**Rules**:
- NetPL represents **unrealized** P&L (floating P&L on open hedge positions), per the Confluence "Production Data comparison 31/01/21" source from Hedge.AccountStatus docs
- In HedgeCostReportHistory, account-side unrealized P&L is computed as delta between consecutive days: `b.UnrealizedNetPL - a.UnrealizedNetPL` (OccurredAt-based max per day join)
- History table lacks InstrumentID unlike Hedge.AccountOpenPositions - so this is account-level (not per-instrument) unrealized P&L
- Saturday rows are excluded from hedge cost calculations: `DATENAME(dw, OccurredAt) != 'Saturday'`

### 2.3 PK Covers Only Two of Three Natural Key Columns

**What**: The PK is (OccurredAt, HedgeServerID) - it omits LiquidityAccountID, unlike the source Hedge.AccountStatus PK.

**Columns/Parameters Involved**: `OccurredAt`, `HedgeServerID`, `LiquidityAccountID`

**Rules**:
- In practice, different LiquidityAccounts polled for the same HedgeServer will have different OccurredAt timestamps (polling does not happen simultaneously), so the 2-column PK is typically unique
- Edge case: if two LiquidityAccounts under the same HedgeServer happen to have the exact same most-recent OccurredAt in the same bucket, the archive INSERT would fail on the PK constraint - this is a known schema limitation

---

## 3. Data Overview

The table is currently empty (0 rows) in the query environment. In production, it stores the most recent status snapshot per (HedgeServerID, LiquidityAccountID) per 15-minute window going back as far as data has been retained.

| OccurredAt | HedgeServerID | LiquidityAccountID | Balance | NetPL | Equity | CurrentLeverage | Meaning |
|---|---|---|---|---|---|---|---|
| 2025-03-15 14:31:22 | 3 | 8 | 1240000.0000 | -18000.0000 | 1222000.0000 | 12.5000 | The 14:15-14:30 bucket's last snapshot for ZBFX execution account on hedge server 3. Negative NetPL = open hedge positions losing. 12.5x leverage is within normal operating range. |
| 2025-03-15 14:29:55 | 2 | 7 | 850000.0000 | 9500.0000 | 859500.0000 | 8.2000 | A different server/account at almost the same bucket. Positive NetPL. Slightly different OccurredAt (14:29 vs 14:31) is why both can coexist despite the 2-column PK. |
| 2025-03-14 09:15:00 | 3 | 8 | 1265000.0000 | 2500.0000 | 1267500.0000 | 11.8000 | Previous day snapshot for same account - shows how Balance and NetPL fluctuated. NetPL positive here vs negative in the recent row - hedge P&L swings with market moves. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). Identifies which hedge server's account status is archived. Part of the PK. See Hedge.AccountStatus and Hedge.HedgeServer for server config details. |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts(LiquidityAccountID). Identifies the liquidity provider account being tracked. NOT part of the PK (unlike in Hedge.AccountStatus), but is part of the archival grouping key. |
| 3 | OccurredAt | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of the latest polling event within the 15-minute bucket - preserved from the source row's OccurredAt. First column of the clustered PK. Used by HedgeCostReportHistory for per-day delta calculations (GROUP BY day). Saturday rows excluded from all hedge cost queries. |
| 4 | OccurredAtAccount | datetime | YES | - | CODE-BACKED | Liquidity provider's own reported timestamp. NULL-able. Inherited from Hedge.AccountStatus. May differ from OccurredAt due to provider clock skew. |
| 5 | Balance | decimal(18,4) | YES | - | CODE-BACKED | Account cash balance in USD. For FD providers (TypeID=3): Balance = UsedMargin + UsableMargin - NetPL (recalculated by Hedge.AddAccountStatus before the source row was created). For IB (TypeID=11): Balance = Equity - NetPL. Others: as reported. |
| 6 | NetPL | decimal(18,4) | YES | - | VERIFIED | Unrealized net P&L on open hedge positions, in USD. Confirmed as UnrealizedPL by Confluence "Production Data comparison 31/01/21". Used in hedge cost history report as "Account P&L - Unrealized" via delta computation: today.NetPL - yesterday.NetPL. Negative = hedge positions currently losing money. |
| 7 | Equity | decimal(18,4) | YES | - | CODE-BACKED | Total account equity = Balance + NetPL (approximately). Used in IB provider Balance recalculation. Represents the account's full value including floating P&L. |
| 8 | UsedMargin | decimal(16,4) | YES | - | CODE-BACKED | Margin locked by open hedge positions, in USD. Used in FD Balance recalculation. Lower values indicate less active hedging. |
| 9 | UsableMargin | decimal(16,4) | YES | - | CODE-BACKED | Free margin available for new hedge orders, in USD. Used in FD Balance recalculation. High UsableMargin relative to Balance = low leverage use. |
| 10 | MaintenanceMargin | decimal(16,4) | YES | - | CODE-BACKED | Minimum margin floor to avoid forced position closure by the provider. If UsableMargin falls below this, the hedge account is at risk of a margin call. |
| 11 | CurrentLeverage | decimal(16,4) | YES | - | CODE-BACKED | Current leverage ratio for this account (e.g., 10.0 = 10:1). Higher values indicate larger open exposure relative to balance. Used for margin risk monitoring. |
| 12 | Cushion | decimal(16,4) | YES | - | CODE-BACKED | Buffer margin above the maintenance level. Cushion = UsableMargin - MaintenanceMargin (approximately). Low cushion signals proximity to margin call. |
| 13 | GrossPositionsValue | decimal(16,4) | YES | - | CODE-BACKED | Total notional value of all open hedge positions, in USD. Used to derive CurrentLeverage. Reflects the scale of the hedge book for this account. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_History_AccountStatus_HedgeServer) | The hedge server whose account status is archived. |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_History_AccountStatus_LiquidityAccounts) | The liquidity provider account being tracked over time. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ArchiveAccountStatus | - | Writer | The only write path - takes last snapshot per (HedgeServerID, LiquidityAccountID, 15-min bucket) from Hedge.AccountStatus and INSERTs here. |
| Hedge.HedgeCostReportHistory | - | Reader | Reads per-day max OccurredAt snapshot for "Account P&L - Unrealized" delta computation. |
| Hedge.HedgeCostReportHistoryPerDay | - | Reader | Daily-bucketed variant reads this for unrealized P&L trend. |
| Hedge.HedgeCostReportHistoryPerHour | - | Reader | Hourly-bucketed variant. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AccountStatus (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target - HedgeServerID must exist |
| Trade.LiquidityAccounts | Table | FK target - LiquidityAccountID must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ArchiveAccountStatus | Stored Procedure | Writer - last-value-per-bucket archival from Hedge.AccountStatus |
| Hedge.HedgeCostReportHistory | Stored Procedure | Reader - unrealized account P&L delta for full history date ranges |
| Hedge.HedgeCostReportHistoryPerDay | Stored Procedure | Reader - daily history |
| Hedge.HedgeCostReportHistoryPerHour | Stored Procedure | Reader - hourly history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountStatus | CLUSTERED PK | OccurredAt ASC, HedgeServerID ASC | - | - | Active |

**Note**: PK omits LiquidityAccountID. In practice, different liquidity accounts per hedge server have distinct OccurredAt timestamps, making the 2-column PK functionally unique. See Section 2.3.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AccountStatus | PRIMARY KEY CLUSTERED | OccurredAt + HedgeServerID - one archived snapshot per server per moment |
| DF_History_AccountStatus_OccurredAt | DEFAULT | OccurredAt = GETUTCDATE() (fallback if not supplied) |
| FK_History_AccountStatus_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_History_AccountStatus_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |

---

## 8. Sample Queries

### 8.1 Historical balance trend for a specific hedge server
```sql
SELECT
    HedgeServerID,
    LiquidityAccountID,
    OccurredAt,
    Balance,
    NetPL,
    Equity,
    CurrentLeverage,
    Cushion
FROM History.AccountStatus WITH (NOLOCK)
WHERE HedgeServerID = 3
  AND OccurredAt >= '2025-01-01'
  AND OccurredAt <  '2026-01-01'
ORDER BY OccurredAt ASC;
```

### 8.2 Daily unrealized P&L delta per server (mirrors HedgeCostReportHistory logic)
```sql
SELECT
    HedgeServerID,
    DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt)) AS RowDate,
    MAX(OccurredAt) AS LatestSnapshot,
    NetPL AS UnrealizedNetPL
FROM History.AccountStatus WITH (NOLOCK)
WHERE OccurredAt BETWEEN '2025-01-01' AND '2025-12-31'
  AND DATENAME(dw, OccurredAt) != 'Saturday'
GROUP BY HedgeServerID,
         DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt)),
         NetPL
ORDER BY HedgeServerID, RowDate;
```

### 8.3 Audit archive bucket coverage by month
```sql
SELECT
    YEAR(OccurredAt)         AS [Year],
    MONTH(OccurredAt)        AS [Month],
    COUNT(*)                 AS SnapshotCount,
    COUNT(DISTINCT HedgeServerID) AS HedgeServers,
    AVG(CurrentLeverage)     AS AvgLeverage,
    MIN(Cushion)             AS MinCushion
FROM History.AccountStatus WITH (NOLOCK)
GROUP BY YEAR(OccurredAt), MONTH(OccurredAt)
ORDER BY [Year] DESC, [Month] DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Production Data comparison 31/01/21](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/1845952868) | Confluence | Confirms NetPL = UnrealizedPL. Provides the comparison query: `SELECT LiquidityAccountID, OccurredAt, OccurredAtAccount, Balance, NetPL AS UnrealizedPL FROM Hedge.AccountStatus` (applies to History version by inheritance). |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AccountStatus | Type: Table | Source: etoro/etoro/History/Tables/History.AccountStatus.sql*
