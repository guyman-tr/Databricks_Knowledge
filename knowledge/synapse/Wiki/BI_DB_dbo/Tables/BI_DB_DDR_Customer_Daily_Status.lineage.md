# BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status — Column Lineage

> Source-to-target column mapping from `SP_DDR_Customer_Daily_Status`.

## Sources

| Source | Type | Role |
|--------|------|------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Table (BI_DB) | TP population base |
| DWH_dbo.Dim_Customer | Table (DWH) | FTD data, RealCID, FTDPlatformID |
| DWH_dbo.Dim_FTDPlatform | Table (DWH) | FTD platform name |
| DWH_dbo.Fact_SnapshotCustomer | Table (DWH) | Regulation, player status, depositor flag |
| DWH_dbo.Dim_Range | Table (DWH) | Date range for snapshot |
| DWH_dbo.Fact_CustomerAction | Table (DWH) | Login events |
| DWH_dbo.Dim_Country | Table (DWH) | Marketing region |
| eMoney_dbo.eMoney_Fact_Transaction_Status | Table (eMoney) | IBAN-only depositors |
| BI_DB_dbo.Function_Population_Funded | TVF | Funded account detection |
| BI_DB_dbo.Function_Population_First_Time_Funded | TVF | First-time funded date + IOB |
| BI_DB_dbo.Function_Population_First_Trading_Action | TVF | First trading action type + date |
| BI_DB_dbo.Function_Population_Balance_Only_Accounts | TVF | Balance-only segment |
| BI_DB_dbo.Function_Population_Portfolio_Only | TVF | Portfolio-only segment |
| BI_DB_dbo.Function_Population_Active_Traders | TVF | Active trader segment |
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | Table (BI_DB) | MIMO deposit/withdraw flags |
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform | Table (BI_DB) | Options MIMO population |

## Column Groups

| Column Group | Source | Transform |
|-------------|--------|-----------|
| Date/CID (cols 1-3) | SP parameter + population | passthrough |
| TP FTD (cols 4-6) | Dim_Customer (FTDPlatformID=1) | CASE filter |
| IBAN FTD (cols 7-9) | Dim_Customer (FTDPlatformID=3) | CASE filter |
| TP External FTDA (col 10) | MIMO AllPlatforms | CASE aggregation |
| Global FTD (cols 11-13) | Dim_Customer (MIN across platforms) | LEAST/MIN |
| Depositor/MIMO flags (cols 14-27) | MIMO AllPlatforms + coercion logic | MAX/CASE aggregation |
| Account segments (cols 28-32) | Population functions | Function calls |
| Snapshot attributes (cols 33-44) | Fact_SnapshotCustomer + Dim_Country | passthrough |
| Funded/Action (cols 45-49) | Population functions | Function calls |
| Login flags (cols 50-54) | Fact_CustomerAction + depositor lookup | CASE logic |
| IOB (cols 55-56) | Function_Population_First_Time_Funded | passthrough |
| Options FTD (cols 57-62) | Dim_Customer (FTDPlatformID=2) + MIMO | CASE filter |
| MoneyFarm FTD (cols 63-66) | Dim_Customer (FTDPlatformID=4) | CASE filter |
