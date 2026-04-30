# Lineage: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument

## Source Objects

| # | Source Object | Schema | Type | Relationship | Wiki |
|---|--------------|--------|------|-------------|------|
| 1 | Fact_MarketPageViews | DWH_pagetracking | Table | Primary — page-view events drive the instrument interest grain | _unresolved_ |
| 2 | Dim_Instrument | DWH_dbo | Table | Lookup — InstrumentName (SymbolFull), InstrumentTypeID | [Dim_Instrument.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md) |
| 3 | Dim_Position | DWH_dbo | Table | Aggregation source — investment amounts, position counts, asset metrics | [Dim_Position.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md) |
| 4 | Dim_Customer | DWH_dbo | Table | Lookup — SalesForceAccountID → AccountId (post-load UPDATE) | [Dim_Customer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md) |
| 5 | SP_MarketingCloudUserBehavior | BI_DB_dbo | Stored Procedure | Writer SP — populates and maintains this table | [SP source](../../../../../DataPlatform/SynapseSQLPool1/sql_dp_prod_we/BI_DB_dbo/Stored%20Procedures/BI_DB_dbo.SP_MarketingCloudUserBehavior.sql) |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | CID | Fact_MarketPageViews | RealCID | Rename (RealCID → CID) | Tier 1 |
| 2 | AccountId | Dim_Customer | SalesForceAccountID | Post-load UPDATE via JOIN on CID=RealCID; rename | Tier 1 |
| 3 | UpdateDate | SP_MarketingCloudUserBehavior | — | GETDATE() on every INSERT/UPDATE | Tier 2 |
| 4 | LastVisit | Fact_MarketPageViews | Occurred | MAX(Occurred) per CID+InstrumentID for the run date | Tier 2 |
| 5 | LastMonthAmountInvest | Dim_Position | Amount | SUM(Amount) WHERE OpenDateID in current month, MirrorID=0 | Tier 2 |
| 6 | LastMonthOpenPositionsInvest | Dim_Position | PositionID | COUNT of positions opened in current month, MirrorID=0 | Tier 2 |
| 7 | TotalAmountInvest | Dim_Position | Amount | SUM(Amount) for all positions on this instrument, MirrorID=0 | Tier 2 |
| 8 | TotalPositionsInvest | Dim_Position | PositionID | COUNT(PositionID) for all positions on this instrument, MirrorID=0 | Tier 2 |
| 9 | AssetAmount | Dim_Position | Amount | SUM(Amount) across all positions for the CID's instrument type, MirrorID=0 | Tier 2 |
| 10 | AssetPositions | Dim_Position | PositionID | COUNT(*) across all positions for the CID's instrument type, MirrorID=0 | Tier 2 |
| 11 | OpenActiveInstruments | Dim_Position | PositionID | COUNT of open positions (CloseDateID=0) for the CID's instrument type, MirrorID=0 | Tier 2 |
| 12 | InstrumentID | Fact_MarketPageViews | InstrumentID | Passthrough (FK to Dim_Instrument) | Tier 1 |
| 13 | DateID | Fact_MarketPageViews | DateID | Passthrough — the @date parameter converted to YYYYMMDD int | Tier 2 |
| 14 | InstrumentTypeID | Dim_Instrument | InstrumentTypeID | Passthrough via JOIN on InstrumentID | Tier 1 |
| 15 | InstrumentName | Dim_Instrument | SymbolFull | Rename (SymbolFull → InstrumentName) | Tier 1 |
| 16 | LastOpen | Dim_Position | OpenDateID | MAX(OpenDateID) converted from int to date via CONVERT(date, CONVERT(varchar(8), ...), 112) | Tier 2 |
