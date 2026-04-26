# BI_DB_dbo.BI_DB_InvestorsKPI

> 322M-row daily AM portfolio KPI table tracking Gold-through-Diamond customers assigned to Account Managers — capturing per-customer investment amounts (AUA by type), deposits, withdrawals, copy-portfolio AUM, and monthly membership flags (Apr 2021–Apr 2026, 21 cols). Written by `SP_InvestorKPI` from `Fact_SnapshotCustomer`+`BI_DB_PositionPnL`+`Guru_Copiers`. Feeds Account Manager bonus calculations and high-value customer dashboards.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `Fact_SnapshotCustomer` + `BI_DB_PositionPnL` + `BI_DB_Guru_Copiers` + `Fact_CustomerAction` + `V_Liabilities` via SP_InvestorKPI |
| **Refresh** | Daily SB_Daily (conditional incremental — see Section 2.2) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC); NONCLUSTERED (ActiveMonth, CID, AccountManagerID) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Unknown (SP header has no author comment) |
| **Row Count** | ~322M (Apr 2021 – Apr 2026) |

---

## 1. Business Meaning

`BI_DB_InvestorsKPI` is the daily Account Manager (AM) portfolio KPI table. It tracks the investment metrics of high-value eToro customers — specifically those at Club tier Gold, Platinum, Platinum Plus, or Diamond — who are assigned to a dedicated Account Manager in the BackOffice CRM system.

Each row represents one customer (CID) under one Account Manager (AccountManagerID) on one day (DateID), for one monthly portfolio cohort (ActiveMonth). The table answers: "What are the investment positions, deposits, withdrawals, and copy-AUM of each club customer managed by each AM, for bonus calculation purposes?"

The table covers Apr 2021–Apr 2026 (~322M rows). With ~486K unique customers on any given date (Gold=52%, Platinum=26%, Platinum Plus=18%, Diamond=2%), most rows are daily observations within the month's AM portfolio. As of 2026-04-11: 96.4% not blocked, 3.6% blocked (restricted status).

**Investment type breakdown** (columns Investment/Crypto/Trade) classifies each customer's open positions from `BI_DB_PositionPnL` into three buckets based on instrument type and leverage:
- **Investment**: InstrumentTypeID=6, or InstrumentTypeID in (4,5) with Leverage<3 — real stocks and low-leverage ETFs/funds
- **Crypto**: InstrumentTypeID=10 — crypto assets
- **Trade**: All other positions — CFD/leveraged instruments

`InvestedAmountCopy` captures the customer's total copy-portfolio AUM from `BI_DB_Guru_Copiers` (Investment + Cash) at the next day's timestamp.

`Classification` is always NULL — the column was commented out in the SP and was never implemented.

---

## 2. Business Logic

### 2.1 Population Filter (Who Qualifies)

**What**: Only a specific subset of customers appears in this table — high-value club members actively managed by an Account Manager.

**Columns Involved**: CID, AccountManagerID, Club, IsBlocked

**Rules**:
- Must be `IsValidCustomer=1` at @DateID per `Fact_SnapshotCustomer` + `Dim_Range` SCD lookup
- Must have Club tier Gold, Platinum, Platinum Plus, or Diamond (`PlayerLevelID IN (2,3,6,7)` per `BI_DB_CID_DailyPanel_Club`)
- Must have an assigned Account Manager (`AccountManagerID` from Fact_SnapshotCustomer)
- IsDowngrade logic: when `BI_DB_CID_DailyPanel_Club.IsDowngrade=1`, uses `LastTier` for the PlayerLevel check (not CurrentTier) — prevents recently downgraded customers from being immediately removed
- IsBlocked=1 when `PlayerStatusID IN (2,4,6,7,8,14)` — these customers remain in the table but are flagged as restricted

### 2.2 Monthly Loading Logic

**What**: The SP uses two different loading paths depending on the day of month — the first 3 days lock in the monthly "start" population; the rest of the month handles additions and ongoing updates.

**Columns Involved**: IsStartOfMonth, IsEndOfMonth, IsFullMonth, ReportingMonth, ActiveMonth, DateID

**Rules (Days 1–3 of month)**:
- Deletes: all rows with `DateID >= @DateID AND ActiveMonth = @StartOfMonth`
- Inserts all qualifying customers as IsStartOfMonth=1, IsEndOfMonth=0, IsFullMonth=1 (provisionally)
- `IsStartOfMonth=1` marks the month-opening portfolio snapshot (used for AM bonus base)
- `ReportingMonth = @StartOfMonth` — counts towards current month's bonus report

**Rules (Days 4+ of month)**:
- Deletes: only `IsStartOfMonth=0` rows for the current ActiveMonth (preserves start-of-month records)
- For **new customers** (first appearance in this ActiveMonth): `IsStartOfMonth=1, IsEndOfMonth=0, IsFullMonth=1`, `ReportingMonth = DATEADD(MONTH,1,@StartOfMonth)` — reports to NEXT month (joined mid-month)
- For **ongoing customers**: `IsStartOfMonth=0, IsEndOfMonth=1, IsFullMonth=1`, preserves their ReportingMonth from first insert
- Rolling `IsEndOfMonth` UPDATE: sets IsEndOfMonth=0 for all non-current-day rows in month; only latest-day rows get IsEndOfMonth=1
- Rolling `IsFullMonth` UPDATE: IsFullMonth=1 if CID+AccountManagerID appears both as IsStartOfMonth=1 AND in today's load

### 2.3 Asset-Under-Advisory (AUA) Classification

**What**: Open position amounts are split into three strategic investment buckets for AM performance reporting.

**Columns Involved**: Investment, Crypto, Trade

**Rules**:
- `BI_DB_PositionPnL.Amount` at @DateID, filtered to `MirrorID=0` (direct customer positions, not copy-mirrored)
- **Investment** = InstrumentTypeID=6 (real stocks?) OR (InstrumentTypeID IN (4,5) AND Leverage<3)
- **Crypto** = InstrumentTypeID=10
- **Trade** = all remaining instrument types (leveraged CFD)
- Zero if customer has no positions of that type (ISNULL...0)

### 2.4 Copy-Portfolio AUM (InvestedAmountCopy)

**What**: The customer's total copy-portfolio value (AUM in copy trading) read from `BI_DB_Guru_Copiers`.

**Columns Involved**: InvestedAmountCopy

**Rules**:
- `SUM(ISNULL(Investment,0) + ISNULL(Cash,0))` from `BI_DB_Guru_Copiers` where `TimestampID = DateID+1` (next day's YYYYMMDD)
- MAX is taken to handle potential duplicate GC rows
- Zero if customer has no copy portfolio (ISNULL...0)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution: ROUND_ROBIN. Clustered on DateID — always filter on DateID or ActiveMonth + DateID for efficient scans. Nonclustered index on (ActiveMonth, CID, AccountManagerID) supports AM-portfolio queries within a month.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| AM portfolio totals for current month-end | `SELECT AccountManagerID, AM, SUM(Investment+Crypto+Trade) WHERE ActiveMonth='2026-04-01' AND IsEndOfMonth=1` |
| Monthly KPI for an AM (start-of-month snapshot) | `SELECT * WHERE AccountManagerID=@AM AND IsStartOfMonth=1 AND ActiveMonth=@Month` |
| Full-month customers per AM | `SELECT CID, AM, Investment, Crypto, Trade WHERE IsFullMonth=1 AND ActiveMonth=@Month` |
| Customers blocked in AM portfolio | `SELECT CID, AM, Club WHERE IsBlocked=1 AND DateID=@D` |
| Daily deposits for club customers | `SELECT CID, Club, Deposit, Withdrawal WHERE DateID=@D AND Deposit>0 ORDER BY Deposit DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Manager | AccountManagerID = ManagerID | Full manager details (IsActive, SFManagerID) |
| DWH_dbo.Dim_Date | DateID = DateKey | Calendar attributes |
| BI_DB_InvestorsKPITarget | AccountManagerID + ActiveMonth | AM KPI targets vs actuals |

### 3.4 Gotchas

- **Classification is always NULL**: Do not attempt to use or filter on Classification — it was commented out of the SP and returns NULL for every row
- **InvestedAmountCopy reads NEXT day's Guru_Copiers**: TimestampID = @Date+1; any delay in Guru_Copiers load for next day will result in 0 for this column
- **Balance = V_Liabilities.Credit, not equity**: The "Balance" column is the customer's credit line from V_Liabilities, not their full account equity or portfolio value
- **ReportingMonth ≠ ActiveMonth for mid-month new additions**: Customers added after day 3 of a month report to the NEXT month (ReportingMonth = ActiveMonth + 1 month). Do not use ReportingMonth without understanding this split
- **ROUND_ROBIN on 322M rows**: Full-table scans are expensive. Always filter on DateID (clustered) or (ActiveMonth, CID, AccountManagerID) (nonclustered)
- **Rolling IsEndOfMonth rewrite**: After the day-4+ path runs, all prior-day rows in the month have IsEndOfMonth=0 and only today's records have IsEndOfMonth=1. Querying for IsEndOfMonth=1 gives only the LATEST snapshot, not all historical end-of-day snapshots
- **Only Gold/Platinum/PlatinumPlus/Diamond**: Absence from this table means a customer is not a club member or is not assigned to an AM — not that they have no positions
- **MirrorID=0 filter in position amounts**: Copy-trading mirror positions are excluded from Investment/Crypto/Trade aggregates. A heavy copier may show 0 Investment but non-zero InvestedAmountCopy

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | From ETL SP code, DWH dimensions, or BI_DB intermediate tables |
| Tier 3 | ETL infrastructure (GETDATE(), system columns) |
| Tier 4 | Unimplemented — always NULL in production data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | YYYYMMDD integer of the daily snapshot date. Primary clustered index key for date-range queries. Range: 20210401–20260411. (Tier 2 — SP_InvestorKPI @Date parameter) |
| 2 | Date | date | YES | Calendar date of the daily snapshot. Corresponds to DateID. (Tier 2 — SP_InvestorKPI @Date parameter) |
| 3 | ReportingMonth | date | YES | First day of the month this record counts towards for AM bonus reporting. Days 1–3 additions: same as ActiveMonth. Mid-month new customer additions (day 4+): DATEADD(MONTH,1,ActiveMonth) — next month. (Tier 2 — SP_InvestorKPI) |
| 4 | ActiveMonth | date | YES | First day of the month in which the customer was in the AM's portfolio. Always = first day of current month at load time. Groups all daily rows for a month's portfolio cohort. (Tier 2 — SP_InvestorKPI) |
| 5 | CID | int | YES | Customer identifier (RealCID). Filtered to Gold–Diamond club members assigned to an Account Manager. (Tier 2 — Fact_SnapshotCustomer.RealCID via BI_DB_CID_DailyPanel_Club) |
| 6 | AM | varchar(255) | YES | Full name of the assigned Account Manager: `FirstName + ' ' + LastName` from `DWH_dbo.Dim_Manager`. (Tier 2 — Dim_Manager.FirstName + Dim_Manager.LastName) |
| 7 | AccountManagerID | int | YES | ManagerID of the assigned Account Manager. FK to `DWH_dbo.Dim_Manager`. (Tier 2 — Fact_SnapshotCustomer.AccountManagerID) |
| 8 | Investment | money | NO | Sum of open position amounts in 'Investment' category (stocks and low-leverage funds: InstrumentTypeID=6, or 4/5 with Leverage<3) from BI_DB_PositionPnL at @DateID. MirrorID=0 only. ISNULL to 0. (Tier 2 — SP_InvestorKPI via BI_DB_PositionPnL + Dim_Instrument) |
| 9 | Crypto | money | YES | Sum of open position amounts in crypto (InstrumentTypeID=10) from BI_DB_PositionPnL at @DateID. MirrorID=0 only. NULL if no crypto positions. (Tier 2 — SP_InvestorKPI via BI_DB_PositionPnL + Dim_Instrument) |
| 10 | Trade | money | YES | Sum of open position amounts in all other instrument types (CFD/leveraged) from BI_DB_PositionPnL at @DateID. MirrorID=0 only. NULL if no trade positions. (Tier 2 — SP_InvestorKPI via BI_DB_PositionPnL + Dim_Instrument) |
| 11 | InvestedAmountCopy | money | YES | Total copy-portfolio AUM: SUM(Investment + Cash) from BI_DB_Guru_Copiers at TimestampID=next-day-DateID. Represents money deployed in copy trading. ISNULL to 0. (Tier 2 — SP_InvestorKPI via BI_DB_Guru_Copiers) |
| 12 | Balance | money | YES | Customer credit balance from `DWH_dbo.V_Liabilities.Credit` at @DateID. NOTE: this is credit/balance, not full portfolio equity. ISNULL to 0. (Tier 2 — SP_InvestorKPI via V_Liabilities) |
| 13 | Deposit | money | YES | Total deposit amount on @DateID. SUM of Fact_CustomerAction.Amount WHERE ActionTypeID=7. ISNULL to 0. (Tier 2 — SP_InvestorKPI via Fact_CustomerAction) |
| 14 | Withdrawal | money | YES | Total withdrawal amount on @DateID. SUM of Fact_CustomerAction.Amount WHERE ActionTypeID=8. ISNULL to 0. (Tier 2 — SP_InvestorKPI via Fact_CustomerAction) |
| 15 | IsStartOfMonth | int | YES | 1 if this row is the start-of-month portfolio record for this CID+AccountManagerID (loaded days 1–3 or on first appearance mid-month). 0 for ongoing daily records. (Tier 2 — SP_InvestorKPI OUTER APPLY logic) |
| 16 | IsEndOfMonth | int | YES | Rolling indicator: 1 for the most recently loaded record of each CID+AccountManagerID+ActiveMonth combination; 0 for all prior rows. Reset on each daily load to maintain only the latest record as end-of-month candidate. (Tier 2 — SP_InvestorKPI rolling UPDATE) |
| 17 | IsFullMonth | int | YES | 1 if the customer was in the AM portfolio at both the start (IsStartOfMonth=1) AND the end (IsEndOfMonth=1) of the month. Used to determine if AM earned full bonus for this customer. Updated daily via rolling UPDATE. (Tier 2 — SP_InvestorKPI rolling UPDATE) |
| 18 | IsBlocked | int | YES | 1 if the customer had a blocked/restricted player status at @DateID (PlayerStatusID IN (2,4,6,7,8,14)). Distribution: 0=96.4%, 1=3.6%. (Tier 2 — Fact_SnapshotCustomer.PlayerStatusID) |
| 19 | Classification | varchar(255) | YES | Always NULL. Column was intended for customer classification but was commented out in SP and never implemented. Do not use. (Tier 4 — Unimplemented, always NULL) |
| 20 | UpdateDate | datetime | NO | Batch timestamp set to GETDATE() at INSERT time or at rolling IsFullMonth/IsEndOfMonth UPDATE time. Reflects when SP last touched the row. (Tier 3 — GETDATE()) |
| 21 | Club | varchar(50) | YES | eToro Club loyalty tier name of the customer at @DateID: Gold, Platinum, Platinum Plus, Diamond. Resolved from BI_DB_CID_DailyPanel_Club (IsDowngrade-aware tier selection) → Dim_PlayerLevel.Name. (Tier 2 — Dim_PlayerLevel.Name via BI_DB_CID_DailyPanel_Club) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Schema | Role |
|--------|--------|------|
| Fact_SnapshotCustomer | DWH_dbo | Customer population — RealCID, AccountManagerID, PlayerStatusID, IsValidCustomer |
| Dim_Range | DWH_dbo | SCD date resolution for Fact_SnapshotCustomer |
| BI_DB_CID_DailyPanel_Club | BI_DB_dbo | Club tier filter + IsDowngrade/CurrentTier/LastTier |
| Dim_PlayerLevel | DWH_dbo | Club tier name lookup |
| Dim_Manager | DWH_dbo | Account Manager first+last name |
| Dim_Date | DWH_dbo | PartitionID and IsFirstDayOfMonth lookup |
| BI_DB_PositionPnL | BI_DB_dbo | Investment/Crypto/Trade AUA amounts by InstrumentTypeID |
| Dim_Instrument | DWH_dbo | InstrumentTypeID for AUA classification |
| BI_DB_Guru_Copiers | BI_DB_dbo | Copy-portfolio AUM (InvestedAmountCopy) |
| V_Liabilities | DWH_dbo | Customer credit balance |
| Fact_CustomerAction | DWH_dbo | Deposit (ActionTypeID=7) and Withdrawal (ActionTypeID=8) |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (SCD)
  + BI_DB_dbo.BI_DB_CID_DailyPanel_Club (Gold–Diamond filter)
  + DWH_dbo.Dim_Manager (AM name) + Dim_PlayerLevel (Club name)
         |-- population filter ---|
BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument --> Investment/Crypto/Trade
BI_DB_dbo.BI_DB_Guru_Copiers (next day) --> InvestedAmountCopy
DWH_dbo.V_Liabilities --> Balance
DWH_dbo.Fact_CustomerAction (ActionTypeID 7,8) --> Deposit, Withdrawal
         |-- SP_InvestorKPI @Date (conditional monthly load logic) ---|
         v
BI_DB_dbo.BI_DB_InvestorsKPI (~322M rows, Apr 2021–Apr 2026)
  |-- (No UC target — Not Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | BI_DB_CID_DailyPanel_Club.CID | Club tier and downgrade status |
| AccountManagerID | DWH_dbo.Dim_Manager.ManagerID | AM identity |
| Investment+Crypto+Trade | BI_DB_PositionPnL | Daily open positions by instrument category |
| InvestedAmountCopy | BI_DB_Guru_Copiers | Copy-portfolio AUM |
| Balance | DWH_dbo.V_Liabilities | Customer credit |

### 6.2 Referenced By (other objects point to this)

| Object | How Used |
|--------|----------|
| BI_DB_InvestorsKPITarget | Target table — JOIN on AccountManagerID + ActiveMonth for actual vs. target comparison |
| AM bonus reporting | Finance/BI team reads IsFullMonth=1 + IsStartOfMonth=1 rows for monthly AM bonus calculation |

---

## 7. Sample Queries

### 7.1 AM portfolio summary for end of month (start-of-month cohort)
```sql
SELECT AccountManagerID, AM, Club,
       COUNT(DISTINCT CID) AS Customers,
       SUM(Investment) AS TotalInvestment,
       SUM(Crypto) AS TotalCrypto,
       SUM(Trade) AS TotalTrade,
       SUM(InvestedAmountCopy) AS TotalCopyAUM
FROM [BI_DB_dbo].[BI_DB_InvestorsKPI]
WHERE ActiveMonth = '2026-04-01'
  AND IsEndOfMonth = 1
  AND IsFullMonth = 1
GROUP BY AccountManagerID, AM, Club
ORDER BY TotalInvestment DESC;
```

### 7.2 Daily deposits and withdrawals for club customers on a specific date
```sql
SELECT CID, AM, Club, Deposit, Withdrawal, Balance, IsBlocked
FROM [BI_DB_dbo].[BI_DB_InvestorsKPI]
WHERE DateID = 20260411
  AND (Deposit > 0 OR Withdrawal > 0)
ORDER BY Deposit DESC;
```

### 7.3 Customers who joined an AM mid-month (ReportingMonth ≠ ActiveMonth)
```sql
SELECT CID, AM, Club, ActiveMonth, ReportingMonth, DateID
FROM [BI_DB_dbo].[BI_DB_InvestorsKPI]
WHERE ActiveMonth = '2026-04-01'
  AND ReportingMonth <> ActiveMonth
  AND IsStartOfMonth = 1
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this table.

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Phases: 13/14*
*Tiers: 0 T1, 19 T2, 1 T3, 1 T4 | Elements: 21/21, Logic: 4 subsections*
*Object: BI_DB_dbo.BI_DB_InvestorsKPI | Type: Table | Production Source: Fact_SnapshotCustomer + BI_DB_PositionPnL + BI_DB_Guru_Copiers (AM portfolio KPI)*
