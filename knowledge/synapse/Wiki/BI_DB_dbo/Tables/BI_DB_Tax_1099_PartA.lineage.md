# BI_DB_dbo.BI_DB_Tax_1099_PartA — Column Lineage

## Writer SP
`BI_DB_dbo.SP_1099_part_A` — conditional TRUNCATE+INSERT (runs only when @Date > last day of reporting year and within Fivetran sync window)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| BI_DB_dbo.External_Fivetran_google_sheets_population_1_1099 | BI_DB_dbo | 1099 population list (report_year, CIDs) |
| DWH_dbo.Dim_Date | DWH_dbo | Calendar year boundaries from report_year |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer profile (RealCID, GCID, RegulationID, FirstDepositDate) |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Player status name |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name |
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | EOY regulation snapshot, block date detection |
| DWH_dbo.Dim_Range | DWH_dbo | Date range validity for snapshots |
| BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | BI_DB_dbo | TIN (Tax Identification Number) values |
| BI_DB_dbo.External_UserApiDB_KYC_CountryTaxType | BI_DB_dbo | Country-level tax type mapping |
| BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType | BI_DB_dbo | Extended user field type dictionary |
| DWH_dbo.Dim_Position | DWH_dbo | Closed positions for US-listed instruments |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument filter (US exchanges, ISIN) |
| BI_DB_dbo.BI_DB_DailyDividendsByPosition | BI_DB_dbo | Position-level dividends with tax codes |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Last login action (ActionTypeID=14) |
| DWH_dbo.Dim_Country | DWH_dbo | Country name for last login |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough (joined via External_Fivetran population) |
| GCID | DWH_dbo.Dim_Customer | GCID | passthrough |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | passthrough (current regulation) |
| FTD | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to DATE |
| Regulation_EOY | DWH_dbo.Dim_Regulation | Name | end-of-year regulation via Fact_SnapshotCustomer snapshot at @lastDayOfYearDateID |
| BlockDate | DWH_dbo.Fact_SnapshotCustomer | FromDateID (via Dim_Range) | MIN(FromDateID) where PlayerStatusID IN (2,4,9), CONVERT to DATE |
| TIN_Value | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | Value | CASE WHEN LEN(Value) IN (0,1) THEN 'Null' ELSE Value END; filtered to FieldId=6, CountryID=219 (US) |
| LastLogInCountry | DWH_dbo.Dim_Country | Name | last login country by IP; blocked users get pre-block login, others get most recent |
| LastLogDate | DWH_dbo.Fact_CustomerAction | DateID | CONVERT to DATE; blocked users get pre-block date, others get most recent |
| Gross_Proceeds_LongReal | DWH_dbo.Dim_Position | Amount, NetProfit | SUM(Amount+NetProfit) WHERE IsBuy=1 AND IsSettled=1 |
| PositionCountLongReal | DWH_dbo.Dim_Position | IsBuy, IsSettled | COUNT WHERE IsBuy=1 AND IsSettled=1 |
| Gross_Proceeds_LongCFD | DWH_dbo.Dim_Position | Amount, NetProfit | SUM(Amount+NetProfit) WHERE IsBuy=1 AND IsSettled=0 |
| PositionCountLongCFD | DWH_dbo.Dim_Position | IsBuy, IsSettled | COUNT WHERE IsBuy=1 AND IsSettled=0 |
| Gross_Proceeds_ShortCFD | DWH_dbo.Dim_Position | Amount, NetProfit | SUM(Amount+NetProfit) WHERE IsBuy=0 AND IsSettled=0 |
| PositionCountShortCFD | DWH_dbo.Dim_Position | IsBuy, IsSettled | COUNT WHERE IsBuy=0 AND IsSettled=0 |
| Dividends_LongReal | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 |
| Dividends_LongCFD | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 |
| Dividends_LongReal_0 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=0 |
| Dividends_LongCFD_0 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=0 |
| Dividends_LongReal_1 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=1 |
| Dividends_LongCFD_1 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=1 |
| Dividends_LongReal_6 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=6 |
| Dividends_LongCFD_6 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=6 |
| Dividends_LongReal_8 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=8 |
| Dividends_LongCFD_8 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=8 |
| Dividends_LongReal_9 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=9 |
| Dividends_LongCFD_9 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=9 |
| Dividends_LongReal_23 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=23 |
| Dividends_LongCFD_23 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=23 |
| Dividends_LongReal_27 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=27 |
| Dividends_LongCFD_27 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=27 |
| Dividends_LongReal_33 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=33 |
| Dividends_LongCFD_33 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=33 |
| Dividends_LongReal_35 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=35 |
| Dividends_LongCFD_35 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=35 |
| Dividends_LongReal_36 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=36 |
| Dividends_LongCFD_36 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=36 |
| Dividends_LongReal_37 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=37 |
| Dividends_LongCFD_37 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=37 |
| Dividends_LongReal_40 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=40 |
| Dividends_LongCFD_40 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=40 |
| Dividends_LongReal_78 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=1 AND TaxCode=78 |
| Dividends_LongCFD_78 | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Amount | SUM WHERE IsBuy=1 AND IsSettled=0 AND TaxCode=78 |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
