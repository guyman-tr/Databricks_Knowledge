# BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Watchlist_Tracking` — daily TRUNCATE+INSERT (Item Level written first, then High Level aggregated from it)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| BI_DB_dbo.BI_DB_WatchListsByFunnel | BI_DB_dbo | Watchlist versions, items, rankings per funnel |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | Registration dates, first action dates for cohort definition |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer attributes, FunnelFromID for attribution |
| DWH_dbo.Dim_Position | DWH_dbo | Instrument trades (MirrorID=0, not partial close children) |
| DWH_dbo.Dim_Instrument | DWH_dbo | InstrumentDisplayName, InstrumentTypeID |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Copy trades (ActionTypeID=17 = register new mirror) |
| DWH_dbo.Dim_Mirror | DWH_dbo | ParentCID, ParentUserName for PI copy trades |
| BI_DB_dbo.BI_DB_First5Actions | BI_DB_dbo | First 5 customer actions for attribution |
| DWH_dbo.Dim_Country | DWH_dbo | Country name, Region, Region-to-Desk mapping |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| VersionID | BI_DB_WatchListsByFunnel | VersionID | passthrough |
| CountryID | DWH_dbo.Dim_Customer / Dim_Country | CountryID | passthrough |
| Country | DWH_dbo.Dim_Country | Country | passthrough |
| Region | DWH_dbo.Dim_Country | Region | passthrough |
| Desk | DWH_dbo.Dim_Country | Region | Region-to-Desk mapping |
| EU | DWH_dbo.Dim_Country | EU | passthrough (1=EU, 0=non-EU) |
| AttributedID | BI_DB_dbo.BI_DB_First5Actions / Dim_Customer | FunnelFromID | funnel attribution logic (1=Stocks, 2=Crypto, 3=Copy, 4=CopyPortfolio, 5=CFD, 0=unattributed) |
| FunnelName | (computed) | — | display name from AttributedID |
| ItemType | (computed) | — | 'Instrument' (from Dim_Position) or 'User' (from Fact_CustomerAction ActionTypeID=17) |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentTypeName | passthrough; NULL for User-type rows |
| ItemName | DWH_dbo.Dim_Instrument / Dim_Mirror | InstrumentDisplayName / ParentUserName | instrument name or PI username |
| ItemID | DWH_dbo.Dim_Instrument | InstrumentID | passthrough; NULL for User-type rows |
| RealCID | DWH_dbo.Dim_Mirror | ParentCID | PI's CID; NULL for Instrument-type rows |
| Ranking | BI_DB_WatchListsByFunnel | Ranking | watchlist position; NULL if not in watchlist |
| Is_In_WL | BI_DB_WatchListsByFunnel | (existence) | 1 if item found in watchlist, 0 otherwise |
| Users_TradedAsFirstAction | (aggregated) | — | COUNT DISTINCT users whose first action was this item |
| Users_TradedAsFirst5Actions | (aggregated) | — | COUNT DISTINCT users who traded this item in first 5 actions |
| First5Actions_Trades | (aggregated) | — | COUNT of first-5-action trades on this item |
| Users_Traded | (aggregated) | — | COUNT DISTINCT users who traded this item |
| PositionsOpened_or_CopyOpened | (aggregated) | — | COUNT positions or copy opens on this item |
| Version_FirstDate | BI_DB_WatchListsByFunnel | FirstDate | version start date |
| Version_LastDate | BI_DB_WatchListsByFunnel | LastDate | version end date |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
