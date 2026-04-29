# Lineage — BI_DB_dbo.BI_DB_Crypto_Top_1000_List

Generated: 2026-04-28 | Writer SP: SP_Crypto_Top_1000_List

---

## Source Objects

| Source Object | Kind | Used For |
|---------------|------|----------|
| `DWH_dbo.Dim_Customer` | Table | Hardcoded 1,000-CID filter (#List) |
| `BI_DB_dbo.BI_DB_DailyCommisionReport` | Table | Revenue aggregations by InstrumentTypeID=10 (#Pop) |
| `BI_DB_dbo.BI_DB_UsageTracking_SF` | Table | Last successful contact date per CID (#Last_Contact) |
| `DWH_dbo.Dim_Position` | Table | Last manual crypto position open date (#Last_Crypto_open) |
| `DWH_dbo.Dim_Instrument` | Table | Crypto instrument filter (InstrumentTypeID=10) |
| `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` | Table | Customer attributes at @BeginOfMonth (Region, AccountManager, LastLoggedIn, EOM_Equity, ACC_Revenue_Total) |
| `BI_DB_dbo.BI_DB_CIDFirstDates` | Table | Customer lifecycle attributes (GCID, Club, LastDepositDate, LastPosOpenDate) |

Upstream wiki paths:
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md`
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DailyCommisionReport.md`
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_UsageTracking_SF.md`
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md`
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md`
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CID_MonthlyPanel_FullData.md`
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CIDFirstDates.md`

---

## Column Lineage

| # | Column | Tier | Source Object | Source Column | Transform |
|---|--------|------|---------------|---------------|-----------|
| 1 | CID | 1 | BI_DB_CID_MonthlyPanel_FullData | CID | Passthrough; population pre-filtered to hardcoded 1,000-CID list |
| 2 | GCID | 1 | BI_DB_CIDFirstDates | GCID | Passthrough |
| 3 | Region | 1 | BI_DB_CID_MonthlyPanel_FullData | NewMarketingRegion | Rename |
| 4 | AccountManager | 1 | BI_DB_CID_MonthlyPanel_FullData | AccountManager | Passthrough |
| 5 | Club | 1 | BI_DB_CIDFirstDates | Club | Passthrough |
| 6 | LastLoggedIn | 1 | BI_DB_CID_MonthlyPanel_FullData | LastLoggedIn | Passthrough |
| 7 | LastDepositDate | 1 | BI_DB_CIDFirstDates | LastDepositDate | CAST(datetime → DATE) |
| 8 | LastPosOpenDate | 1 | BI_DB_CIDFirstDates | LastPosOpenDate | CAST(datetime → DATE) |
| 9 | LastContacted | 2 | BI_DB_UsageTracking_SF | CreatedDate | MAX(CAST(CreatedDate AS DATE)) WHERE ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c'), NULL if no contact |
| 10 | LastCryptoPosOpenDate | 2 | Dim_Position + Dim_Instrument | OpenOccurred | MAX(CAST(OpenOccurred AS DATE)) WHERE InstrumentTypeID=10 AND MirrorID=0 (manual only) |
| 11 | Equity | 1 | BI_DB_CID_MonthlyPanel_FullData | EOM_Equity | Rename |
| 12 | ACC_Revenue | 1 | BI_DB_CID_MonthlyPanel_FullData | ACC_Revenue_Total | Rename |
| 13 | ACC_Revenue_Crypto | 2 | BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM(FullCommissions + RollOverFee) WHERE InstrumentTypeID=10, all time |
| 14 | Revenue_Crypto_from_20230801 | 2 | BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM(FullCommissions + RollOverFee) WHERE InstrumentTypeID=10 AND DateID BETWEEN 20230801 AND 20231115 |
| 15 | Revenue_Crypto_from_20231201 | 2 | BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM(FullCommissions + RollOverFee) WHERE InstrumentTypeID=10 AND DateID >= 20231201 |
| 16 | UpdateDate | 2 | SP execution | — | GETDATE() at INSERT |
