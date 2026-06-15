# Hedge.Netting

> Live net hedge position table - stores the current aggregate open hedge position for each (liquidity account, instrument, value date) combination, enabling the hedge server to track what it has already hedged and compute unrealized P&L on the hedge book.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (LiquidityAccountID, InstrumentID, ValueDate) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 2 active (1 CLUSTERED PK + 1 NC on InstrumentID) |

---

## 1. Business Meaning

Hedge.Netting represents the hedge server's "open book" - for each financial instrument traded on each liquidity provider account, it holds the current net aggregate position: how many units the hedge server has bought or sold on the market to offset eToro's customer book exposure. Think of it as the current state of the hedge server's trading portfolio with each LP.

This table exists because the hedge server does not hedge each customer trade individually - instead, it nets many customer trades into a single large aggregate position per instrument per LP account. Without this table, the hedge server would have no persistent record of what it has already hedged, making exposure calculation and reconciliation impossible. It also feeds the PnL calculation: by comparing the average entry rate (AvgRate) against the current market rate, the system can compute the unrealized gain/loss on the hedge portfolio.

Data flows as an ongoing upsert: when the hedge server executes a hedge order, it calls Hedge.AddOrUpdateNetting to adjust the position. The table is also written when the ExposureBalancer corrects imbalances (noted by UpdateNetting=true in ManualOrderExecutionLog). System versioning automatically captures every change to History.Netting_History, providing a complete point-in-time history of the hedge book's evolution.

---

## 2. Business Logic

### 2.1 Upsert Semantics - One Active Position per Instrument per Account

**What**: The table maintains at most one active position per (LiquidityAccountID, InstrumentID) combination via upsert semantics.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`, `ValueDate`, `Units`, `IsBuy`, `AvgRate`

**Rules**:
- Hedge.AddOrUpdateNetting first attempts UPDATE WHERE (LiquidityAccountID, InstrumentID) - note: no ValueDate filter
- If 0 rows updated (no existing position), it inserts a new row with the given ValueDate
- This means: when a position rolls to a new ValueDate, the UPDATE overwrites the old ValueDate - the PK uniqueness on 3 columns is a design artifact, not a multi-position mechanism
- Net result: exactly one row per (LiquidityAccountID, InstrumentID) exists at any point (for different instruments under the same account)
- Hedge.RemoveNetting deletes a specific position when it is closed or rolled off; Hedge.RemoveBadNetting removes all positions for a HedgeServerID that do not belong to the specified LiquidityAccountID (data integrity cleanup)

**Diagram**:
```
Customer trades accumulate ->
  Hedge server calculates net exposure ->
    Hedge.AddOrUpdateNetting called ->

  IF row exists for (LiquidityAccountID, InstrumentID):
    UPDATE Units, IsBuy, AvgRate, ValueDate, ExecTime, UpdateTime
    [temporal history captured automatically in History.Netting_History]

  ELSE:
    INSERT new row
    [SysStartTime = now, SysEndTime = 9999-12-31]
```

### 2.2 Unrealized P&L Calculation

**What**: The combination of Units, IsBuy, and AvgRate enables real-time unrealized P&L computation on the hedge book.

**Columns/Parameters Involved**: `Units`, `IsBuy`, `AvgRate`, `LiquidityAccountID`

**Rules**:
- Hedge.CalculateAccountStatusFromNetting computes PnL by joining with Trade.CurrencyPrice
- Formula: `SUM(Units * (Bid - AvgRate) * UnitMargin/Bid * direction)` where direction = 1 for IsBuy=true, -1 for IsBuy=false
- Long position (IsBuy=true): profit when current Bid > AvgRate
- Short position (IsBuy=false): profit when current Bid < AvgRate
- Aggregated across all instruments for a given LiquidityAccountID

**Diagram**:
```
Hedge.Netting (LiquidityAccountID=10, InstrumentID=5, Units=224M, IsBuy=true, AvgRate=159.32)
           +
Trade.CurrencyPrice (InstrumentID=5, Bid=current market price)
           |
           v
PnL = 224,924,151 * (Bid - 159.32) * UnitMargin/Bid
           = unrealized P&L on this position in account currency
```

### 2.3 System Versioning - Full Position History

**What**: Every change to a netting position is captured automatically in History.Netting_History via SQL Server system-versioning.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- When any row is inserted, SysStartTime = current UTC time, SysEndTime = 9999-12-31 23:59:59 (current row sentinel)
- When a row is updated, the old version is moved to History.Netting_History with SysEndTime = update timestamp; new version gets SysStartTime = update timestamp
- When a row is deleted, the old version moves to History.Netting_History with SysEndTime = delete timestamp
- Point-in-time queries: `SELECT * FROM Hedge.Netting FOR SYSTEM_TIME AS OF '2026-01-01'` returns the state of all positions at that moment
- This provides automatic audit trail without any application code changes

---

## 3. Data Overview

| LiquidityAccountID | InstrumentID | Units | IsBuy | AvgRate | ValueDate | Meaning |
|---|---|---|---|---|---|---|
| 10 | 5 | 224,924,151 | true | 159.32 | 2026-02-09 | Main LP account (10) holds 224M units long on InstrumentID 5 (a high-volume forex or major asset). ValueDate 2026-02-09 is the settlement date with the LP. The massive unit count reflects the net of all eToro customer positions in this instrument. |
| 10 | 100000 | 9,376.85 | true | 104,023.48 | 2026-02-09 | 9,376 units long on InstrumentID 100000 at rate 104,023 - likely Bitcoin (BTC) based on the price scale. The fractional unit count shows high-precision tracking of crypto holdings. |
| 10 | 1127 | 10,709.95 | true | 1,019.75 | 2026-02-08 | InstrumentID 1127 settles on 2026-02-08 (one day earlier than most) - some instruments have different settlement calendars. Rate around 1,019 suggests a mid-priced equity or commodity. |
| 10 | 2089 | 1,383,887 | true | 35.26 | 2026-02-09 | 1.38M units at rate 35.26 - a low-priced asset with large unit quantities (typical for stocks trading at $35). The scale shows how eToro's customer book exposure translates to large hedge volumes. |
| 10 | 32 | 204.52 | true | 18,306.40 | 2026-02-08 | InstrumentID 32 at rate 18,306 - a high-value instrument (possibly gold or a high-priced stock). Only 204 units needed because each unit represents significant dollar value. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | VERIFIED | First component of composite PK. FK to Trade.LiquidityAccounts - identifies which liquidity provider account holds this hedge position. In production, LiquidityAccountID=10 holds the dominant position (713/738 rows), representing the main execution account. Remaining accounts (2145-2152, 354541, etc.) are alternative or testing LP accounts. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Second component of composite PK. FK to Trade.Instrument (implicit - no declared constraint). The financial instrument being hedged. Each unique InstrumentID under a given LiquidityAccountID represents a separate hedge book entry. Indexed separately (IX_InstrumentID) to support instrument-level queries. |
| 3 | Units | decimal(16,2) | YES | - | VERIFIED | The net aggregate size of the open hedge position in units of the instrument. 2 decimal places (vs 6 in ManualOrderExecutionLog) reflects that netting positions are rounded to avoid micro-lot accumulation. Used directly in PnL formula: `Units * (Bid - AvgRate) * UnitMargin/Bid`. |
| 4 | IsBuy | bit | NO | - | VERIFIED | Direction of the net hedge position. true = net long (bought more than sold on the LP), false = net short (sold more than bought). 82% of current positions are long (IsBuy=true), reflecting that eToro's customer book is predominantly long across most instruments - requiring the hedge server to hold corresponding long positions. Used as a sign multiplier in PnL calculation (1 for long, -1 for short). |
| 5 | AvgRate | dbo.dtPrice | YES | - | VERIFIED | Volume-weighted average entry rate of the current net position, using the custom dbo.dtPrice type. This is the blended price across all hedge executions that make up the current netting position. Used in PnL formula as cost basis: `Bid - AvgRate` gives the gain/loss per unit since entry. For positions built up over many trades, this will differ from the current market rate, reflecting accumulated execution. |
| 6 | ValueDate | date | NO | - | CODE-BACKED | Third component of composite PK. The settlement/delivery date with the liquidity provider - when the actual transfer of underlying assets or cash occurs for the hedge position. DATE type (no time component) reflects that settlement dates are calendar-day boundaries. While included in the PK, the AddOrUpdateNetting upsert updates this column on each position change, so effectively one ValueDate exists per (LiquidityAccountID, InstrumentID) pair at any time. |
| 7 | ExecTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the last hedge execution that contributed to this position (nanosecond precision via datetime2(7)). Set by AddOrUpdateNetting from the @ExecTime parameter. Differs from UpdateTime in that ExecTime reflects when the market execution occurred, while UpdateTime reflects when the database was updated. |
| 8 | UpdateTime | datetime2(7) | YES | - | VERIFIED | Timestamp when this netting position row was last written to the database. Set by AddOrUpdateNetting from the @UpdateTime parameter. In practice, ExecTime and UpdateTime are within milliseconds of each other (they're set together in the same call). UpdateTime determines SysStartTime in the temporal versioning system. |
| 9 | HedgeServerID | int | NO | - | VERIFIED | FK to Trade.HedgeServer (implicit). Identifies which hedge server instance manages this position. HedgeServerID=1 dominates (713/738 rows = the primary production hedge server). Additional server IDs (5, 8, 9, 12, 222, 1100, 5454) represent test environments or secondary hedge server instances. RemoveBadNetting uses this column to clean up positions that appear under the wrong LiquidityAccountID for a given HedgeServer. |
| 10 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-generated temporal column. Records when this version of the row became current (UTC). Set automatically by SQL Server when the row is inserted or updated. Combined with SysEndTime enables `FOR SYSTEM_TIME AS OF` point-in-time queries across Hedge.Netting and History.Netting_History. |
| 11 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-generated temporal column. Records when this version of the row stopped being current. For all current (live) rows: value = 9999-12-31 23:59:59.9999999 (the "forever" sentinel meaning "currently valid"). When a row is updated or deleted, the old version is moved to History.Netting_History with SysEndTime = the update/delete timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | FK (explicit, WITH CHECK) | Identifies the LP account through which this hedge position is executed. Each position belongs to exactly one LP account. |
| InstrumentID | Trade.Instrument | Implicit | Identifies the financial instrument for the hedge position. No declared FK (performance optimization). |
| HedgeServerID | Trade.HedgeServer | Implicit | Identifies the hedge server instance managing this position. No declared FK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddOrUpdateNetting | LiquidityAccountID, InstrumentID | WRITER/MODIFIER | Upserts the current netting position after each hedge execution |
| Hedge.GetNetting | LiquidityAccountID | READER | Returns all open positions for a given LP account |
| Hedge.RemoveNetting | LiquidityAccountID, InstrumentID | DELETER | Removes a closed or rolled-off position |
| Hedge.RemoveBadNetting | HedgeServerID, LiquidityAccountID | DELETER | Cleans up positions assigned to the wrong LP account for a hedge server |
| Hedge.CalculateAccountStatusFromNetting | LiquidityAccountID | READER | Computes total unrealized P&L for a LP account's hedge book |
| Hedge.AddAccountPositionsFromNetting | - | READER | Reads netting positions to derive account-level hedge exposure |
| Hedge.RemoveMultiBadNetting | HedgeServerID | DELETER | Bulk cleanup - removes all netting rows for a server where LiquidityAccountID is not in its currently configured valid LP set (HedgeServerToLiquidityAccount) |
| Hedge.GetExposuresForAllHedgeServers | - | VIEW | Aggregates netting data across all hedge servers for exposure monitoring |
| History.Netting_History | - | Temporal history | Automatic archive - captures all versions of each row |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Netting (table)
├── Trade.LiquidityAccounts (table) [FK target - leaf]
├── Trade.Instrument (table) [implicit FK target - leaf]
└── Trade.HedgeServer (table) [implicit FK target - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID - constrains which LP accounts can hold positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddOrUpdateNetting | Stored Procedure | WRITER/MODIFIER - upserts the netting position on each hedge execution |
| Hedge.GetNetting | Stored Procedure | READER - retrieves all positions for a LiquidityAccountID |
| Hedge.RemoveNetting | Stored Procedure | DELETER - removes a specific position by LA+Instrument+ValueDate |
| Hedge.RemoveBadNetting | Stored Procedure | DELETER - removes positions with mismatched HedgeServerID/LiquidityAccountID |
| Hedge.RemoveMultiBadNetting | Stored Procedure | DELETER - bulk version of RemoveBadNetting |
| Hedge.CalculateAccountStatusFromNetting | Stored Procedure | READER - computes PnL using live prices from Trade.CurrencyPrice |
| Hedge.AddAccountPositionsFromNetting | Stored Procedure | READER - reads positions to compute account-level exposure |
| Hedge.GetExposuresForAllHedgeServers | View | READER - aggregates positions for exposure dashboard |
| History.Netting_History | Table | TEMPORAL HISTORY - auto-populated by system versioning |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_NettingTemp | CLUSTERED PK | LiquidityAccountID ASC, InstrumentID ASC, ValueDate ASC | - | - | Active |
| IX_InstrumentID | NONCLUSTERED | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_NettingTemp | PRIMARY KEY | Unique hedge position per (LiquidityAccount, Instrument, ValueDate). FILLFACTOR=95 allows 5% free space per page for in-place updates without page splits. |
| FK_Netting_LiquidityAccountID_Temp | FOREIGN KEY (WITH CHECK) | LiquidityAccountID must exist in Trade.LiquidityAccounts |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime/SysEndTime managed by SQL Server for system-versioning |
| SYSTEM_VERSIONING = ON | TEMPORAL | Changes are automatically archived to History.Netting_History |

---

## 8. Sample Queries

### 8.1 Current hedge book for the main LP account
```sql
SELECT  n.InstrumentID,
        n.Units,
        CASE WHEN n.IsBuy = 1 THEN 'Long' ELSE 'Short' END AS Direction,
        n.AvgRate,
        n.ValueDate,
        n.UpdateTime
FROM    [Hedge].[Netting] n WITH (NOLOCK)
WHERE   n.LiquidityAccountID = 10
ORDER BY n.Units DESC;
```

### 8.2 Unrealized P&L across all instruments for the main LP account
```sql
SELECT  hn.InstrumentID,
        hn.Units,
        hn.AvgRate,
        tcp.Bid AS CurrentRate,
        SUM(hn.Units * (tcp.Bid - hn.AvgRate) * tcp.UnitMargin / tcp.Bid
            * CASE WHEN hn.IsBuy = 0 THEN -1 ELSE 1 END) AS UnrealizedPnL
FROM    [Hedge].[Netting] hn WITH (NOLOCK)
JOIN    [Trade].[CurrencyPrice] tcp WITH (NOLOCK)
        ON hn.InstrumentID = tcp.InstrumentID
WHERE   hn.LiquidityAccountID = 10
GROUP BY hn.InstrumentID, hn.Units, hn.AvgRate, tcp.Bid
ORDER BY ABS(SUM(hn.Units * (tcp.Bid - hn.AvgRate) * tcp.UnitMargin / tcp.Bid
            * CASE WHEN hn.IsBuy = 0 THEN -1 ELSE 1 END)) DESC;
```

### 8.3 Historical position for a specific instrument (point-in-time via system versioning)
```sql
-- Current position
SELECT  n.LiquidityAccountID, n.Units, n.IsBuy, n.AvgRate, n.ValueDate,
        n.SysStartTime, n.SysEndTime
FROM    [Hedge].[Netting] n WITH (NOLOCK)
WHERE   n.InstrumentID = 5

UNION ALL

-- Historical positions from the archive
SELECT  nh.LiquidityAccountID, nh.Units, nh.IsBuy, nh.AvgRate, nh.ValueDate,
        nh.SysStartTime, nh.SysEndTime
FROM    [History].[Netting_History] nh WITH (NOLOCK)
WHERE   nh.InstrumentID = 5
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | Referenced in search (2026-03-18, very recent) - likely describes the overall hedge system architecture including netting. Content not accessible via API. |
| [Exposure Balancer Saga - HLD](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13823705272/Exposure+Balancer+Saga+-+HLD) | Confluence | Referenced in search (2026-01-22) - describes the ExposureBalancer service which reads and updates Netting positions. Content not accessible via API. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence (content inaccessible) + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.Netting | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.Netting.sql*
