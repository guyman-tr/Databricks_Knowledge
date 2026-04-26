# Lineage: BI_DB_dbo.AML_InstrumentMetaData_Daily_Email_DayToDay_Changes

## Chain Summary

etoro.Trade.InstrumentMetaData (today) + etoro.Trade.History_InstrumentMetaData (yesterday) → two-snapshot ISIN diff → AML_InstrumentMetaData_Daily_Email_DayToDay_Changes

## ETL Hops

| Hop | Object | Type | Notes |
|-----|--------|------|-------|
| 1a | etoro.Trade.InstrumentMetaData | Production table (SQL Server) | Today's instrument metadata — InstrumentID, InstrumentDisplayName, SymbolFull, ISINCode, Tradable |
| 1b | etoro.Trade.History_InstrumentMetaData | Production temporal history (SQL Server) | Yesterday's ISIN state; SysEndTime column tracks record validity windows |
| 2a | Bronze/etoro/Trade/InstrumentMetaData | Azure Data Lake (Parquet) | Daily Generic Pipeline export |
| 2b | Bronze/etoro/Trade/History_InstrumentMetaData | Azure Data Lake (Parquet) | Daily Generic Pipeline export of temporal history |
| 3a | BI_DB_dbo.External_etoro_Trade_InstrumentMetaData | Synapse External Table | Parquet reader — today's instrument set |
| 3b | BI_DB_dbo.External_etoro_History_InstrumentMetaData | Synapse External Table | Parquet reader — yesterday's historical snapshot |
| 4 | SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email_DayToDay_Changes | Stored Procedure (BI_DB_dbo) | Builds #currentIsins (Tradable=1, valid ISIN) and #yesterdayIsins (SysEndTime >= yesterday, earliest per InstrumentID). INNER JOIN WHERE ISINCode differs. TRUNCATE + INSERT. Author: Eyal Boas (2025-04-27) |
| 5 | BI_DB_dbo.AML_InstrumentMetaData_Daily_Email_DayToDay_Changes | Target (ROUND_ROBIN HEAP) | 0 rows on 2026-04-23 (event-driven). 5 columns. |

## Column Lineage

| Column | Source | Source Column | Transform |
|--------|--------|---------------|-----------|
| InstrumentID | etoro.Trade.InstrumentMetaData (current) | InstrumentID | INNER JOIN key; passthrough |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData (current) | InstrumentDisplayName | Passthrough from #currentIsins |
| SymbolFull | etoro.Trade.InstrumentMetaData (current) | SymbolFull | Passthrough from #currentIsins |
| New_ISINCode | etoro.Trade.InstrumentMetaData (current) | ISINCode | Renamed — today's ISIN value |
| Old_ISINCode | etoro.Trade.History_InstrumentMetaData (yesterday) | ISINCode | Renamed — yesterday's earliest ISIN per InstrumentID |

## Downstream

| Consumer | Notes |
|----------|-------|
| AML daily email process | External consumer: ISIN change alert feed for sanctions/AML monitoring |
| AML_InstrumentMetaData_Daily_Email | Parent table providing full current-day ISIN universe for cross-reference |
