# Lineage: BI_DB_dbo.BI_DB_GST_Report

## Source Objects

| # | Source Object | Schema | Type | Relationship |
|---|--------------|--------|------|-------------|
| 1 | Fact_SnapshotCustomer | DWH_dbo | Table | Population base — Singapore depositors filtered by IsCreditReportValidCB=1, IsValidCustomer=1, IsDepositor=1, CountryID=183 |
| 2 | Dim_Range | DWH_dbo | Table | Date range filter for Fact_SnapshotCustomer snapshot validity |
| 3 | Dim_Regulation | DWH_dbo | Table | Regulation name lookup (JOIN on RegulationID = DWHRegulationID) |
| 4 | Dim_PlayerLevel | DWH_dbo | Table | Club/tier name lookup (JOIN on PlayerLevelID) |
| 5 | Dim_Country | DWH_dbo | Table | Country filter (CountryID=183 = Singapore) |
| 6 | Fact_CustomerAction | DWH_dbo | Table | Commission by InstrumentType + IsSettled; Islamic fee (CompensationReasonID 117,118); Staking compensation (CompensationReasonID=3) |
| 7 | Dim_Instrument | DWH_dbo | Table | InstrumentType classification for commission split (Stocks, ETF, Indices, Commodities, Crypto Currencies, Currencies) |
| 8 | BI_DB_DDR_CID_Level | BI_DB_dbo | Table | OvernightFee, CashoutFee, TotalDormantFee, TransferCoinFees |
| 9 | BI_DB_DepositWithdrawFee | BI_DB_dbo | Table | ConversionFee (SUM of PIPsCalculation) |
| 10 | Function_Revenue_TicketFee | BI_DB_dbo | Function (TVF) | TicketingFee calculation |
| 11 | Function_Revenue_TicketFeeByPercent | BI_DB_dbo | Function (TVF) | TicketingFeeByPercent calculation |
| 12 | Dim_Position | DWH_dbo | Table | Airdrop positions (IsAirDrop=1) for staking RevShare computation |
| 13 | Dealing_Staking_Parameters | Dealing_dbo | Table | Staking-eligible instrument list (automated, replaces hardcoded InstrumentID list) |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|--------------|---------------|-----------|------|
| 1 | RealCID | Fact_SnapshotCustomer | RealCID | Passthrough | T1 |
| 2 | Regulation | Dim_Regulation | Name | Dim-lookup passthrough (JOIN on DWHRegulationID = fsc.RegulationID) | T1 |
| 3 | Club | Dim_PlayerLevel | Name | Dim-lookup passthrough (JOIN on PlayerLevelID) | T1 |
| 4 | Entity | Fact_SnapshotCustomer | RegulationID | CASE WHEN RegulationID IN (4,10) THEN 'eToro Capital Australia' WHEN 2 THEN 'eToro UK' ELSE NULL END | T2 |
| 5 | Is_eToro Group Trading | Fact_SnapshotCustomer | RegulationID | CASE WHEN RegulationID IN (1,2,4,10,9) THEN 1 ELSE 0 END | T2 |
| 6 | Date | SP_GST_Report | @Date | CONVERT(date, @DateID) — the business date for the report | T2 |
| 7 | Real Stocks | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Stocks' | T2 |
| 8 | Real ETF | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='ETF' | T2 |
| 9 | Real Indices | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Indices' | T2 |
| 10 | Real Commodities | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Commodities' | T2 |
| 11 | Real Crypto Currencies | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Crypto Currencies' | T2 |
| 12 | Real Currenciess | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Currencies' | T2 |
| 13 | CFD Stocks | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Stocks' | T2 |
| 14 | CFD ETF | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='ETF' | T2 |
| 15 | CFD Indices | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Indices' | T2 |
| 16 | CFD Commodities | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Commodities' | T2 |
| 17 | CFD Crypto Currencies | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Crypto Currencies' | T2 |
| 18 | CFD Currenciess | Fact_CustomerAction | CommissionOnClose | SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Currencies' | T2 |
| 19 | OvernightFee | BI_DB_DDR_CID_Level | OvernightFee | SUM(OvernightFee) for CID on @dateID | T2 |
| 20 | CashoutFee | BI_DB_DDR_CID_Level | CashoutFee + TransferCoinFees | SUM(CashoutFee) + SUM(TransferCoinFees) — composite of two DDR columns | T2 |
| 21 | ConversionFee | BI_DB_DepositWithdrawFee | PIPsCalculation | SUM(ISNULL(PIPsCalculation,0)) for CID on @dateID | T2 |
| 22 | TotalDormantFee | BI_DB_DDR_CID_Level | DormantFee | SUM(ISNULL(DormantFee,0)) | T2 |
| 23 | Staking_Revshare | Fact_CustomerAction / Dim_Position | Amount | SUM(Amount * (1-RevShare)/RevShare) from compensation (CompensationReasonID=3) + airdrop positions (IsAirDrop=1) | T2 |
| 24 | UpdateDate | SP_GST_Report | @Date | @Date parameter passed to SP | T2 |
| 25 | TicketingFee | Function_Revenue_TicketFee | TicketFee | -SUM(ISNULL(TicketFee,0)) — negated to represent cost to company | T2 |
| 26 | IslamicFee | Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=36 AND CompensationReasonID IN (117,118) | T2 |
| 27 | TicketingFeeByPercent | Function_Revenue_TicketFeeByPercent | TicketFeeByPercent | -SUM(ISNULL(TicketFeeByPercent,0)) — negated to represent cost to company | T2 |
