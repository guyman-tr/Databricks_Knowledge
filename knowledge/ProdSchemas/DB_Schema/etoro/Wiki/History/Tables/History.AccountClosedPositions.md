# History.AccountClosedPositions

> Long-term archive of broker-side realized P&L from hedge position closes, storing 15-minute aggregated buckets compressed from the Hedge.AccountClosedPositions rolling window.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: OccurredAt, HedgeServerID, InstrumentID, LiquidityAccountID (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK, PAGE compression) |

---

## 1. Business Meaning

History.AccountClosedPositions is the historical archive counterpart to `Hedge.AccountClosedPositions`. While the Hedge version maintains a 30-day rolling window of individual close events, this History table stores those events after they are aggregated into 15-minute time buckets and compressed for long-term retention. Each row represents the broker/execution-side net P&L and volume for a given hedge server, liquidity account, and instrument during a 15-minute interval.

Without this table, historical hedge cost reporting would be limited to the last 30 days. `Hedge.HedgeCostReportHistory`, `Hedge.HedgeCostReportHistoryPerDay`, and `Hedge.HedgeCostReportHistoryPerHour` all query this table to compute the "Account Diff - Realized" component of the hedge cost formula over arbitrary historical date ranges. The table enables risk management to analyze how hedge execution costs have evolved over months or years.

Data flows into this table exclusively from `Hedge.ArchiveAccountClosedPositions`, which runs on a schedule. It reads a date range from `Hedge.AccountClosedPositions`, aggregates records into 15-minute buckets using `DATEDIFF(minute,'2010-01-01', OccurredAt)/@IntervalInMinutes` grouping, SUMs NetPL and ExecutionVolumeInUSD within each bucket, and INSERTs the result here within a transaction. No other procedure writes to History.AccountClosedPositions. Reads come from the hedge cost history reporting procedures.

---

## 2. Business Logic

### 2.1 15-Minute Aggregation and Compression

**What**: Raw close events from Hedge.AccountClosedPositions are aggregated into 15-minute buckets before being stored here, reducing row count while preserving time-series granularity.

**Columns/Parameters Involved**: `OccurredAt`, `NetPL`, `ExecutionVolumeInUSD`

**Rules**:
- Bucket key: `DATEDIFF(minute,'2010-01-01', OccurredAt) / @IntervalInMinutes` (integer division groups rows into intervals)
- OccurredAt stored is the MAX within the bucket (most recent raw event in the interval)
- NetPL stored is SUM of all NetPL within the bucket across the same (HedgeServerID, LiquidityAccountID, InstrumentID) group
- ExecutionVolumeInUSD stored is SUM of all volumes within the bucket
- DATA_COMPRESSION = PAGE applied at table level to reduce storage footprint for long-term retention

**Diagram**:
```
Hedge.AccountClosedPositions (raw, 30-day rolling):
  14:30:01 - HS=3, LA=8, Inst=1, NetPL=-5.0, Vol=20000
  14:35:22 - HS=3, LA=8, Inst=1, NetPL=-3.5, Vol=15000
  14:42:10 - HS=3, LA=8, Inst=1, NetPL=+2.0, Vol=10000
                 |
           ArchiveAccountClosedPositions (@IntervalInMinutes=15)
                 |
History.AccountClosedPositions (15-min bucket):
  14:42:10 - HS=3, LA=8, Inst=1, NetPL=-6.5, Vol=45000
  (OccurredAt=max, NetPL=sum, Vol=sum)
```

### 2.2 Historical Hedge Cost Calculation

**What**: The "Account Diff - Realized" column in hedge cost reports is sourced from this table, representing the broker/account-side P&L over a historical period.

**Columns/Parameters Involved**: `NetPL`, `HedgeServerID`, `InstrumentID`, `OccurredAt`

**Rules**:
- Query groups by (HedgeServerID, InstrumentID, day): `DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt)) AS RowDate`
- Saturday rows are excluded from all hedge cost calculations: `DATENAME(dw, OccurredAt) != 'Saturday'`
- Hedge Cost formula: `[Hedge Cost - Realized] = [Etoro Zero] - [Account Diff - Realized]` where Account Diff Realized = SUM(History.AccountClosedPositions.NetPL) and Etoro Zero = SUM(History.CustomerClosedPositions.ZeroPL)
- Positive NetPL = broker profited on execution; negative = broker paid more than received

**Diagram**:
```
Hedge Cost - Realized =
    SUM(History.CustomerClosedPositions.ZeroPL)  [Etoro Zero]
  - SUM(History.AccountClosedPositions.NetPL)    [Account Diff - Realized]
```

---

## 3. Data Overview

The table is currently empty (0 rows) in the query environment. In production, rows are aggregated 15-minute snapshots of hedge close events going back as far as data has been retained. Representative rows based on archival patterns:

| OccurredAt | HedgeServerID | LiquidityAccountID | InstrumentID | NetPL | ExecutionVolumeInUSD | Meaning |
|---|---|---|---|---|---|---|
| 2025-03-15 14:44:55 | 3 | 8 | 1 | -18.7500 | 250000.0000 | 15-min bucket for EUR/USD closes on hedge server 3 (ZBFX account 8). Negative NetPL means broker paid more than received during this interval - a hedge cost incurred. High volume suggests active trading period. |
| 2025-03-15 14:44:55 | 3 | 8 | 5 | 42.3000 | 180000.0000 | USD/JPY bucket same time window. Positive NetPL - broker side profited on this instrument. Used alongside the EUR/USD row to compute per-instrument hedge cost in HedgeCostReportHistory. |
| 2025-03-14 09:30:00 | 2 | 7 | 1 | 0.0000 | 0.0000 | Zero-value bucket - no net P&L or volume during this 15-minute window. Inserted by ArchiveAccountClosedPositions to preserve time-series continuity even when no closes occurred. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). Identifies which hedge execution server generated the close events in this bucket. First component of the grouping key for all hedge cost report aggregations. Inherited from Hedge.AccountClosedPositions on archival. |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts(LiquidityAccountID). Identifies the liquidity provider account where closes were executed. Part of the bucket key - P&L is tracked per execution account, enabling analysis of hedge cost by counterparty. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | Identifies the financial instrument (currency pair, stock, crypto, etc.) being hedged. Key grouping dimension in all hedge cost reports. Part of the composite PK - each bucket is unique per OccurredAt + HedgeServerID + InstrumentID + LiquidityAccountID. |
| 4 | OccurredAt | datetime | NO | - | CODE-BACKED | Timestamp of the latest raw close event within the 15-minute bucket (MAX(OccurredAt) from the source rows in ArchiveAccountClosedPositions). Serves as the time axis for historical hedge cost reports. Saturdays are excluded from all report queries. No default constraint - always provided explicitly by ArchiveAccountClosedPositions. |
| 5 | NetPL | decimal(14,4) | NO | - | CODE-BACKED | Aggregated net realized P&L from the broker/account side, summed across all closes within the 15-minute bucket, in USD with 4 decimal precision. SUM(Hedge.AccountClosedPositions.NetPL) for the bucket. Positive = broker profited; negative = broker paid. Used in Hedge.HedgeCostReportHistory as "Account Diff - Realized": `SUM(NetPL)` grouped by (HedgeServerID, InstrumentID, day). |
| 6 | ExecutionVolumeInUSD | decimal(14,4) | NO | - | CODE-BACKED | Total notional execution volume in USD, summed across all closes within the 15-minute bucket. SUM(Hedge.AccountClosedPositions.ExecutionVolumeInUSD) for the bucket. Used to provide context for the P&L magnitude - a large negative NetPL on low volume is more concerning than on high volume. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_HistoryAccountClosedPositions_HedgeServer) | Each archive bucket belongs to one hedge server. Inherited from Hedge.AccountClosedPositions via archival. |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_HistoryAccountClosedPositions_LiquidityAccounts) | Each archive bucket belongs to one liquidity account. Ensures referential integrity for historical reporting. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ArchiveAccountClosedPositions | - | Writer | Aggregates Hedge.AccountClosedPositions into 15-min buckets and INSERTs here. The only write path. |
| Hedge.HedgeCostReportHistory | - | Reader | Reads grouped by (HedgeServerID, InstrumentID, day) to produce "Account Diff - Realized" for full historical date ranges. |
| Hedge.HedgeCostReportHistoryPerDay | - | Reader | Daily-bucketed variant of hedge cost history report. |
| Hedge.HedgeCostReportHistoryPerHour | - | Reader | Hourly-bucketed variant of hedge cost history report. |
| dbo.DeleteInstrumentDebug | - | Deleter | Debug/maintenance procedure that removes instrument-related records from this table when an instrument is deleted. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AccountClosedPositions (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target - HedgeServerID must exist in Trade.HedgeServer |
| Trade.LiquidityAccounts | Table | FK target - LiquidityAccountID must exist in Trade.LiquidityAccounts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ArchiveAccountClosedPositions | Stored Procedure | Writer - INSERT with 15-min aggregated buckets from Hedge.AccountClosedPositions |
| Hedge.HedgeCostReportHistory | Stored Procedure | Reader - "Account Diff - Realized" computation for historical date ranges |
| Hedge.HedgeCostReportHistoryPerDay | Stored Procedure | Reader - daily-bucketed historical hedge cost |
| Hedge.HedgeCostReportHistoryPerHour | Stored Procedure | Reader - hourly-bucketed historical hedge cost |
| dbo.DeleteInstrumentDebug | Stored Procedure | Deleter - removes records for a deleted instrument |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryAccountClosedPositions | CLUSTERED PK (PAGE compressed) | OccurredAt ASC, HedgeServerID ASC, InstrumentID ASC, LiquidityAccountID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryAccountClosedPositions | PRIMARY KEY CLUSTERED | Composite key: OccurredAt + HedgeServerID + InstrumentID + LiquidityAccountID. Ensures uniqueness of each 15-minute aggregated bucket per server/account/instrument combination. |
| FK_HistoryAccountClosedPositions_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_HistoryAccountClosedPositions_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |

**Storage**: DATA_COMPRESSION = PAGE reduces physical storage for this long-term archive. Filegroup: PRIMARY (vs Hedge.AccountClosedPositions which is on default).

---

## 8. Sample Queries

### 8.1 Historical account-side P&L by instrument for a date range
```sql
SELECT
    CAST(OccurredAt AS date)  AS TradeDate,
    HedgeServerID,
    InstrumentID,
    SUM(NetPL)                AS AccountDiffRealized,
    SUM(ExecutionVolumeInUSD) AS TotalVolumeUSD
FROM History.AccountClosedPositions WITH (NOLOCK)
WHERE OccurredAt >= '2025-01-01'
  AND OccurredAt <  '2026-01-01'
  AND DATENAME(dw, OccurredAt) != 'Saturday'
GROUP BY CAST(OccurredAt AS date), HedgeServerID, InstrumentID
ORDER BY TradeDate, HedgeServerID, InstrumentID;
```

### 8.2 Hedge cost calculation over a historical period (mirrors HedgeCostReportHistory logic)
```sql
SELECT
    DATEADD(day, 0, DATEDIFF(day, 0, acp.OccurredAt)) AS RowDate,
    acp.HedgeServerID,
    acp.InstrumentID,
    SUM(acp.NetPL) AS AccountDiffRealized
FROM History.AccountClosedPositions acp WITH (NOLOCK)
WHERE acp.OccurredAt BETWEEN '2025-01-01' AND '2025-12-31'
  AND DATENAME(dw, acp.OccurredAt) != 'Saturday'
GROUP BY DATEADD(day, 0, DATEDIFF(day, 0, acp.OccurredAt)),
         acp.HedgeServerID,
         acp.InstrumentID;
```

### 8.3 Archive bucket count by month - audit the archival process
```sql
SELECT
    YEAR(OccurredAt)  AS [Year],
    MONTH(OccurredAt) AS [Month],
    COUNT(*)          AS BucketCount,
    SUM(NetPL)        AS TotalNetPL,
    MIN(OccurredAt)   AS FirstBucket,
    MAX(OccurredAt)   AS LastBucket
FROM History.AccountClosedPositions WITH (NOLOCK)
GROUP BY YEAR(OccurredAt), MONTH(OccurredAt)
ORDER BY [Year] DESC, [Month] DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AccountClosedPositions | Type: Table | Source: etoro/etoro/History/Tables/History.AccountClosedPositions.sql*
