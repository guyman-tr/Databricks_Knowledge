# EXW_dbo.EXW_DimUser_Enriched — Column Lineage

**Writer SP**: `EXW_dbo.SP_EXW_DimUser_Enriched`
**Load Pattern**: TRUNCATE + INSERT (full daily refresh)
**Generated**: 2026-04-20

---

## ETL Source Objects

| Object | Role |
|--------|------|
| `EXW_dbo.EXW_DimUser` | Primary Wallet user dimension (GCID scope, Region, IsTestAccount, CreditReportValid) |
| `DWH_dbo.Dim_Customer` | DWH customer master (compliance, regulation, verification attributes) |
| `DWH_dbo.Dim_Country` | Country name resolution for Country, CountryByIP, LastLoginCountry |
| `DWH_dbo.Dim_State_and_Province` | State/province name resolution for RegisterState, IPState |
| `DWH_dbo.Dim_PlayerStatus` | Player status name resolution for CurrentStatus, PreviousStatus |
| `DWH_dbo.Dim_Range` | Date range → status change date derivation |
| `DWH_dbo.Fact_SnapshotCustomer` | Historical player status snapshots for status change detection |
| `EXW_dbo.EXW_FCA_UserLogin` | Latest login events for LastLoginCountry (PlatformID IN 118,119,120) |
| `EXW_dbo.EXW_WalletInventory` | Wallet allocation timestamps for JoinDate (MIN Allocated per GCID) |
| `EXW_dbo.EXW_FinanceReportsBalancesNew` | Balance data for TotalBalanceUSD (SUM at max BalanceDateID) |
| `BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data` | KYC Q14 answer text and derived UpperLimit |
| `DWH_dbo.V_Liabilities` | Realized equity at prior day's DateID |

---

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | GCID | EXW_dbo.EXW_DimUser | GCID | Passthrough | Tier 1 — Customer.CustomerStatic |
| 2 | RealCID | EXW_dbo.EXW_DimUser | RealCID | Passthrough | Tier 1 — Customer.CustomerStatic |
| 3 | PlayerLevelID | DWH_dbo.Dim_Customer | PlayerLevelID | Passthrough via #dwh_dim_customer | Tier 1 — Customer.CustomerStatic |
| 4 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough | Tier 1 — BackOffice.Customer |
| 5 | Country | DWH_dbo.Dim_Country | Name | JOIN on Dim_Customer.CountryID = Dim_Country.CountryID | Tier 2 — SP_EXW_DimUser_Enriched |
| 6 | Region | EXW_dbo.EXW_DimUser | Region | Passthrough (already join-resolved in EXW_DimUser) | Tier 2 — SP_DimUser |
| 7 | CountryByIP | DWH_dbo.Dim_Country | Name | JOIN on Dim_Customer.CountryIDByIP = Dim_Country.CountryID | Tier 2 — SP_EXW_DimUser_Enriched |
| 8 | RegisterState | DWH_dbo.Dim_State_and_Province | Name | JOIN on Dim_Customer.RegionID = Dim_State_and_Province.RegionByIP_ID | Tier 2 — SP_EXW_DimUser_Enriched |
| 9 | IPState | DWH_dbo.Dim_State_and_Province | Name | JOIN on Dim_Customer.RegionByIP_ID = Dim_State_and_Province.RegionByIP_ID | Tier 2 — SP_EXW_DimUser_Enriched |
| 10 | IsTestAccount | EXW_dbo.EXW_DimUser | IsTestAccount | Passthrough | Tier 2 — SP_DimUser |
| 11 | CreditReportValid | EXW_dbo.EXW_DimUser | CreditReportValid | Passthrough (renamed from Dim_Customer.IsCreditReportValidCB) | Tier 2 — SP_Dim_Customer |
| 12 | IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough of DWH-computed flag | Tier 2 — SP_Dim_Customer |
| 13 | [2FA] | DWH_dbo.Dim_Customer | 2FA | Passthrough | Tier 2 — SP_Dim_Customer |
| 14 | RegulationID | DWH_dbo.Dim_Customer | RegulationID | Passthrough | Tier 1 — BackOffice.Customer |
| 15 | DesignatedRegulationID | DWH_dbo.Dim_Customer | DesignatedRegulationID | Passthrough | Tier 1 — BackOffice.Customer |
| 16 | PEPStatusID | DWH_dbo.Dim_Customer | ScreeningStatusID | Renamed | Tier 2 — SP_Dim_Customer |
| 17 | WorldCheckID | DWH_dbo.Dim_Customer | WorldCheckID | Passthrough | Tier 1 — BackOffice.Customer |
| 18 | WorldCheckResultsUpdated | DWH_dbo.Dim_Customer | WorldCheckResultsUpdated | Passthrough (preserved from prior row) | Tier 2 — SP_Dim_Customer |
| 19 | EvMatchStatus | DWH_dbo.Dim_Customer | EvMatchStatus | Passthrough | Tier 1 — BackOffice.Customer |
| 20 | DocumentStatusID | DWH_dbo.Dim_Customer | DocumentStatusID | Passthrough | Tier 1 — BackOffice.Customer |
| 21 | PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough | Tier 1 — Customer.CustomerStatic |
| 22 | AccountStatusID | DWH_dbo.Dim_Customer | AccountStatusID | Passthrough | Tier 1 — Customer.CustomerStatic |
| 23 | UserType | (computed) | — | CASE: TestAccount if IsTestAccount=1; eTorian if IsValidCustomer=0; else RealUser | Tier 2 — SP_EXW_DimUser_Enriched |
| 24 | CurrentStatus | DWH_dbo.Dim_PlayerStatus | Name | LAG-based most recent PlayerStatusID change per RealCID; DPS_curr.Name | Tier 2 — SP_EXW_DimUser_Enriched |
| 25 | PreviousStatus | DWH_dbo.Dim_PlayerStatus | Name | Previous PlayerStatusID before most recent change | Tier 2 — SP_EXW_DimUser_Enriched |
| 26 | StatusChangeDate | DWH_dbo.Dim_Range | FromDateID | CONVERT(DATE, CONVERT(CHAR(8), FromDateID)) at last PlayerStatusID change | Tier 2 — SP_EXW_DimUser_Enriched |
| 27 | LastLoginCountry | DWH_dbo.Dim_Country | Name | ROW_NUMBER latest EXW_FCA_UserLogin by DateID DESC (PlatformID IN 118,119,120) JOIN Dim_Country | Tier 2 — SP_EXW_DimUser_Enriched |
| 28 | JoinDate | EXW_dbo.EXW_WalletInventory | Allocated | MIN(Allocated) per GCID WHERE GCID > 0 | Tier 2 — SP_EXW_DimUser_Enriched |
| 29 | TotalBalanceUSD | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceUSD | SUM(BalanceUSD) per GCID at MAX(BalanceDateID) | Tier 2 — SP_EXW_DimUser_Enriched |
| 30 | POIExpireDate | DWH_dbo.Dim_Customer | IsIDProofExpiryDate | Renamed | Tier 2 — SP_Dim_Customer |
| 31 | POAExpireDate | DWH_dbo.Dim_Customer | IsAddressProofExpiryDate | Renamed | Tier 2 — SP_Dim_Customer |
| 32 | AnswerText | BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | Latest answer text for QuestionID=14 (net worth/investment capacity) | Tier 2 — SP_EXW_DimUser_Enriched |
| 33 | UpperLimit | BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | AnswerID | CASE: AnswerID→USD cap (39=1K, 40=5K, 41/141=20K, 42/48=100K, 58=50K, 59=200K, 60=500K, 61/62=1M) | Tier 2 — SP_EXW_DimUser_Enriched |
| 34 | RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | As of DateID = yesterday (GETDATE()-1) | Tier 2 — SP_EXW_DimUser_Enriched |
| 35 | TotalUnderTheLimit | (computed) | — | ISNULL(UpperLimit,0) - ISNULL(RealizedEquity,0); negative means over limit | Tier 2 — SP_EXW_DimUser_Enriched |
| 36 | IsOverLimit | (computed) | — | CASE WHEN TotalUnderTheLimit < 0 THEN 1 ELSE 0; 1 = user's realized equity exceeds declared net worth cap | Tier 2 — SP_EXW_DimUser_Enriched |
| 37 | UpdateDate | (computed) | — | GETDATE() at INSERT | Tier 2 — SP_EXW_DimUser_Enriched |

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 11 | GCID, RealCID, PlayerLevelID, VerificationLevelID, RegulationID, DesignatedRegulationID, WorldCheckID, EvMatchStatus, DocumentStatusID, PlayerStatusID, AccountStatusID |
| Tier 2 | 26 | Country, Region, CountryByIP, RegisterState, IPState, IsTestAccount, CreditReportValid, IsValidCustomer, [2FA], PEPStatusID, WorldCheckResultsUpdated, UserType, CurrentStatus, PreviousStatus, StatusChangeDate, LastLoginCountry, JoinDate, TotalBalanceUSD, POIExpireDate, POAExpireDate, AnswerText, UpperLimit, RealizedEquity, TotalUnderTheLimit, IsOverLimit, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

**PHASE 10B CHECKPOINT: PASS**
