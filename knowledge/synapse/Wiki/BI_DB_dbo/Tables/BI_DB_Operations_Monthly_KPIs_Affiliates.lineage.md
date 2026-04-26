# Lineage: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates

## Source Chain

| Level | Object | Type | Role |
|-------|--------|------|------|
| L0 | DWH_dbo.Fact_BillingWithdraw | DWH Fact | Affiliate/PI withdrawal events (CashoutReasonID IN 14,15) |
| L0 | DWH_dbo.Dim_Customer | DWH Dimension | CID, RegulationID, CountryID, VerificationLevelID, LabelID, PlayerLevelID |
| L0 | DWH_dbo.Dim_Country | DWH Dimension | Region, CountryName |
| L0 | DWH_dbo.Dim_Regulation | DWH Dimension | Regulation short code |
| L1 | BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates | **THIS TABLE** | 6-month rolling affiliate SLA dataset |

## ETL Pipeline

```
DWH_dbo.Fact_BillingWithdraw (affiliate/PI withdrawals, CashoutReasonID IN 14,15)
DWH_dbo.Dim_Customer (CID join — RegulationID, CountryID, VerificationLevelID=3, PlayerLevelID≠4, LabelID NOT IN 26,30)
DWH_dbo.Dim_Country (CountryID join — CountryID NOT IN 250 — Region)
DWH_dbo.Dim_Regulation (RegulationID join — Regulation name)
  |-- SP_OperationsMonthlyAffiliateKPIsFullData (daily, no parameters) ---|
  |   @StartDate = DATEADD(month,-6,GETDATE()); @EndDate = GETDATE()      |
  |   TRUNCATE + INSERT (6-month rolling window)                           |
  v
BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates (7,733 rows as of 2026-04-13)
  |-- UC: Not Migrated ---|
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | WithdrawID | DWH_dbo.Fact_BillingWithdraw | WithdrawID | Direct — withdrawal request PK | Tier 1 |
| 2 | CurrencyID | DWH_dbo.Fact_BillingWithdraw | CurrencyID | Direct — FK to Dictionary.Currency | Tier 1 |
| 3 | FundingTypeID | DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Withdraw | Payment method of the withdrawal request | Tier 1 |
| 4 | CID | DWH_dbo.Fact_BillingWithdraw | CID | Direct — customer FK | Tier 1 |
| 5 | CashoutStatusID | DWH_dbo.Fact_BillingWithdraw | CashoutStatusID_Withdraw | Always 3 (Processed) per SP filter | Tier 1 |
| 6 | RequestDate | DWH_dbo.Fact_BillingWithdraw | RequestDate | Direct — withdrawal submission timestamp | Tier 1 |
| 7 | Amount | DWH_dbo.Fact_BillingWithdraw | Amount_Withdraw | Gross withdrawal amount in CurrencyID | Tier 1 |
| 8 | ModificationDate | DWH_dbo.Fact_BillingWithdraw | ModificationDate_WithdrawToFunding | NOT Billing.Withdraw.ModificationDate — maps to the payment leg processing date | Tier 2 |
| 9 | FundingID | DWH_dbo.Fact_BillingWithdraw | FundingID | FK to Billing.Funding instrument; NULL for unsaved methods | Tier 1 |
| 10 | CashoutReasonID | DWH_dbo.Fact_BillingWithdraw | CashoutReasonID | Always 14 (PI Payment) or 15 (Affiliate Payment) per SP filter | Tier 1 |
| 11 | ReqCyTime | DWH_dbo.Fact_BillingWithdraw | RequestDate | `bw.RequestDate AS ReqCyTime` — duplicate of RequestDate; exact same value | Tier 2 |
| 12 | ModCyTime | DWH_dbo.Fact_BillingWithdraw | ModificationDate_WithdrawToFunding | `bw.ModificationDate_WithdrawToFunding AS ModCyTime` — duplicate of ModificationDate | Tier 2 |
| 13 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Always 3 per SP filter VerificationLevelID=3 | Tier 2 |
| 14 | RequestDay | DWH_dbo.Fact_BillingWithdraw | RequestDate | `DATEPART(dw, RequestDate)` stored as datetime (1900-01-0N base); 1=Sunday…7=Saturday | Tier 2 |
| 15 | Month | DWH_dbo.Fact_BillingWithdraw | RequestDate | `DATEPART(month, RequestDate)` — request calendar month | Tier 2 |
| 16 | Year | DWH_dbo.Fact_BillingWithdraw | RequestDate | `DATEPART(year, RequestDate)` — request calendar year | Tier 2 |
| 17 | Region | DWH_dbo.Dim_Country | Region | Geographic market region; passthrough from Dim_Country | Tier 2 |
| 18 | Regulation | DWH_dbo.Dim_Regulation | Name | Regulation short code (CySEC/FCA/BVI/etc.); passthrough string | Tier 1 |
| 19 | ProcessMonth | DWH_dbo.Fact_BillingWithdraw | ProcessorValueDate | `DATEPART(month, ProcessorValueDate)` — processor completion calendar month | Tier 2 |
| 20 | ProcessYear | DWH_dbo.Fact_BillingWithdraw | ProcessorValueDate | `DATEPART(year, ProcessorValueDate)` — processor completion year | Tier 2 |
| 21 | ProcessDay | DWH_dbo.Fact_BillingWithdraw | ProcessorValueDate | `DATEPART(dw, ProcessorValueDate)` stored as int — day of week 1=Sunday…7=Saturday | Tier 2 |
| 22 | HoursBetween | DWH_dbo.Fact_BillingWithdraw | RequestDate, ProcessorValueDate | `DATEDIFF(hour, RequestDate, ProcessorValueDate)` — end-to-end processing hours | Tier 2 |
| 23 | SLA | DWH_dbo.Fact_BillingWithdraw | RequestDate, ProcessorValueDate, FundingTypeID, CurrencyID, Regulation | Complex CASE: 1=within SLA threshold, 0=breach. Thresholds vary by method/currency/day-of-week (post-2021 block) | Tier 2 |
| 24 | SLA48 | DWH_dbo.Fact_BillingWithdraw | RequestDate, ProcessorValueDate, FundingTypeID, CurrencyID, Regulation | Complex CASE: 48-hour variant thresholds; same input signals as SLA | Tier 2 |
| 25 | SLA5days | DWH_dbo.Fact_BillingWithdraw | RequestDate, ProcessorValueDate, FundingTypeID, CurrencyID, Regulation | Complex CASE: 5-business-day threshold variant; most permissive — always 1 in current data | Tier 2 |
| 26 | WD_ID_SLA | SP-computed | SLA per leg | MIN across all payment legs: 'OverallSLA' (99.97%) or 'OverallNotSLA' (0.03%) | Tier 2 |
| 27 | WD_ID_SLA48 | SP-computed | SLA48 per leg | MIN across all payment legs: 'OverallSLA48' or 'OverallNotSLA48' | Tier 2 |
| 28 | WD_ID_SLA5days | SP-computed | SLA5days per leg | MIN across all payment legs: 'OverallSLA5days' (always 1 in current data) | Tier 2 |
| 29 | UpdateDate | SP-computed | GETDATE() | ETL run timestamp; single value per load (2026-04-13 04:13:56) | Tier 2 |

## UC External Lineage

UC Target: Not Migrated
