# Lineage — BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|-------------|
| 1 | External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp | External Table | BI_DB_dbo | Fivetran (Google Sheet) | Primary source — EU sustainability-stamped equities list |
| 2 | Dim_Instrument | Table | DWH_dbo | Synapse DWH | JOIN on ISINCode = ISIN to resolve InstrumentID |
| 3 | SP_Equities_With_Sustainability_Stamp | Stored Procedure | BI_DB_dbo | Synapse DWH | Writer SP — truncate-and-reload |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| Ticker | External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp | Ticker | Passthrough | Tier 3 |
| ISIN | External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp | ISIN | Passthrough | Tier 3 |
| Name | External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp | Name | Passthrough | Tier 3 |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Dim-lookup passthrough via JOIN on ISINCode = ISIN | Tier 1 |
| UpdateDate | SP_Equities_With_Sustainability_Stamp | GETDATE() | ETL timestamp | Tier 2 |
