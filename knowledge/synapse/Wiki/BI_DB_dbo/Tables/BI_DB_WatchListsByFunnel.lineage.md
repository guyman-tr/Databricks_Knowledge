# BI_DB_dbo.BI_DB_WatchListsByFunnel — Column Lineage

## Source Objects

| Source | Schema | Role | Confidence |
|--------|--------|------|------------|
| DWH_dbo.Dim_Position | DWH_dbo | Position trading activity for instrument ranking | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer attributes (FunnelFromID, RealCID) | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument metadata (name, type, ISIN) | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Country | DWH_dbo | Country/region/EU attributes and compliance rules | Tier 1 — SP code confirmed |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | Customer country/region for geo attribution | Tier 1 — SP code confirmed |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| CountryID | BI_DB_CIDFirstDates | CountryID | passthrough (user's country) |
| Country | BI_DB_CIDFirstDates / Dim_Country | Country / Name | passthrough — resolved from Dim_Country.Name via CountryID |
| Region | BI_DB_CIDFirstDates / Dim_Country | Region | passthrough — from Dim_Country.Region via MarketingRegionID |
| EU | Dim_Country | EU | passthrough — 1=EU member, 0=non-EU |
| AttributedID | Dim_Customer | FunnelFromID | computed — mapped via #funnel_name_dictionary to 0-6 funnel codes |
| FunnelName | Dim_Customer | FunnelFromID | computed — mapped to 'None','Stocks','Crypto','Copy','CopyPortfolio','CFD','ETF' |
| Ranking | Dim_Position | — | computed — ROW_NUMBER by COUNT(positions) DESC within partition |
| ItemID | Dim_Instrument / Dim_Customer | InstrumentID / RealCID | passthrough — InstrumentID for Instrument items, RealCID for User items |
| RealCID | Dim_Customer | RealCID | passthrough — only populated for User/PI items |
| ItemName | Dim_Instrument / Dim_Customer | InstrumentDisplayName / username | passthrough — instrument display name or PI username |
| ItemType | — | — | computed — literal 'Instrument' or 'User' |
| InstrumentType | Dim_Instrument | InstrumentTypeID | computed — resolved to display name (Stocks, Crypto Currencies, Commodities, etc.) |
| InstrumentType_Category | SP allocation tables | — | computed — allocation category (Crypto, Stocks, CFD, ETF_only, Stocks_only, etc.) |
| ISINCountryCode | Dim_Instrument | ISIN | computed — extracted country code prefix from ISIN |
| StockCountry | Dim_Country | Name | computed — resolved from ISINCountryCode via ISIN-to-Country dictionary |
| StockRegion | Dim_Country | Region | computed — resolved from ISINCountryCode via ISIN-to-Region dictionary |
| IsLocalStock | — | — | computed — 1 if StockRegion matches user's Region, else 0 |
| ObservationPeriod_Start | — | — | computed — @TwoMonthsAgo (DATEADD(MONTH,-2,GETDATE()-1)) for Instrument items, NULL for User items |
| ObservationPeriod_End | — | — | computed — @Yesterday for Instrument items, NULL for User items |
| Optimized_by | — | — | computed — literal: 'Country','Region','WorldWide','Region_Local','Ext Hours Stock/ETF','Permanent Instrument','Country_Local' |
| ObservationPeriod_OpenPos | Dim_Position | — | computed — COUNT(*) of positions opened in observation window for Instrument items |
| VersionID | — | — | computed — MAX(VersionID)+1, incrementing monthly version counter |
| FromDate | — | — | computed — last Sunday of the current month when SP runs |
| UpdateDate | — | — | computed — GETDATE() at execution time |

## Lineage Notes

- This table is purely ETL-computed with no direct production passthrough. All columns are derived from DWH dimensions or SP logic.
- CountryID inherits Tier 1 from Customer.CustomerStatic via BI_DB_CIDFirstDates.
- Country and Region are dim-lookup passthroughs from Dim_Country (Tier 1 for Country from Dictionary.Country, Tier 2 for Region from SP_Dictionaries).
- EU is Tier 3 from Ext_Dim_Country.
- Most columns are Tier 2 (SP-computed logic).
