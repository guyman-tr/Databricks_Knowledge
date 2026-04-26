# BI_DB_dbo.BI_DB_Investors_Unclustered — Column Lineage

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| Date | SP_InvestorReport | @dd parameter | Direct assignment from SP date parameter | Tier 2 |
| DateID | SP_InvestorReport | @ddINT | CONVERT(CHAR(8), @dd, 112) — integer YYYYMMDD | Tier 2 |
| AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | Passthrough via temp tables | Tier 2 |
| CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | Passthrough via temp tables | Tier 2 |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | Passthrough via temp tables | Tier 2 |
| ActionType | SP_InvestorReport | Computed | CASE: 1→'Open', 4→'Close' (Manual stream); 'Copy' (Copy stream); 'Balance' (Balance stream) | Tier 2 |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough for Manual; CASE MirrorTypeID IN(1,2)→'Copy Trading' ELSE 'Copy Portfolio' for Copy; 'Balance' for Balance | Tier 2 |
| AssetType | SP_InvestorReport | Computed | CASE: InstrumentTypeID IN(5,6) AND Leverage<3 OR InstrumentTypeID=4 AND Leverage<3→'Investment' ELSE 'Trade'; 'Copy' for copy stream; 'NonInvested' for balance | Tier 2 |
| Customers | SP_InvestorReport | Aggregated | Manual/Copy: COUNT(DISTINCT CID); Balance: COUNT(CID) | Tier 2 |
| Amount | SP_InvestorReport | NetMI | SUM of net investment flows (-1 * Fact_CustomerAction.Amount for Manual; copy mirror amounts for Copy; credit delta for Balance) | Tier 2 |
| AUM_AUA | SP_InvestorReport | AUA/AUM | Manual: SUM(BI_DB_PositionPnL.Amount + PositionPnL); Copy: SUM(GuruCopiers Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL); Balance: V_Liabilities.Credit | Tier 2 |
| UpdateDate | SP_InvestorReport | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| DWH_dbo.Dim_Position | Position leverage and open/close dates | DWH_dbo |
| DWH_dbo.Fact_CustomerAction | Customer actions (open=1, close=4, copy mirror=15-18) | DWH_dbo |
| DWH_dbo.Dim_Instrument | Instrument type classification | DWH_dbo |
| DWH_dbo.Fact_SnapshotCustomer | Customer snapshot — AM, country, regulation, valid/depositor flags | DWH_dbo |
| DWH_dbo.Dim_Range | Date range SCD for snapshot validity | DWH_dbo |
| DWH_dbo.Dim_Manager | Account manager validation | DWH_dbo |
| DWH_dbo.Dim_Mirror | Active mirror relationships (copy trading) | DWH_dbo |
| BI_DB_dbo.BI_DB_PositionPnL | Position-level PnL for AUA calculation | BI_DB_dbo |
| general.etoroGeneral_History_GuruCopiers | Copy portfolio AUM components | general |
| DWH_dbo.V_Liabilities | Customer cash credit balance | DWH_dbo |
| BI_DB_dbo.BI_DB_Investors_STG | Staging table — intermediate aggregation | BI_DB_dbo |
