# Lineage: BI_DB_dbo.BI_DB_AffiliateCOAbuse

**Writer SP**: `SP_AffiliateCOAbuse` (No author; monthly-only guard: `IF DATEPART(DAY,@FirstDayofCurrentMonth)=1`)
**Pattern**: DELETE WHERE FirstPosOpenDate in prior-month range + INSERT
**UC Target**: `_Not_Migrated`

## ETL Chain

```
SP exits silently if @FirstDayofCurrentMonth is not the 1st of the month.

@Date = @FirstDayofCurrentMonth - 1 day (= last day of prior month)
@ReportDate = first day of prior month
@DateID = EOMONTH(@Date) as YYYYMMDD int

DWH_dbo.V_Liabilities (DateID = @DateID)
  → #Liabilities (CID, RealizedEquity — equity at end of prior month)

DWH_dbo.Dim_Customer
  JOIN BI_DB_dbo.BI_DB_CIDFirstDates (FirstPosOpenDate in [@ReportDate, EOMONTH(@Date)])
  LEFT JOIN BI_DB_dbo.BI_DB_FirstTimeRev10 (joined but NO columns used in output — vestigial)
  LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData (TotalPositionCount, TotalDeposit)
  LEFT JOIN #Liabilities (RealizedEquity)
  Computes: AffWizID = OriginalCID + 17
  → #ThisMonthOpenPos (customers whose first position opened in prior month)

BI_DB_dbo.External_fiktivo_AffiliateCommission_CreditCommission
  LEFT JOIN BI_DB_dbo.External_fiktivo_AffiliateCommission_Credit (CreditTypeID=1 = CPA)
  JOIN BI_DB_dbo.External_fiktivo_dbo_tblaff_Affiliates (MarketingExpenseID NOT IN (3,4,5,6,9))
  WHERE OriginalCID != 17 (exclude sentinel zero-offset record)
  Computes: OriginalCID = Credit.OriginalCID - 17 (reverse AffWizID mapping)
  GROUP BY AffiliateID + OriginalCID
  → #AllFTDs (AffID, AffWizID, AffWiz_CountryID, OriginalCID, FTD_Date=MIN(TrackingDate), AW_CPA=SUM(Commission))

#ThisMonthOpenPos
  JOIN #AllFTDs ON (a.AffWizID = b.AffWizID AND a.AffiliateID = b.AffID)
  JOIN DWH_dbo.Dim_Country dcDB ON DB_CountryID → DB_CountryName
  JOIN DWH_dbo.Dim_Country dcAW ON AffWiz_CountryID → AffWiz_CountryName
  JOIN DWH_dbo.Dim_Affiliate ON AffiliateID → Contact, AffiliatesGroupsName
  ReportDateID = CONVERT(VARCHAR(8), CAST(FirstPosOpenDate AS date), 112)

DELETE FROM BI_DB_AffiliateCOAbuse WHERE FirstPosOpenDate in [@ReportDate, EOMONTH(@Date)]
INSERT INTO BI_DB_AffiliateCOAbuse (full joined result)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | Direct | T1 — Customer.CustomerStatic |
| 2 | Contact | DWH_dbo.Dim_Affiliate | Contact | Direct — affiliate contact name/entity | T1 — Dim_Affiliate |
| 3 | AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | Direct — affiliate group/program name | T1 — Dim_Affiliate |
| 4 | AffID | #AllFTDs | AffiliateID | From fiktivo AffiliateCommission_CreditCommission.AffiliateID (same as eToro AffiliateID) | T2 — SP_AffiliateCOAbuse |
| 5 | CID | DWH_dbo.Dim_Customer | RealCID | Direct — eToro internal customer ID | T1 — Customer.CustomerStatic |
| 6 | OriginalCID | DWH_dbo.Dim_Customer | OriginalCID | Direct — customer's original registration CID | T2 — Dim_Customer |
| 7 | AffWizID | SP | OriginalCID | OriginalCID + 17 — hardcoded namespace offset: eToro OriginalCID → AffiliateWiz CID space | T2 — SP_AffiliateCOAbuse |
| 8 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Direct — datetime of real account registration | T1 — Customer.CustomerStatic |
| 9 | FirstPosOpenDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstPosOpenDate | Direct — datetime of first position open; monthly filter applied to this date | T2 — SP_CIDFirstDates |
| 10 | FirstDepositDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | Direct — datetime of first deposit in eToro | T2 — SP_CIDFirstDates |
| 11 | FTD_Date | #AllFTDs | TrackingDate | MIN(CAST(TrackingDate AS date)) per AffID+AffWizID — earliest CPA trigger date in AffiliateWiz | T2 — SP_AffiliateCOAbuse |
| 12 | FirstDepositAmount | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositAmount | Direct — USD amount of first deposit | T2 — SP_CIDFirstDates |
| 13 | TotalPositionCount | BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData | TotalPositionCount | Direct — lifetime total positions opened | T2 — External source |
| 14 | TotalDeposit | BI_DB_dbo.External_etoro_BackOffice_CustomerAllTimeAggregatedData | TotalDeposit | Direct — lifetime total deposit amount | T2 — External source |
| 15 | RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Direct — realized equity at EOMONTH(@Date) snapshot | T2 — V_Liabilities |
| 16 | Channel | BI_DB_dbo.BI_DB_CIDFirstDates | Channel | Direct — acquisition channel from CIDFirstDates | T2 — SP_CIDFirstDates |
| 17 | AW_CPA | #AllFTDs | Commission | SUM(Commission) per AffID+AffWizID — total CPA commission in AffiliateWiz | T2 — SP_AffiliateCOAbuse |
| 18 | DB_CountryID | DWH_dbo.Dim_Customer | CountryID | Direct — customer's country ID in eToro DB | T1 — Customer.CustomerStatic |
| 19 | DB_CountryName | DWH_dbo.Dim_Country | Name | Dim_Country.Name via Dim_Customer.CountryID | T2 — Dim_Country |
| 20 | AffWiz_CountryID | #AllFTDs | AffWiz_CountryID | From External_fiktivo_AffiliateCommission_Credit.CountryID | T2 — SP_AffiliateCOAbuse |
| 21 | AffWiz_CountryName | DWH_dbo.Dim_Country | Name | Dim_Country.Name via #AllFTDs.AffWiz_CountryID | T2 — Dim_Country |
| 22 | ReportDateID | SP | FirstPosOpenDate | CONVERT(VARCHAR(8), CAST(FirstPosOpenDate AS date), 112) — YYYYMMDD string | T2 — SP_AffiliateCOAbuse |
| 23 | UpdateDate | SP | GETDATE() | ETL insertion timestamp | Propagation |

## Tier Summary

- **Tier 1**: 6 (AffiliateID, Contact, AffiliatesGroupsName, CID, RegisteredReal, DB_CountryID)
- **Tier 2**: 16 (OriginalCID, AffWizID, AffID, FirstPosOpenDate, FirstDepositDate, FTD_Date, FirstDepositAmount, TotalPositionCount, TotalDeposit, RealizedEquity, Channel, AW_CPA, DB_CountryName, AffWiz_CountryID, AffWiz_CountryName, ReportDateID)
- **Propagation**: 1 (UpdateDate)
