# BI_DB_dbo.BI_DB_CySEC_Submission_ICF — Column Lineage

## Writer SP

`BI_DB_dbo.SP_CySEC_Submission_ICF` (Priority 0, Daily, SB_Daily)

## Source Objects

| Source Object | Role |
|--------------|------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Client balance data (TransferDirection=1, ClosingBalance IS NOT NULL) |
| BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI | EUR/USD ECB exchange rate (latest rate <= @Date) |
| DWH_dbo.Fact_SnapshotCustomer | Customer snapshot (MifidCategorizationID, RegulationID, PlayerLevelID, IsCreditReportValidCB) |
| DWH_dbo.Dim_Range | Date range resolution for snapshot |
| DWH_dbo.Dim_MifidCategorization | MifidCategorizationID → Name |
| DWH_dbo.Dim_Regulation | RegulationID → Name |
| DWH_dbo.Dim_PlayerLevel | PlayerLevelID → Name (Club) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | BI_DB_Client_Balance_CID_Level_New | CID | Passthrough (GROUP BY) |
| EndOfMonth | BI_DB_Client_Balance_CID_Level_New | Date | EOMONTH(Date) |
| ClosingBalance | BI_DB_Client_Balance_CID_Level_New | ClosingBalance | SUM(ISNULL(ClosingBalance,0)) — total balance across transfer directions |
| RealCryptoClosingBalance | BI_DB_Client_Balance_CID_Level_New | RealCryptoClosingBalance | SUM(ISNULL(RealCryptoClosingBalance,0)) |
| ClosingBalanceAdj_USD | — | — | ETL-computed: SUM(ClosingBalance - RealCryptoClosingBalance) — excludes real crypto for ICF |
| ClosingBalanceAdj_EUR | — | — | ETL-computed: ClosingBalanceAdj_USD / ECB rate |
| MifidCategory | DWH_dbo.Dim_MifidCategorization | Name | Passthrough via Fact_SnapshotCustomer JOIN |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via Fact_SnapshotCustomer JOIN |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough via Fact_SnapshotCustomer JOIN |
| UpdateDate | — | — | ETL metadata: GETDATE() |
| RealStocksBalance_USD | BI_DB_Client_Balance_CID_Level_New | RealStocksClosingBalance | SUM(ISNULL(RealStocksClosingBalance,0)) |
| RealStocksBalance_EUR | — | — | ETL-computed: RealStocksBalance_USD / ECB rate |
| ISRealStocksBalanceAdj_EUR>20000 | — | — | ETL-computed: CASE WHEN RealStocksBalance_EUR >= 20000 THEN 'Yes' ELSE 'No' |
| ISClosingBalanceAdj_EUR>20000 | — | — | ETL-computed: CASE WHEN ClosingBalanceAdj_EUR >= 20000 THEN 'Yes' ELSE 'No' |

## UC External Lineage

Not applicable — UC Target: _Not_Migrated.
