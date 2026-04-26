# BI_DB_dbo.BI_DB_CID_LifeStageDefinition

> SCD Type 2 customer lifecycle stage table. Assigns every valid eToro customer one of 19 lifecycle segments (LSD — Life Stage Definition) and tracks transitions over time. Each customer has one current open row (ToDateID=99991231) representing their present stage, plus historical rows for past stages. 122M total rows, 46.3M distinct customers, data from 2022-01-01.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (population), Dim_Position, V_Liabilities, Fact_SnapshotEquity, BI_DB_CIDFirstDates, Fact_CustomerAction |
| **Refresh** | Daily — SCD Type 2 UPDATE + INSERT (SP_CID_LifeStageDefinition, SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH (RealCID) |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC, DateID ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CID_LifeStageDefinition is the master customer lifecycle classification table. It assigns every valid eToro customer to one of 19 lifecycle segments — the **LSD (Life Stage Definition)** — based on their current activity, deposit history, and engagement patterns. The table drives CRM targeting, lifecycle marketing campaigns, win-back initiatives, and customer health monitoring.

**Key architectural pattern**: This is an SCD (Slowly Changing Dimension) Type 2 table, **not a daily grain table**. Each customer has exactly one current row (ToDateID=99991231) and potentially many historical rows showing when their lifecycle stage changed. The DateID column records when the current LSD was first assigned; ToDateID records when it ended (or 99991231 for still-current). A new row is written only when the stage changes — days when the stage remains the same do NOT generate new rows.

**Coverage**: 122M total rows across 46.3M distinct customers (2022-01-01 to present). Current (open) stage distribution: Dump Lead (38.3M = ~83%), the rest distributed across active/churned/new stages.

**LSD Hierarchy** (priority assignment order, first match wins):

| Priority | LSD Values | Business Signal |
|----------|-----------|----------------|
| 1 — Win Back | Win Back Deposit, Win Back Active Open | Previously churned, re-engaged within 14 days |
| 2 — Lead | Lead | Registered, not deposited, still logging in |
| 3 — New | New Funded, New Depositor Only | First deposit within last 14 days |
| 4 — Dump | Dump Lead, Dump Churn | Inactive non-depositor (180+ days no login) or long-term churned |
| 5 — Churn | Churn 14-30 days, 31-60 days, over 60 days | Was funded, now equity < $20 |
| 6 — Active Open | Active Open, Active Open Club, Active Open 30-90 days, Active Open 30-90 days Club | Has opened positions recently |
| 7 — Holder | Holder, Holder Club | Has open positions but no recent activity |
| 8 — Active Login | Active LogIn | Logged in last 30 days, no positions |
| 9 — No Activity | No Activity - Funded, No Activity - Not Funded | No qualifying recent activity |

"Club" variants (Active Open Club, Holder Club, etc.) apply when the customer's current PlayerLevelID >= 2 (Silver, Gold, Platinum, Platinum Plus, or Diamond tier). Non-club variants apply to Bronze (PlayerLevelID=1).

---

## 2. Business Logic

### 2.1 SCD Type 2 Update Pattern

**What**: The table accumulates stage transitions; only changes are written.

**Columns Involved**: DateID, ToDate, ToDateID, LSD

**Rules**:
- Each customer has ONE open row at any time: `WHERE ToDateID = 99991231`.
- When LSD changes on @date: UPDATE previous row to `ToDate = @date - 1`, then INSERT new row with `ToDate = '9999-12-31'`.
- Days with no LSD change: no new row, existing row's ToDate stays 99991231.
- Change detection: EXCEPT logic compares new computed LSD against #lastStatus (previous row from table). If the new LSD is different, it's treated as a change.
- Self-join: The SP reads the table itself to determine "was the customer previously churned?" (Winback logic) and "is the customer within a 14-day lock period?" (sticky Winback logic).

### 2.2 Population Coverage

**What**: Scope of customers tracked by this table.

**Columns Involved**: RealCID, LSD

**Rules**:
- Population = ALL valid customers at each @date: `Fact_SnapshotCustomer WHERE IsValidCustomer=1` filtered to the active snapshot row via `Dim_Range.DateRangeID`.
- Includes depositors AND non-depositors (Leads, Dump Leads cover non-depositors).
- Unlike `BI_DB_CID_DailyPanel_Club`, this table covers ALL ~46M eToro customers, not just Club members.

### 2.3 Win Back Stage

**What**: Identifies churned customers who have re-engaged.

**Columns Involved**: LSD (Win Back Deposit / Win Back Active Open)

**Rules**:
- Prerequisite: Customer's previous LSD was in `('Churn 14-30 days', 'Churn 31-60 days', 'Churn over 60 days', 'Dump Churn')`.
- AND customer's RealizedEquity >= $20 today (`IsFundedOver20=1`).
- **Win Back Deposit**: Re-engaged via deposit (MaxDepositDate within last 14 days, but no open position in last 14 days).
- **Win Back Active Open**: Re-engaged via trading (opened position in last 14 days).
- **14-day lock**: Once assigned Win Back, the stage is "sticky" for 14 days (prev LSD = Win Back + date diff <= 14). After 14 days, the customer transitions to Active Open / Active Open Club based on recency.

### 2.4 New Customer Stage (14-Day Window)

**What**: Identifies recently-acquired customers in their first 14 days.

**Columns Involved**: LSD (New Funded / New Depositor Only), FirstDepositDate

**Rules**:
- Applies when `FirstDepositDate BETWEEN @date - 13 AND @date` (deposit within last 14 days).
- **New Funded**: Has `BI_DB_CIDFirstDates.FirstNewFundedDate` — customer opened a funded position.
- **New Depositor Only**: Deposited but no funded position yet.
- FirstDepositDate filter: Only years >= 2000 are valid (nullifies bad/ancient data).

### 2.5 Churn Stage Classification

**What**: Customers who were previously funded (equity >= $20) but now are not.

**Columns Involved**: LSD (Churn 14-30 days / Churn 31-60 days / Churn over 60 days), ToDate

**Rules**:
- Prerequisite: `FirstFundedDate IS NOT NULL` (was ever funded) AND `IsFundedOver20 = 0` (current equity < $20).
- Churn age is measured by `LastFunded20Date_LastYear`: the most recent date in the past year where RealizedEquity >= $20 (from `Fact_SnapshotEquity` + `Dim_Range`).
- **Churn 14-30 days**: LastFunded20Date between 14 and 30 days ago, and previous LSD was NOT already Churn over 60 days.
- **Churn 31-60 days**: LastFunded20Date between 31 and 60 days ago.
- **Churn over 60 days**: LastFunded20Date > 60 days ago.
- Sticky behavior: Customers stay in their churn bucket based on previous LSD (a Churn 31-60d customer doesn't move to Churn 14-30d even if equity briefly recovered).

### 2.6 Dump Stage

**What**: Long-term inactive customers with no recovery signal.

**Columns Involved**: LSD (Dump Lead / Dump Churn)

**Rules**:
- **Dump Lead**: Never deposited (IsDepositor=0) AND last login > 180 days ago OR never logged in.
- **Dump Churn**: Previously "Churn over 60 days" or "Dump Churn" AND `LastFunded20Date_LastYear IS NULL` (equity < $20 for the entire past year = churned for over a year).

### 2.7 Active Open Stage with Club Variant

**What**: Customers who recently opened a trading position.

**Columns Involved**: LSD (Active Open / Active Open Club / Active Open 30-90 days / Active Open 30-90 days Club)

**Rules**:
- **Active Open** / **Active Open Club**: Last opened position in last 30 days.
- **Active Open 30-90 days** / **Active Open 30-90 days Club**: Last opened position 31-90 days ago.
- **Club variant** (suffix "Club"): `PlayerLevelID >= 2` (Silver or above at @date snapshot).
- Position lookup: `MAX(OpenOccurred) FROM Dim_Position WHERE OpenDateID BETWEEN @date-90 AND @date AND IsPartialCloseChild=0`.

### 2.8 Gap-Fill Behavior (Daily Run)

**What**: The SP self-heals if it missed days.

**Columns Involved**: DateID (internal loop variable)

**Rules**:
- Daily run (@date = yesterday): After deleting the yesterday row, the SP checks `MAX(Date)` in the table and runs a WHILE loop from `MAX(Date)+1` to yesterday.
- If MAX(Date) = @date - 1 (no gaps), the loop runs exactly once.
- If the SP missed N days, the loop runs N times to backfill.
- Historical run (@date < yesterday): DELETE all rows from @date forward and rebuild the entire history. Used for corrections.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) with CLUSTERED INDEX(RealCID, DateID). Queries filtering on RealCID will use data locality (single distribution). Point-in-time queries should always filter by `@queryDateINT BETWEEN DateID AND ToDateID` — this leverages the clustered index on (RealCID, DateID).

### 3.2 Getting Current Stage

The most common access pattern is "what is this customer's current LSD?":

```sql
WHERE ToDateID = 99991231  -- open/current rows only
```

### 3.3 Getting Stage at a Point in Time

```sql
WHERE @dateINT BETWEEN DateID AND ToDateID
```

This returns the one row active on @dateINT for each RealCID.

### 3.4 LSD Comparison Gotchas

- **PlayerLevelID >= 2 is NOT Platinum+**: In the SP, `PlayerLevelID >= 2` means "above Bronze" (Silver, Gold, Platinum, Platinum Plus, Diamond) — all non-Bronze tiers. Don't confuse with Platinum/higher only.
- **19 LSD values**: The complete set of LSD values from live data (as of April 2026): Dump Lead, Dump Churn, Lead, Holder, No Activity - Not Funded, Active Open Club, Active Open, Churn over 60 days, Active Open 30-90 days, Holder Club, No Activity - Funded, Active Open 30-90 days Club, Win Back Active Open, Active LogIn, Churn 31-60 days, Churn 14-30 days, New Funded, New Depositor Only, Win Back Deposit.
- **Dump Lead dominates (83%)**: 38.3M of 46.3M open rows are "Dump Lead". Most eToro registered users are inactive leads. Exclude this when analyzing active segments.

### 3.5 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current stage distribution | WHERE ToDateID=99991231, GROUP BY LSD |
| Active customers today | WHERE ToDateID=99991231 AND LSD NOT LIKE 'Dump%' AND LSD NOT IN ('Lead','No Activity - Not Funded') |
| Stage as of a specific date | WHERE @yyyymmdd BETWEEN DateID AND ToDateID |
| Stage transition events | Self-JOIN on RealCID, ORDER BY DateID — rows are transitions |
| Win-back cohort since date | WHERE LSD LIKE 'Win Back%' AND DateID >= @fromDate AND ToDateID = 99991231 |
| Recently churned (entry into churn) | WHERE LSD = 'Churn 14-30 days' AND DateID >= @fromDate |

### 3.6 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID = RealCID | Customer name/segment attributes |
| BI_DB_dbo.BI_DB_CID_DailyPanel_Club | ON RealCID = CID AND DateID | Club + LSD combined view |
| DWH_dbo.Fact_SnapshotCustomer | ON RealCID = RealCID + date range | Current customer status |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - SP code / live data | (T2 - SP_CID_LifeStageDefinition) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | varchar(10) | NO | Report date string (YYYY-MM-DD format) when the LSD was assigned. Stored as varchar(10) — not a date type. Cast when comparing: CAST(Date AS DATE). (T2 - SP_CID_LifeStageDefinition) |
| 2 | DateID | int | NO | Date integer (YYYYMMDD) when the LSD stage transition occurred. Combined with ToDateID, defines the validity window. CLUSTERED INDEX key (with RealCID). (T2 - SP_CID_LifeStageDefinition) |
| 3 | RealCID | int | YES | Customer identifier. FK into DWH_dbo.Dim_Customer. HASH distribution key. One open row per RealCID at ToDateID=99991231. (T2 - SP_CID_LifeStageDefinition) |
| 4 | FirstDepositDate | date | YES | Customer's first ever deposit date (from Dim_Customer.FirstDepositDate). NULL if never deposited. Used for "New" stage detection (deposit within last 14 days). Stored per-row for convenience — static attribute, same across all rows for a given RealCID. (T2 - SP_CID_LifeStageDefinition) |
| 5 | PlayerLevelID | int | YES | Customer's Club tier at the time of the LSD transition (from Fact_SnapshotCustomer). Same non-sequential ID mapping as Dim_PlayerLevel: 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond. Used to determine "Club" vs. non-Club variants of Active Open / Holder stages. (T2 - SP_CID_LifeStageDefinition) |
| 6 | LSD | varchar(29) | YES | Life Stage Definition — the customer's lifecycle segment. 19 possible values: 'Lead', 'New Funded', 'New Depositor Only', 'Win Back Deposit', 'Win Back Active Open', 'Active Open', 'Active Open Club', 'Active Open 30-90 days', 'Active Open 30-90 days Club', 'Holder', 'Holder Club', 'Active LogIn', 'Churn 14-30 days', 'Churn 31-60 days', 'Churn over 60 days', 'Dump Lead', 'Dump Churn', 'No Activity - Funded', 'No Activity - Not Funded'. Assigned by priority CASE (WinBack > Lead > New > Dump > Churn > Active Open > Holder > Active LogIn > No Activity). (T2 - SP_CID_LifeStageDefinition) |
| 7 | ToDate | date | YES | Date when this LSD row ended (closed). '9999-12-31' = current/open row (customer still in this stage). DATEADD(DAY,-1,@date) when the stage changed. Query pattern: WHERE ToDateID=99991231 for current state. (T2 - SP_CID_LifeStageDefinition) |
| 8 | ToDateID | int | YES | Integer version of ToDate (YYYYMMDD). 99991231 = current/open row. Use this for point-in-time filtering: WHERE @yyyymmdd BETWEEN DateID AND ToDateID. (T2 - SP_CID_LifeStageDefinition) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last written (GETDATE() on INSERT or UPDATE). Useful for diagnosing pipeline run timing. (T2 - SP_CID_LifeStageDefinition) |

---

## 5. Lineage

### 5.1 Production Sources

| Column / Logic | Source Object | Notes |
|--------------|---------------|-------|
| RealCID population | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer=1 filtered via Dim_Range |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate CAST as DATE |
| PlayerLevelID | DWH_dbo.Fact_SnapshotCustomer | Current tier at @date |
| LastOpenPosition | DWH_dbo.Dim_Position | MAX(OpenOccurred) in last 90 days, IsPartialCloseChild=0 |
| IsFundedOver20 | DWH_dbo.V_Liabilities | RealizedEquity >= 20 at @date |
| LastFunded20Date_LastYear (churn calc) | DWH_dbo.Fact_SnapshotEquity + Dim_Range + Dim_Date | Last date RealizedEquity >= 20 in past year |
| FirstFundedDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstNewFundedDate |
| LastLogInLastYear | DWH_dbo.Fact_CustomerAction | MAX(Occurred) WHERE ActionTypeID=14 (login) in last 365 days |
| Deposit (90 days) | DWH_dbo.Fact_CustomerAction | MAX(Occurred) WHERE ActionTypeID=7 (deposit) in last 90 days |
| Previous LSD (winback) | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | Self-join: WHERE PervdateINT BETWEEN DateID AND ToDateID |

Full column-level mapping: see `BI_DB_CID_LifeStageDefinition.lineage.md`.

### 5.2 ETL Pipeline

```
Fact_SnapshotCustomer (population)
  -> SP_CID_LifeStageDefinition(@date)
     + Dim_Position, V_Liabilities, Fact_SnapshotEquity
     + BI_DB_CIDFirstDates, Fact_CustomerAction
     + [self-reference for Winback logic]
  -> UPDATE open rows (close LSD that changed)
  -> INSERT new rows (new/changed LSD states)
  -> BI_DB_CID_LifeStageDefinition
```

| Step | Object | Description |
|------|--------|-------------|
| Population | Fact_SnapshotCustomer + Dim_Range + Dim_Customer | All valid customers at @date |
| Position lookup | Dim_Position | Last opened position in 90-day window |
| Equity check | V_Liabilities | IsFunded >= $20 check |
| Churn date | Fact_SnapshotEquity + Dim_Range | Last date funded >= $20 in past year |
| Self-reference | BI_DB_CID_LifeStageDefinition | Previous LSD for Winback detection |
| Writer | SP_CID_LifeStageDefinition | UPDATE closed rows + INSERT new rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Object | Join Column | Purpose |
|--------|------------|---------|
| DWH_dbo.Fact_SnapshotCustomer | RealCID, DateRangeID | Population, IsDepositor, PlayerLevelID |
| DWH_dbo.Dim_Customer | RealCID | FirstDepositDate, RegistrationDate |
| DWH_dbo.Dim_Position | CID | Last open position recency |
| DWH_dbo.V_Liabilities | CID + DateID | Current equity |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID | First funded date |
| DWH_dbo.Fact_CustomerAction | RealCID + DateID | Login and deposit events |
| BI_DB_dbo.BI_DB_CID_LifeStageDefinition | RealCID + date range | Self (previous LSD for Winback) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_Snapshot_CID_LifeStageDefinition | RealCID | Monthly snapshot of current LSD (SP_M_Snapshot_CID_LifeStageDefinition) |
| CRM campaign systems | RealCID + LSD | Lifecycle marketing segmentation |
| Analytics/BI dashboards | RealCID + LSD | Customer health monitoring |

---

## 7. Sample Queries

### 7.1 Current lifecycle stage distribution (active customers only)

```sql
SELECT LSD, COUNT(*) AS customers
FROM   [BI_DB_dbo].[BI_DB_CID_LifeStageDefinition]
WHERE  ToDateID = 99991231
  AND  LSD NOT LIKE 'Dump%'        -- exclude inactive leads and long-term churn
GROUP BY LSD
ORDER BY customers DESC;
```

### 7.2 Customer's current lifecycle stage

```sql
SELECT RealCID, LSD, Date AS stage_start_date, PlayerLevelID
FROM   [BI_DB_dbo].[BI_DB_CID_LifeStageDefinition]
WHERE  RealCID = 12345678
  AND  ToDateID = 99991231;
```

### 7.3 Customers who entered Churn today (new churn events)

```sql
SELECT RealCID, LSD, Date AS churn_start_date
FROM   [BI_DB_dbo].[BI_DB_CID_LifeStageDefinition]
WHERE  DateID = 20260412
  AND  LSD LIKE 'Churn%'
ORDER BY LSD;
```

### 7.4 Win-back stage customers with their club tier

```sql
SELECT ld.RealCID, ld.LSD, ld.Date AS winback_start_date, ld.PlayerLevelID
FROM   [BI_DB_dbo].[BI_DB_CID_LifeStageDefinition] ld
WHERE  ld.ToDateID = 99991231
  AND  ld.LSD LIKE 'Win Back%'
ORDER BY ld.Date DESC;
```

### 7.5 Stage history for a customer (all transitions)

```sql
SELECT Date AS stage_start, ToDate AS stage_end, LSD, PlayerLevelID
FROM   [BI_DB_dbo].[BI_DB_CID_LifeStageDefinition]
WHERE  RealCID = 12345678
ORDER BY DateID ASC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this specific table. Lifecycle stage methodology documentation may exist in Confluence DATA space under "CRM" or "Life Stage" pages.

---

*Generated: 2026-04-23 | Quality: 8.5/10 (****) | Phases: 11/14*
*Tiers: 0 T1, 9 T2, 0 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 10/10, Relationships: 9/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_CID_LifeStageDefinition | Type: Table | Production Source: Multi-source via SP_CID_LifeStageDefinition*
