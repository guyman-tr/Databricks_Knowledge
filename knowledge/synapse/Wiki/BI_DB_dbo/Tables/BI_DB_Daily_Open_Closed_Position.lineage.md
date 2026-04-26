# Column Lineage: BI_DB_dbo.BI_DB_Daily_Open_Closed_Position

## Source Systems

| Source | Type | Database | Schema | Object |
|--------|------|----------|--------|--------|
| Dim_Position | DWH Dimension | Synapse DWH | DWH_dbo | Dim_Position |
| Dim_Instrument | DWH Dimension | Synapse DWH | DWH_dbo | Dim_Instrument |
| Fact_SnapshotCustomer | DWH Fact | Synapse DWH | DWH_dbo | Fact_SnapshotCustomer |
| Dim_Regulation | DWH Dimension | Synapse DWH | DWH_dbo | Dim_Regulation |
| Dim_PlayerStatus | DWH Dimension | Synapse DWH | DWH_dbo | Dim_PlayerStatus |
| Dim_PlayerLevel | DWH Dimension | Synapse DWH | DWH_dbo | Dim_PlayerLevel |
| Dim_Country | DWH Dimension | Synapse DWH | DWH_dbo | Dim_Country |
| Dim_Range | DWH Dimension | Synapse DWH | DWH_dbo | Dim_Range |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | CAST as DATE; opens use OpenOccurred, closes use CloseOccurred |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.DWHRegulationID |
| IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough — point-in-time from snapshot via Dim_Range |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough — point-in-time from snapshot via Dim_Range |
| IsSettled | DWH_dbo.Dim_Position | IsSettledOnOpen / IsSettled | Opens: ISNULL(IsSettledOnOpen, IsSettled); Closes: IsSettled |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType, ISINCode, InstrumentTypeID | CASE: ISINCode LIKE '%US%' AND TypeID=5 → 'US Stocks'; NOT LIKE '%US%' AND TypeID=5 → 'Non-US Stocks'; else InstrumentType |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Passthrough via Fact_SnapshotCustomer.PlayerStatusID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough via Fact_SnapshotCustomer.PlayerLevelID |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via Fact_SnapshotCustomer.CountryID |
| Buy Amount | DWH_dbo.Dim_Position | InitialAmountCents | SUM(InitialAmountCents/100) for open positions only |
| Sell Amount | DWH_dbo.Dim_Position | Amount, NetProfit | SUM(Amount+NetProfit) for close positions only |
| Total Amount | (computed) | Buy Amount, Sell Amount | Buy Amount - Sell Amount |
| UpdateDate | (ETL metadata) | GETDATE() | CAST(GETDATE() AS DATE) |
| DateID | (ETL parameter) | @date | DWH_dbo.DateToDateID(@date) |

## Writer SP

- **SP**: `BI_DB_dbo.SP_Daily_Open_Closed_Position`
- **Author**: Adi Meidan
- **Pattern**: DELETE WHERE Date=@date, then INSERT (daily incremental)
- **Key filters**: ISNULL(IsPartialCloseChild,0)=0 on opens; point-in-time snapshot via Dim_Range
