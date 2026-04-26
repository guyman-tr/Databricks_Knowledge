# Lineage: BI_DB_dbo.BI_DB_AffiliatePayment

**Writer SP**: `SP_AffiliatePaymentsReport` (No author; monthly-only guard: `IF DATEPART(DAY,@ReportDate)=1`)
**Pattern**: DELETE WHERE MonthPeriod=@MonthPeriod + INSERT
**UC Target**: `_Not_Migrated`

## ETL Chain

```
SP exits silently if @ReportDate is not the 1st of the month.

@MonthPeriod = YEAR(DATEADD(dd,-1,@ReportDate))*100 + MONTH(DATEADD(dd,-1,@ReportDate))
@CalcFrom = '2013-01-01' (hardcoded — unpaid commission accumulates from this date)
@month, @month2, @month3, @month4 = current + prior 3 months (for 3M columns — now unused)

External_fiktivo_dbo_tblaff_Affiliates (AccountActivated=1, MarketingExpenseID NOT IN (3,4,5,6,9))
  LEFT JOIN External_fiktivo_dbo_tblaff_PaymentDetails (pd1, pd2, pd3 — 3 payment slot priority)
  → #AffiliatesOrgData (AffiliateID, UserName1/2/3/4, PaymentMethodID, LoginName, CompanyName, Email, CountryID, AffiliateTypeID)

#AffiliatesOrgData
  LEFT JOIN DWH_dbo.Dim_Customer cc1 ON UserName1 (collate match)
  LEFT JOIN DWH_dbo.Dim_Customer cc2 ON UserName2
  LEFT JOIN DWH_dbo.Dim_Customer cc3 ON UserName3
  LEFT JOIN DWH_dbo.Dim_Customer cc4 ON LoginName
  COALESCE(cc1.RealCID, cc2.RealCID, cc3.RealCID, cc4.RealCID) = TradingAccount_RealCID
  → #AffiliatesOrgData2

#AffiliatesOrgData2
  LEFT JOIN DWH_dbo.Dim_Customer (RealCID=TradingAccount_RealCID AND AffiliateID matches → SelfTrading)
  LEFT JOIN External_fiktivo_fiktivo_Dictionary_PaymentMethods (PaymentMethodID → PaymentMethod name)
  → #AffiliatesData

External_fiktivo_dbo_tblaff_PaymentHistory (Approved=1)
  MAX(ApprovalDate) per affiliate → #LastDates (LastPaymentProcess)

Commission UNION ALL (all Paid=0, Commission != 0.00, from @CalcFrom to @ReportDate):
  Ext_Affiliate_Payments_Report_Closed_Position
    JOIN Dim_Affiliate (AccountActivated=1)
    JOIN Dim_Channel (channel NOT IN ('Direct','SEO','SEM','Friend Referral'))
    → CommissionType='Sales' (RevShare)

  UNION External_fiktivo_AffiliateCommission_CreditCommission
    JOIN External_fiktivo_AffiliateCommission_Credit (CreditTypeID IN (4,5))
    JOIN Dim_Affiliate, JOIN Dim_Channel
    GROUP BY AffiliateID, Tier, month → CommissionType='Chargebacks'

  UNION External_fiktivo_AffiliateCommission_CreditCommission
    JOIN External_fiktivo_AffiliateCommission_Credit (CreditTypeID=1, Valid!=0)
    JOIN Dim_Affiliate, JOIN Dim_Channel
    GROUP BY → CommissionType='CPA'

  UNION External_fiktivo_dbo_tblaff_Leads_Commissions
    JOIN External_fiktivo_dbo_tblaff_Leads
    JOIN Dim_Affiliate, JOIN Dim_Channel
    GROUP BY → CommissionType='Leads'

  UNION External_fiktivo_AffiliateCommission_RegistrationCommission
    JOIN External_fiktivo_AffiliateCommission_Registration
    JOIN Dim_Affiliate, JOIN Dim_Channel
    GROUP BY → CommissionType='Regs'

  UNION External_fiktivo_dbo_tblaff_eCost_Commissions
    JOIN External_fiktivo_dbo_tblaff_eCost
    JOIN Dim_Affiliate, JOIN Dim_Channel
    GROUP BY → CommissionType='eCost'

  → #CommissionCurrentMonth (AffiliateID, Tier, Commission, CommissionType, month)

#CommissionCurrentMonth GROUP BY AffiliateID (HAVING SUM(Commission) > 0)
  → #PaymentFromCurrentMonth (per affiliate: PaymentCurrentMonth, Sales, Bonuses=0, Chargebacks, CPA, Leads, Regs, eCost, Tier2, Tier3)

#PaymentFromCurrentMonth
  LEFT JOIN #AffiliatesData (affiliate metadata)
  LEFT JOIN DWH_dbo.Dim_Country (affiliate country)
  LEFT JOIN External_fiktivo_dbo_tblaff_AffiliateTypes (ContractType, MinCommToCPA)
  JOIN DWH_dbo.Dim_Affiliate (DateCreated, AffiliatesGroupsName, AccountActivated=1)
  JOIN DWH_dbo.Dim_Channel (Channel, SubChannel — excludes Direct/SEO/SEM/Friend Referral)
  LEFT JOIN #LastDates (LastPaymentProcess)
  16 NULL literal columns (Registrations through ActiveUserOutOfFTDs3M — #InfoData commented out)
  → #ThisMonthData

DELETE FROM BI_DB_AffiliatePayment WHERE MonthPeriod = @MonthPeriod
INSERT INTO BI_DB_AffiliatePayment (SELECT * FROM #ThisMonthData, getUTCdate() AS UpdateDate)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | YEAR | SP param | @ReportDate | YEAR(DATEADD(dd,-1,@ReportDate)) | T2 — SP param |
| 2 | MONTH | SP param | @ReportDate | MONTH(DATEADD(dd,-1,@ReportDate)) | T2 — SP param |
| 3 | MonthPeriod | SP param | @ReportDate | YEAR(...)*100+MONTH(...) — YYYYMM int | T2 — SP param |
| 4 | AffiliateID | External_fiktivo_dbo_tblaff_Affiliates | AffiliateID | Direct | T1 — fiktivo affiliate |
| 5 | TradingAccount_RealCID | DWH_dbo.Dim_Customer | RealCID | COALESCE(cc1.RealCID, cc2.RealCID, cc3.RealCID, cc4.RealCID) across 4 username variants | T2 — SP_AffiliatePaymentsReport |
| 6 | TradingAccount_UserName | DWH_dbo.Dim_Customer | UserName | COALESCE across 4 username variants | T2 — SP_AffiliatePaymentsReport |
| 7 | SelfTrading | DWH_dbo.Dim_Customer | RealCID, AffiliateID | CASE: WHEN TradingAccount_RealCID found in Dim_Customer WITH same AffiliateID → 1 ELSE 0 | T2 — SP_AffiliatePaymentsReport |
| 8 | DateCreated | DWH_dbo.Dim_Affiliate | DateCreated | Direct | T1 — Dim_Affiliate |
| 9 | AW_UserName | External_fiktivo_dbo_tblaff_Affiliates | LoginName | Direct | T2 — External_fiktivo |
| 10 | CompanyName | External_fiktivo_dbo_tblaff_Affiliates | CompanyName | Direct | T2 — External_fiktivo |
| 11 | Country | DWH_dbo.Dim_Country | Name | Dim_Country.Name via tblaff_Affiliates.CountryID | T2 — Dim_Country |
| 12 | AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | Direct | T1 — Dim_Affiliate |
| 13 | Channel | DWH_dbo.Dim_Channel | Channel | Direct | T1 — Dim_Channel |
| 14 | SubChannel | DWH_dbo.Dim_Channel | SubChannel | Direct | T1 — Dim_Channel |
| 15 | PaymentUrl | SP | AffiliateID, @CalcFrom, @ReportDate | Hardcoded template: 'http://affiliatewiz-globaltrad.msappproxy.net/Tools_Adjust.aspx?AffiliateID='+AffiliateID+'&StartDate=2013-01-01&EndDate='+(ReportDate-1) | T2 — SP_AffiliatePaymentsReport |
| 16 | LastPaymentProcess | External_fiktivo_dbo_tblaff_PaymentHistory | ApprovalDate | MAX(ApprovalDate WHERE Approved=1) per affiliate | T2 — SP_AffiliatePaymentsReport |
| 17 | CurrentPayment | #PaymentFromCurrentMonth | Commission | ISNULL(SUM(all unpaid Commission),0) per affiliate | T2 — SP_AffiliatePaymentsReport |
| 18 | RevShare_Comm | Ext_Affiliate_Payments_Report_Closed_Position | Commission | SUM WHERE CommissionType='Sales' | T2 — External source |
| 19 | Bonuses | #CommissionCurrentMonth | Commission | SUM WHERE CommissionType='Bonuses' — always 0; Bonuses UNION branch commented out | Propagation — dead column |
| 20 | Chargebacks | External_fiktivo_AffiliateCommission_CreditCommission | Commission | SUM WHERE CreditTypeID IN (4,5) — chargeback commission (typically negative) | T2 — External_fiktivo |
| 21 | CPA_Comm | External_fiktivo_AffiliateCommission_CreditCommission | Commission | SUM WHERE CreditTypeID=1 AND Valid!=0 AND Paid=0 | T2 — External_fiktivo |
| 22 | CPL_Comm | External_fiktivo_dbo_tblaff_Leads_Commissions | Commission | SUM WHERE CommissionType='Leads' | T2 — External_fiktivo |
| 23 | CPR_Comm | External_fiktivo_AffiliateCommission_RegistrationCommission | Commission | SUM WHERE CommissionType='Regs' | T2 — External_fiktivo |
| 24 | eCost | External_fiktivo_dbo_tblaff_eCost_Commissions | Commission | SUM WHERE CommissionType='eCost' | T2 — External_fiktivo |
| 25 | Tier2Commition | #CommissionCurrentMonth | Commission, Tier | SUM(Commission WHERE Tier=2) across all commission types | T2 — SP_AffiliatePaymentsReport |
| 26 | Tier3Commition | #CommissionCurrentMonth | Commission, Tier | SUM(Commission WHERE Tier=3) across all commission types | T2 — SP_AffiliatePaymentsReport |
| 27 | ContractType | External_fiktivo_dbo_tblaff_AffiliateTypes | Description | Direct via AffiliateTypeID | T2 — External_fiktivo |
| 28 | MinCommToCPA | External_fiktivo_dbo_tblaff_AffiliateTypes | MinimumCommission | Direct via AffiliateTypeID | T2 — External_fiktivo |
| 29 | PaymentMethod | External_fiktivo_fiktivo_Dictionary_PaymentMethods | Name | Direct via PaymentMethodID | T2 — External_fiktivo |
| 30 | Registrations | SP | — | NULL literal — #InfoData section commented out | Propagation — NULL hardcoded |
| 31 | Registrations3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 32 | FTDs | SP | — | NULL literal | Propagation — NULL hardcoded |
| 33 | FTDs3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 34 | FTDAmount | SP | — | NULL literal | Propagation — NULL hardcoded |
| 35 | FTDAmount3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 36 | Reaching10Dollars | SP | — | NULL literal | Propagation — NULL hardcoded |
| 37 | Reaching10Dollars3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 38 | Reaching10DollarsOutOfFTDs | SP | — | NULL literal | Propagation — NULL hardcoded |
| 39 | Reaching10DollarsOutOfFTDs3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 40 | VerificationLevel2OutOfFTDs | SP | — | NULL literal | Propagation — NULL hardcoded |
| 41 | VerificationLevel2OutOfFTDs3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 42 | VerificationLevel3OutOfFTDs | SP | — | NULL literal | Propagation — NULL hardcoded |
| 43 | VerificationLevel3OutOfFTDs3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 44 | ActiveTradersOutOfFTDs | SP | — | NULL literal | Propagation — NULL hardcoded |
| 45 | ActiveTradersOutOfFTDs3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 46 | ActiveUserOutOfFTDs | SP | — | NULL literal | Propagation — NULL hardcoded |
| 47 | ActiveUserOutOfFTDs3M | SP | — | NULL literal | Propagation — NULL hardcoded |
| 48 | ReportDate | SP param | @ReportDate | Direct (= first day of current month = run date) | T2 — SP param |
| 49 | UpdateDate | SP | getUTCdate() | UTC timestamp at INSERT — note: UTC, not local time | Propagation |

## Tier Summary

- **Tier 1**: 5 (AffiliateID, DateCreated, AffiliatesGroupsName, Channel, SubChannel)
- **Tier 2**: 25 (YEAR, MONTH, MonthPeriod, TradingAccount_RealCID, TradingAccount_UserName, SelfTrading, AW_UserName, CompanyName, Country, PaymentUrl, LastPaymentProcess, CurrentPayment, RevShare_Comm, Chargebacks, CPA_Comm, CPL_Comm, CPR_Comm, eCost, Tier2Commition, Tier3Commition, ContractType, MinCommToCPA, PaymentMethod, ReportDate)
- **Propagation**: 19 (Bonuses as dead column + 16 NULL-hardcoded funnel columns + UpdateDate)
