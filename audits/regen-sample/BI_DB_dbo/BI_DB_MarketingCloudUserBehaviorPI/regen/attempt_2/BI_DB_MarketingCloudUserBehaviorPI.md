# BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI

> 156,092-row marketing analytics table capturing per-customer Popular Investor (PI) profile-view behavior for Salesforce Marketing Cloud SFTP export -- linking PI profile page views (from Fact_UserPageViews) with copy-trading position metrics (from Dim_Position + Dim_Mirror) for 75,347 distinct customers across 5,575 viewed PIs, maintained with a rolling 1-month retention window by SP_MarketingCloudUserBehavior.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_pagetracking.Fact_UserPageViews + DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror + DWH_dbo.Dim_Customer via SP_MarketingCloudUserBehavior |
| **Refresh** | Daily (SP_MarketingCloudUserBehavior @date); rolling 1-month retention |
| **Synapse Distribution** | HASH (CID) |
| **Synapse Index** | CLUSTERED INDEX (CIDViewed ASC) |
| **UC Target** | `_Not_Migrated` |

---

## 1. Business Meaning

`BI_DB_MarketingCloudUserBehaviorPI` is a Marketing Cloud export table that pairs customer PI profile-view activity (which Popular Investors a customer looked at) with their actual copy-trading behavior toward those PIs. Each row represents a unique (CID, CIDViewed) pair for a given DateID, enriched with copy-trade investment totals, position counts, and the PI's username.

The table is populated daily by `BI_DB_dbo.SP_MarketingCloudUserBehavior` (authored by Katy F, migrated from the legacy `SalesForce_DB_Prod.dbo.SP_UserBehavior` in August 2023). The SP:

1. Builds a set of (CID, CIDViewed) pairs from `DWH_pagetracking.Fact_UserPageViews` for the run date, joining to `DWH_dbo.Dim_Customer` to resolve the viewed PI's username.
2. Joins to `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Mirror` (matching on MirrorID + CID) to compute copy-trade investment amounts, position counts, and last-open dates per copied PI.
3. Aggregates metrics across all mirrors per (CID, ParentCID) combination.
4. Performs an UPSERT: UPDATE existing rows where values changed, INSERT new (CID, CIDViewed) pairs.
5. Post-load UPDATE: fills `AccountId` from `DWH_dbo.Dim_Customer.SalesForceAccountID` for rows where AccountId IS NULL.
6. Retention: deletes rows with DateID older than 1 month before the current date.

As of the last load, the table holds 156,092 rows spanning DateID 20240502--20240531, covering 75,347 distinct customers and 5,575 distinct viewed PIs. Data appears stale (last update June 2024) -- the SP may not be running in the current schedule.

This table is the PI companion to `BI_DB_MarketingCloudUserBehaviorInstrument`, which captures instrument-level interest rather than PI-level interest. Both are populated by the same SP.

---

## 2. Business Logic

### 2.1 PI Profile-View-to-Copy-Trade Correlation

**What**: Each row exists because a customer viewed a PI's profile page AND has at least one copy-trade position linked to that PI via Dim_Mirror.

**Columns Involved**: `CID`, `CIDViewed`, `LastVisit`, `TotalAmountInvest`, `TotalPositionsInvest`

**Rules**:
- The grain is (CID, CIDViewed) -- one row per customer per viewed Popular Investor.
- Only customers who appear in `Fact_UserPageViews` for the run date AND have copy-trade position history linked to the viewed PI via `Dim_Mirror` are included.
- Unlike the Instrument companion table (which filters `MirrorID=0` for direct positions), this PI table specifically uses mirror-linked positions (`JOIN Dim_Mirror ON dp.MirrorID = dm.MirrorID`).

### 2.2 Current-Month vs All-Time Investment Metrics

**What**: The SP computes both current-month and all-time metrics for each (CID, CIDViewed) pair.

**Columns Involved**: `LastMonthAmountInvest`, `LastMonthOpenPositionsInvest`, `TotalAmountInvest`, `TotalPositionsInvest`

**Rules**:
- `LastMonthAmountInvest` = SUM of Dim_Position.Amount WHERE the position's OpenDateID year-month matches the current GETDATE() year-month, for positions linked to the viewed PI via Dim_Mirror.
- `LastMonthOpenPositionsInvest` = COUNT of positions in the same current-month filter.
- `TotalAmountInvest` = SUM of Dim_Mirror.RealizedEquity across all mirrors between this CID and the viewed PI (ParentCID). Note: unlike the Instrument table (which uses SUM(Amount)), the PI table uses RealizedEquity from Dim_Mirror.
- `TotalPositionsInvest` = COUNT of ALL positions linked via Dim_Mirror for this (CID, ParentCID).
- "Last month" is a misnomer -- it actually means "current calendar month at SP runtime", not the previous month.

### 2.3 Open Active Instruments (Copy Context)

**What**: OpenActiveInstruments counts open copy-trade positions linked via Dim_Mirror for this (CID, ParentCID) pair, then aggregated across all mirrors.

**Columns Involved**: `OpenActiveInstruments`

**Rules**:
- `COUNT(CASE WHEN dp.CloseDateID=0 THEN dp.PositionID END)` from Dim_Position, joined to Dim_Mirror.
- Aggregated at the (CID, ParentCID) level across multiple mirrors.
- Despite the column name suggesting instruments, this actually counts open positions, not distinct instruments.

### 2.4 UPSERT with Change Detection

**What**: The SP uses UPDATE-then-INSERT pattern with explicit change detection to avoid unnecessary writes.

**Rules**:
- UPDATE fires only when at least one of the tracked columns differs (using ISNULL comparisons for NULL safety).
- INSERT fires only for (CID, CIDViewed) pairs that do not yet exist in the table.
- `UpdateDate` is set to GETDATE() on both UPDATE and INSERT paths.

### 2.5 Rolling 1-Month Retention

**What**: Rows older than 1 month are purged at the start of each SP run.

**Columns Involved**: `DateID`

**Rules**:
- `DELETE WHERE DateID < CONVERT(VARCHAR(8), DATEADD(M,-1,CAST(GETDATE() AS DATE)), 112)`
- This means the table retains approximately 30 days of data at any time.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution with CLUSTERED INDEX on CIDViewed. This means:
- Queries filtered by CID are co-located on a single node.
- Queries filtered by CIDViewed benefit from the clustered index for efficient range scans.
- JOINs to other CID-distributed tables (e.g., Dim_Customer via RealCID) are co-located.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's PI interests | `WHERE CID = @cid` |
| PI popularity | `SELECT CIDViewed, UserPI, COUNT(DISTINCT CID) ... GROUP BY CIDViewed, UserPI` |
| Active copiers of a PI | `WHERE CIDViewed = @pid AND OpenActiveInstruments > 0` |
| Recent high-value copy viewers | `WHERE TotalAmountInvest > 10000 AND DateID >= 20240520` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer (copier) | `ON CID = RealCID` | Copier demographics, regulation, verification |
| DWH_dbo.Dim_Customer (PI) | `ON CIDViewed = RealCID` | PI profile details |
| BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument | `ON CID` | Combine PI interest with instrument interest for same customer |

### 3.4 Gotchas

- **"LastMonth" means current month**: `LastMonthAmountInvest` and `LastMonthOpenPositionsInvest` filter on the current calendar month at SP runtime, not the previous month. The column names are misleading.
- **TotalAmountInvest uses RealizedEquity, not Amount**: Unlike the Instrument companion table (which sums Dim_Position.Amount), this PI table sums Dim_Mirror.RealizedEquity. These are fundamentally different metrics.
- **OpenActiveInstruments counts positions, not instruments**: Despite the name, this column counts open copy-trade positions, not distinct instruments.
- **Only copy-trade positions counted**: All metrics come from Dim_Position JOINed to Dim_Mirror, so only mirror-linked positions are included. Direct positions are excluded (opposite of the Instrument table).
- **Rolling retention**: Only ~30 days of data exist at any time. Historical analysis is not possible from this table alone.
- **AccountId can be NULL**: 118 rows have NULL AccountId (customers without a Salesforce account mapping).
- **Data appears stale**: Current data spans May 2024. The SP may not be running in the current schedule.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki -- description copied as-is from Dim_Customer wiki |
| Tier 2 | ETL-computed in SP_MarketingCloudUserBehavior -- transform documented from SP code |
| Tier 3 | Source identified but no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_UserPageViews.RealCID (renamed). (Tier 1 — Customer.CustomerStatic) |
| 2 | AccountId | nvarchar(18) | YES | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID. (Tier 1 — BackOffice.Customer) |
| 3 | UpdateDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() on every INSERT and UPDATE by SP_MarketingCloudUserBehavior. (Tier 2 — SP_MarketingCloudUserBehavior) |
| 4 | LastVisit | datetime | YES | Most recent PI profile-view timestamp for this (CID, CIDViewed) pair on the run date. Computed as MAX(Fact_UserPageViews.Occurred) grouped by CID and CIDViewed. (Tier 2 — Fact_UserPageViews) |
| 5 | LastMonthAmountInvest | money | YES | Sum of Dim_Position.Amount for copy-trade positions (via Dim_Mirror) opened in the current calendar month at SP runtime for this customer copying this PI. Despite the name, this is current-month, not previous-month. (Tier 2 — Dim_Position) |
| 6 | LastMonthOpenPositionsInvest | int | YES | Count of copy-trade positions (via Dim_Mirror) opened in the current calendar month at SP runtime for this customer copying this PI. Despite the name, this is current-month, not previous-month. (Tier 2 — Dim_Position) |
| 7 | TotalAmountInvest | money | YES | Sum of Dim_Mirror.RealizedEquity across all mirrors between this customer and the viewed PI (ParentCID). Unlike the Instrument companion table (which uses SUM(Amount)), this uses mirror realized equity. (Tier 2 — Dim_Mirror) |
| 8 | TotalPositionsInvest | int | YES | Count of all copy-trade positions (via Dim_Mirror) for this customer copying this PI, across all time. (Tier 2 — Dim_Position) |
| 9 | OpenActiveInstruments | int | YES | Count of currently open copy-trade positions (CloseDateID=0) via Dim_Mirror for this customer copying this PI. Despite the column name, this counts positions, not distinct instruments. Aggregated across all mirrors per (CID, ParentCID). (Tier 2 — Dim_Position) |
| 10 | DateID | int | YES | YYYYMMDD integer representing the SP run date. Derived from the @date parameter: CONVERT(VARCHAR(8), @date, 112). Used for retention filtering (rows older than 1 month are purged). (Tier 2 — SP_MarketingCloudUserBehavior) |
| 11 | CIDViewed | int | YES | Customer ID of the Popular Investor whose profile was viewed. FK to Dim_Customer.RealCID. Passthrough from Fact_UserPageViews.CIDViewed. (Tier 3 — Fact_UserPageViews, no upstream wiki available) |
| 12 | LastOpen | date | YES | Date of the most recent mirror opened by this customer copying this PI. Computed as MAX(Dim_Mirror.OpenDateID) converted from YYYYMMDD int to date, aggregated across all mirrors per (CID, ParentCID). (Tier 2 — Dim_Mirror) |
| 13 | UserPI | varchar(100) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer.UserName via JOIN on CIDViewed=RealCID (renamed to UserPI). (Tier 1 — Customer.CustomerStatic) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CID | DWH_pagetracking.Fact_UserPageViews | RealCID | Rename |
| AccountId | DWH_dbo.Dim_Customer | SalesForceAccountID | Post-load UPDATE, rename |
| UpdateDate | SP_MarketingCloudUserBehavior | -- | GETDATE() |
| LastVisit | DWH_pagetracking.Fact_UserPageViews | Occurred | MAX() aggregation |
| LastMonthAmountInvest | DWH_dbo.Dim_Position | Amount | SUM() with current-month filter, copy positions via Dim_Mirror |
| LastMonthOpenPositionsInvest | DWH_dbo.Dim_Position | PositionID | COUNT with current-month filter, copy positions via Dim_Mirror |
| TotalAmountInvest | DWH_dbo.Dim_Mirror | RealizedEquity | SUM() across mirrors per (CID, ParentCID) |
| TotalPositionsInvest | DWH_dbo.Dim_Position | PositionID | COUNT() across all copy positions via Dim_Mirror |
| OpenActiveInstruments | DWH_dbo.Dim_Position | PositionID | COUNT(CASE WHEN CloseDateID=0) across copy positions via Dim_Mirror |
| DateID | SP_MarketingCloudUserBehavior | @date parameter | CONVERT(VARCHAR(8), @date, 112) |
| CIDViewed | DWH_pagetracking.Fact_UserPageViews | CIDViewed | Passthrough |
| LastOpen | DWH_dbo.Dim_Mirror | OpenDateID | MAX() + CONVERT to date, across mirrors per (CID, ParentCID) |
| UserPI | DWH_dbo.Dim_Customer | UserName | Rename (dim-lookup passthrough via JOIN on CIDViewed=RealCID) |

### 5.2 ETL Pipeline

```
DWH_pagetracking.Fact_UserPageViews (PI profile-view events, filtered to @DateID)
DWH_dbo.Dim_Customer (UserName for UserPI; SalesForceAccountID for post-load enrichment)
DWH_dbo.Dim_Position (position metrics, joined via Dim_Mirror)
DWH_dbo.Dim_Mirror (copy-trading relationships: MirrorID, ParentCID, RealizedEquity, OpenDateID)
  |
  |-- SP_MarketingCloudUserBehavior @date ---|
  |   Step 1: DELETE rows older than 1 month
  |   Step 2: Build #PI (page views + Dim_Customer username)
  |   Step 3: Build #dp_AmountInvestPI (position amounts per copied PI via Dim_Mirror)
  |   Step 4: Build #dpAssetPI (aggregated per CID + ParentCID)
  |   Step 5: JOIN -> #PIResults
  |   Step 6: UPSERT (UPDATE changed rows, INSERT new rows)
  |   Step 7: Post-load UPDATE AccountId from Dim_Customer
  v
BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI (156,092 rows, rolling 1-month)
  |
  |-- SFTP export to Salesforce Marketing Cloud ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Copier customer identifier |
| CIDViewed | DWH_dbo.Dim_Customer (RealCID) | Viewed Popular Investor identifier |
| AccountId | Salesforce CRM | External Salesforce Account ID |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Salesforce Marketing Cloud | SFTP export | Downstream consumer of this data for marketing campaigns |

---

## 7. Sample Queries

### 7.1 Most-viewed Popular Investors by copier count

```sql
SELECT TOP 20
    CIDViewed,
    UserPI,
    COUNT(DISTINCT CID) AS CopierViewerCount,
    SUM(TotalAmountInvest) AS TotalCopyEquity
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI]
GROUP BY CIDViewed, UserPI
ORDER BY CopierViewerCount DESC
```

### 7.2 High-value copy viewers with active positions

```sql
SELECT
    CID,
    AccountId,
    UserPI,
    TotalAmountInvest,
    OpenActiveInstruments,
    LastVisit,
    LastOpen
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI]
WHERE TotalAmountInvest > 5000
  AND OpenActiveInstruments > 0
ORDER BY TotalAmountInvest DESC
```

### 7.3 Customers who viewed a PI but stopped copying this month

```sql
SELECT
    CID,
    AccountId,
    UserPI,
    LastVisit,
    TotalAmountInvest,
    LastMonthAmountInvest,
    LastOpen
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI]
WHERE LastMonthAmountInvest = 0
  AND TotalAmountInvest > 0
ORDER BY TotalAmountInvest DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 3 T1, 9 T2, 1 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI | Type: Table | Production Source: Fact_UserPageViews + Dim_Position + Dim_Mirror + Dim_Customer via SP_MarketingCloudUserBehavior*
