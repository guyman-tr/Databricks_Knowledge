# Column Lineage: main.bi_output.bi_output_customer_compliance_mas_population

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_customer_compliance_mas_population` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bi_output_customer_compliance_mas_population.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `CID` | `—` | `—` | `runtime_lineage` |
| 2 | `GCID` | `—` | `—` | `runtime_lineage` |
| 3 | `IsValidCustomer` | `—` | `—` | `runtime_lineage` |
| 4 | `Regulation` | `—` | `—` | `runtime_lineage` |
| 5 | `DesignatedRegulation` | `—` | `—` | `runtime_lineage` |
| 6 | `Region` | `—` | `—` | `runtime_lineage` |
| 7 | `Country` | `—` | `—` | `runtime_lineage` |
| 8 | `VerificationLevelID` | `—` | `—` | `runtime_lineage` |
| 9 | `Is_V3_verified` | `—` | `—` | `runtime_lineage` |
| 10 | `Reg_Date` | `—` | `—` | `runtime_lineage` |
| 11 | `V1_Date` | `—` | `—` | `runtime_lineage` |
| 12 | `V2_Date` | `—` | `—` | `runtime_lineage` |
| 13 | `V3_Date` | `—` | `—` | `runtime_lineage` |
| 14 | `UserFlowId` | `—` | `—` | `runtime_lineage` |
| 15 | `FlowId` | `—` | `—` | `runtime_lineage` |
| 16 | `CurrentStep` | `—` | `—` | `runtime_lineage` |
| 17 | `MaximumStep` | `—` | `—` | `runtime_lineage` |
| 18 | `CreatedAt` | `—` | `—` | `runtime_lineage` |
| 19 | `CompletedAt` | `—` | `—` | `runtime_lineage` |
| 20 | `Progress` | `—` | `—` | `runtime_lineage` |
| 21 | `Is_Stocks_Onboard` | `—` | `—` | `runtime_lineage` |
| 22 | `Stocks_onboard_date` | `—` | `—` | `runtime_lineage` |
| 23 | `Is_CKA_onboard` | `—` | `—` | `runtime_lineage` |
| 24 | `CKA_onboard_date` | `—` | `—` | `runtime_lineage` |
| 25 | `Is_CAR_onboard` | `—` | `—` | `runtime_lineage` |
| 26 | `CAR_onboard_date` | `—` | `—` | `runtime_lineage` |
| 27 | `isEligible_CKA` | `—` | `—` | `runtime_lineage` |
| 28 | `CKA_statusdate` | `—` | `—` | `runtime_lineage` |
| 29 | `isEligible_CAR` | `—` | `—` | `runtime_lineage` |
| 30 | `CAR_statusdate` | `—` | `—` | `runtime_lineage` |
| 31 | `FirstManualCFDpos_Date` | `—` | `—` | `runtime_lineage` |
| 32 | `Didtrade_manualCFD` | `—` | `—` | `runtime_lineage` |
| 33 | `FirstManualETFpos_Date` | `—` | `—` | `runtime_lineage` |
| 34 | `Didtrade_manualETF` | `—` | `—` | `runtime_lineage` |
| 35 | `FirstManualStockspos_Date` | `—` | `—` | `runtime_lineage` |
| 36 | `Didtrade_manualStocks` | `—` | `—` | `runtime_lineage` |
| 37 | `Deposit_Amount` | `—` | `—` | `runtime_lineage` |
| 38 | `Cashout_Amount` | `—` | `—` | `runtime_lineage` |
| 39 | `NetDeposit_Amount` | `—` | `—` | `runtime_lineage` |
| 40 | `ManualStocks_opencount` | `—` | `—` | `runtime_lineage` |
| 41 | `ManualETF_opencount` | `—` | `—` | `runtime_lineage` |
| 42 | `ManualCFD_opencount` | `—` | `—` | `runtime_lineage` |
| 43 | `Curr_Regulation` | `—` | `—` | `runtime_lineage` |
| 44 | `Previous_Regulation` | `—` | `—` | `runtime_lineage` |
| 45 | `Change_Date` | `—` | `—` | `runtime_lineage` |
| 46 | `IP_Country` | `—` | `—` | `runtime_lineage` |
| 47 | `Citizenship_Country` | `—` | `—` | `runtime_lineage` |
| 48 | `Has_AdditionalCitizenship` | `—` | `—` | `runtime_lineage` |
| 49 | `AdditionalCitizenship_Country` | `—` | `—` | `runtime_lineage` |
| 50 | `POB_Country` | `—` | `—` | `runtime_lineage` |
| 51 | `PlayerStatus` | `—` | `—` | `runtime_lineage` |
| 52 | `PlayerStatusReason` | `—` | `—` | `runtime_lineage` |
| 53 | `PlayerStatusSubReason` | `—` | `—` | `runtime_lineage` |
| 54 | `ScreeningStatus` | `—` | `—` | `runtime_lineage` |
| 55 | `Club` | `—` | `—` | `runtime_lineage` |
| 56 | `FirstDepositDate` | `—` | `—` | `runtime_lineage` |
| 57 | `FirstDepositAmount` | `—` | `—` | `runtime_lineage` |
| 58 | `Is_Shareholder` | `—` | `—` | `runtime_lineage` |
| 59 | `Is_Employed_By_Broker` | `—` | `—` | `runtime_lineage` |
| 60 | `Is_Public_Official` | `—` | `—` | `runtime_lineage` |
| 61 | `Is_Vulnerable_Client` | `—` | `—` | `runtime_lineage` |
| 62 | `Sources_of_Funds` | `—` | `—` | `runtime_lineage` |
| 63 | `Cash_Liquid_Assets` | `—` | `—` | `runtime_lineage` |
| 64 | `Net_Annual_Income` | `—` | `—` | `runtime_lineage` |
| 65 | `Planned_Invested_Amount` | `—` | `—` | `runtime_lineage` |
| 66 | `Occupation` | `—` | `—` | `runtime_lineage` |
| 67 | `Employment_Status` | `—` | `—` | `runtime_lineage` |
| 68 | `Employment_Status_AnsDate` | `—` | `—` | `runtime_lineage` |
| 69 | `EV_MatchStatus` | `—` | `—` | `runtime_lineage` |
| 70 | `EV_MatchStatusID` | `—` | `—` | `runtime_lineage` |
| 71 | `EV_MatchStatusDateTime` | `—` | `—` | `runtime_lineage` |
| 72 | `VendorPOA` | `—` | `—` | `runtime_lineage` |
| 73 | `VendorPOI` | `—` | `—` | `runtime_lineage` |
| 74 | `AutoPassed_Onboarding_selfie` | `—` | `—` | `runtime_lineage` |
| 75 | `AutoPassed_DocChecks` | `—` | `—` | `runtime_lineage` |
| 76 | `AMLComment` | `—` | `—` | `runtime_lineage` |
| 77 | `RiskComment` | `—` | `—` | `runtime_lineage` |
| 78 | `IsEDD` | `—` | `—` | `runtime_lineage` |
| 79 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
