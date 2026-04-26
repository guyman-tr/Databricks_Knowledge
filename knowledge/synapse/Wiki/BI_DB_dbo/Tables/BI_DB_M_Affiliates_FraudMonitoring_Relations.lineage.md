# BI_DB_dbo.BI_DB_M_Affiliates_FraudMonitoring_Relations — Column Lineage

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| AffiliateID | BI_DB_CIDFirstDates | SerialID | Passthrough | Tier 2 |
| CID | BI_DB_CIDFirstDates | CID | Passthrough | Tier 2 |
| GCID | BI_DB_CIDFirstDates | GCID | Passthrough | Tier 2 |
| registered | BI_DB_CIDFirstDates | registered | Passthrough | Tier 2 |
| Country | BI_DB_CIDFirstDates | Country | Passthrough | Tier 2 |
| FirstDepositAmount | BI_DB_CIDFirstDates | FirstDepositAmount | Passthrough | Tier 2 |
| IsFTD | SP computed | FirstDepositDate | CASE WHEN IS NULL THEN 0 ELSE 1 | Tier 2 |
| FTDYearMonth | BI_DB_CIDFirstDates | FirstDepositDate | CAST(CONVERT(VARCHAR(6), FirstDepositDate, 112) AS INT) | Tier 2 |
| ClientName | DWH_dbo.Dim_Customer | FirstName, LastName | FirstName + ' ' + LastName | Tier 2 |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough | Tier 2 |
| FundingRelation | SP computed | Fact_BillingDeposit.FundingID | 1 if CID shares a FundingID (!=1) with another CID under the same affiliate, 0 otherwise | Tier 2 |
| PersonalDetailsRelation | SP computed | Dim_Customer.FirstName+LastName+BirthDate | 1 if CID shares name+DOB with another CID under the same affiliate, 0 otherwise | Tier 2 |
| UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| RegisteredID | BI_DB_CIDFirstDates | registered | CAST(CONVERT(VARCHAR(6), registered, 112) AS INT) — YYYYMM | Tier 2 |

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| BI_DB_dbo.BI_DB_CIDFirstDates | Primary source — customer registration, FTD, affiliate | BI_DB_dbo |
| DWH_dbo.Dim_Affiliate | Active affiliate filter (AccountActivated=1) | DWH_dbo |
| DWH_dbo.Dim_Customer | Customer name, DOB, verification, validity | DWH_dbo |
| DWH_dbo.Fact_BillingDeposit | Deposit FundingIDs for relation detection | DWH_dbo |
