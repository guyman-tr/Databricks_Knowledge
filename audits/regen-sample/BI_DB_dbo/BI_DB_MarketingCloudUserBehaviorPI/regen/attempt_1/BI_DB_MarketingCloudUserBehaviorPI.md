# BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI

> 156K-row marketing analytics table capturing per-customer Popular Investor (PI) page-view interest paired with copy-trading position metrics for Salesforce Marketing Cloud SFTP export -- linking PI profile views (from Fact_UserPageViews) with mirror/copy-trade investment data (from Dim_Position + Dim_Mirror) for 75K distinct customers across 5,575 PIs, maintained with a rolling 1-month retention window by SP_MarketingCloudUserBehavior.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_pagetracking.Fact_UserPageViews + DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror + DWH_dbo.Dim_Customer via SP_MarketingCloudUserBehavior |
| **Refresh** | Daily (SP_MarketingCloudUserBehavior @date); rolling 1-month retention |
| **Synapse Distribution** | HASH (CID) |
| **Synapse Index** | CLUSTERED INDEX (CIDViewed ASC) |

---

## 1. Business Meaning

`BI_DB_MarketingCloudUserBehaviorPI` is a Marketing Cloud export table that pairs customer PI profile page-view activity with their actual copy-trading behavior. Each row represents a unique (CID, CIDViewed) pair -- a customer who viewed a Popular Investor's profile and has copy-trading positions linked to that PI via `Dim_Mirror`. The table is the PI-focused counterpart to `BI_DB_MarketingCloudUserBehaviorInstrument` (which tracks instrument-level interest).

The table is populated daily by the PI section of `BI_DB_dbo.SP_MarketingCloudUserBehavior` (authored by Katy F, migrated from the legacy `SalesForce_DB_Prod.dbo.SP_UserBehavior` in August 2023). The SP:

1. Builds a set of (CID, CIDViewed) pairs from `DWH_pagetracking.Fact_UserPageViews` for the run date, joining `Dim_Customer` to resolve the PI's `UserName`.
2. Joins to `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Mirror` (linked via MirrorID and CID) to compute investment amounts, position counts, and last-open dates per (CID, ParentCID) copy relationship.
3. Aggregates mirror-level metrics into `#dpAssetPI` (SUM across all mirrors for each CID/ParentCID pair).
4. Performs an UPSERT: UPDATE existing rows where values changed, INSERT new (CID, CIDViewed) pairs.
5. Post-load UPDATE: fills `AccountId` from `DWH_dbo.Dim_Customer.SalesForceAccountID` for rows where AccountId IS NULL.
6. Retention: deletes rows with DateID older than 1 month before the current date.

As of the last load, the table holds 156,092 rows spanning DateID 20240502--20240531, covering 75,347 distinct customers and 5,575 distinct Popular Investors.

**Key difference from the Instrument sibling table**: This table tracks copy-trading relationships (via Dim_Mirror), NOT direct instrument positions. `TotalAmountInvest` here comes from `Dim_Mirror.RealizedEquity`, not from `SUM(Dim_Position.Amount)`.

---

## 2. Business Logic

### 2.1 PI Page-View-to-CopyTrade Correlation

**What**: Each row exists because a customer viewed a Popular Investor's profile page AND has copy-trading positions linked to that PI.

**Columns Involved**: `CID`, `CIDViewed`, `UserPI`, `LastVisit`, `TotalAmountInvest`, `TotalPositionsInvest`

**Rules**:
- The grain is (CID, CIDViewed) -- one row per customer per viewed Popular Investor.
- Only customers who appear in `Fact_UserPageViews` for the run date AND have positions linked via `Dim_Mirror` (where `ParentCID = CIDViewed`) are included.
- Positions are linked through `Dim_Mirror` via `dp.MirrorID = dm.MirrorID AND dp.CID = dm.CID`.

### 2.2 Current-Month vs All-Time Investment Metrics

**What**: The SP computes both current-month and all-time investment metrics for each (CID, ParentCID) pair, aggregated across all mirrors.

**Columns Involved**: `LastMonthAmountInvest`, `LastMonthOpenPositionsInvest`, `TotalAmountInvest`, `TotalPositionsInvest`

**Rules**:
- `LastMonthAmountInvest` = SUM of Dim_Position.Amount WHERE the position's OpenDateID year-month matches the current GETDATE() year-month, grouped by (CID, ParentCID) across mirrors.
- `LastMonthOpenPositionsInvest` = COUNT of positions in the same current-month filter.
- `TotalAmountInvest` = SUM of `Dim_Mirror.RealizedEquity` across all mirrors for the (CID, ParentCID) pair. **This differs from the Instrument sibling**, which uses `SUM(Dim_Position.Amount)`.
- `TotalPositionsInvest` = COUNT of all positions across all mirrors for this (CID, ParentCID) pair.
- "Last month" is a misnomer -- it actually means "current calendar month at SP runtime", not the previous month.

### 2.3 Open Active Instruments (per PI)

**What**: OpenActiveInstruments counts open positions across all mirrors for a (CID, ParentCID) pair.

**Columns Involved**: `OpenActiveInstruments`

**Rules**:
- Counts positions WHERE `CloseDateID=0` across all mirrors linking CID to ParentCID.
- Unlike the Instrument sibling table (which aggregates by InstrumentTypeID), this aggregates by copy-trade relationship.

### 2.4 UPSERT with Change Detection

**What**: The SP uses UPDATE-then-INSERT pattern with explicit change detection.

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
- Customer-level queries (`WHERE CID = @cid`) are efficient -- single distribution node.
- PI-level queries (`WHERE CIDViewed = @pi_cid`) use the clustered index for efficient scans.
- JOINs to Dim_Customer on CID=RealCID require data movement (Dim_Customer is HASH on RealCID, but key values differ in the mapping).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's PI interests | `WHERE CID = @cid` |
| PI popularity | `SELECT CIDViewed, UserPI, COUNT(DISTINCT CID) ... GROUP BY CIDViewed, UserPI` |
| Active copiers by PI | `WHERE OpenActiveInstruments > 0 AND CIDViewed = @pi_cid` |
| Recent high-value viewers | `WHERE TotalAmountInvest > 10000 AND DateID >= 20240520` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer (viewer) | `ON CID = RealCID` | Customer demographics for the viewer |
| DWH_dbo.Dim_Customer (PI) | `ON CIDViewed = RealCID` | Full PI profile details |
| BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument | `ON CID` | Combine PI interest with instrument interest for same customer |

### 3.4 Gotchas

- **"LastMonth" means current month**: `LastMonthAmountInvest` and `LastMonthOpenPositionsInvest` filter on the current calendar month at SP runtime, not the previous month. The column names are misleading.
- **TotalAmountInvest comes from Dim_Mirror.RealizedEquity**: Unlike the Instrument sibling table (which sums Dim_Position.Amount), this table uses the mirror's realized equity. This means `TotalAmountInvest` reflects the copy-relationship-level equity, not the sum of individual position amounts.
- **LastOpen is mirror open date, not position open date**: `LastOpen` is derived from `MAX(Dim_Mirror.OpenDateID)`, meaning it reflects the most recent mirror relationship opened, not the most recent position opened.
- **Rolling retention**: Only ~30 days of data exist at any time. Historical analysis is not possible from this table alone.
- **AccountId can be NULL**: Customers without a Salesforce account mapping will have NULL AccountId. The post-load UPDATE only fills previously-NULL values.
- **Data appears stale**: Current data spans May 2024. The SP may not be running in the current schedule, or the data reflects the last active run.
- **CIDViewed is the clustered index key**: Queries filtering on CIDViewed are efficient; queries scanning by DateID require full clustered index scan.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki -- description copied as-is from Dim_Customer or other documented source |
| Tier 2 | ETL-computed in SP_MarketingCloudUserBehavior -- transform documented from SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_UserPageViews.RealCID (renamed). (Tier 1 — Customer.CustomerStatic) |
| 2 | AccountId | nvarchar(18) | YES | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID. (Tier 1 — BackOffice.Customer) |
| 3 | UpdateDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() on every INSERT and UPDATE by SP_MarketingCloudUserBehavior. (Tier 2 — SP_MarketingCloudUserBehavior) |
| 4 | LastVisit | datetime | YES | Most recent PI profile page-view timestamp for this (CID, CIDViewed) pair on the run date. Computed as MAX(Fact_UserPageViews.Occurred) grouped by CID and CIDViewed. (Tier 2 — Fact_UserPageViews) |
| 5 | LastMonthAmountInvest | money | YES | Sum of Dim_Position.Amount for copy-trade positions (via Dim_Mirror) opened in the current calendar month at SP runtime for this (CID, ParentCID) pair, aggregated across all mirrors. Despite the name, this is current-month, not previous-month. (Tier 2 — Dim_Position) |
| 6 | LastMonthOpenPositionsInvest | int | YES | Count of copy-trade positions (via Dim_Mirror) opened in the current calendar month at SP runtime for this (CID, ParentCID) pair, aggregated across all mirrors. Despite the name, this is current-month, not previous-month. (Tier 2 — Dim_Position) |
| 7 | TotalAmountInvest | money | YES | Sum of Dim_Mirror.RealizedEquity across all mirrors for this (CID, ParentCID) pair. Unlike the Instrument sibling table, this represents copy-relationship-level realized equity, not sum of position amounts. (Tier 2 — Dim_Mirror) |
| 8 | TotalPositionsInvest | int | YES | Count of all copy-trade positions (via Dim_Mirror) across all mirrors for this (CID, ParentCID) pair. (Tier 2 — Dim_Position) |
| 9 | OpenActiveInstruments | int | YES | Count of currently open copy-trade positions (CloseDateID=0) across all mirrors for this (CID, ParentCID) pair. (Tier 2 — Dim_Position) |
| 10 | DateID | int | YES | YYYYMMDD integer representing the SP run date. Derived from the @date parameter: CONVERT(VARCHAR(8), @date, 112). Used for retention filtering (rows older than 1 month are purged). (Tier 2 — SP_MarketingCloudUserBehavior) |
| 11 | CIDViewed | int | YES | Customer ID of the Popular Investor whose profile was viewed. FK to Dim_Customer.RealCID. Passthrough from Fact_UserPageViews.CIDViewed. (Tier 1 — Fact_UserPageViews) |
| 12 | LastOpen | date | YES | Date of the most recent mirror (copy-trade relationship) opened by this customer for this PI. Computed as MAX(Dim_Mirror.OpenDateID) converted from YYYYMMDD int to date. Note: this is the mirror open date, not the position open date. (Tier 2 — Dim_Mirror) |
| 13 | UserPI | varchar(100) | YES | Customer login username. Unique (case-insensitive). Passthrough from Dim_Customer.UserName via JOIN on CIDViewed=RealCID. Represents the Popular Investor's display name. (Tier 1 — Customer.CustomerStatic) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CID | DWH_pagetracking.Fact_UserPageViews | RealCID | Rename |
| AccountId | DWH_dbo.Dim_Customer | SalesForceAccountID | Post-load UPDATE, rename |
| UpdateDate | SP_MarketingCloudUserBehavior | -- | GETDATE() |
| LastVisit | DWH_pagetracking.Fact_UserPageViews | Occurred | MAX() aggregation |
| LastMonthAmountInvest | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror | Amount | SUM() with current-month filter via Mirror JOIN |
| LastMonthOpenPositionsInvest | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror | PositionID | COUNT with current-month filter via Mirror JOIN |
| TotalAmountInvest | DWH_dbo.Dim_Mirror | RealizedEquity | SUM() per (CID, ParentCID) |
| TotalPositionsInvest | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror | PositionID | COUNT(*) via Mirror JOIN |
| OpenActiveInstruments | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror | PositionID | COUNT(CASE WHEN CloseDateID=0) via Mirror JOIN |
| DateID | DWH_pagetracking.Fact_UserPageViews | DateID | Passthrough (filtered to @DateID) |
| CIDViewed | DWH_pagetracking.Fact_UserPageViews | CIDViewed | Passthrough |
| LastOpen | DWH_dbo.Dim_Mirror | OpenDateID | MAX() + CONVERT to date |
| UserPI | DWH_dbo.Dim_Customer | UserName | Dim-lookup passthrough via CIDViewed=RealCID |

### 5.2 ETL Pipeline

```
DWH_pagetracking.Fact_UserPageViews (PI profile page-view events, filtered to @DateID)
DWH_dbo.Dim_Customer (UserName for PI, SalesForceAccountID for post-load enrichment)
DWH_dbo.Dim_Position (position metrics, linked via MirrorID)
DWH_dbo.Dim_Mirror (copy-trade relationships: RealizedEquity, OpenDateID, ParentCID)
  |
  |-- SP_MarketingCloudUserBehavior @date (PI section) ---|
  |   Step 1: DELETE rows older than 1 month
  |   Step 2: Build #PI (page views + Dim_Customer for UserName)
  |   Step 3: Build #dp_AmountInvestPI (position amounts per CID/ParentCID via Mirror)
  |   Step 4: Build #dpAssetPI (aggregated across mirrors per CID/ParentCID)
  |   Step 5: JOIN -> #PIResults
  |   Step 6: UPSERT (UPDATE changed rows, INSERT new rows)
  |   Step 7: Post-load UPDATE AccountId from Dim_Customer
  v
BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI (156K rows, rolling 1-month)
  |
  |-- SFTP export to Salesforce Marketing Cloud ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer who viewed the PI profile |
| CIDViewed | DWH_dbo.Dim_Customer (RealCID) | Popular Investor whose profile was viewed |
| AccountId | Salesforce CRM | External Salesforce Account ID |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Salesforce Marketing Cloud | SFTP export | Downstream consumer of this data for marketing campaigns |

---

## 7. Sample Queries

### 7.1 Top Popular Investors by viewer count

```sql
SELECT TOP 20
    CIDViewed,
    UserPI,
    COUNT(DISTINCT CID) AS ViewerCount,
    SUM(TotalAmountInvest) AS TotalInvested
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI]
GROUP BY CIDViewed, UserPI
ORDER BY ViewerCount DESC
```

### 7.2 High-value copiers viewing a specific PI

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
WHERE CIDViewed = 562154
  AND TotalAmountInvest > 1000
ORDER BY TotalAmountInvest DESC
```

### 7.3 Customers who viewed PIs but have no open copy positions this month

```sql
SELECT
    CID,
    AccountId,
    UserPI,
    LastVisit,
    TotalAmountInvest,
    LastMonthAmountInvest,
    OpenActiveInstruments
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorPI]
WHERE LastMonthAmountInvest = 0
  AND TotalAmountInvest > 0
  AND OpenActiveInstruments = 0
ORDER BY TotalAmountInvest DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 4 T1, 9 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI | Type: Table | Production Source: Fact_UserPageViews + Dim_Position + Dim_Mirror + Dim_Customer via SP_MarketingCloudUserBehavior*
