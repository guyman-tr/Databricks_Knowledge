# Hedge.AccountClosedPositions

> Rolling 30-day log of account-side (broker/execution) realized P&L from hedge position closes, used to calculate the broker's hedge cost versus the client-side P&L.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: OccurredAt, HedgeServerID, InstrumentID, LiquidityAccountID (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Hedge.AccountClosedPositions records the **broker/execution side** of realized P&L each time the hedge system closes positions at a liquidity provider account. Each row captures a close event: which hedge server and liquidity account executed it, which instrument was traded, when it occurred, what the net P&L was from the account side, and the notional execution volume in USD.

This table exists as the counterpart to `Hedge.CustomerClosedPositions` (the client side). The delta between these two views of the same close events defines the **realized hedge cost** - the money eToro gains or loses from hedging client positions. Without this table, the `Hedge.HedgeCostReport` could not compute the "Account Diff - Realized" component, making it impossible to measure hedge execution efficiency per instrument and server.

Data flows as follows: rows are inserted by `Hedge.AddAccountClosedPositions` when the hedge execution system closes positions at a liquidity account (each insert carries the server, account, instrument, P&L, and volume). `Hedge.GetAccountClosedPositionsData` aggregates recent rows by group for hedge cost monitoring services. `Hedge.ArchiveAccountClosedPositions` periodically aggregates records into 15-minute buckets and saves them to `History.AccountClosedPositions` for long-term retention. `Hedge.DelAccountClosedPositions` purges records older than 30 days in rolling batches of 50,000 rows to bound the table size. Per Confluence (DROD space), this pattern is part of the broader "Hedge Cost Service" initiative which routes ClosePositionNotification events (carrying NetPL, HedgeServerId, InstrumentId) into the hedge cost calculation pipeline.

---

## 2. Business Logic

### 2.1 Hedge Cost - Realized Calculation

**What**: The difference between client-side zero P&L and account-side net P&L represents the realized hedge cost for a given period, server, and instrument.

**Columns/Parameters Involved**: `NetPL`, `HedgeServerID`, `InstrumentID`

**Rules**:
- `AccountClosedPositions.NetPL` is the execution/broker side - what the liquidity provider account actually recorded
- `CustomerClosedPositions.ZeroPL` is the client side - what eToro "zeroed" for the client
- `[Hedge Cost - Realized] = CustomerClosedPositions.ZeroPL - AccountClosedPositions.NetPL`
- Both tables are grouped by (HedgeServerID, InstrumentID, day) when computing the report
- Rows with OccurredAt on Saturdays are excluded from the hedge cost report (weekend exclusion)

**Diagram**:
```
Hedge.CustomerClosedPositions.ZeroPL
                   -
Hedge.AccountClosedPositions.NetPL
                   =
[Hedge Cost - Realized]  (in Hedge.HedgeCostReport)
```

### 2.2 Rolling Window and Archive Lifecycle

**What**: The table maintains a short-term rolling window for live monitoring; historical data is aggregated into 15-minute buckets in History.

**Columns/Parameters Involved**: `OccurredAt`, all columns

**Rules**:
- Active window: records for the past 30 days (rolling). `Hedge.DelAccountClosedPositions` deletes WHERE OccurredAt < GETDATE()-30, in batches of 50,000 rows using GOTO loop until none remain.
- Archive: `Hedge.ArchiveAccountClosedPositions` reads a date range, groups raw records into 15-minute time buckets (using `DATEDIFF(minute,'2010-01-01', OccurredAt)/@IntervalInMinutes`), sums NetPL and ExecutionVolumeInUSD, and INSERTs the aggregated rows into `History.AccountClosedPositions` within a transaction.
- Live query: `Hedge.GetAccountClosedPositionsData` filters WHERE OccurredAt > @ReferenceDate AND HedgeServerID IN (@HedgeServers), then GROUPs by (HedgeServerID, LiquidityAccountID, InstrumentID) - returns one row per group with summed P&L and most recent OccurredAt.

**Diagram**:
```
Hedge.AddAccountClosedPositions
         |
         v
Hedge.AccountClosedPositions (30-day rolling window)
         |
         +-- Hedge.GetAccountClosedPositionsData (aggregated read for monitoring)
         |
         +-- Hedge.HedgeCostReport (hedge cost calculation - groups by day)
         |
         +-- Hedge.ArchiveAccountClosedPositions ---> History.AccountClosedPositions
         |
         +-- Hedge.DelAccountClosedPositions (purge older than 30 days)
```

---

## 3. Data Overview

The table is currently empty (0 rows) in this environment - it is pre-provisioned for write activity from the hedge execution system. Representative rows based on schema and usage patterns:

| OccurredAt | HedgeServerID | LiquidityAccountID | InstrumentID | NetPL | ExecutionVolumeInUSD | Meaning |
|---|---|---|---|---|---|---|
| 2026-03-19 14:32:00 | 3 | 8 | 1 | -12.5000 | 85000.0000 | Hedge server 3 closed EUR/USD positions at ZBFX execution account. Negative NetPL indicates a loss on the account side - the broker paid more than received. Part of hedge cost calculation for this server/instrument pair. |
| 2026-03-19 14:32:00 | 3 | 8 | 5 | 45.2500 | 120000.0000 | Same server/account but on USD/JPY. Positive NetPL means the broker side profited. High volume close. OccurredAt matches the EUR/USD close - likely a batch close event from one hedge execution cycle. |
| 2026-03-19 09:00:00 | 2 | 7 | 1203 | 0.0000 | 0.0000 | Zero-value row - may represent a failed or rolled-back execution logged for completeness. Some close events may result in zero volume if the hedge was cancelled. |

**Selection criteria for the 3 rows:**
- Mix of positive and negative NetPL to illustrate the hedge cost calculation in both directions
- Same OccurredAt for two rows to show batch close events from a single execution cycle
- Zero-value row to illustrate the edge case

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). Identifies which hedge execution server initiated the close. Part of the clustered PK - all P&L for a given OccurredAt/Instrument/LiquidityAccount is grouped per server. See Trade.HedgeServer for server config and strategy modes. |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts(LiquidityAccountID). Identifies which liquidity provider account executed the close. Determines the broker counterparty for the hedge. See Trade.LiquidityAccounts for account types (Execution vs Price). |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument(InstrumentID). The financial instrument for which positions were closed. Used as grouping key in all P&L aggregations. See Trade.Instrument for instrument pair definitions. |
| 4 | OccurredAt | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of when the account-side close occurred. First column in the clustered PK - the table is physically ordered by time, optimizing range scans used by DelAccountClosedPositions (WHERE OccurredAt < @DelFromDate) and GetAccountClosedPositionsData (WHERE OccurredAt > @ReferenceDate). Defaults to GETUTCDATE() at insert via DF_AccountClosedPositions_OccurredAt. |
| 5 | NetPL | decimal(14,4) | NO | - | CODE-BACKED | Net realized P&L from the account/broker side of the close event, in USD with 4 decimal precision. Positive = broker profited on the execution, negative = broker paid more than received. Summed in Hedge.HedgeCostReport to compute "Account Diff - Realized" = `SUM(NetPL)` grouped by (HedgeServerID, InstrumentID, day). Hedge cost formula: `[Etoro Zero] - [Account Diff - Realized]`. |
| 6 | ExecutionVolumeInUSD | decimal(14,4) | NO | - | CODE-BACKED | Notional execution volume in USD at the time of close, with 4 decimal precision. Summed alongside NetPL by Hedge.GetAccountClosedPositionsData. Aggregated (SUM) by Hedge.ArchiveAccountClosedPositions when compressing records into 15-minute buckets. Used to measure execution scale alongside P&L impact. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK | The hedge server instance that executed the close. FK_AccountClosedPositions_HedgeServer. |
| InstrumentID | Trade.Instrument | FK | The financial instrument whose hedge positions were closed. FK_AccountClosedPositions_Instrument. |
| LiquidityAccountID | Trade.LiquidityAccounts | FK | The liquidity provider execution account used for the close. FK_AccountClosedPositions_LiquidityAccounts. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddAccountClosedPositions | - | Writer | Inserts one row per close event. Called by hedge execution service. |
| Hedge.GetAccountClosedPositionsData | - | Reader | Aggregates rows since @ReferenceDate for specified HedgeServerIDs. Called by hedge cost monitoring. |
| Hedge.HedgeCostReport | - | Reader | Groups rows by (HedgeServerID, InstrumentID, day) to compute "Account Diff - Realized" P&L. |
| Hedge.HedgeCostReportHistory | - | Reader | Historical variant of HedgeCostReport reading archived data. |
| Hedge.HedgeCostReportHistoryPerDay | - | Reader | Daily-bucketed hedge cost history report. |
| Hedge.HedgeCostReportHistoryPerHour | - | Reader | Hourly-bucketed hedge cost history report. |
| Hedge.ArchiveAccountClosedPositions | - | Reader/Archiver | Reads rows in date range, aggregates into 15-min buckets, writes to History.AccountClosedPositions. |
| Hedge.DelAccountClosedPositions | - | Deleter | Purges rows older than 30 days in batches of 50,000. |
| Hedge.ArchiveHedgeTables | - | Archiver | Umbrella archive procedure that calls ArchiveAccountClosedPositions. |
| Hedge.ArchiveHedgeTables_SS | - | Archiver | Secondary-server archive variant. |
| Hedge.DeleteRecordsFromHedgingTables | - | Deleter | Umbrella delete procedure referencing this table. |
| History.AccountClosedPositions | - | Archive Target | Stores aggregated historical records from ArchiveAccountClosedPositions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AccountClosedPositions (table)
```

This table has no code-level dependencies (CREATE TABLE has no FROM/JOIN). FK targets are structural references only.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |
| Trade.Instrument | Table | FK target for InstrumentID |
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddAccountClosedPositions | Procedure | Writer - inserts close event rows |
| Hedge.GetAccountClosedPositionsData | Procedure | Reader - aggregates by server/account/instrument since reference date |
| Hedge.HedgeCostReport | Procedure | Reader - computes "Account Diff - Realized" by day |
| Hedge.HedgeCostReportHistory | Procedure | Reader - historical cost report |
| Hedge.HedgeCostReportHistoryPerDay | Procedure | Reader - daily history report |
| Hedge.HedgeCostReportHistoryPerHour | Procedure | Reader - hourly history report |
| Hedge.DelAccountClosedPositions | Procedure | Deleter - purges rows older than 30 days |
| Hedge.ArchiveAccountClosedPositions | Procedure | Archiver - aggregates into 15-min buckets to History |
| Hedge.ArchiveHedgeTables | Procedure | Archiver - umbrella archive |
| Hedge.ArchiveHedgeTables_SS | Procedure | Archiver - secondary server variant |
| Hedge.DeleteRecordsFromHedgingTables | Procedure | Deleter - umbrella delete |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeAccountClosedPositions | CLUSTERED PK | OccurredAt ASC, HedgeServerID ASC, InstrumentID ASC, LiquidityAccountID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeAccountClosedPositions | PRIMARY KEY | Composite key: OccurredAt + HedgeServerID + InstrumentID + LiquidityAccountID - ensures one row per close event per server/account/instrument combination within a given moment |
| FK_AccountClosedPositions_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_AccountClosedPositions_Instrument | FOREIGN KEY | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_AccountClosedPositions_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| DF_AccountClosedPositions_OccurredAt | DEFAULT | OccurredAt = GETUTCDATE() - automatically stamps close events with current UTC time if not provided by caller |

---

## 8. Sample Queries

### 8.1 Get recent close events for a specific hedge server
```sql
SELECT HedgeServerID, LiquidityAccountID, InstrumentID,
       OccurredAt, NetPL, ExecutionVolumeInUSD
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
WHERE HedgeServerID = 3
  AND OccurredAt > DATEADD(day, -1, GETUTCDATE())
ORDER BY OccurredAt DESC;
```

### 8.2 Aggregate account P&L by instrument since a reference date (mirrors GetAccountClosedPositionsData)
```sql
SELECT HedgeServerID, LiquidityAccountID, InstrumentID,
       SUM(NetPL) AS TotalNetPL,
       SUM(ExecutionVolumeInUSD) AS TotalVolumeUSD,
       MAX(OccurredAt) AS MostRecentClose
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
WHERE OccurredAt > DATEADD(hour, -24, GETUTCDATE())
  AND HedgeServerID IN (2, 3, 4)
GROUP BY HedgeServerID, LiquidityAccountID, InstrumentID
ORDER BY TotalNetPL ASC;
```

### 8.3 Daily hedge cost - account side joined to instrument and server names
```sql
SELECT CAST(ACP.OccurredAt AS date) AS TradeDate,
       HS.IPAddress + ':' + CAST(HS.Port AS varchar) AS HedgeServer,
       LA.LiquidityAccountName,
       TI.BuyCurrencyID AS InstrumentID,
       SUM(ACP.NetPL) AS AccountNetPL,
       SUM(ACP.ExecutionVolumeInUSD) AS VolumeUSD
FROM Hedge.AccountClosedPositions ACP WITH (NOLOCK)
JOIN Trade.HedgeServer HS WITH (NOLOCK)
  ON ACP.HedgeServerID = HS.HedgeServerID
JOIN Trade.LiquidityAccounts LA WITH (NOLOCK)
  ON ACP.LiquidityAccountID = LA.LiquidityAccountID
JOIN Trade.Instrument TI WITH (NOLOCK)
  ON ACP.InstrumentID = TI.InstrumentID
WHERE ACP.OccurredAt >= DATEADD(day, -7, GETUTCDATE())
  AND DATENAME(dw, ACP.OccurredAt) != 'Saturday'
GROUP BY CAST(ACP.OccurredAt AS date),
         HS.IPAddress, HS.Port,
         LA.LiquidityAccountName,
         TI.BuyCurrencyID
ORDER BY TradeDate DESC, AccountNetPL ASC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD: Hedge Cost Service - Customer Side](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/1205698593) | Confluence | Confirms this table is part of the hedge cost calculation pipeline; the Hedge Cost Service replaces the "delta desk job" (Hedge.AddCustomerData) which queried Trade.Position directly, with a service consuming RabbitMQ ClosePositionNotification events. Jira tickets DEALR-4, DEALR-27, DEALR-36, DEALR-48 track this initiative. |
| [HLD: Realized Customer Service](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12020321469) | Confluence | Confirms ClosePositionNotification carries NetPL (decimal), HedgeServerId (int), InstrumentId (int), and Commission - these map directly to AccountClosedPositions columns. The realized customer entity aggregates NetPL and Commission per (InstrumentId, HedgeServerId) and is stored in Redis for real-time hedge cost calculations. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AccountClosedPositions | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.AccountClosedPositions.sql*
