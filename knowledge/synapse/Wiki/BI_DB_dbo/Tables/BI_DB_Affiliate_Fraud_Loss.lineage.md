# Lineage: BI_DB_dbo.BI_DB_Affiliate_Fraud_Loss

Generated: 2026-04-21 | Writer SP: SP_Affiliate_Fraud_Loss | Batch 13 #4

## ETL Chain

```
DWH_dbo.Dim_Customer (AccountTypeID IN (6,15), IsValidCustomer=1)
  [Affiliate private + corporate account holders — "affiliates as customers"]
  |-- JOIN Dim_Regulation dr  (DesignatedRegulationID → DesignatedRegulation)
  |-- JOIN Dim_Regulation dr1 (RegulationID → Regulation)
  |-- JOIN Dim_Country dc1    (CountryID → Country)
  |-- JOIN Dim_PlayerStatus   (PlayerStatusID → PlayerStatus)
  |-- LEFT JOIN Dim_RiskStatus (RiskStatusID → RiskStatus)
  → #all (all affiliate-type accounts)
  |
  |-- #blocked: filter PlayerStatus IN ('Blocked','Trade & MIMO Blocked')
  |-- #risk: External_etoro_BackOffice_CustomerRisk WHERE RiskStatusID=60, RiskEventStatusID=1
  |-- #blockedaffiliates: JOIN #blocked + #risk → 'Suspicous Affiliate' risk events
  |-- #blockedtime: filter YearMonthDay = @YearMonthDay (newly flagged on target date)
  |
  |-- #DATA: BI_DB_Client_Balance_CID_Level_New WHERE Date=@Date, CompensationToAffiliate>0
  |          [daily affiliate payments]
  |-- #DATA1: BI_DB_Client_Balance_CID_Level_New (all dates) for affiliates in #all
  |-- #LOSS: SUM(#DATA1.Payment) per blocked affiliate → TotalLoss
  |
  |-- #monthpayments: affiliates WITH payments on @Date + risk/block enrichment
  |-- #blockeinmonth: affiliates NEWLY BLOCKED on @Date WITH NO payments on @Date
  |-- #FINAL1: UNION of #monthpayments + #blockeinmonth
  |
  |-- #FUNDINGS: most recent FundingType from Fact_CustomerAction (ActionTypeID IN 7,8)
  |-- #FINAL: enrich with KYCCountry (CountryID), CountryByRegIP (CountryIDByIP), FundingType
  |
  v [SP_Affiliate_Fraud_Loss @Date — Daily, SB_Daily, Priority 20]
  v [DELETE WHERE YearMonthDay=@YearMonthDay + INSERT from #FINAL]
  v
BI_DB_dbo.BI_DB_Affiliate_Fraud_Loss (15,464 rows)
  |
  v [UC Target: _Not_Migrated]
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | ID | DDL IDENTITY | — | Auto-increment surrogate key, not inserted via SP | Tier 5 |
| 2 | RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough key — affiliate's own customer account | Tier 1 |
| 3 | YearMonth | BI_DB_Client_Balance_CID_Level_New / External_etoro_BackOffice_CustomerRisk | Date / Occurred | CONVERT(VARCHAR(6), date, 112) — payment date for #monthpayments; block event date for #blockeinmonth | Tier 2 |
| 4 | YearMonthDay | Same as YearMonth | Same | CONVERT(VARCHAR(8), date, 112) | Tier 2 |
| 5 | AffiliatePayment | BI_DB_Client_Balance_CID_Level_New | CompensationToAffiliate | SUM(CompensationToAffiliate) for @Date; ISNULL(…,0). 0 for block-only rows | Tier 2 |
| 6 | Loss | BI_DB_Client_Balance_CID_Level_New | CompensationToAffiliate | SUM of ALL-TIME CompensationToAffiliate for blocked affiliates; 0 for non-blocked | Tier 2 |
| 7 | DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | Passthrough via JOIN on Dim_Customer.DesignatedRegulationID | Tier 1 |
| 8 | Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via JOIN on Dim_Customer.RegulationID | Tier 1 |
| 9 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Passthrough at time of #all build | Tier 1 |
| 10 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough | Tier 1 |
| 11 | RiskStatus | DWH_dbo.Dim_RiskStatus / Hardcoded | Name / 'Suspicous Affiliate' | CASE: 'Suspicous Affiliate' if affiliate in #blocked, else Dim_RiskStatus.Name | Tier 2 |
| 12 | Country | DWH_dbo.Dim_Country | Name | Via Dim_Customer.CountryID JOIN in #all | Tier 1 |
| 13 | AffiliateStatus | Hardcoded | — | CASE: 'Blocked' if affiliate in #blockedaffiliates; 'Active' otherwise | Tier 2 |
| 14 | YearMonth-Block | External_etoro_BackOffice_CustomerRisk | Occurred | CONVERT(VARCHAR(6), MIN(Occurred), 112) from #blockedaffiliates; NULL for non-blocked | Tier 2 |
| 15 | YearMonthDay-Block | External_etoro_BackOffice_CustomerRisk | Occurred | CONVERT(VARCHAR(8), MIN(Occurred), 112) from #blockedaffiliates; NULL for non-blocked | Tier 2 |
| 16 | KYCCountry | DWH_dbo.Dim_Country | Name | Via Dim_Customer.CountryID JOIN in #FINAL — same source as Country (see review notes) | Tier 1 |
| 17 | CountryByRegIP | DWH_dbo.Dim_Country | Name | Via Dim_Customer.CountryIDByIP JOIN in #FINAL | Tier 1 |
| 18 | FundingType | DWH_dbo.Dim_FundingType | Name | Most recent FundingType from Fact_CustomerAction (ActionTypeID IN 7,8); ROW_NUMBER DESC | Tier 1 |
| 19 | UpdateDate | ETL metadata | GETDATE() | Set at INSERT time | Tier 5 |

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| Dim_Customer | DWH_dbo | Affiliate account holder master — AccountTypeID 6/15, RealCID, RegisteredReal, CountryID, CountryIDByIP, RegulationID, DesignatedRegulationID, PlayerStatusID |
| Dim_Regulation | DWH_dbo | DesignatedRegulation and Regulation name lookups |
| Dim_Country | DWH_dbo | Country, KYCCountry, CountryByRegIP name lookups |
| Dim_PlayerStatus | DWH_dbo | PlayerStatus name lookup |
| Dim_RiskStatus | DWH_dbo | RiskStatus name lookup (overridden for blocked affiliates) |
| Dim_FundingType | DWH_dbo | FundingType name lookup (most recent deposit method) |
| Fact_CustomerAction | DWH_dbo | Most recent funding action for FundingType |
| External_etoro_BackOffice_CustomerRisk | BI_DB_dbo | Risk events — RiskStatusID=60 ('Suspicious Affiliate'), RiskEventStatusID=1 |
| BI_DB_Client_Balance_CID_Level_New | BI_DB_dbo | Daily CompensationToAffiliate payments |

## UC Lineage

UC Target: `_Not_Migrated` — no Unity Catalog counterpart.
