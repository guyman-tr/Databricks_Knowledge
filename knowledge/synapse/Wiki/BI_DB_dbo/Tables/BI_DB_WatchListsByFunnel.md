# BI_DB_dbo.BI_DB_WatchListsByFunnel

> 2.02M-row personalized default watchlist generation table tracking the top instruments and Popular Investors shown per country, region, and funnel on the eToro platform — compiled monthly (last Sunday of each month) by SP_WatchListsByFunnel from DWH_dbo.Dim_Position trading activity, Dim_Customer funnel segmentation, Dim_Instrument metadata, and Dim_Country compliance rules, accumulating 61 monthly versions from Feb 2020 to present. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_WatchListsByFunnel` from DWH_dbo dimensions |
| **Refresh** | Monthly — runs daily but only executes on the last Sunday of each month (IF @Today = @lastSundayOfMonth). INSERT-only (accumulating versions). |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table powers the **personalized default watchlist** feature on the eToro platform. When a new user registers or visits etoro.com/watchlists, they see a curated list of instruments (stocks, crypto, CFDs, ETFs) and Popular Investors tailored to their country and funnel (acquisition channel). The SP builds these lists by analyzing the most-traded instruments over a rolling 2-month window, segmented by geography and funnel type.

The 2.02M rows represent 61 monthly snapshot versions (VersionID 1–61), each containing ~37,445 rows across 250 countries × 7 funnels × up to 18 ranking positions. Items are either **Instruments** (1.28M rows — ranked by position count in the observation period) or **Users/PIs** (740K rows — Popular Investors inserted at region/country level).

The SP implements a sophisticated **multi-level geo-optimization strategy**: for each funnel, it first tries to rank instruments at the Country level, falls back to Region level, then WorldWide level. It also enforces **compliance-driven allocation rules** per jurisdiction:
- **US**: only 3 approved crypto currencies (Bitcoin, Ethereum, Bitcoin Cash), US-only stocks/ETFs
- **Russia**: no FX currencies
- **China**: no FX currencies, no crypto
- **Israel/Japan/Canada + 15 others**: no CFDs
- **EU regions**: forced 2 local stocks per region
- **Australia**: forced 5 local stocks

Each funnel (Default, Stocks, Crypto, Copy, CopyPortfolio, CFD, ETF) has a predefined allocation template that controls how many items of each instrument type category appear and in what order.

---

## 2. Business Logic

### 2.1 Funnel Allocation System

**What**: Each funnel has a predefined allocation template controlling the mix of instrument types.
**Columns Involved**: AttributedID, FunnelName, InstrumentType_Category, Ranking
**Rules**:
- AttributedID 0 (Default/None): Crypto up to rank 4, CFD up to rank 10, Stocks up to rank 15
- AttributedID 1 (Stocks): Stocks up to rank 12, Crypto up to rank 15
- AttributedID 2 (Crypto): Crypto up to rank 9, Stocks up to rank 15
- AttributedID 3 (Copy): Stocks up to rank 4, CFD up to rank 8, Crypto up to rank 10
- AttributedID 4 (CopyPortfolio): Stocks_only up to rank 3, ETF_only up to rank 6
- AttributedID 5 (CFD): CFD up to rank 9, Stocks up to rank 13, Crypto up to rank 15
- AttributedID 6 (ETF): ETF_only up to rank 6, Stocks_only up to rank 12, Crypto up to rank 15
- Separate allocation tables exist for US, Russia, China, NoCFD, and OnlyCrypto jurisdictions

### 2.2 Multi-Level Geo-Optimization

**What**: Instruments are ranked at the most granular geographic level where sufficient trading data exists.
**Columns Involved**: CountryID, Region, Optimized_by, ObservationPeriod_OpenPos
**Rules**:
- Country-level optimization: rank instruments by position count within each country
- Region-level fallback: aggregate across countries in the same marketing region
- WorldWide fallback: aggregate across all countries
- Optimized_by records which level was used: 'Country', 'Region', 'WorldWide', 'Region_Local', 'Country_Local', 'Ext Hours Stock/ETF', 'Permanent Instrument'

### 2.3 Item Type Duality

**What**: Watchlist items are either tradeable instruments or Popular Investors (users to copy).
**Columns Involved**: ItemType, ItemID, RealCID, ItemName, InstrumentType, ObservationPeriod_Start/End
**Rules**:
- ItemType='Instrument': ItemID=InstrumentID, RealCID=NULL, ObservationPeriod populated, InstrumentType populated
- ItemType='User': ItemID=NULL, RealCID=CID of the PI, ObservationPeriod=NULL, InstrumentType=NULL
- PIs are inserted at region and country level with 3 permanent PIs added globally

### 2.4 Local Stock Forcing

**What**: EU and AU regions get forced local stock entries to promote domestic market engagement.
**Columns Involved**: IsLocalStock, StockCountry, StockRegion, ISINCountryCode
**Rules**:
- EU: 2 local stocks forced per region for Default and Stocks funnels
- Australia: 5 local stocks forced for Default and Stocks funnels
- IsLocalStock=1 when StockRegion matches user's Region

### 2.5 US Crypto Restriction

**What**: US customers receive a restricted crypto selection per SEC compliance.
**Columns Involved**: Region, InstrumentType, ItemID
**Rules**:
- USA region: only crypto with ItemID <= 100002 (Bitcoin, Ethereum, Bitcoin Cash)
- Non-USA: full crypto catalogue available
- Changed 2024-09-10 by Eti Rozolio

### 2.6 Extended Hours Instruments

**What**: Selected stocks/ETFs available for extended trading hours are added to Default funnel watchlists.
**Columns Involved**: Optimized_by, FunnelName, Ranking
**Rules**:
- Optimized_by='Ext Hours Stock/ETF' identifies these entries
- Only inserted into Default (AttributedID=0) funnel
- Rankings of subsequent items shift +1 to accommodate

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no co-located JOINs. CLUSTERED INDEX on RealCID favors lookups by customer but most queries will filter by VersionID/FromDate for a specific monthly snapshot.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What does today's watchlist look like? | `WHERE VersionID = (SELECT MAX(VersionID) FROM BI_DB_WatchListsByFunnel)` |
| Watchlist for a specific country + funnel | `WHERE CountryID = X AND AttributedID = Y AND VersionID = Z ORDER BY Ranking` |
| How has a country's watchlist evolved? | `WHERE CountryID = X AND AttributedID = 0 ORDER BY VersionID, Ranking` |
| Which instruments appear most across countries? | `WHERE ItemType = 'Instrument' AND VersionID = Z GROUP BY ItemID, ItemName ORDER BY COUNT(DISTINCT CountryID) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | CountryID = CountryID | Full country attributes |
| DWH_dbo.Dim_Instrument | ItemID = InstrumentID (WHERE ItemType='Instrument') | Instrument details |
| DWH_dbo.Dim_Customer | RealCID = RealCID (WHERE ItemType='User') | PI profile |
| BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level | — | Downstream conversion tracking |

### 3.4 Gotchas

- **ItemID semantics change by ItemType**: ItemID is InstrumentID when ItemType='Instrument' but NULL when ItemType='User' (RealCID holds the CID instead). Never JOIN ItemID to Dim_Instrument without filtering ItemType='Instrument' first.
- **NULL columns on User items**: ObservationPeriod_Start, ObservationPeriod_End, ObservationPeriod_OpenPos, InstrumentType, InstrumentType_Category, ISINCountryCode, StockCountry, StockRegion are all NULL for User/PI items.
- **Accumulating table**: No DELETE/TRUNCATE — all 61 versions coexist. Always filter by VersionID or FromDate for a single snapshot.
- **Monthly cadence despite daily schedule**: The SP is called daily by OpsDB but only executes on the last Sunday of each month (IF @Today = @lastSundayOfMonth). Most days it is a no-op.
- **Empty Optimized_by**: ~760K rows (all User/PI items) have empty Optimized_by since PIs are not geo-optimized by the same ranking logic.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream production wiki — verbatim description |
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 3 | Inferred from live data patterns — medium confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Passthrough from BI_DB_CIDFirstDates. (Tier 1 — Customer.CustomerStatic) |
| 2 | Country | varchar(50) | YES | Full country name in English. Resolved from Dim_Country.Name via CountryID. 250 distinct countries. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 3 | Region | varchar(50) | YES | Marketing region label for this country. Resolved from Dim_Country.Region via CountryID. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other", "USA", "UK"). Used for geo-optimization hierarchy. Passthrough from Dim_Country. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 4 | EU | int | YES | Whether this country is a full EU member state. 1=EU member (27 countries), 0=non-EU. Passthrough from Dim_Country. (Tier 3 — Ext_Dim_Country) |
| 5 | AttributedID | int | NO | Funnel identifier controlling watchlist allocation template. 0=Default/None, 1=Stocks, 2=Crypto, 3=Copy, 4=CopyPortfolio, 5=CFD, 6=ETF. Derived from Dim_Customer.FunnelFromID via lookup dictionary. (Tier 2 — SP_WatchListsByFunnel) |
| 6 | FunnelName | varchar(50) | YES | Display name of the acquisition funnel. Values: 'None', 'Stocks', 'Crypto', 'Copy', 'CopyPortfolio', 'CFD', 'ETF'. Derived from AttributedID. (Tier 2 — SP_WatchListsByFunnel) |
| 7 | Ranking | int | NO | Position rank of this item within the country+funnel watchlist. 1=highest priority, up to 18. Computed by ROW_NUMBER ordered by COUNT(positions) DESC for instruments, or by PI selection logic for users. (Tier 2 — SP_WatchListsByFunnel) |
| 8 | ItemID | int | YES | Instrument identifier when ItemType='Instrument' (FK to Dim_Instrument.InstrumentID). NULL when ItemType='User'. Do not JOIN to Dim_Instrument without filtering ItemType first. (Tier 2 — SP_WatchListsByFunnel) |
| 9 | RealCID | int | YES | Customer ID of the Popular Investor when ItemType='User'. NULL when ItemType='Instrument'. Passthrough from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 10 | ItemName | varchar(max) | YES | Display name of the watchlist item. Dim_Instrument.InstrumentDisplayName for instruments (e.g., "Apple Inc.", "Bitcoin"), or PI username for users (e.g., "RealEstateTrusts", "eToroTeam"). (Tier 2 — SP_WatchListsByFunnel) |
| 11 | ItemType | varchar(50) | YES | Type discriminator. 'Instrument'=tradeable asset (1.28M rows), 'User'=Popular Investor to copy (740K rows). Determines which columns are populated (see Gotchas). (Tier 2 — SP_WatchListsByFunnel) |
| 12 | InstrumentType | varchar(50) | YES | Instrument type display name. Values: 'Stocks', 'Crypto Currencies', 'Commodities', 'Indices', 'ETF', 'Currencies'. NULL for User items. Resolved from Dim_Instrument.InstrumentTypeID. (Tier 2 — SP_WatchListsByFunnel) |
| 13 | InstrumentType_Category | varchar(50) | YES | Allocation category used by the funnel allocation engine. Values: 'Stocks', 'Crypto', 'CFD', 'ETF_only', 'Stocks_only', 'Crypto_exc_coins', 'Stocks_only_US', 'ETF_only_US', 'CFD_no_Currencies', 'Stocks_no_HK', 'Crypto_no_BNB', etc. NULL for User items. (Tier 2 — SP_WatchListsByFunnel) |
| 14 | ISINCountryCode | varchar(15) | YES | ISO country code prefix extracted from the instrument's ISIN. Used to determine stock nationality for local stock forcing. NULL for non-stock instruments and User items. 45 distinct codes. (Tier 2 — SP_WatchListsByFunnel) |
| 15 | StockCountry | varchar(50) | YES | Country name resolved from ISINCountryCode. NULL for non-stock instruments and User items. (Tier 2 — SP_WatchListsByFunnel) |
| 16 | StockRegion | varchar(50) | YES | Marketing region resolved from ISINCountryCode. Used with IsLocalStock to determine if a stock is local to the user's region. NULL for non-stock instruments and User items. (Tier 2 — SP_WatchListsByFunnel) |
| 17 | IsLocalStock | int | YES | Flag indicating whether the stock's region matches the user's region. 1=local stock, 0=non-local or not applicable. Used for EU/AU local stock forcing rules. (Tier 2 — SP_WatchListsByFunnel) |
| 18 | ObservationPeriod_Start | date | YES | Start of the 2-month rolling observation window used to rank instruments by trading activity. Typically GETDATE()-1 minus 2 months. NULL for User items. (Tier 2 — SP_WatchListsByFunnel) |
| 19 | ObservationPeriod_End | date | YES | End of the 2-month rolling observation window. Typically GETDATE()-1 (yesterday). NULL for User items. (Tier 2 — SP_WatchListsByFunnel) |
| 20 | Optimized_by | varchar(50) | YES | Geo-optimization level that produced this item. 'Country'=country-level ranking, 'Region'=region fallback, 'WorldWide'=global fallback, 'Region_Local'=forced local stock (region), 'Country_Local'=forced local stock (country), 'Ext Hours Stock/ETF'=extended hours instrument, 'Permanent Instrument'=always-present instrument. Empty string for User/PI items. (Tier 2 — SP_WatchListsByFunnel) |
| 21 | ObservationPeriod_OpenPos | int | YES | Number of positions opened for this instrument during the observation period. Used as the ranking metric (higher count = higher rank). NULL for User items. (Tier 2 — SP_WatchListsByFunnel) |
| 22 | VersionID | int | NO | Monotonically incrementing monthly version counter. MAX(existing)+1 on each run. 61 versions from Feb 2020 to Apr 2026. ~37K rows per version. (Tier 2 — SP_WatchListsByFunnel) |
| 23 | FromDate | date | YES | Date when this watchlist version was generated. Always the last Sunday of the month. Used to identify which monthly snapshot a row belongs to. (Tier 2 — SP_WatchListsByFunnel) |
| 24 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by SP_WatchListsByFunnel. (Tier 5 — ETL infrastructure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CountryID | Customer.CustomerStatic | CountryID | passthrough via BI_DB_CIDFirstDates |
| Country | Dictionary.Country | Name | dim-lookup passthrough via Dim_Country |
| Region | Dictionary.MarketingRegion | Name | dim-lookup passthrough via Dim_Country.Region |
| EU | Ext_Dim_Country | EU | passthrough via Dim_Country |
| AttributedID | Customer.CustomerStatic | FunnelFromID | computed — FunnelFromID mapped to 0-6 via dictionary |
| FunnelName | Customer.CustomerStatic | FunnelFromID | computed — mapped to display name |
| Ranking | Trade.PositionTbl | — | computed — ROW_NUMBER by position count |
| ItemID | Trade.Instrument / Customer.CustomerStatic | InstrumentID / CID | conditional passthrough by ItemType |
| RealCID | Customer.CustomerStatic | CID | passthrough for User items |
| ItemName | Trade.InstrumentMetaData / Customer | InstrumentDisplayName / username | conditional passthrough by ItemType |
| ItemType | — | — | SP literal |
| InstrumentType | Trade.Instrument | InstrumentTypeID | computed — resolved to name |
| InstrumentType_Category | — | — | SP allocation logic |
| ISINCountryCode | Trade.Instrument | ISIN | computed — country code extraction |
| StockCountry | Dictionary.Country | Name | computed — via ISINCountryCode resolution |
| StockRegion | Dictionary.MarketingRegion | Name | computed — via ISINCountryCode resolution |
| IsLocalStock | — | — | SP computed flag |
| ObservationPeriod_Start | — | — | SP computed date |
| ObservationPeriod_End | — | — | SP computed date |
| Optimized_by | — | — | SP literal |
| ObservationPeriod_OpenPos | Trade.PositionTbl | — | computed — COUNT(*) positions |
| VersionID | — | — | SP computed incrementing counter |
| FromDate | — | — | SP computed last Sunday of month |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (open positions, last 2 months)
DWH_dbo.Dim_Customer (FunnelFromID → funnel segmentation)
DWH_dbo.Dim_Instrument (instrument metadata, ISIN, type)
DWH_dbo.Dim_Country (country/region/EU, compliance rules)
BI_DB_dbo.BI_DB_CIDFirstDates (customer geo attribution)
  |
  |-- SP_WatchListsByFunnel @date (monthly, last Sunday)
  |   Sections 1-11: allocation tables → instrument ranking →
  |   geo-optimization (Country→Region→WorldWide) → PI insertion →
  |   local stock forcing → extended hours → compliance filtering
  v
BI_DB_dbo.BI_DB_WatchListsByFunnel (2.02M rows, 61 versions)
  |
  |-- SP_Watchlist_Tracking (downstream consumer)
  v
BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level
BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country dimension lookup |
| ItemID | DWH_dbo.Dim_Instrument | Instrument details (when ItemType='Instrument') |
| RealCID | DWH_dbo.Dim_Customer | PI profile (when ItemType='User') |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| BI_DB_dbo.SP_Watchlist_Tracking | Reader | Reads from this table for conversion tracking analysis |
| BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level | Downstream | Per-item watchlist trading attribution |
| BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level | Downstream | Aggregated watchlist conversion metrics |

---

## 7. Sample Queries

### 7.1 Current Watchlist for a Specific Country and Funnel

```sql
SELECT Ranking, ItemName, ItemType, InstrumentType, InstrumentType_Category, Optimized_by
FROM BI_DB_dbo.BI_DB_WatchListsByFunnel
WHERE VersionID = (SELECT MAX(VersionID) FROM BI_DB_dbo.BI_DB_WatchListsByFunnel)
  AND CountryID = 218  -- United Kingdom
  AND AttributedID = 0  -- Default funnel
ORDER BY Ranking
```

### 7.2 Most Globally Popular Instruments in Latest Version

```sql
SELECT TOP 20 ItemID, ItemName, InstrumentType, COUNT(DISTINCT CountryID) AS countries_shown, AVG(Ranking) AS avg_rank
FROM BI_DB_dbo.BI_DB_WatchListsByFunnel
WHERE VersionID = (SELECT MAX(VersionID) FROM BI_DB_dbo.BI_DB_WatchListsByFunnel)
  AND ItemType = 'Instrument'
GROUP BY ItemID, ItemName, InstrumentType
ORDER BY countries_shown DESC
```

### 7.3 Version History — How Many Items Per Version

```sql
SELECT VersionID, FromDate, COUNT(*) AS total_items,
       SUM(CASE WHEN ItemType = 'Instrument' THEN 1 ELSE 0 END) AS instruments,
       SUM(CASE WHEN ItemType = 'User' THEN 1 ELSE 0 END) AS users
FROM BI_DB_dbo.BI_DB_WatchListsByFunnel
GROUP BY VersionID, FromDate
ORDER BY VersionID DESC
```

---

## 8. Atlassian Knowledge Sources

- [Watchlist Terms](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13927481406/Watchlist+Terms) — Defines AttributeID, FunnelAttribute, and default watchlist terminology
- [Watchlist - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11459723271/Watchlist+-+System+Document) — System overview including PRD links for funnel-based watchlists
- [Watchlist DB Architecture](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13941440722/Watchlist+DB+Architecture) — DefaultItemsMapping schema and AttributeId role in personalization

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 3 T1, 17 T2, 1 T3, 0 T4, 1 T5 | Elements: 24/24, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_WatchListsByFunnel | Type: Table | Production Source: SP_WatchListsByFunnel (ETL-computed from DWH dimensions)*
