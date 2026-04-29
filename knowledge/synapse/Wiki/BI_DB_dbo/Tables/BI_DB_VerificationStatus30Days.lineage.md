# BI_DB_dbo.BI_DB_VerificationStatus30Days — Column Lineage

## Source Objects

| Source Object | Schema | Role | Confidence |
|--------------|--------|------|------------|
| External_etoro_BackOffice_Customer | BI_DB_dbo (external) | Primary — VerificationLevelID, EvMatchStatus, DocumentStatusID, RegulationID | Tier 2 — SP code |
| Dim_Customer | DWH_dbo | Primary — RealCID, FirstDepositDate, PlayerStatus, PendingClosure, IsDepositor | Tier 1 — Customer.CustomerStatic wiki |
| Dim_Country | DWH_dbo | Lookup — Country name, marketing Region | Tier 1 — Dictionary.Country wiki |
| BI_DB_AllDeposits | BI_DB_dbo | Aggregation — TotalDeposit (SUM approved amounts) | Tier 2 — SP code |
| External_etoro_Billing_Withdraw | BI_DB_dbo (external) | Flag — DidCO (any approved cashout) | Tier 2 — SP code |
| V_Liabilities | DWH_dbo | Lookup — RealizedEquity at FTD+14 | Tier 2 — SP code |
| Fact_CustomerAction | DWH_dbo | Aggregation — deposits within 14 days (ActionTypeID=7) | Tier 2 — SP code |
| External_etoro_BackOffice_CustomerDocument | BI_DB_dbo (external) | Flag — document upload status, suggested POA/POI | Tier 2 — SP code |

## Column Lineage

| Target Column | Source Table | Source Column | Transform | Tier |
|--------------|-------------|---------------|-----------|------|
| RealCID | External_etoro_BackOffice_Customer + Dim_Customer | CID / RealCID | Passthrough (BackOffice.Customer.CID = Dim_Customer.RealCID) | Tier 1 |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | CONVERT(date) | Tier 2 |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough via CountryID | Tier 1 |
| Region | DWH_dbo.Dim_Country | Region | Dim-lookup passthrough | Tier 2 |
| CurrentVerificationLevel | External_etoro_BackOffice_Customer | VerificationLevelID | Rename (VerificationLevelID → CurrentVerificationLevel) | Tier 2 |
| PendingClosureStatusID | DWH_dbo.Dim_Customer | PendingClosureStatusID | Passthrough | Tier 1 |
| CurrentPlayerStatus | DWH_dbo.Dim_Customer | PlayerStatusID | Rename (PlayerStatusID → CurrentPlayerStatus) | Tier 1 |
| PlayerStatusReasonID | DWH_dbo.Dim_Customer | PlayerStatusReasonID | Passthrough | Tier 1 |
| RegulationID | External_etoro_BackOffice_Customer | RegulationID | Passthrough | Tier 1 |
| EvMatchStatus | External_etoro_BackOffice_Customer | EvMatchStatus | Passthrough | Tier 1 |
| EvVerified | External_etoro_BackOffice_Customer | EvMatchStatus | Computed: CASE WHEN EvMatchStatus=2 THEN 1 ELSE 0 | Tier 2 |
| NewUpload | External_etoro_BackOffice_Customer | DocumentStatusID | Computed: CASE WHEN DocumentStatusID=1 THEN 1 ELSE 0 | Tier 2 |
| TotalDeposit | BI_DB_AllDeposits | Amount in $ | SUM WHERE PaymentStatus='Approved' | Tier 2 |
| IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough | Tier 2 |
| DidCO | External_etoro_Billing_Withdraw | Approved | MAX(CASE WHEN Approved <> 0 THEN 1 ELSE 0) | Tier 2 |
| FTD_Plus_14 | — | — | Computed: DATEADD(day, 14, FirstDepositDate) | Tier 2 |
| 14_Days_RE | DWH_dbo.V_Liabilities | RealizedEquity | RealizedEquity at FTD+14 date (or yesterday if FTD+14 is future) | Tier 2 |
| 14_Days_Deposits | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7 within 14 days of FTD | Tier 2 |
| UploadDocs | External_etoro_BackOffice_CustomerDocument | — | 1 if any document exists for this CID, 0 otherwise | Tier 2 |
| SuggestedPOA | External_etoro_BackOffice_CustomerDocument | SuggestedDocumentTypeID | MAX(CASE WHEN SuggestedDocumentTypeID=1 THEN 1 ELSE 0) | Tier 2 |
| SuggestedPOI | External_etoro_BackOffice_CustomerDocument | SuggestedDocumentTypeID | MAX(CASE WHEN SuggestedDocumentTypeID=2 THEN 1 ELSE 0) | Tier 2 |
| Closed | Multiple | Multiple | Computed: 1 if VL<3 AND DidCO=1 AND PendingClosureStatusID=3 AND PlayerStatusID=13 AND PlayerStatusReasonID=1 | Tier 2 |
| Priority | Multiple | Multiple | Computed: 5-tier urgency score based on VL, 14_Days_RE, and days remaining to FTD+15 | Tier 2 |
| IsWalletUser | — | — | Deprecated: always NULL (was from BI_DEV/EXW wallet data) | Tier 2 |
| UpdateDate | — | — | ETL metadata: GETDATE() | Tier 5 |

## ETL Pipeline

```
External_etoro_BackOffice_Customer (VL, EvMatchStatus, DocumentStatusID, RegulationID)
  + DWH_dbo.Dim_Customer (RealCID, FTD, PlayerStatus, PendingClosure, IsDepositor)
  + DWH_dbo.Dim_Country (Country, Region)
  + BI_DB_AllDeposits (TotalDeposit SUM)
  |
  → #pop (population: FTD last 30 days OR registered last 15 days without FTD)
  |
  + External_etoro_Billing_Withdraw (DidCO flag)
  + DWH_dbo.V_Liabilities (14_Days_RE at FTD+14)
  + Fact_CustomerAction (14_Days_Deposits, ActionTypeID=7)
  + External_BackOffice_CustomerDocument (UploadDocs, SuggestedPOA/POI)
  |
  → Priority scoring (5=VL3, 1-4 urgency based on RE and days remaining)
  |
  |-- SP_H_VerificationStatus30Days (TRUNCATE + INSERT) ---|
  v
BI_DB_dbo.BI_DB_VerificationStatus30Days (~34K rows, rolling 30-day window)
```
