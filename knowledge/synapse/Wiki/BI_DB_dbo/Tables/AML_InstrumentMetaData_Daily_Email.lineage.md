# Lineage: BI_DB_dbo.AML_InstrumentMetaData_Daily_Email

## Chain Summary

etoro.Trade.InstrumentMetaData → Bronze/etoro/Trade/InstrumentMetaData → External_etoro_Trade_InstrumentMetaData → AML_InstrumentMetaData_Daily_Email

## ETL Hops

| Hop | Object | Type | Notes |
|-----|--------|------|-------|
| 1 | etoro.Trade.InstrumentMetaData | Production table (SQL Server) | 37-column instrument metadata; source of InstrumentID, InstrumentDisplayName, ISINCode, Tradable |
| 2 | Bronze/etoro/Trade/InstrumentMetaData | Azure Data Lake (Parquet) | Daily Generic Pipeline export from production |
| 3 | BI_DB_dbo.External_etoro_Trade_InstrumentMetaData | Synapse External Table | Parquet reader; DATA_SOURCE = internal-sources; LOCATION = Bronze/etoro/Trade/InstrumentMetaData |
| 4 | SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email | Stored Procedure (BI_DB_dbo) | TRUNCATE + INSERT. Filter: Tradable=1, valid ISINCode (not NULL/'null'/'0'/'na'/'n.a'/'n.a.'). Author: Eyal Boas (2025-02-25) |
| 5 | BI_DB_dbo.AML_InstrumentMetaData_Daily_Email | Target (ROUND_ROBIN HEAP) | 12,124 rows (2026-04-23 sample). 3 columns. |

## Column Lineage

| Column | Source | Source Column | Transform |
|--------|--------|---------------|-----------|
| InstrumentID | etoro.Trade.InstrumentMetaData | InstrumentID | Passthrough |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData | InstrumentDisplayName | Passthrough |
| ISINCode | etoro.Trade.InstrumentMetaData | ISINCode | Passthrough; SP WHERE filter removes NULLs and 6 invalid string patterns |

## Downstream

| Consumer | Notes |
|----------|-------|
| AML_InstrumentMetaData_Daily_Email_DayToDay_Changes | Sibling: compares today's ISINs vs External_etoro_History_InstrumentMetaData yesterday to detect ISIN changes |
| AML daily email process | External consumer; this table is the filtered instrument universe feed |
