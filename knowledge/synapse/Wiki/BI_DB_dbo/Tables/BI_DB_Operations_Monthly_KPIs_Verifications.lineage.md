# Column Lineage: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications

> **STALE TABLE WARNING**: Writer SP code was removed from SP_Operations_Monthly_KPIs_FullData on 2025-04-14. A replacement SP was created but is NOT in the SSDT repo. Last data refresh: 2025-07-28. Lineage below reflects the historical SP logic.

## Source Objects
| Source | Type | Relationship |
|--------|------|-------------|
| DWH_dbo.Dim_Customer | Table | Primary source (core customer/verification attributes) |
| DWH_dbo.Dim_Country | Table | Region lookup via CountryID |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup |
| History_BackOfficeCustomer | Staging/History | Verification level change dates (VL1, VL2, EV match) |
| BackOffice document/EV tables | Staging | Document upload and electronic verification data |

## Column Lineage
| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | RealCID | Dim_Customer | RealCID | Passthrough |
| 2 | FirstDepositDate | Dim_Customer | FirstDepositDate | Passthrough |
| 3 | VerificationLevelID | Dim_Customer | VerificationLevelID | Passthrough |
| 4 | PlayerStatusID | Dim_Customer | PlayerStatusID | Passthrough |
| 5 | PendingClosureStatusID | Dim_Customer | PendingClosureStatusID | Passthrough |
| 6 | PlayerStatusReasonID | Dim_Customer | PlayerStatusReasonID | Passthrough |
| 7 | EvMatchStatus | Dim_Customer | EvMatchStatus | Passthrough |
| 8 | Region | Dim_Country | Region | Lookup via Dim_Customer.CountryID -> Dim_Country.CountryID |
| 9 | Regulation | Dim_Regulation | Name | Lookup via Dim_Customer.RegulationID -> Dim_Regulation.ID |
| 10 | VerificationDate | History_BackOfficeCustomer | — | Derived: date when customer reached VerificationLevelID >= 3 |
| 11 | DaysToVerify | — | — | ETL-computed: DATEDIFF from registration/FTD to VerificationDate |
| 12 | "Uploaded 2 Docs (not EV)" | — | — | ETL-computed: flag indicating customer uploaded 2+ documents without using electronic verification |
| 13 | IsDepositor | Dim_Customer | IsDepositor | Passthrough (cast to int) |
| 14 | DidCO | — | — | ETL-computed: flag indicating customer completed a cashout |
| 15 | Liquidated | — | — | ETL-computed: flag/amount indicating account liquidation |
| 16 | EffectiveAddDate | — | — | Tier 3 — likely registration or account activation date |
| 17 | FirstReviewed | — | — | ETL-computed: date of first back-office review |
| 18 | FirstTouch | — | — | ETL-computed: days from registration to first back-office touch |
| 19 | VerificationLevel1Date | History_BackOfficeCustomer | — | Derived: date when VerificationLevelID first changed to >= 1 |
| 20 | VerificationLevel2Date | History_BackOfficeCustomer | — | Derived: date when VerificationLevelID first changed to >= 2 |
| 21 | EvMatchStatusDate | History_BackOfficeCustomer | — | Derived: date when EvMatchStatus was set |
| 22 | RiskGroupID | Dim_Customer / Dim_Country | RiskGroupID | Lookup via customer CountryID |
| 23 | SuggestedPOA | — | — | ETL-computed: flag for suggested Proof of Address requirement |
| 24 | SuggestedPOI | — | — | ETL-computed: flag for suggested Proof of Identity requirement |
| 25 | VerificationMethod | — | — | ETL-computed: 'EV' (electronic), 'Docs' (document upload), or 'NA' |
| 26 | WorkingDaysToVerify | — | — | ETL-computed: business days from registration/FTD to VerificationDate |
| 27 | UnderOneDay | — | — | ETL-computed: 1 if verified within 1 working day, else 0 |
| 28 | OverOneDay | — | — | ETL-computed: 1 if verification took more than 1 working day, else 0 |
| 29 | FirstTouchSLA | — | — | ETL-computed: SLA compliance for first back-office touch |
| 30 | VerificationSLA | — | — | ETL-computed: SLA compliance for full verification completion |
| 31 | IsVerifyB4Deposit | — | — | ETL-computed: 1 if customer verified before first deposit |
| 32 | UpdateDate | — | — | ETL-computed: GETDATE() at SP execution |
| 33 | HoursToVerify | — | — | ETL-computed: DATEDIFF(hh, ...) from start to verification |
| 34 | MinutesToVerify | — | — | ETL-computed: DATEDIFF(mi, ...) from start to verification |
| 35 | FirstTouchHour | — | — | ETL-computed: hours from registration to first touch |
| 36 | FirstTouchMinute | — | — | ETL-computed: minutes from registration to first touch |
| 37 | KYCFlow | — | — | ETL-computed: KYC workflow classification (varchar 225) |
| 38 | RegisteredDate | Dim_Customer | RegisteredReal | Passthrough (renamed) |
