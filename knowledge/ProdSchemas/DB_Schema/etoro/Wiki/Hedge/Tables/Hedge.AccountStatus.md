# Hedge.AccountStatus

> Rolling 30-day time-series of liquidity provider account financial snapshots, recording balance, margin, leverage, and unrealized P&L per hedge server and account at each polling interval.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: OccurredAt, HedgeServerID, LiquidityAccountID (CLUSTERED, FILLFACTOR=95) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 NC on HedgeServerID+OccurredAt) |

---

## 1. Business Meaning

Hedge.AccountStatus stores periodic snapshots of a liquidity provider account's financial state as seen from the hedge server side. Each row captures a point-in-time reading for a specific hedge server and liquidity account pair: the account's cash balance, unrealized net P&L on open hedge positions, equity, used and usable margin, maintenance margin, current leverage, cushion, and gross positions value. Two timestamps are stored: `OccurredAt` (the DB server's UTC time when the snapshot was recorded) and `OccurredAtAccount` (the liquidity provider's own clock at the time of the report).

This table exists so the hedge monitoring and cost reporting system can track account health over time - detecting margin calls, leverage breaches, and P&L drift across different liquidity providers. Without it, there would be no historical record of how hedge accounts evolved, making it impossible to investigate incidents, calculate hedge cost trends, or verify that account balances match expected values.

Data flows as follows: `Hedge.AddAccountStatus` inserts rows on each polling cycle, applying provider-specific Balance adjustments before storing (FD and IB providers have non-standard balance reporting that requires recalculation). `Hedge.AddHedgeAccountStatus` is a simpler variant that inserts without adjustment. `Hedge.GetCurrentAccountStatus` (inline TVF) returns the most recent row per HedgeServerID within the last hour - used by real-time monitoring. `Hedge.GetReferenceAccountStatus` returns the most recent row per server within a date range - used for historical reference comparisons. The 30-day rolling window is enforced by `Hedge.DelAccountStatus` (same batch-delete pattern as AccountClosedPositions). A Confluence comparison page ("Production Data comparison 31/01/21") confirms that `AccountStatus.NetPL` represents **unrealized P&L** - the current floating P&L on open hedge positions.

---

## 2. Business Logic

### 2.1 Provider-Specific Balance Adjustment

**What**: Some liquidity providers report balance in a non-standard way that requires recalculation before storage.

**Columns/Parameters Involved**: `Balance`, `UsedMargin`, `UsableMargin`, `NetPL`, `Equity`

**Rules**:
- Default: Balance is stored as-is from the provider report
- LiquidityProviderTypeID = 3 (FD - Fortis/Deutsche Bank): `Balance = UsedMargin + UsableMargin - NetPL`
- LiquidityProviderTypeID = 11 (IB - Interactive Brokers): `Balance = Equity - NetPL`
- The lookup of LiquidityProviderTypeID is done via JOIN: `Trade.LiquidityAccounts -> Trade.LiquidityProviders -> LiquidityProviderTypeID`
- `Hedge.AddHedgeAccountStatus` bypasses this adjustment and stores Balance as-is (used for providers where the raw balance is correct)

**Diagram**:
```
AddAccountStatus(@LiquidityAccountID, @Balance, ...)
     |
     v
JOIN Trade.LiquidityAccounts -> Trade.LiquidityProviders
     |
     +-> TypeID = 3 (FD): Balance = UsedMargin + UsableMargin - NetPL
     +-> TypeID = 11 (IB): Balance = Equity - NetPL
     +-> Other:            Balance = @Balance (as-is)
     |
     v
INSERT INTO Hedge.AccountStatus
```

### 2.2 Current Status Query Pattern (Latest Row Per Server)

**What**: Consumers need the most recent snapshot per hedge server, not the full history - achieved via ROW_NUMBER window function.

**Columns/Parameters Involved**: `HedgeServerID`, `OccurredAt`, all financial columns

**Rules**:
- `Hedge.GetCurrentAccountStatus(@LastRunTime)` partitions by HedgeServerID (NOTE: LiquidityAccountID is commented out of the PARTITION), orders by OccurredAt DESC, returns RowNum=1
- Also filters: `OccurredAt >= @LastRunTime AND OccurredAt >= DATEADD(hh,-1,getutcdate())` - both a caller-provided time and a hard 1-hour lookback
- `Hedge.GetReferenceAccountStatus(@StartDate, @EndDate, @HedgeServerIDs)` applies same ROW_NUMBER logic but within a date window and for specified server IDs
- Because the PARTITION is by HedgeServerID only (not by LiquidityAccountID), when multiple liquidity accounts exist per server, the function returns the row from whichever account had the most recent update

**Diagram**:
```
Hedge.AccountStatus (time series: many rows per server)
     |
     v
ROW_NUMBER() OVER (PARTITION BY HedgeServerID ORDER BY OccurredAt DESC)
     |
     v
WHERE RowNum = 1  ->  One row per HedgeServerID (the most recent snapshot)
```

### 2.3 OccurredAt vs OccurredAtAccount Dual Timestamps

**What**: Two timestamps capture both the DB-side recording time and the provider's own reported time, enabling clock skew analysis and accurate cross-provider comparisons.

**Columns/Parameters Involved**: `OccurredAt`, `OccurredAtAccount`

**Rules**:
- `OccurredAt` is the DB server's UTC time at INSERT (DEFAULT getutcdate()). Reliable, consistent, used for all queries, PK ordering, and the 30-day purge window.
- `OccurredAtAccount` is the timestamp from the liquidity provider's own system (NULL-able). May differ from OccurredAt due to network latency or provider clock differences. Used by the Confluence data comparison ("Production Data comparison 31/01/21") for cross-validating accountstatusplservice data alignment.
- The clustered PK uses OccurredAt (not OccurredAtAccount) for physical ordering - provider timestamps are not trusted for ordering.

---

## 3. Data Overview

The table is currently empty (0 rows) in this environment - it is pre-provisioned for write activity from the hedge polling service. Representative rows based on schema and usage patterns:

| OccurredAt | HedgeServerID | LiquidityAccountID | Balance | NetPL | Equity | UsedMargin | Meaning |
|---|---|---|---|---|---|---|---|
| 2026-03-19 14:30:00 | 3 | 8 | 1250000.0000 | -18500.0000 | 1231500.0000 | 450000.0000 | ZBFX execution account on hedge server 3. Negative NetPL = open hedge positions are currently underwater. Equity = Balance + NetPL. UsedMargin reflects active hedge position requirements. |
| 2026-03-19 14:30:00 | 2 | 7 | 850000.0000 | 12300.0000 | 862300.0000 | 320000.0000 | Different server/account combo at the same poll cycle. Positive NetPL = hedge positions profitable. Balance was adjusted via FD formula (UsedMargin + UsableMargin - NetPL) by AddAccountStatus. |
| 2026-03-19 14:15:00 | 3 | 8 | 1265000.0000 | -5200.0000 | 1259800.0000 | 445000.0000 | Earlier snapshot for same server/account. Shows the time-series nature - multiple rows per server/account over time. GetCurrentAccountStatus would return the 14:30 row (RowNum=1). |

**Selection criteria for the 3 rows:**
- Mix of positive and negative NetPL to show the unrealized P&L can swing either direction
- Same server/account at two different times to illustrate the time-series pattern
- Rows at the same OccurredAt timestamp to show multiple accounts can be polled in the same cycle

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). Identifies which hedge server owns this account status snapshot. Part of the clustered PK. Used as the PARTITION key in GetCurrentAccountStatus ROW_NUMBER window. |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts(LiquidityAccountID). Identifies which liquidity provider account this snapshot belongs to. Used to look up LiquidityProviderTypeID for Balance adjustment in AddAccountStatus. |
| 3 | OccurredAt | datetime | NO | getutcdate() | CODE-BACKED | DB server UTC timestamp when this snapshot was recorded. First column of the clustered PK - physical ordering by time optimizes range queries (purge: WHERE OccurredAt < GETDATE()-30, current status: WHERE OccurredAt >= @LastRunTime). Default DF__HedgeAccountStatus = GETUTCDATE(). |
| 4 | OccurredAtAccount | datetime | YES | - | CODE-BACKED | The liquidity provider's own timestamp for this status report. NULL-able because some providers do not supply a timestamp. May differ from OccurredAt due to network latency or provider clock drift. Referenced in Confluence data comparison queries as the provider-side time reference. |
| 5 | Balance | decimal(18,4) | YES | - | CODE-BACKED | Account cash balance in USD, adjusted before storage for specific provider types: FD (TypeID=3): Balance = UsedMargin + UsableMargin - NetPL; IB (TypeID=11): Balance = Equity - NetPL; others: stored as provided. Represents available cash in the hedge account. |
| 6 | NetPL | decimal(18,4) | YES | - | CODE-BACKED | Unrealized net P&L on currently open hedge positions, in USD. Confirmed as "UnrealizedPL" by Confluence comparison query (`a.NetPL as UnrealizedPL`). Used in Balance recalculation for FD and IB providers. Negative = hedge positions currently losing money. |
| 7 | Equity | decimal(18,4) | YES | - | CODE-BACKED | Total account equity = Balance + NetPL (approximately). Used in IB Balance recalculation: Balance = Equity - NetPL. Represents the account's total value including floating P&L. |
| 8 | UsedMargin | decimal(16,4) | YES | - | CODE-BACKED | Margin currently committed to open hedge positions, in USD. Used in FD Balance recalculation. Represents how much of the account is locked by active positions. |
| 9 | UsableMargin | decimal(16,4) | YES | - | CODE-BACKED | Free margin available for new hedge orders, in USD. Used in FD Balance recalculation: Balance = UsedMargin + UsableMargin - NetPL. |
| 10 | MaintenanceMargin | decimal(16,4) | YES | - | CODE-BACKED | Minimum margin required to maintain current open positions without a margin call, in USD. Below this level the provider would force-close positions. |
| 11 | CurrentLeverage | decimal(16,4) | YES | - | CODE-BACKED | Current leverage ratio (e.g., 10.0 = 10:1 leverage). Reflects the ratio of GrossPositionsValue to Balance/Equity. Monitored for compliance with per-server leverage limits. |
| 12 | Cushion | decimal(16,4) | YES | - | CODE-BACKED | Available margin buffer above the maintenance margin level. Cushion = UsableMargin - MaintenanceMargin (approximately). Indicates how much headroom the account has before a margin call. |
| 13 | GrossPositionsValue | decimal(16,4) | YES | - | CODE-BACKED | Total notional value of all open hedge positions, in USD. Used to derive CurrentLeverage. Higher values indicate larger open hedge book exposure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK | The hedge server whose account is being snapshotted. FK__AccountStatus_HedgeServer. |
| LiquidityAccountID | Trade.LiquidityAccounts | FK | The liquidity provider account being monitored. FK_AccountStatus__LiquidityAccounts. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddAccountStatus | - | Writer | Inserts snapshot with provider-specific Balance adjustment for FD and IB accounts. |
| Hedge.AddHedgeAccountStatus | - | Writer | Inserts snapshot without Balance adjustment (stores provider values as-is). |
| Hedge.GetCurrentAccountStatus | - | Reader/TVF | Returns most recent row per HedgeServerID within last hour. Used by real-time monitoring. |
| Hedge.GetReferenceAccountStatus | - | Reader | Returns most recent row per HedgeServerID within a date range. Used for historical comparison. |
| Hedge.CalculateAccountStatusFromNetting | - | Related | Calculates unrealized P&L from current netting (a cross-check against AccountStatus.NetPL). |
| Hedge.DelAccountStatus | - | Deleter | Purges rows older than 30 days in batches of 50,000. |
| Hedge.ArchiveAccountStatus | - | Archiver | Archives rows to History before deletion. |
| Hedge.ArchiveHedgeTables | - | Archiver | Umbrella archive procedure. |
| Hedge.ArchiveHedgeTables_SS | - | Archiver | Secondary-server archive variant. |
| Hedge.HedgeCostReportHistoryPerDay | - | Reader | Daily hedge cost report uses AccountStatus for unrealized P&L baseline. |
| Hedge.HedgeCostReportHistoryPerHour | - | Reader | Hourly hedge cost report. |
| Hedge.DeleteRecordsFromHedgingTables | - | Deleter | Umbrella delete procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AccountStatus (table)
```

This table has no code-level dependencies. FK targets are structural references only.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddAccountStatus | Procedure | Writer - inserts with provider-type Balance adjustment |
| Hedge.AddHedgeAccountStatus | Procedure | Writer - inserts without adjustment |
| Hedge.GetCurrentAccountStatus | Function | Reader - returns latest row per HedgeServerID (TVF) |
| Hedge.GetReferenceAccountStatus | Procedure | Reader - returns latest row per server in date range |
| Hedge.DelAccountStatus | Procedure | Deleter - 30-day rolling purge |
| Hedge.ArchiveAccountStatus | Procedure | Archiver |
| Hedge.ArchiveHedgeTables | Procedure | Umbrella archiver |
| Hedge.ArchiveHedgeTables_SS | Procedure | Secondary-server archiver |
| Hedge.HedgeCostReportHistoryPerDay | Procedure | Reader - daily cost report |
| Hedge.HedgeCostReportHistoryPerHour | Procedure | Reader - hourly cost report |
| Hedge.CalculateAccountStatusFromNetting | Procedure | Related calculation - cross-checks unrealized P&L from netting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeAccountStatus | CLUSTERED PK | OccurredAt ASC, HedgeServerID ASC, LiquidityAccountID ASC | - | - | Active (FILLFACTOR=95) |
| Idx_Hedge_AccountStatus_HedgeServerID_OccurredAt | NC | HedgeServerID ASC, OccurredAt ASC | Balance, NetPL | - | Active (FILLFACTOR=95, filegroup: MAIN) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeAccountStatus | PRIMARY KEY | Composite: OccurredAt + HedgeServerID + LiquidityAccountID - one snapshot per server/account per moment |
| FK__AccountStatus_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_AccountStatus__LiquidityAccounts | FOREIGN KEY | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| DF__HedgeAccountStatus | DEFAULT | OccurredAt = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get current account status (latest snapshot per hedge server, last hour)
```sql
SELECT HedgeServerID, LiquidityAccountID, OccurredAt, OccurredAtAccount,
       Balance, NetPL, Equity, UsedMargin, UsableMargin, CurrentLeverage
FROM Hedge.GetCurrentAccountStatus(DATEADD(minute, -5, GETUTCDATE())) WITH (NOLOCK)
ORDER BY HedgeServerID;
```

### 8.2 Account status trend for a specific server over the last 24 hours
```sql
SELECT HedgeServerID, LiquidityAccountID, OccurredAt,
       Balance, NetPL, Equity, UsedMargin, CurrentLeverage, Cushion
FROM Hedge.AccountStatus WITH (NOLOCK)
WHERE HedgeServerID = 3
  AND OccurredAt > DATEADD(hour, -24, GETUTCDATE())
ORDER BY OccurredAt DESC;
```

### 8.3 Current account health joined to server and account details
```sql
SELECT HS.HedgeServerID,
       HS.IPAddress + ':' + CAST(HS.Port AS varchar) AS HedgeServer,
       LA.LiquidityAccountName,
       CAS.Balance, CAS.NetPL, CAS.Equity,
       CAS.UsedMargin, CAS.UsableMargin, CAS.CurrentLeverage,
       CAS.OccurredAt AS LastUpdated
FROM Hedge.GetCurrentAccountStatus(DATEADD(minute, -10, GETUTCDATE())) CAS WITH (NOLOCK)
JOIN Trade.HedgeServer HS WITH (NOLOCK)
  ON CAS.HedgeServerID = HS.HedgeServerID
JOIN Trade.LiquidityAccounts LA WITH (NOLOCK)
  ON CAS.LiquidityAccountID = LA.LiquidityAccountID
WHERE HS.IsActive = 1
ORDER BY CAS.Balance ASC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Production Data comparison 31/01/21](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/1845952868) | Confluence | Confirms AccountStatus.NetPL = UnrealizedPL. Provides the canonical cross-validation query: `SELECT LiquidityAccountID, OccurredAt, OccurredAtAccount, Balance, NetPL AS UnrealizedPL FROM Hedge.AccountStatus`. Used to align accountstatusplservice output with delta desk DB data. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AccountStatus | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.AccountStatus.sql*
