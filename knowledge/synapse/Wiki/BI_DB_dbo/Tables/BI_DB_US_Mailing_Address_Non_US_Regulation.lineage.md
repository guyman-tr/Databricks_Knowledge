# BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation — Column Lineage

## Writer SP
`BI_DB_dbo.SP_US_Mailing_Address_Non_US_Regulation` — daily DELETE @Date + INSERT (accumulation: only NEW customers appended)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Customer | DWH_dbo | Customer attributes (RealCID, FirstDepositDate, VerificationLevelID, CountryID) |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name lookup |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Player status name lookup |
| DWH_dbo.Dim_Country | DWH_dbo | Country name lookup |
| External_etoro_Customer_Address | External | Mailing address (filtered CountryID=219 for US) |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | VerificationLevel3Date |
| DWH_dbo.V_Liabilities | DWH_dbo | Equity (Liabilities + ActualNWA) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to date |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | dim-lookup via RegulationID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | dim-lookup via PlayerStatusID |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | passthrough |
| Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | computed sum |
| DateRelevance | (parameter) | @Date | passthrough |
| UpdateDate | (computed) | — | GETDATE() |
| KYC_Country | DWH_dbo.Dim_Country | Name | dim-lookup via Dim_Customer.CountryID |

**PHASE 10B CHECKPOINT: PASS**
