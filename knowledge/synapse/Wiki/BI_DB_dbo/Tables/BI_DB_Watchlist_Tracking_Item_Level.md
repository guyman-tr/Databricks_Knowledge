# BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level

> Per-item watchlist conversion tracking table — each row represents one instrument or Popular Investor within a specific country/funnel/watchlist-version combination. Measures first-action, first-5-action, and position-open attribution for items inside vs outside the watchlist. Daily TRUNCATE+INSERT via SP_Watchlist_Tracking (written first; the High Level table is then aggregated from this table). Paired cluster with BI_DB_Watchlist_Tracking_High_Level.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_WatchListsByFunnel + Dim_Position + Fact_CustomerAction + First5Actions via `SP_Watchlist_Tracking` |
| **Refresh** | Daily (TRUNCATE+INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Priority** | 0 |
| **Schedule** | SB_Daily |
| **Paired With** | BI_DB_Watchlist_Tracking_High_Level (aggregated FROM this table) |
| **Row Count** | _(placeholder — run SELECT COUNT(*) to populate)_ |

---

## 1. Business Meaning

`BI_DB_Watchlist_Tracking_Item_Level` provides granular per-item watchlist analytics. Each row represents a single tradable item (instrument or Popular Investor) within a specific country, funnel, and watchlist version combination. The table answers: "For each item in (or outside) the watchlist, how many new users traded it as their first action, within their first 5 actions, or at any point?"

Items come from two distinct trade populations:
- **Instruments**: Extracted from `Dim_Position` (MirrorID=0, excluding partial close children) and enriched with `Dim_Instrument` for display name and instrument type (Stocks, ETF, Crypto, etc.)
- **Users (Popular Investors)**: Extracted from `Fact_CustomerAction` where ActionTypeID=17 (register new mirror), enriched via `Dim_Mirror` for the PI's ParentCID and ParentUserName

The `Is_In_WL` flag and `Ranking` column indicate whether the item was included in the active watchlist version and its ranking position. Items traded but NOT in the watchlist appear with `Is_In_WL=0` and `Ranking=NULL`, providing the comparison baseline for watchlist effectiveness analysis.

This table is the first output of SP_Watchlist_Tracking. The companion table `BI_DB_Watchlist_Tracking_High_Level` is aggregated directly from this table's rows.

---

## 2. Business Logic

### 2.1 Item Population — Instruments

**What**: All instruments traded by the registered cohort during the watchlist version period.
**Columns Involved**: `ItemType`, `ItemID`, `ItemName`, `InstrumentType`
**Rules**:
- Source: Dim_Position WHERE MirrorID=0 AND not partial close children
- ItemType = 'Instrument'
- ItemID = InstrumentID, ItemName = InstrumentDisplayName (from Dim_Instrument)
- InstrumentType = Stocks, ETF, Crypto, etc. (from Dim_Instrument)
- RealCID is NULL for Instrument-type rows

### 2.2 Item Population — Users (PIs)

**What**: All Popular Investors copied by the registered cohort during the watchlist version period.
**Columns Involved**: `ItemType`, `RealCID`, `ItemName`
**Rules**:
- Source: Fact_CustomerAction WHERE ActionTypeID=17 (register new mirror)
- ItemType = 'User'
- RealCID = ParentCID from Dim_Mirror, ItemName = ParentUserName
- ItemID and InstrumentType are NULL for User-type rows

### 2.3 Watchlist Matching

**What**: Determines whether each item was in the active watchlist version.
**Columns Involved**: `Is_In_WL`, `Ranking`
**Rules**:
- Matched against BI_DB_WatchListsByFunnel for the given VersionID and funnel
- Is_In_WL = 1 if the item exists in the watchlist; 0 otherwise
- Ranking = watchlist position if in watchlist; NULL if not

### 2.4 Funnel Attribution

**What**: Assigns each cohort user to a funnel based on their first actions.
**Columns Involved**: `AttributedID`, `FunnelName`
**Rules**:
- AttributedID values: 1=Stocks, 2=Crypto, 3=Copy, 4=CopyPortfolio, 5=CFD, 0=unattributed
- Derived from FunnelFromID via Dim_Customer and BI_DB_First5Actions
- FunnelName is the display label for the AttributedID

### 2.5 Country/Region/Desk Enrichment

**What**: Geographic enrichment from Dim_Country.
**Columns Involved**: `CountryID`, `Country`, `Region`, `Desk`, `EU`
**Rules**:
- Country and Region are passthrough from Dim_Country
- Desk is derived from Dim_Country.Region via a Region-to-Desk mapping
- EU = 1 for EU countries, 0 for non-EU

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. Filter on VersionID + CountryID + AttributedID for specific cohort analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top traded watchlist items by version | `WHERE Is_In_WL = 1 ORDER BY Users_TradedAsFirstAction DESC` |
| Watchlist vs non-watchlist conversion | `GROUP BY Is_In_WL` and compare SUM(Users_TradedAsFirstAction) |
| Items traded but not in watchlist | `WHERE Is_In_WL = 0 AND Users_Traded > 0` |
| PI copy performance in watchlist | `WHERE ItemType = 'User' AND Is_In_WL = 1` |
| Instrument breakdown by type | `WHERE ItemType = 'Instrument' GROUP BY InstrumentType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Watchlist_Tracking_High_Level | VersionID + CountryID + AttributedID | Paired aggregated metrics |
| BI_DB_WatchListsByFunnel | VersionID | Watchlist version metadata |
| DWH_dbo.Dim_Instrument | ItemID = InstrumentID (WHERE ItemType='Instrument') | Full instrument details |
| DWH_dbo.Dim_Customer | RealCID (WHERE ItemType='User') | PI customer profile |

### 3.4 Gotchas

- **Dual item types**: Instrument rows have ItemID populated but RealCID=NULL; User rows have RealCID populated but ItemID=NULL and InstrumentType=NULL
- **Ranking NULL**: NULL ranking does NOT mean the item is unranked in the watchlist — it means the item is NOT in the watchlist (Is_In_WL=0)
- **Paired table**: This is the detail table. Aggregated metrics are in BI_DB_Watchlist_Tracking_High_Level
- **Same SP writes both tables**: SP_Watchlist_Tracking writes Item Level first, then aggregates into High Level

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | System/ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | VersionID | int | NO | Watchlist version ID. Foreign key to BI_DB_WatchListsByFunnel. Identifies which watchlist configuration was active. (Tier 2 — SP_Watchlist_Tracking) |
| 2 | CountryID | int | NO | Country ID. Foreign key to Dim_Country. Part of the cohort segmentation key. (Tier 2 — SP_Watchlist_Tracking) |
| 3 | Country | varchar(50) | YES | Country name. Passthrough from Dim_Country. (Tier 2 — SP_Watchlist_Tracking, Dim_Country) |
| 4 | Region | varchar(50) | YES | Marketing region. Passthrough from Dim_Country.Region. (Tier 2 — SP_Watchlist_Tracking, Dim_Country) |
| 5 | Desk | nvarchar(50) | YES | Sales desk. Derived from Dim_Country.Region via Region-to-Desk mapping. (Tier 2 — SP_Watchlist_Tracking, Dim_Country) |
| 6 | EU | int | YES | EU flag: 1=EU country, 0=non-EU. Passthrough from Dim_Country. (Tier 2 — SP_Watchlist_Tracking, Dim_Country) |
| 7 | AttributedID | int | NO | Funnel attributed ID: 1=Stocks, 2=Crypto, 3=Copy, 4=CopyPortfolio, 5=CFD, 0=unattributed. Derived from FunnelFromID via Dim_Customer and BI_DB_First5Actions. (Tier 2 — SP_Watchlist_Tracking) |
| 8 | FunnelName | varchar(50) | YES | Human-readable funnel display name corresponding to AttributedID. (Tier 2 — SP_Watchlist_Tracking) |
| 9 | ItemType | varchar(50) | YES | Item classification: 'Instrument' for tradable instruments (from Dim_Position) or 'User' for Popular Investors (from Fact_CustomerAction ActionTypeID=17). (Tier 2 — SP_Watchlist_Tracking) |
| 10 | InstrumentType | varchar(50) | YES | Instrument category: Stocks, ETF, Crypto, etc. From Dim_Instrument. NULL for User-type rows. (Tier 2 — SP_Watchlist_Tracking, Dim_Instrument) |
| 11 | ItemName | varchar(max) | YES | Display name: InstrumentDisplayName for instruments, ParentUserName for PIs. From Dim_Instrument or Dim_Mirror respectively. (Tier 2 — SP_Watchlist_Tracking) |
| 12 | ItemID | int | YES | Instrument ID from Dim_Instrument. NULL for User-type rows. (Tier 2 — SP_Watchlist_Tracking) |
| 13 | RealCID | int | YES | Popular Investor's CID from Dim_Mirror.ParentCID. NULL for Instrument-type rows. (Tier 2 — SP_Watchlist_Tracking) |
| 14 | Ranking | int | YES | Watchlist ranking position for this item within the version/funnel. NULL if the item is not in the watchlist (Is_In_WL=0). (Tier 2 — SP_Watchlist_Tracking, BI_DB_WatchListsByFunnel) |
| 15 | Is_In_WL | int | NO | Watchlist membership flag: 1 if the item is in the watchlist for this version/funnel, 0 if not. Determined by existence in BI_DB_WatchListsByFunnel. (Tier 2 — SP_Watchlist_Tracking) |
| 16 | Users_TradedAsFirstAction | int | YES | Count of distinct users whose very first action on the platform was trading this item. (Tier 2 — SP_Watchlist_Tracking) |
| 17 | Users_TradedAsFirst5Actions | int | YES | Count of distinct users who traded this item within their first 5 actions. (Tier 2 — SP_Watchlist_Tracking) |
| 18 | First5Actions_Trades | int | YES | Total number of first-5-action trades on this item (a single user can contribute multiple trades). (Tier 2 — SP_Watchlist_Tracking) |
| 19 | Users_Traded | int | YES | Count of distinct users who traded this item at any point (not limited to first actions). (Tier 2 — SP_Watchlist_Tracking) |
| 20 | PositionsOpened_or_CopyOpened | int | YES | Total positions opened (instruments) or copy relationships opened (PIs) on this item. (Tier 2 — SP_Watchlist_Tracking) |
| 21 | Version_FirstDate | date | YES | Start date of this watchlist version. Passthrough from BI_DB_WatchListsByFunnel. (Tier 2 — SP_Watchlist_Tracking) |
| 22 | Version_LastDate | date | YES | End date of this watchlist version. Passthrough from BI_DB_WatchListsByFunnel. (Tier 2 — SP_Watchlist_Tracking) |
| 23 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. All rows share the same value per daily run. (Tier 5 — system) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CountryID, Country, Region, Desk, EU | Dictionary.Country | CountryID, Name, Region | passthrough + Region-to-Desk mapping via Dim_Country |
| ItemID, ItemName, InstrumentType | DWH_dbo.Dim_Instrument | InstrumentID, DisplayName, TypeName | passthrough (Instrument rows only) |
| RealCID, ItemName (User) | DWH_dbo.Dim_Mirror | ParentCID, ParentUserName | passthrough (User rows only) |
| VersionID, Ranking, Version_FirstDate/LastDate | BI_DB_WatchListsByFunnel | VersionID, Ranking, FirstDate, LastDate | passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_WatchListsByFunnel (watchlist versions + items)
  + BI_DB_dbo.BI_DB_CIDFirstDates (registered cohort)
  + DWH_dbo.Dim_Customer (FunnelFromID, CountryID)
  + DWH_dbo.Dim_Position (instrument trades, MirrorID=0)
  + DWH_dbo.Dim_Instrument (instrument metadata)
  + DWH_dbo.Fact_CustomerAction (copy trades, ActionTypeID=17)
  + DWH_dbo.Dim_Mirror (PI ParentCID, ParentUserName)
  + BI_DB_dbo.BI_DB_First5Actions (first 5 actions)
  + DWH_dbo.Dim_Country (Region -> Desk mapping)
  |
  |-- SP_Watchlist_Tracking (daily TRUNCATE+INSERT)
  |   Step 1: Build registered cohort per version from CIDFirstDates + Dim_Customer
  |   Step 2: Extract instrument trades from Dim_Position (MirrorID=0)
  |   Step 3: Extract copy trades from Fact_CustomerAction (ActionTypeID=17) + Dim_Mirror
  |   Step 4: Match items to watchlist via WatchListsByFunnel -> Is_In_WL, Ranking
  |   Step 5: Attribute to funnels via First5Actions
  |   Step 6: Aggregate per-item metrics (first action, first 5, positions opened)
  |   Step 7: Enrich with Country/Region/Desk from Dim_Country
  |   Step 8: TRUNCATE + INSERT into BI_DB_Watchlist_Tracking_Item_Level
  |   Step 9: Aggregate Item Level -> High Level (next table)
  v
BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level (ROUND_ROBIN HEAP)
  |
  v (aggregated into)
BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| VersionID | BI_DB_dbo.BI_DB_WatchListsByFunnel | Watchlist version definition |
| CountryID | DWH_dbo.Dim_Country (CountryID) | Country dimension |
| ItemID | DWH_dbo.Dim_Instrument (InstrumentID) | Instrument dimension (Instrument rows) |
| RealCID | DWH_dbo.Dim_Customer (RealCID) | PI customer dimension (User rows) |

### 6.2 Referenced By (other objects point to this)

| Consumer Object | Relationship |
|----------------|-------------|
| BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level | Aggregated FROM this table by SP_Watchlist_Tracking |

---

## 7. Sample Queries

### 7.1 Top Watchlist Items by First-Action Conversion

```sql
SELECT ItemType, ItemName, InstrumentType, Ranking,
       SUM(Users_TradedAsFirstAction) AS total_first_action_users
FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level
WHERE Is_In_WL = 1
  AND VersionID = (SELECT MAX(VersionID) FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level)
GROUP BY ItemType, ItemName, InstrumentType, Ranking
ORDER BY total_first_action_users DESC
```

### 7.2 Watchlist vs Non-Watchlist First-Action Comparison

```sql
SELECT Is_In_WL,
       COUNT(DISTINCT COALESCE(CAST(ItemID AS VARCHAR), ItemName)) AS distinct_items,
       SUM(Users_TradedAsFirstAction) AS first_action_users,
       SUM(PositionsOpened_or_CopyOpened) AS total_positions
FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level
WHERE VersionID = {target_version}
GROUP BY Is_In_WL
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 1 T5 | Elements: 23/23, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level | Type: Table | Production Source: WatchListsByFunnel + Dim_Position + Fact_CustomerAction via SP_Watchlist_Tracking*
