# Lineage: BI_DB_dbo.BI_DB_HighCOsAndRedeemsWithSF

**Generated**: 2026-04-22 | **Writer SP**: `BI_DB_dbo.SP_HighCOsAndRedeemsWithSF` | **Schema**: BI_DB_dbo

## ETL Chain

```
DWH_dbo.Fact_BillingWithdraw (CashoutStatusID_Withdraw=1, SUM≥200K per CID/day)
BI_DB_dbo.External_etoro_Billing_Redeem (RedeemStatusID=1)
  + DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted (BidLast price, DateTo=@day-1)
  → SUM(Units × BidLast) > 50K per CID/day
BI_DB_dbo.BI_DB_UsageTracking_SF (ActionName='Phone_Call_Succeed__c', last 12 months)
DWH_dbo.Dim_Customer (BirthDate for age check, AccountManagerID)
DWH_dbo.Dim_Manager (FirstName, LastName for Account Manager name)
  |-- SP_HighCOsAndRedeemsWithSF (TRUNCATE + INSERT, @day = GETDATE()-1) ---|
  v
BI_DB_dbo.BI_DB_HighCOsAndRedeemsWithSF
  (UC Target: Not Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Fact_BillingWithdraw / External_etoro_Billing_Redeem | CID | Passthrough (group key) | Tier 1 |
| 2 | RequestDate | Fact_BillingWithdraw / External_etoro_Billing_Redeem | RequestDate | CAST to DATE; group key | Tier 2 |
| 3 | Amount | Fact_BillingWithdraw / Computed | Amount_Withdraw / SUM(Units × BidLast) | SUM aggregation; threshold filter (≥200K for cashouts, >50K for redeems) | Tier 2 |
| 4 | Type | Literal | — | 'Cashout' or 'Redeem' | Tier 2 |
| 5 | WasContactedLast12Months | BI_DB_UsageTracking_SF | CID | CASE WHEN SF.CID IS NOT NULL THEN 'yes' ELSE 'no'; most recent Phone_Call_Succeed__c in past 12 months | Tier 2 |
| 6 | Account Manager | Dim_Manager + Dim_Customer | FirstName + LastName | SF contact manager preferred; fallback to Dim_Customer.AccountManagerID → Dim_Manager | Tier 2 |
| 7 | UpdateDate | ETL | — | GETDATE() at INSERT time | ETL_METADATA |

## Source Objects

| Object | Type | Role |
|--------|------|------|
| DWH_dbo.Fact_BillingWithdraw | Table | Cashout requests — large pending withdrawals (≥$200K daily) |
| BI_DB_dbo.External_etoro_Billing_Redeem | External Table | Redeem requests (crypto/position redemptions) |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Table | End-of-day BidLast prices for redeem valuation |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Table | Salesforce CRM contact history (Phone_Call_Succeed__c events) |
| DWH_dbo.Dim_Customer | Table | Customer birth date (age check) + assigned AccountManagerID |
| DWH_dbo.Dim_Manager | Table | Manager name lookup (for Account Manager column) |

## Key Constraints (from SP)

- **Cashout threshold**: SUM(Amount_Withdraw) >= 200,000 (pending requests, CashoutStatusID_Withdraw=1)
- **Redeem threshold**: SUM(Units × BidLast) > 50,000 (pending redeems, RedeemStatusID=1)
- **Final filter**: `(age > 70 AND Amount > 50,000) OR Amount > 100,000` — elderly customers (>70) flagged at lower threshold
- **SF lookback**: Salesforce contacts limited to past 12 months, ActionName = 'Phone_Call_Succeed__c' only
- **Full reload**: TRUNCATE + INSERT; no date partitioning; snapshot always reflects @day=GETDATE()-1

## UC Target

Not Migrated
