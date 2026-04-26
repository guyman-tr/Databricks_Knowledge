# Lineage: BI_DB_dbo.BI_DB_AMLPeriodicReview

## Chain Summary

DWH_dbo.Dim_Customer (base population) + 25+ source tables → SP_BI_AMLPeriodicReview → cumulative DELETE+INSERT per review date → BI_DB_AMLPeriodicReview

## ETL Hops (Key Sources)

| Hop | Object | Type | Notes |
|-----|--------|------|-------|
| 1 | DWH_dbo.Dim_Customer | DWH dimension | Base population: VerificationLevelID=3, active depositor, PlayerStatusID NOT IN (2,4), PendingClosureStatusID NOT IN (2,3) |
| 2 | DWH_dbo.Dim_Country (×3) | DWH dimension | KYC/POB/Citizenship country names and RiskGroupID |
| 3 | DWH_dbo.Dim_Regulation | DWH dimension | Regulation text |
| 4 | DWH_dbo.Dim_PlayerStatus/Reasons/SubReasons | DWH dimensions | PlayerStatus family |
| 5 | DWH_dbo.Dim_PlayerLevel | DWH dimension | Club text |
| 6 | DWH_dbo.Dim_RiskClassification | DWH dimension | RiskClassification name |
| 7 | DWH_dbo.Dim_EvMatchStatus | DWH dimension | EV match status name |
| 8 | DWH_dbo.Dim_ScreeningStatus + Dim_PhoneVerified | DWH dimensions | Screening and phone verification status |
| 9 | DWH_dbo.Fact_CustomerAction | DWH fact | GROUP B dormancy detection; login geography; VPN analysis (ActionTypeID=14) |
| 10 | DWH_dbo.Fact_SnapshotCustomer + Dim_Range | DWH fact | GROUP C risk classification history; PII change history |
| 11 | DWH_dbo.Fact_BillingDeposit | DWH fact | Deposit amounts (lifetime/12m/6m/3m/current year); non-KYC country deposits |
| 12 | DWH_dbo.Fact_BillingWithdraw | DWH fact | Non-KYC country withdrawals |
| 13 | BI_DB_dbo.External_ScreeningService_Screening_UserScreening | External table | GROUP D PEP screening change date |
| 14 | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | External table | POA IssueDate (DocumentTypeID=1) |
| 15 | BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | External table | Document type mapping |
| 16 | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | External table | TIN/tax country (FieldId=6) |
| 17 | BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType | External table | Extended field type lookup |
| 18 | BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB fact | EV date (EvMatchStatusDate) |
| 19 | BI_DB_dbo.BI_DB_KYC_Panel | BI_DB table | KYC Q&A answers (Q10/Q11/Q14/Q15/Q18) |
| 20 | BI_DB_dbo.BI_DB_RiskAlertManagementTool | BI_DB table | RAMT alert aggregation |
| 21 | BI_DB_dbo.BI_DB_AML_BI_Alerts_New | BI_DB table | BI AML alert aggregation |
| 22 | BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractions | External table | APU (compliance interactions) |
| 23 | BI_DB_dbo.BI_DB_AMLPeriodicReview (self) | Target table | Self-reference for deduplication: exclude customers already reviewed within 12m/3yr |
| 24 | DWH_dbo.Dim_Position + Dim_Instrument | DWH dimensions | Occupation alert: leveraged/crypto position check |
| 25 | SP_BI_AMLPeriodicReview | Stored Procedure (BI_DB_dbo) | DELETE WHERE Review_Due_Date=@Date + INSERT. Author: Pavlina Masoura (2025-06-17). @Date parameter. |
| 26 | BI_DB_dbo.BI_DB_AMLPeriodicReview | Target (ROUND_ROBIN HEAP) | 573,216 rows cumulative (2026-04-23). 70 columns. Cumulative: rows persist across dates. |

## Column Lineage (Key Columns)

| Column | Source | Source Column | Transform |
|--------|--------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough |
| Review_Due_Date | SP logic | — | GROUP A: FirstDepositDate+3n yr; GROUP B: @Date; GROUP C/D: change date or anniversary |
| KYC_Country, POBCountry, CitizenshipCountry | DWH_dbo.Dim_Country | Name | JOIN on respective CountryID FKs |
| KYC_Country_Rank, POBCountry_Rank, CitizenshipCountry_Rank | DWH_dbo.Dim_Country | RiskGroupID | Passthrough |
| AlertCategory | SP logic | — | UNION of 4 population queries |
| PlayerStatus/Reason/SubReason, Club, RiskClassification, Regulation | DWH dimension tables | Name | JOINs at #finalreport stage |
| POI_ExpiryDate, Is_POI_Expired | DWH_dbo.Dim_Customer | IsIDProofExpiryDate | Passthrough + date comparison |
| POA_ExpiryDate, Is_POA_Expired | External_etoro_BackOffice_CustomerDocument | IssueDate | MAX IssueDate, expiry = < 1yr ago if flagged |
| TaxCountry, TaxCountryDiscrepancy | External_UserApiDB_Customer_ExtendedUserField | Value, CountryId | Pivot to comma-separated TIN countries |
| EVStatus, LastEVDate, EVReviewPending | BI_DB_CIDFirstDates + Dim_RiskClassification | EvMatchStatusDate | Staleness logic by risk tier |
| KYC_LastUpdateDate, SourcesOfIncome, Occupation, AnnualIncome, etc. | BI_DB_KYC_Panel | Q-answer text/dates | MAX aggregation by RealCID |
| TotalDeposits* | Fact_BillingDeposit (PaymentStatusID=2) | AmountUSD | SUM with date-range conditions |
| MaterialChangePII | Fact_SnapshotCustomer | Address/City/Zip/Email/Phone | LAG window function delta detection |
| MaterialChangeLogins | Fact_CustomerAction (ActionTypeID=14) | CountryIDByIP vs KYC Country | Count of mismatch days as % of total login days |
| MaterialChangeMIMO | Fact_BillingDeposit + Fact_BillingWithdraw | BinCountryID, CountryID, MOPCountry | Country not in KYC/POB/Citizenship/EEA set |
| RoutineMonitoringRedFlagsOutdatedData | #docs + #taxchangeinperod + Dim_EvMatchStatus | POI/POA expiry + TIN country | CASE flag combination |
| RoutineMonitoringRedFlagsEP | #KYCanswers + #DepositsMorethanDeclaredAlert + #occupation + #PlannedInvestmentAlert | Multiple | OR of 4 economic profile alerts |
| RoutineMonitoringRedFlagsHRC | #unionrank12 | RiskGroupID IN (1,2) | Deposits/logins/country changes to high-risk countries |
| RiskAlertSummary, LatestRiskAlertDateReview | BI_DB_RiskAlertManagementTool | AlertType, StatusReason, etc. | STRING_AGG |
| BIAMLAlerts, LatestBIAlertDate | BI_DB_AML_BI_Alerts_New | AlertType, AlertDate | STRING_AGG |
| APU_Gaps_Summary | External_ComplianceStateDB_Compliance_CustomerInteractions | DisplayName, CompletedDate, LastEvaluationData | STRING_AGG formatted |
| UpdateDate | — | GETDATE() | ETL timestamp |

## Downstream

| Consumer | Notes |
|----------|-------|
| BI_DB_dbo.BI_DB_AMLPeriodicReview_PostReview | Post-review outcome tracking |
| AML analyst review queues | Primary consumer — daily review workbook |
| SP_BI_AMLPeriodicReview (self) | Table is self-referenced in deduplication step |
