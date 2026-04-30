# Lineage: BI_DB_dbo.BI_DB_Investors_STG

## Source Objects

| # | Source Object | Schema | Type | Relationship |
|---|--------------|--------|------|-------------|
| 1 | Fact_CustomerAction | DWH_dbo | Table | Manual + Copy stream: position open/close and mirror action amounts |
| 2 | Dim_Instrument | DWH_dbo | Table | Manual stream: InstrumentType classification |
| 3 | Fact_SnapshotCustomer | DWH_dbo | Table | All streams: AccountManagerID, CountryID, RegulationID (passthrough); validity filters |
| 4 | Dim_Range | DWH_dbo | Table | All streams: DateRangeID boundary filter for Fact_SnapshotCustomer |
| 5 | Dim_Manager | DWH_dbo | Table | Manual + Copy stream: JOIN filter on AccountManagerID |
| 6 | Dim_Position | DWH_dbo | Table | Manual stream: Leverage for AssetType classification |
| 7 | BI_DB_PositionPnL | BI_DB_dbo | Table | Manual stream: AUA = Amount + PositionPnL for non-mirror positions |
| 8 | Dim_Mirror | DWH_dbo | Table | Copy stream: active mirror relationships, CID, MirrorTypeID |
| 9 | etoroGeneral_History_GuruCopiers | general | Table | Copy stream: AUM = Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL |
| 10 | V_Liabilities | DWH_dbo | View | Balance stream: Credit (AUA) and credit delta (NetMI) |

## Column Lineage

| Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|--------------|-----------------|-----------------|-----------|------|
| SourceTable | SP_InvestorReport | — | Literal: 'Manual', 'Copy', or 'Balance' | Tier 2 |
| Date | SP_InvestorReport | @dd parameter | Direct assignment | Tier 2 |
| DateID | SP_InvestorReport | @dd parameter | CONVERT(CHAR(8), @dd, 112) | Tier 2 |
| CID | Fact_CustomerAction / Dim_Mirror / V_Liabilities | RealCID / CID / CID | Passthrough per stream | Tier 2 |
| AccountManagerID | Fact_SnapshotCustomer | AccountManagerID | Passthrough — no transform | Tier 1 |
| CountryID | Fact_SnapshotCustomer | CountryID | Passthrough — no transform | Tier 1 |
| RegulationID | Fact_SnapshotCustomer | RegulationID | Passthrough — no transform | Tier 1 |
| ActionType | SP_InvestorReport | — | Literal: 'Manual', 'Copy', or 'Balance' | Tier 2 |
| AssetType | SP_InvestorReport | InstrumentTypeID, Leverage | CASE: 'Investment' (TypeID 4/5/6 AND Leverage<3), 'Trade', 'Copy', 'NonInvested' | Tier 2 |
| InstrumentType | Dim_Instrument / Dim_Mirror | InstrumentType / MirrorTypeID | Manual: passthrough. Copy: CASE on MirrorTypeID. Balance: literal 'Balance' | Tier 2 |
| NetMI | Fact_CustomerAction / V_Liabilities | Amount / Credit | Manual/Copy: SUM(-1 * Amount). Balance: today Credit − yesterday Credit | Tier 2 |
| AUA | BI_DB_PositionPnL / etoroGeneral_History_GuruCopiers / V_Liabilities | Amount+PositionPnL / Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL / Credit | Multi-source SUM per stream | Tier 2 |
| UpdateDate | SP_InvestorReport | — | GETDATE() | Tier 2 |

## Writer SP

| SP | Role |
|----|------|
| SP_InvestorReport | TRUNCATE + 3x INSERT (Manual, Copy, Balance streams) |

## Reader SP

| SP | Role |
|----|------|
| SP_InvestorReport_Cluster | Reads STG, JOINs BI_DB_CID_DailyCluster for ClusterSF, aggregates into BI_DB_Investors |
