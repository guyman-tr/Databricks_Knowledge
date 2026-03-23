# Column Lineage: BI_DB_dbo.BI_DB_InterestDaily

## Column Mapping

| DWH Column | Source Table | Source Column | Transform | Notes |
|------------|-------------|---------------|-----------|-------|
| CID | Interest.Trade.InterestDaily | CID | passthrough | Via external table |
| DailyInterest | Interest.Trade.InterestDaily | DailyInterest | passthrough | |
| FundsForInterest | Interest.Trade.InterestDaily | FundsForInterest | passthrough | |
| DailyInterestPercentage | Interest.Trade.InterestDaily | DailyInterestPercentage | passthrough | |
| DayOfInterest | Interest.Trade.InterestDaily | DayOfInterest | passthrough | |
| DateID | Interest.Trade.InterestDaily | DayOfInterest | ETL-computed | CONVERT(VARCHAR, DayOfInterest, 112) → YYYYMMDD int |
| CountryID | Interest.Trade.InterestDaily | CountryID | passthrough | |
| PlayerLevelID | Interest.Trade.InterestDaily | PlayerLevelID | passthrough | |
| AccountTypeID | Interest.Trade.InterestDaily | AccountTypeID | passthrough | |
| RegulationID | Interest.Trade.InterestDaily | RegulationID | passthrough | |
| Interest | Interest.Trade.InterestDaily | Interest | passthrough | |
| MinRealMoney | Interest.Trade.InterestDaily | MinRealMoney | passthrough | |
| SumOfPendingCashoutRequests | Interest.Trade.InterestDaily | SumOfPendingCashoutRequests | passthrough | |
| Credit | Interest.Trade.InterestDaily | Credit | passthrough | |
| RealizedEquity | Interest.Trade.InterestDaily | RealizedEquity | passthrough | |
| Bonus | Interest.Trade.InterestDaily | Bonus | passthrough | |
| YearlyInterestPercentage | Interest.Trade.InterestDaily | YearlyInterestPercentage | passthrough | |
| StatusID | Interest.Trade.InterestDaily | StatusID | passthrough | |
| MonthlyTaxPercentage | Interest.Trade.InterestDaily | MonthlyTaxPercentage | passthrough | |
| UpdateDate | -- | -- | ETL-computed | GETDATE() |

## ETL Pipeline

```
Interest DB (interest-west.database.windows.net)
  → Trade.InterestDaily
    │
    └─ SP_InterestDaily(@date)
        ├─ EXEC SP_Create_External_Interest_Trade_InterestDaily @date, 'Daily_Data'
        │   (creates external table External_Interest_Trade_InterestDaily_Daily_Data
        │    pointing to Interest DB via elastic query)
        ├─ DELETE FROM BI_DB_InterestDaily WHERE DayOfInterest = @date
        └─ INSERT INTO BI_DB_InterestDaily (SELECT from external table + DateID + UpdateDate)
```

## Source Tables

| Source | Role | Columns Used |
|--------|------|-------------|
| Interest.Trade.InterestDaily | Primary — external Interest DB on interest-west.database.windows.net | All 18 business columns (passthrough) |

## Consumers

| Consumer SP | Usage |
|-------------|-------|
| SP_Monthly_InterestPayment_Dashboard | Monthly interest payment dashboard aggregation |
| SP_CMR_Automation_EU_ClientInterestReport | EU client interest regulatory report |
| SP_CMR_Automation_FSA_ClientInterestReport | FSA client interest regulatory report |
| SP_CMR_Automation_US_ClientInterestReport | US client interest regulatory report |
| SP_CMR_Automation_FSRA_ClientInterestReport | FSRA client interest regulatory report |
| SP_CMR_Automation_ASIC_ASICG_ClientInterestReport | ASIC client interest regulatory report |
| SP_CID_DailyPanel_Club | CID daily panel with club level metrics |
