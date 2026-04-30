# BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument

> 3.55M-row marketing analytics table capturing per-customer, per-instrument investment behavior for Salesforce Marketing Cloud SFTP export -- linking page-view interest (from Fact_MarketPageViews) with position metrics (from Dim_Position) for 722K distinct customers across 5,644 instruments, maintained with a rolling 1-month retention window by SP_MarketingCloudUserBehavior.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_pagetracking.Fact_MarketPageViews + DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument + DWH_dbo.Dim_Customer via SP_MarketingCloudUserBehavior |
| **Refresh** | Daily (SP_MarketingCloudUserBehavior @date); rolling 1-month retention |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |

---

## 1. Business Meaning

`BI_DB_MarketingCloudUserBehaviorInstrument` is a Marketing Cloud export table that pairs customer page-view activity (which instruments a customer looked at) with their actual trading behavior on those instruments. Each row represents a unique (CID, InstrumentID) pair for a given DateID, enriched with investment totals, position counts, and asset-class-level portfolio metrics.

The table is populated daily by `BI_DB_dbo.SP_MarketingCloudUserBehavior` (authored by Katy F, migrated from the legacy `SalesForce_DB_Prod.dbo.SP_UserBehavior` in August 2023). The SP:

1. Builds a set of (CID, InstrumentID) pairs from `DWH_pagetracking.Fact_MarketPageViews` for the run date.
2. Joins to `DWH_dbo.Dim_Position` (filtered to direct positions only: `MirrorID=0`) to compute investment amounts, position counts, and last-open dates per instrument.
3. Joins to `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Instrument` to compute asset-class-level portfolio metrics (AssetAmount, AssetPositions, OpenActiveInstruments) grouped by InstrumentTypeID.
4. Performs an UPSERT: UPDATE existing rows where values changed, INSERT new (CID, InstrumentID) pairs.
5. Post-load UPDATE: fills `AccountId` from `DWH_dbo.Dim_Customer.SalesForceAccountID` for rows where AccountId IS NULL.
6. Retention: deletes rows with DateID older than 1 month before the current date.

As of the last load (June 2024), the table holds 3,551,713 rows spanning DateID 20240502--20240531, covering 722,211 distinct customers and 5,644 distinct instruments.

---

## 2. Business Logic

### 2.1 Page-View-to-Position Correlation

**What**: Each row exists because a customer viewed an instrument's market page AND has at least one direct (non-copy) position on that instrument.

**Columns Involved**: `CID`, `InstrumentID`, `LastVisit`, `TotalAmountInvest`, `TotalPositionsInvest`

**Rules**:
- The grain is (CID, InstrumentID) -- one row per customer per viewed instrument.
- Only customers who appear in `Fact_MarketPageViews` for the run date AND have position history on that instrument in `Dim_Position` are included.
- Copy-trading positions (`MirrorID != 0`) are excluded from all investment metrics.

### 2.2 Current-Month vs All-Time Investment Metrics

**What**: The SP computes both current-month and all-time investment amounts for each (CID, InstrumentID) pair.

**Columns Involved**: `LastMonthAmountInvest`, `LastMonthOpenPositionsInvest`, `TotalAmountInvest`, `TotalPositionsInvest`

**Rules**:
- `LastMonthAmountInvest` = SUM of Dim_Position.Amount WHERE the position's OpenDateID year-month matches the current GETDATE() year-month.
- `LastMonthOpenPositionsInvest` = COUNT of positions in the same current-month filter.
- `TotalAmountInvest` = SUM of Dim_Position.Amount across ALL positions for this (CID, InstrumentID), regardless of date.
- `TotalPositionsInvest` = COUNT of ALL positions for this (CID, InstrumentID).
- "Last month" is a misnomer -- it actually means "current calendar month at SP runtime", not the previous month.

### 2.3 Asset-Class-Level Portfolio Metrics

**What**: AssetAmount, AssetPositions, and OpenActiveInstruments are computed at the (CID, InstrumentTypeID) level, not at the individual instrument level.

**Columns Involved**: `AssetAmount`, `AssetPositions`, `OpenActiveInstruments`

**Rules**:
- These metrics aggregate across ALL instruments of the same InstrumentTypeID for a given CID.
- `OpenActiveInstruments` counts only open positions (`CloseDateID=0`).
- `AssetAmount` and `AssetPositions` include both open and closed positions.
- The same (AssetAmount, AssetPositions, OpenActiveInstruments) values appear on every row for a given (CID, InstrumentTypeID) combination.

### 2.4 UPSERT with Change Detection

**What**: The SP uses UPDATE-then-INSERT pattern with explicit change detection to avoid unnecessary writes.

**Rules**:
- UPDATE fires only when at least one of the tracked columns differs (using ISNULL comparisons for NULL safety).
- INSERT fires only for (CID, InstrumentID) pairs that do not yet exist in the table.
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

ROUND_ROBIN distribution with HEAP storage -- no clustered index or distribution key. This means:
- Full table scans on every query unless filtered.
- No co-located JOINs -- all JOINs require data movement.
- Appropriate for a marketing export table that is primarily written in bulk and exported via SFTP rather than queried interactively.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's instrument interests | `WHERE CID = @cid` |
| Instrument popularity | `SELECT InstrumentID, InstrumentName, COUNT(DISTINCT CID) ... GROUP BY InstrumentID, InstrumentName` |
| Active investors by asset class | `WHERE OpenActiveInstruments > 0 AND InstrumentTypeID = 5` |
| Recent high-value viewers | `WHERE TotalAmountInvest > 10000 AND DateID >= 20240520` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON InstrumentID` | Full instrument metadata (exchange, ISIN, asset class) |
| DWH_dbo.Dim_Customer | `ON CID = RealCID` | Customer demographics, regulation, verification |
| BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI | `ON CID` | Combine instrument interest with Popular Investor interest for same customer |

### 3.4 Gotchas

- **"LastMonth" means current month**: `LastMonthAmountInvest` and `LastMonthOpenPositionsInvest` filter on the current calendar month at SP runtime, not the previous month. The column names are misleading.
- **Asset metrics are per InstrumentTypeID, not per InstrumentID**: `AssetAmount`, `AssetPositions`, and `OpenActiveInstruments` are aggregated at the asset-class level. The same values repeat for every (CID, InstrumentTypeID) combination.
- **Only direct positions counted**: All Dim_Position metrics filter `MirrorID=0`, excluding copy-trading positions entirely. This is intentional for the marketing use case.
- **Rolling retention**: Only ~30 days of data exist at any time. Historical analysis is not possible from this table alone.
- **AccountId can be NULL**: 167 rows have NULL AccountId (customers without a Salesforce account mapping). The post-load UPDATE only fills previously-NULL values.
- **Data appears stale**: Current data spans May 2024. The SP may not be running in the current schedule, or the data reflects the last active run.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki -- description copied as-is from Dim_Instrument, Dim_Customer, or Dim_Position wiki |
| Tier 2 | ETL-computed in SP_MarketingCloudUserBehavior -- transform documented from SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_MarketPageViews.RealCID (renamed). (Tier 1 — Customer.CustomerStatic) |
| 2 | AccountId | nvarchar(18) | YES | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID. (Tier 1 — BackOffice.Customer) |
| 3 | UpdateDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() on every INSERT and UPDATE by SP_MarketingCloudUserBehavior. (Tier 2 — SP_MarketingCloudUserBehavior) |
| 4 | LastVisit | datetime | YES | Most recent page-view timestamp for this (CID, InstrumentID) pair on the run date. Computed as MAX(Fact_MarketPageViews.Occurred) grouped by CID and InstrumentID. (Tier 2 — Fact_MarketPageViews) |
| 5 | LastMonthAmountInvest | money | YES | Sum of Dim_Position.Amount for positions opened in the current calendar month at SP runtime on this instrument by this customer. Only direct positions (MirrorID=0). Despite the name, this is current-month, not previous-month. (Tier 2 — Dim_Position) |
| 6 | LastMonthOpenPositionsInvest | int | YES | Count of positions opened in the current calendar month at SP runtime on this instrument by this customer. Only direct positions (MirrorID=0). Despite the name, this is current-month, not previous-month. (Tier 2 — Dim_Position) |
| 7 | TotalAmountInvest | money | YES | Sum of Dim_Position.Amount across all positions (open and closed) on this instrument by this customer. Only direct positions (MirrorID=0). (Tier 2 — Dim_Position) |
| 8 | TotalPositionsInvest | int | YES | Count of all positions (open and closed) on this instrument by this customer. Only direct positions (MirrorID=0). (Tier 2 — Dim_Position) |
| 9 | AssetAmount | money | YES | Sum of Dim_Position.Amount across ALL instruments of the same InstrumentTypeID for this customer. Not instrument-specific -- same value repeats for every (CID, InstrumentTypeID) pair. Only direct positions (MirrorID=0). (Tier 2 — Dim_Position) |
| 10 | AssetPositions | int | YES | Count of all positions across ALL instruments of the same InstrumentTypeID for this customer. Not instrument-specific -- same value repeats for every (CID, InstrumentTypeID) pair. Only direct positions (MirrorID=0). (Tier 2 — Dim_Position) |
| 11 | OpenActiveInstruments | int | YES | Count of currently open positions (CloseDateID=0) across ALL instruments of the same InstrumentTypeID for this customer. Not instrument-specific -- same value repeats for every (CID, InstrumentTypeID) pair. Only direct positions (MirrorID=0). (Tier 2 — Dim_Position) |
| 12 | InstrumentID | int | YES | FK to Dim_Instrument. Financial instrument being traded. Passthrough from Fact_MarketPageViews. (Tier 1 — Trade.GetInstrument) |
| 13 | DateID | int | YES | YYYYMMDD integer representing the SP run date. Derived from the @date parameter: CONVERT(VARCHAR(8), @date, 112). Used for retention filtering (rows older than 1 month are purged). (Tier 2 — SP_MarketingCloudUserBehavior) |
| 14 | InstrumentTypeID | int | YES | Asset class identifier from Dim_Instrument. 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. FK to Dictionary.CurrencyType. Passthrough from Dim_Instrument via JOIN on InstrumentID. (Tier 1 — Trade.GetInstrument) |
| 15 | InstrumentName | varchar(100) | YES | Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. Passthrough from Dim_Instrument.SymbolFull (renamed to InstrumentName). (Tier 1 — Trade.InstrumentMetaData) |
| 16 | LastOpen | date | YES | Date of the most recent position opened by this customer on this instrument. Computed as MAX(Dim_Position.OpenDateID) converted from YYYYMMDD int to date. Only direct positions (MirrorID=0). (Tier 2 — Dim_Position) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CID | DWH_pagetracking.Fact_MarketPageViews | RealCID | Rename |
| AccountId | DWH_dbo.Dim_Customer | SalesForceAccountID | Post-load UPDATE, rename |
| UpdateDate | SP_MarketingCloudUserBehavior | -- | GETDATE() |
| LastVisit | DWH_pagetracking.Fact_MarketPageViews | Occurred | MAX() aggregation |
| LastMonthAmountInvest | DWH_dbo.Dim_Position | Amount | SUM() with current-month filter |
| LastMonthOpenPositionsInvest | DWH_dbo.Dim_Position | PositionID | COUNT with current-month filter |
| TotalAmountInvest | DWH_dbo.Dim_Position | Amount | SUM() all-time |
| TotalPositionsInvest | DWH_dbo.Dim_Position | PositionID | COUNT() all-time |
| AssetAmount | DWH_dbo.Dim_Position | Amount | SUM() per InstrumentTypeID |
| AssetPositions | DWH_dbo.Dim_Position | PositionID | COUNT(*) per InstrumentTypeID |
| OpenActiveInstruments | DWH_dbo.Dim_Position | PositionID | COUNT(CASE WHEN CloseDateID=0) per InstrumentTypeID |
| InstrumentID | DWH_pagetracking.Fact_MarketPageViews | InstrumentID | Passthrough |
| DateID | DWH_pagetracking.Fact_MarketPageViews | DateID | Passthrough (filtered to @DateID) |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Passthrough via JOIN |
| InstrumentName | DWH_dbo.Dim_Instrument | SymbolFull | Rename |
| LastOpen | DWH_dbo.Dim_Position | OpenDateID | MAX() + CONVERT to date |

### 5.2 ETL Pipeline

```
DWH_pagetracking.Fact_MarketPageViews (page-view events, filtered to @DateID)
DWH_dbo.Dim_Instrument (instrument metadata: SymbolFull, InstrumentTypeID)
DWH_dbo.Dim_Position (position metrics, filtered MirrorID=0)
DWH_dbo.Dim_Customer (SalesForceAccountID for post-load enrichment)
  |
  |-- SP_MarketingCloudUserBehavior @date ---|
  |   Step 1: DELETE rows older than 1 month
  |   Step 2: Build #Instrument (page views + instrument metadata)
  |   Step 3: Build #dp_AmountInvestInstrument (position amounts per instrument)
  |   Step 4: Build #dpAssetInstrument (asset-class-level portfolio metrics)
  |   Step 5: JOIN → #InstrumentResults
  |   Step 6: UPSERT (UPDATE changed rows, INSERT new rows)
  |   Step 7: Post-load UPDATE AccountId from Dim_Customer
  v
BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument (3.55M rows, rolling 1-month)
  |
  |-- SFTP export to Salesforce Marketing Cloud ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer identifier |
| InstrumentID | DWH_dbo.Dim_Instrument | Tradeable instrument |
| InstrumentTypeID | DWH_dbo.Dim_Instrument / Dictionary.CurrencyType | Asset class |
| AccountId | Salesforce CRM | External Salesforce Account ID |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Salesforce Marketing Cloud | SFTP export | Downstream consumer of this data for marketing campaigns |

---

## 7. Sample Queries

### 7.1 Top instruments by viewer count

```sql
SELECT TOP 20
    InstrumentName,
    InstrumentTypeID,
    COUNT(DISTINCT CID) AS ViewerCount,
    SUM(TotalAmountInvest) AS TotalInvested
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument]
GROUP BY InstrumentName, InstrumentTypeID
ORDER BY ViewerCount DESC
```

### 7.2 High-value crypto viewers with open positions

```sql
SELECT
    CID,
    AccountId,
    InstrumentName,
    TotalAmountInvest,
    OpenActiveInstruments,
    LastVisit,
    LastOpen
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument]
WHERE InstrumentTypeID = 10
  AND TotalAmountInvest > 5000
  AND OpenActiveInstruments > 0
ORDER BY TotalAmountInvest DESC
```

### 7.3 Customers who viewed but never invested this month

```sql
SELECT
    CID,
    AccountId,
    InstrumentName,
    LastVisit,
    TotalAmountInvest,
    LastMonthAmountInvest
FROM [BI_DB_dbo].[BI_DB_MarketingCloudUserBehaviorInstrument]
WHERE LastMonthAmountInvest = 0
  AND TotalAmountInvest > 0
ORDER BY TotalAmountInvest DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 5 T1, 11 T2, 0 T3, 0 T4, 0 T5 | Elements: 16/16, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument | Type: Table | Production Source: Fact_MarketPageViews + Dim_Position + Dim_Instrument + Dim_Customer via SP_MarketingCloudUserBehavior*
