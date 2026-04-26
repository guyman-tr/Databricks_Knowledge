# Lineage: BI_DB_dbo.BI_DB_Affiliates_FraudMonitoring

**Writer SP**: `SP_M_Affiliates_FraudMonitoring` (Author: Michail Vryoni, 2024-03-04; updated 2025-10-08)
**Pattern**: DELETE WHERE RegisteredID=@StartDateID + INSERT (monthly append — replaces that month's cohort)
**UC Target**: `_Not_Migrated`

## ETL Chain

```
BI_DB_dbo.BI_DB_CIDFirstDates (registered in [@StartDate, @EndDate))
  JOIN DWH_dbo.Dim_Affiliate (AccountActivated=1)
    → #newregs (customers who registered in the target month under active affiliates)

#newregs → GROUP BY AffiliateID
    → #conversion (FTD rate = SUM(IsFTD)*100/COUNT(CID) per affiliate)

#newregs WHERE IsFTD=1 → GROUP BY AffiliateID, Country
    → #AFTDA (AVG(FirstDepositAmount) per affiliate × country)

DWH_dbo.Dim_Customer (IP, CountryIDByIP)
  JOIN DWH_dbo.Dim_Country (Name for IP country)
  JOIN #newregs
    → #IPs (CID → IP → IPCountry mapping)
    → #groupIPS (IPs with >1 customer, count per IP per affiliate)
    → #groupIPS1 (%SameIP per affiliate)
    → #groupCountryIPS → #groupIPCountryUnique (%SameCountry per affiliate)

#newregs GROUP BY AffiliateID
    → #clientsunderAff (total customers per affiliate)

DWH_dbo.Fact_BillingDeposit (PaymentStatusID=2 / Approved)
  JOIN #newregs
    → #deposits (deposit dates per CID)
    → #depositsperaff (#OfDepositors per affiliate)

DWH_dbo.V_Liabilities (Liabilities + ActualNWA)
  JOIN #newregs, JOIN #deposits
  WHERE equity=0 AND within 10 days of first deposit
    → #equity → #equityunique → #GroupEquity (#OfClientsChurn, %Churn per affiliate)

BI_DB_dbo.External_etoro_BackOffice_CustomerRisk (RiskStatusID IN (82,83))
  JOIN #newregs (on GCID)
    → #lowtrading → #lowtradingGroup (#OfClientsLowTrading, %LowTrading per affiliate)

All above assembled into → #details (per customer with all affiliate-level metrics)

#details + 6 alert CASE expressions → #alerts
#alerts WHERE ConversionAlert+FTDAAlert+SameIPAlert+SameCountryIPAlert+LowTradingAlert>=3
    → #SELECTION (affiliates triggering ≥3 of 5 primary alerts)

#alerts WHERE AffiliateID IN #SELECTION → #final

DELETE WHERE RegisteredID=@StartDateID → INSERT BI_DB_Affiliates_FraudMonitoring
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | AffiliateID | BI_DB_CIDFirstDates | SerialID | Direct (SerialID = Dim_Customer.AffiliateID) | T1 — Customer.CustomerStatic |
| 2 | CID | BI_DB_CIDFirstDates | CID | Direct | T1 — Customer.CustomerStatic |
| 3 | GCID | BI_DB_CIDFirstDates | GCID | Direct | T1 — Customer.CustomerStatic |
| 4 | registered | BI_DB_CIDFirstDates | registered | Direct (MIN of RegisteredDemo, RegisteredReal) | T2 — SP_CIDFirstDates |
| 5 | RegisteredID | SP | registered | CAST(CONVERT(VARCHAR(6), registered, 112) AS INT) — YYYYMM integer | T2 — SP_M_Affiliates_FraudMonitoring |
| 6 | Country | BI_DB_CIDFirstDates | Country | Direct (customer country from Dim_Country) | T2 — SP_CIDFirstDates |
| 7 | FirstDepositAmount | BI_DB_CIDFirstDates | FirstDepositAmount | Direct (from Dim_Customer.FirstDepositAmount) | T2 — SP_Dim_Customer |
| 8 | IsFTD | BI_DB_CIDFirstDates | FirstDepositDate | CASE: YEAR(FirstDepositDate)=1900 → 0 else 1 | T2 — SP_M_Affiliates_FraudMonitoring |
| 9 | AvgFTDA | BI_DB_CIDFirstDates | FirstDepositAmount | AVG(FirstDepositAmount) for IsFTD=1 per affiliate × country | T2 — SP_M_Affiliates_FraudMonitoring |
| 10 | Conversion | #newregs | IsFTD, CID | ROUND(SUM(IsFTD)*100.00/COUNT(DISTINCT CID),4) per affiliate — FTD rate % | T2 — SP_M_Affiliates_FraudMonitoring |
| 11 | IPCountry | Dim_Country | Name | Dim_Country.Name via Dim_Customer.CountryIDByIP (IP geolocation country) | T2 — SP_M_Affiliates_FraudMonitoring |
| 12 | #Aff_RegisteredClients | #newregs | CID | COUNT(DISTINCT CID) per affiliate in the target month | T2 — SP_M_Affiliates_FraudMonitoring |
| 13 | NoOFClientsUnderSameIP | #IPs | CID, IP | COUNT(CID) per shared IP per affiliate (only IPs with >1 customer) | T2 — SP_M_Affiliates_FraudMonitoring |
| 14 | %SameIP | #groupIPS, #clientsunderAff | NoOFClientsUnderSameIP | ROUND(SUM(NoOFClientsUnderSameIP)*100.00 / #ofClients, 2) per affiliate | T2 — SP_M_Affiliates_FraudMonitoring |
| 15 | NoOFClientsUnderSameCountryIP | #IPs | CID | COUNT(DISTINCT CID) sharing the same IP-country per affiliate | T2 — SP_M_Affiliates_FraudMonitoring |
| 16 | %SameCountry | #groupCountryIPS | NoOFClientsUnderSameCountryIP | ROUND(count/total*100,2) per affiliate × IP country | T2 — SP_M_Affiliates_FraudMonitoring |
| 17 | CIDChurn<10days | #equityunique | CID | 1 if customer's total equity hit 0 within 10 days of first deposit; 0 otherwise | T2 — SP_M_Affiliates_FraudMonitoring |
| 18 | #OfClientsChurn | #GroupEquity | CID | COUNT(DISTINCT CID) who churned (zero equity within 10 days) per affiliate | T2 — SP_M_Affiliates_FraudMonitoring |
| 19 | #OfDepositors | #depositsperaff | CID | COUNT(DISTINCT CID) with at least one approved Fact_BillingDeposit in target month | T2 — SP_M_Affiliates_FraudMonitoring |
| 20 | %Churn | #GroupEquity | #OfClientsChurn, #OfDepositors | ROUND(churned/depositors*100, 2) per affiliate | T2 — SP_M_Affiliates_FraudMonitoring |
| 21 | CIDLowTrading | External_etoro_BackOffice_CustomerRisk | RiskStatusID | 1 if RiskStatusID IN (82=WithdrawWithShortTermTrades, 83=WithdrawWithLowTradingRatio) | T2 — SP_M_Affiliates_FraudMonitoring |
| 22 | #OfClientsLowTrading | #lowtradingGroup | CID | COUNT(DISTINCT CID) with low-trading risk flag per affiliate | T2 — SP_M_Affiliates_FraudMonitoring |
| 23 | %LowTrading | #lowtradingGroup | #OfClientsLowTrading, #OfDepositors | ROUND(low-trading/depositors*100, 2) per affiliate | T2 — SP_M_Affiliates_FraudMonitoring |
| 24 | ConversionAlert | #details | Conversion | CASE: Conversion > 70 → 1 else 0 | T2 — SP_M_Affiliates_FraudMonitoring |
| 25 | FTDAAlert | #details | AvgFTDA | CASE: AvgFTDA < 50 → 1 else 0 | T2 — SP_M_Affiliates_FraudMonitoring |
| 26 | SameIPAlert | #details | %SameIP, NoOFClientsUnderSameIP | CASE: %SameIP>0 AND NoOFClientsUnderSameIP>1 → 1 else 0 | T2 — SP_M_Affiliates_FraudMonitoring |
| 27 | SameCountryIPAlert | #details | %SameCountry | CASE: %SameCountry > 30 → 1 else 0 | T2 — SP_M_Affiliates_FraudMonitoring |
| 28 | LowTradingAlert | #details | %LowTrading | CASE: %LowTrading > 20 → 1 else 0 | T2 — SP_M_Affiliates_FraudMonitoring |
| 29 | ChurnAlert | #details | %Churn | CASE: %Churn > 20 → 1 else 0 | T2 — SP_M_Affiliates_FraudMonitoring |
| 30 | FTDYearMonth | BI_DB_CIDFirstDates | FirstDepositDate | CASE: YEAR=1900 → NULL else CAST(CONVERT(VARCHAR(6),...,112) AS INT) — YYYYMM | T2 — SP_M_Affiliates_FraudMonitoring |
| 31 | UpdateDate | SP | GETDATE() | ETL timestamp | Propagation |

## Tier Summary

- **Tier 1**: 3 (AffiliateID, CID, GCID)
- **Tier 2**: 27 (registered, RegisteredID, Country, FirstDepositAmount, IsFTD, AvgFTDA, Conversion, IPCountry, #Aff_RegisteredClients, NoOFClientsUnderSameIP, %SameIP, NoOFClientsUnderSameCountryIP, %SameCountry, CIDChurn<10days, #OfClientsChurn, #OfDepositors, %Churn, CIDLowTrading, #OfClientsLowTrading, %LowTrading, ConversionAlert, FTDAAlert, SameIPAlert, SameCountryIPAlert, LowTradingAlert, ChurnAlert, FTDYearMonth)
- **Propagation**: 1 (UpdateDate)
